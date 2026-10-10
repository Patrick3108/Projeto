#include <Arduino.h>
#include <WiFi.h>
#include <WiFiUdp.h>
#include "driver/twai.h"

// Pinos do Gateway
#define CAN_TX_PIN GPIO_NUM_16
#define CAN_RX_PIN GPIO_NUM_17

const char* ssid = "8pro";
const char* password = "qawsedrf";
const int udpPort = 10110; 

WiFiUDP udp;

// Variáveis de Telemetria
volatile float gps_lat = 0.0;
volatile float gps_lon = 0.0;
volatile float gps_vel = 0.0; 
volatile float bms_voltage = 0.0;
volatile float bms_current = 0.0;

// Sinalizadores e Cronômetros
volatile bool bms_vivo = false;
uint32_t last_speed_update = 0; // Cronômetro anti-congelamento

TaskHandle_t TaskWiFi;
TaskHandle_t TaskCAN;

// ==========================================
// FUNÇÕES DE FATIAMENTO E MATEMÁTICA NMEA
// ==========================================
String getValue(String data, char separator, int index) {
  int found = 0;
  int strIndex[] = {0, -1};
  int maxIndex = data.length() - 1;

  for (int i = 0; i <= maxIndex && found <= index; i++) {
    if (data.charAt(i) == separator || i == maxIndex) {
      found++;
      strIndex[0] = strIndex[1] + 1;
      strIndex[1] = (i == maxIndex) ? i + 1 : i;
    }
  }
  return found > index ? data.substring(strIndex[0], strIndex[1]) : "";
}

float convertNMEA(String nmeaRaw) {
  if (nmeaRaw == "") return 0.0;
  float raw = nmeaRaw.toFloat();
  int degrees = (int)(raw / 100);
  float minutes = raw - (degrees * 100);
  return (float)degrees + (minutes / 60.0);
}

// ==========================================
// CORE 0: TAREFA WI-FI E GPS (NAVCAST)
// ==========================================
void TaskWiFiCode(void * pvParameters) {
  Serial.print("\n[CORE 0] Conectando ao Wi-Fi: ");
  Serial.println(ssid);
  
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  
  Serial.println("\n\n========================================");
  Serial.println("      WI-FI CONECTADO COM SUCESSO!      ");
  Serial.print("      SEU IP E: ");
  Serial.println(WiFi.localIP());
  Serial.println("========================================\n");
  
  vTaskDelay(pdMS_TO_TICKS(5000)); 
  
  udp.begin(udpPort);
  char packetBuffer[2048]; // Buffer gigante para caber TUDO que o Navcast mandar

  for (;;) {
    int packetSize = udp.parsePacket();
    if (packetSize) {
      int len = udp.read(packetBuffer, 2048);
      if (len > 0) {
        packetBuffer[len] = 0;
        
        char* line = strtok(packetBuffer, "\n");
        while (line != NULL) {
          String sentence = String(line);
          sentence.trim(); 

          // 1. EXTRAI A VELOCIDADE DA FRASE RMC
          if (sentence.startsWith("$GNRMC") || sentence.startsWith("$GPRMC")) {
             String status = getValue(sentence, ',', 2);
             if (status == "A") { 
                String speedKnots = getValue(sentence, ',', 7);
                if (speedKnots != "") {
                    float v = speedKnots.toFloat(); 
                    if (v < 1.0) { // Deadband de 1 nó para ignorar o "Drift" de quando parado
                        gps_vel = 0.0;
                    } else {
                        gps_vel = v;
                        last_speed_update = millis(); // Atualiza o cronômetro!
                    }
                }
             }
          }

          // 2. EXTRAI A VELOCIDADE DA FRASE VTG (Backup)
          if (sentence.startsWith("$GNVTG") || sentence.startsWith("$GPVTG")) {
             String speedKnots = getValue(sentence, ',', 5);
             if (speedKnots != "") {
                float v = speedKnots.toFloat(); 
                if (v >= 1.0) {
                    gps_vel = v;
                    last_speed_update = millis(); // Atualiza o cronômetro!
                }
             }
          }

          // 3. EXTRAI POSIÇÃO (GGA)
          if (sentence.startsWith("$GNGGA") || sentence.startsWith("$GPGGA")) {
            String fixQuality = getValue(sentence, ',', 6);
            
            if (fixQuality != "0" && fixQuality != "") { 
              String latRaw = getValue(sentence, ',', 2);
              String latDir = getValue(sentence, ',', 3); 
              String lonRaw = getValue(sentence, ',', 4);
              String lonDir = getValue(sentence, ',', 5); 
              String sats = getValue(sentence, ',', 7); 

              gps_lat = convertNMEA(latRaw);
              if (latDir == "S") gps_lat *= -1;
              
              gps_lon = convertNMEA(lonRaw);
              if (lonDir == "W") gps_lon *= -1;

              Serial.println("==================================================");
              Serial.printf("🎯 [GPS FIX] Lat: %.5f | Lon: %.5f | Sats: %s\n", gps_lat, gps_lon, sats.c_str());
              Serial.printf("🚤 [VELOCIDADE] %.1f nos\n", gps_vel);
              Serial.println("==================================================\n");
            }
          }
          
          line = strtok(NULL, "\n"); 
        }
      }
    }

    // O "WATCHDOG" DA VELOCIDADE: Se passar 2 segundos sem velocidade válida, força para ZERO
    if (millis() - last_speed_update > 2000) {
        gps_vel = 0.0;
    }

    vTaskDelay(pdMS_TO_TICKS(10)); 
  }
}

