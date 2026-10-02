#include <Arduino.h>
#include <WiFi.h>
#include <ArduinoOTA.h>
#include <BLEDevice.h>
#include <BLEScan.h>
#include <BLEAdvertisedDevice.h>
#include <SPI.h>
#include <mcp_can.h>
#include "mbedtls/aes.h"

// ==========================================
// CONFIGURAÇÕES DO MCP2515 (DISPLAY)
// ==========================================
const int SPI_CS_PIN = 5;
const int CAN_INT_PIN = 4;
MCP_CAN CAN(SPI_CS_PIN);

// ==========================================
// ESTRUTURA DOS MPPTs VICTRON
// ==========================================
struct VictronMPPT {
  String mac;
  uint8_t bindKey[16];
  uint16_t idTensao;
  uint16_t idCorrente;
};

// Array contendo os seus dois controladores de carga
VictronMPPT mppts[2] = {
  { // ================= MPPT 1 =================
    "ff:8b:3a:10:f6:e6",
    {0x9b, 0x7b, 0x3c, 0xd5, 0x58, 0x27, 0x6c, 0xca, 0x07, 0x57, 0x5e, 0x1d, 0x8f, 0x7c, 0xd0, 0xcf},
    200, 
    201  
  },
  { // ================= MPPT 2 =================
    "d1:94:ad:e1:ba:e9",
    {0xaa, 0xef, 0x28, 0x6a, 0x8c, 0xc3, 0x1a, 0x21, 0xdd, 0xd4, 0x8e, 0x6f, 0xb9, 0x61, 0x82, 0x8d}, 
    202, 
    203  
  }
};

BLEScan* pBLEScan;

// ==========================================
// FUNÇÃO: ENVIAR UAVCAN (Padrão Float32)
// ==========================================
void enviarUavcan(uint16_t subjectId, float valor) {
  // Cabeçalho UAVCAN v1 (Cyphal)
  uint32_t canId = (4UL << 26) | ((uint32_t)(subjectId & 0x1FFF) << 7) | 55;
  
  byte payload[8] = {0}; 
  
  // Copia nativamente os 4 bytes do Float para o pacote (Formato IEEE 754)
  memcpy(payload, &valor, sizeof(float)); 

  // Envia via CAN (Estendido / 29 bits)
  CAN.sendMsgBuf(canId, 1, 8, payload);
}

// ==========================================
// CALLBACK BLE (LEITURA DE MÚLTIPLOS MPPTs)
// ==========================================
class MyAdvertisedDeviceCallbacks : public BLEAdvertisedDeviceCallbacks {
    void onResult(BLEAdvertisedDevice advertisedDevice) {
      // CORREÇÃO AQUI: adicionado o .c_str() para converter para String do Arduino
      String deviceMac = advertisedDevice.getAddress().toString().c_str();
      
      int mpptIndex = -1;
      for (int i = 0; i < 2; i++) {
        if (deviceMac.equalsIgnoreCase(mppts[i].mac)) {
          mpptIndex = i;
          break;
        }
      }

      if (mpptIndex == -1) return; 

      if (advertisedDevice.haveManufacturerData()) {
        std::string rawData = advertisedDevice.getManufacturerData();
        
        if (rawData.length() >= 22 && rawData[2] == 0x10) {
          if (rawData[9] == mppts[mpptIndex].bindKey[0]) {
            
            uint8_t nonce[16] = {0};
            nonce[0] = rawData[7]; 
            nonce[1] = rawData[8]; 

            uint8_t ciphertext[12];
            for (int i = 0; i < 12; i++) ciphertext[i] = rawData[10 + i];

            uint8_t decrypted[12] = {0}; 

            mbedtls_aes_context aes;
            mbedtls_aes_init(&aes);
            mbedtls_aes_setkey_enc(&aes, mppts[mpptIndex].bindKey, 128);
            size_t nc_off = 0;
            uint8_t stream_block[16] = {0};
            mbedtls_aes_crypt_ctr(&aes, 12, &nc_off, nonce, stream_block, ciphertext, decrypted);
            mbedtls_aes_free(&aes);

            int16_t raw_v = decrypted[2] | (decrypted[3] << 8);
            float tensao_real = raw_v / 100.0f;

            int16_t raw_c = decrypted[4] | (decrypted[5] << 8);
            float corrente_real = raw_c / 10.0f;

            // IMPRESSÃO CLARA DE QUAL MPPT FOI LIDO
            Serial.printf("[MPPT %d] Tensao: %5.2f V | Corrente: %5.2f A\n", mpptIndex + 1, tensao_real, corrente_real);
            
            // Envia para a CAN
            enviarUavcan(mppts[mpptIndex].idTensao, tensao_real);
            enviarUavcan(mppts[mpptIndex].idCorrente, corrente_real);
          }
        }
      }
    }
};

void setup() {
  Serial.begin(115200);
  Serial.println("\n--- TRADUTOR VICTRON DUAL -> UAVCAN INICIADO ---");

  if(CAN.begin(MCP_ANY, CAN_250KBPS, MCP_8MHZ) == CAN_OK) {
    Serial.println("MCP2515 Inciado a 250kbps!");
    CAN.setMode(MCP_NORMAL);
  } else {
    Serial.println("Falha no MCP2515!");
  }

  BLEDevice::init("");
  pBLEScan = BLEDevice::getScan();
  pBLEScan->setAdvertisedDeviceCallbacks(new MyAdvertisedDeviceCallbacks());
  pBLEScan->setActiveScan(true);
  pBLEScan->setInterval(100);
  pBLEScan->setWindow(99); 
}

void loop() {
  pBLEScan->start(1, false);
  pBLEScan->clearResults(); 
  delay(10);
}