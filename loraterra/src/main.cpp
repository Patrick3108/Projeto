#include <Arduino.h>
#include <SPI.h>
#include <LoRa.h>

// --- CONFIGURAÇÕES LORA (LilyGO T-Beam) ---
#define LORA_SCK 5
#define LORA_MISO 19
#define LORA_MOSI 27
#define LORA_CS 18
#define LORA_RST 14
#define LORA_IRQ 26

// ==========================================
// ESTRUTURA COMPLETA DA TELEMETRIA DO BARCO
// ==========================================
struct __attribute__((packed)) MiniMavlink {
  uint8_t header;         // 0xFE
  
  // GPS
  float lat;
  float lon;
  float vel;
  
  // BMS Daly
  float bms_voltage;
  float bms_current;
  
  // Motores HPM3000B
  int32_t motor1_rpm;
  float   motor1_temp;
  int32_t motor2_rpm;
  float   motor2_temp;
  
  // Victron MPPTs
  float mppt1_watts;
  float mppt1_batt_v;
  float mppt2_watts;
  float mppt2_batt_v;
  
  uint8_t checksum;
};

MiniMavlink telemetry;

// Função que joga a string formatada direto na porta COM (USB)
void printCanSend(uint32_t id, uint8_t* data, uint8_t len) {
  Serial.print("cansend can0 ");
  Serial.printf("%08X#", id);
  for (int i = 0; i < len; i++) {
    Serial.printf("%02X", data[i]);
  }
  Serial.println(); 
}

void setup() {
  Serial.begin(115200);
  delay(1000);
  
  // SINAL DE VIDA NO MONITOR SERIAL
  Serial.println("\n===========================================");
  Serial.println("   BASE RECEPTORA LORA INICIADA (115200)   ");
  Serial.println("===========================================");
  
  SPI.begin(LORA_SCK, LORA_MISO, LORA_MOSI, LORA_CS);
  LoRa.setPins(LORA_CS, LORA_RST, LORA_IRQ);
  
  if (!LoRa.begin(915E6)) {
    Serial.println("[ERRO] Rádio LoRa Base não iniciado! Verifique os pinos.");
    while (1);
  }
  
  LoRa.setSignalBandwidth(125E3);
  LoRa.setSpreadingFactor(9);
  
  Serial.println("✅ [OK] Radio LoRa configurado (915MHz).");
  Serial.println("⏳ Aguardando telemetria do barco pelo ar...");
  Serial.println("-------------------------------------------\n");
}

void loop() {
  int packetSize = LoRa.parsePacket();
  
  if (packetSize == sizeof(MiniMavlink)) {
    LoRa.readBytes((uint8_t*)&telemetry, sizeof(MiniMavlink));
    
    // Valida se o pacote realmente veio do barco (Header 0xFE)
    if (telemetry.header == 0xFE) {
      
      uint8_t buffer[8];

      // 1. GPS (ID: 0x10000001) - Lat e Lon
      memcpy(&buffer[0], &telemetry.lat, 4);
      memcpy(&buffer[4], &telemetry.lon, 4);
      printCanSend(0x10000001, buffer, 8);
      
      // 2. GPS VELOCIDADE (ID: 0x10000002)
      memcpy(&buffer[0], &telemetry.vel, 4);
      memset(&buffer[4], 0, 4); 
      printCanSend(0x10000002, buffer, 8);

      // 3. BMS DALY (ID: 0x10000003)
      memcpy(&buffer[0], &telemetry.bms_voltage, 4);
      memcpy(&buffer[4], &telemetry.bms_current, 4);
      printCanSend(0x10000003, buffer, 8);

      // 4. MOTOR 1 (ID: 0x10000004)
      memcpy(&buffer[0], &telemetry.motor1_rpm, 4);
      memcpy(&buffer[4], &telemetry.motor1_temp, 4);
      printCanSend(0x10000004, buffer, 8);

      // 5. MOTOR 2 (ID: 0x10000005)
      memcpy(&buffer[0], &telemetry.motor2_rpm, 4);
      memcpy(&buffer[4], &telemetry.motor2_temp, 4);
      printCanSend(0x10000005, buffer, 8);

      // 6. MPPT 1 (ID: 0x10000006)
      memcpy(&buffer[0], &telemetry.mppt1_watts, 4);
      memcpy(&buffer[4], &telemetry.mppt1_batt_v, 4);
      printCanSend(0x10000006, buffer, 8);

      // 7. MPPT 2 (ID: 0x10000007)
      memcpy(&buffer[0], &telemetry.mppt2_watts, 4);
      memcpy(&buffer[4], &telemetry.mppt2_batt_v, 4);
      printCanSend(0x10000007, buffer, 8);
    }
  }
}