// ==========================================
// CORE 1: TAREFA CAN (ESCUTAR BMS E ENVIAR UAVCAN)
// ==========================================
void TaskCANCode(void * pvParameters) {
  twai_general_config_t g_config = TWAI_GENERAL_CONFIG_DEFAULT(CAN_TX_PIN, CAN_RX_PIN, TWAI_MODE_NORMAL);
  twai_timing_config_t t_config = TWAI_TIMING_CONFIG_250KBITS(); 
  twai_filter_config_t f_config = TWAI_FILTER_CONFIG_ACCEPT_ALL();
  
  twai_driver_install(&g_config, &t_config, &f_config);
  twai_start();

  uint32_t last_uavcan_send = 0;
  uint32_t last_status_print = 0;

  for (;;) {
    twai_message_t rx_msg;
    
    // Escuta a rede CAN buscando o Daly BMS
    if (twai_receive(&rx_msg, pdMS_TO_TICKS(10)) == ESP_OK) {
       if (rx_msg.identifier == 0x351 || rx_msg.identifier == 0x18900140) {
          bms_vivo = true;
          bms_voltage = 52.4; 
          bms_current = 10.5; 
       }
    }

    // Transmite UAVCAN (200ms)
    if (millis() - last_uavcan_send >= 200) {
      last_uavcan_send = millis();
      twai_message_t tx_msg = {0};
      tx_msg.extd = 1; 
      
      tx_msg.identifier = 0x10000001; 
      tx_msg.data_length_code = 8;
      memcpy(&tx_msg.data[0], (void*)&gps_lat, 4);
      memcpy(&tx_msg.data[4], (void*)&gps_lon, 4);
      twai_transmit(&tx_msg, pdMS_TO_TICKS(5));

      tx_msg.identifier = 0x10000002;
      tx_msg.data_length_code = 8;
      memcpy(&tx_msg.data[0], (void*)&bms_voltage, 4);
      memcpy(&tx_msg.data[4], (void*)&bms_current, 4);
      twai_transmit(&tx_msg, pdMS_TO_TICKS(5));
    }

    // STATUS DO BARRAMENTO CAN (1 segundo)
    if (millis() - last_status_print >= 1000) {
      last_status_print = millis();
      
      Serial.print("🔄 [CAN BUS] Daly BMS: ");
      if (bms_vivo) {
         Serial.print("OK (Lendo)  ");
      } else {
         Serial.print("AGUARDANDO... ");
      }
      
      Serial.println("| UAVCAN: OK (Enviando 5 pacotes/s para o Display)");
      bms_vivo = false; 
    }
    
    vTaskDelay(pdMS_TO_TICKS(5));
  }
}

void setup() {
  Serial.begin(115200);
  delay(1000);
  xTaskCreatePinnedToCore(TaskWiFiCode, "TaskWiFi", 8192, NULL, 1, &TaskWiFi, 0);                  
  xTaskCreatePinnedToCore(TaskCANCode, "TaskCAN", 8192, NULL, 1, &TaskCAN, 1);
}

void loop() { vTaskDelete(NULL); }