#include <Arduino.h>
#include <SPI.h>
#include <LoRa.h>

// --- CONFIGURAÇÕES LORA (LilyGO T-Beam - Transmissor) ---
#define LORA_SCK 5
#define LORA_MISO 19
#define LORA_MOSI 27
#define LORA_CS 18
#define LORA_RST 14
#define LORA_IRQ 26

// ==========================================
// ESTRUTURA COMPLETA DA TELEMETRIA DO BARCO
// (EXATAMENTE igual à da Base Receptora)
// ==========================================
struct __attribute__((packed)) MiniMavlink {
  uint8_t header;         // Sempre 0xFE
  
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
uint32_t last_send_time = 0;

void setup() {
  Serial.begin(115200);
  delay(1000);
  
  Serial.println("\n===========================================");
  Serial.println("    GATEWAY DO BARCO (TRANSMISSOR LORA)    ");
  Serial.println("===========================================");
  
  SPI.begin(LORA_SCK, LORA_MISO, LORA_MOSI, LORA_CS);
  LoRa.setPins(LORA_CS, LORA_RST, LORA_IRQ);
  
  if (!LoRa.begin(915E6)) {
    Serial.println("[ERRO] Rádio LoRa do Barco não iniciado!");
    while (1);
  }
  
  // As configurações de rádio PRECISAM ser idênticas às da base
  LoRa.setSignalBandwidth(125E3);
  LoRa.setSpreadingFactor(9);
  
  Serial.println("✅ [OK] Rádio LoRa Transmissor configurado (915MHz).");
  Serial.println("🚀 Iniciando transmissão de telemetria...\n");
}

void loop() {
  // Dispara a telemetria a cada 500ms (2 vezes por segundo)
  if (millis() - last_send_time >= 500) {
    last_send_time = millis();

    // 1. PREENCHE OS DADOS (Valores fictícios para o teste de bancada)
    telemetry.header = 0xFE;
    
    telemetry.lat = -22.90521; // Baía de Guanabara
    telemetry.lon = -43.13171;
    telemetry.vel = 15.4;      // 15.4 nós
    
    telemetry.bms_voltage = 53.2;
    telemetry.bms_current = 45.5;
    
    telemetry.motor1_rpm = 1250;
    telemetry.motor1_temp = 42.5;
    telemetry.motor2_rpm = 1248;
    telemetry.motor2_temp = 43.1;
    
    telemetry.mppt1_watts = 350.0;
    telemetry.mppt1_batt_v = 53.2;
    telemetry.mppt2_watts = 345.0;
    telemetry.mppt2_batt_v = 53.2;
    
    telemetry.checksum = 0xFF; // Ignorado por enquanto

    // 2. ENVIA O PACOTE PELO AR
    LoRa.beginPacket();
    LoRa.write((uint8_t*)&telemetry, sizeof(MiniMavlink));
    LoRa.endPacket();

    Serial.println("📡 Pacote de 54 bytes enviado para a Base!");
  }
}