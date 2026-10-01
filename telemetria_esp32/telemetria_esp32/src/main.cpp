#include <Arduino.h>
#include <SPI.h>
#include <mcp_can.h>
#include <CAN.h>
#include <VictronBLE.h>
#include <BLEDevice.h>

// =========================================================================
// 1. CREDENCIAIS E CONFIGURAÇÕES DA REDE
// =========================================================================

// Seu Node ID na rede UAVCAN
const uint8_t MEU_NODE_ID = 50; 

// --- DADOS DO VICTRON MPPT [PREENCHER] ---
const char* mppt_mac = "00:00:00:00:00:00"; 
const char* mppt_key = "INSERIR_AQUI_SUA_CHAVE_DE_32_DIGITOS";

// --- DADOS DO DALY BMS [PREENCHER] ---
static BLEAddress dalyMac("11:22:33:44:55:66");

// --- IDs DOS MOTORES EZCONTROL [PREENCHER] ---
// Consulte o manual EZControl v1.0 para os IDs exatos de Tx dos ESCs
const uint32_t ID_CAN_MOTOR_1 = 0x0CF11E01; // Exemplo Motor 1 (Bombordo)
const uint32_t ID_CAN_MOTOR_2 = 0x0CF11E02; // Exemplo Motor 2 (Boreste)

// =========================================================================
// 2. VARIÁVEIS GLOBAIS E TIMERS
// =========================================================================
VictronBLE victron;
MCP_CAN motorCAN(15); // MCP2515 no pino CS 15

static BLEUUID dalyServiceUUID("0000ff00-0000-1000-8000-00805f9b34fb");
static BLEUUID dalyRxUUID("0000ff01-0000-1000-8000-00805f9b34fb");
static BLEUUID dalyTxUUID("0000ff02-0000-1000-8000-00805f9b34fb");
uint8_t cmdDaly[13] = {0xA5, 0x40, 0x90, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x7D};

unsigned long tempoAnteriorBLE = 0;
bool lendoVictron = true;

// =========================================================================
// 3. FUNÇÕES MATEMÁTICAS (UAVCAN)
// =========================================================================

// Comprime um float de 32bits para Float16 (Padrão exigido pelo UAVCAN)
uint16_t floatToFloat16(float value) {
  uint32_t bits32;
  memcpy(&bits32, &value, sizeof(float));
  uint32_t sign = (bits32 >> 16) & 0x8000;
  int32_t exponent = ((bits32 >> 23) & 0xFF) - 127 + 15;
  uint32_t mantissa = bits32 & 0x007FFFFF;

  if (exponent <= 0) return sign; 
  else if (exponent >= 31) return sign | 0x7C00;
  else return sign | (exponent << 10) | (mantissa >> 13);
}

// =========================================================================
// 4. TRADUTORES PARA UAVCAN (ENVIOS)
// =========================================================================

void publicarBateriaUAVCAN(float tensao, float corrente) {
  uint16_t v16 = floatToFloat16(tensao);
  uint16_t i16 = floatToFloat16(corrente);
  
  uint8_t payload[4];
  payload[0] = v16 & 0xFF;         
  payload[1] = (v16 >> 8) & 0xFF;  
  payload[2] = i16 & 0xFF;         
  payload[3] = (i16 >> 8) & 0xFF;  

  uint32_t uavcan_id = (6 << 24) | (1092 << 8) | MEU_NODE_ID; // 1092 = BatteryInfo

  CAN.beginExtendedPacket(uavcan_id);
  for(int i = 0; i < 4; i++) CAN.write(payload[i]);
  CAN.endPacket();
}

void publicarEscUAVCAN(uint8_t esc_index, long rpm, float tensao, float corrente, float tempC) {
  uint16_t v16 = floatToFloat16(tensao);
  uint16_t i16 = floatToFloat16(corrente);
  
  // UAVCAN exige Temperatura em Kelvin
  uint16_t t16 = floatToFloat16(tempC + 273.15f); 
  
  uint8_t payload[16] = {0}; // Pacote EscStatus usa 16 bytes
  
  // Bytes 0-3: Error count (Deixado em 0)
  
  // Bytes 4-5: Tensão
  payload[4] = v16 & 0xFF;
  payload[5] = (v16 >> 8) & 0xFF;
  
  // Bytes 6-7: Corrente
  payload[6] = i16 & 0xFF;
  payload[7] = (i16 >> 8) & 0xFF;
  
  // Bytes 8-9: Temperatura
  payload[8] = t16 & 0xFF;
  payload[9] = (t16 >> 8) & 0xFF;
  
  // Bytes 10-13: RPM (32 bits Little Endian)
  payload[10] = rpm & 0xFF;
  payload[11] = (rpm >> 8) & 0xFF;
  payload[12] = (rpm >> 16) & 0xFF;
  payload[13] = (rpm >> 24) & 0xFF;
  
  // Bytes 14-15: Power Rating (7 bits) + ESC Index (5 bits)
  uint8_t power_rating = 0; // Desconhecido = 0
  payload[14] = (power_rating & 0x7F) | ((esc_index & 0x01) << 7);
  payload[15] = (esc_index >> 1) & 0x0F;

  uint32_t uavcan_id = (5 << 24) | (1034 << 8) | MEU_NODE_ID; // 1034 = EscStatus

  CAN.beginExtendedPacket(uavcan_id);
  for(int i = 0; i < 16; i++) CAN.write(payload[i]);
  CAN.endPacket();
}

// =========================================================================
// 5. RECEPÇÃO DE DADOS: RÁDIO (VICTRON E DALY)
// =========================================================================

void onVictronData(const VictronDevice* dev) {
  if (dev->deviceType == DEVICE_TYPE_SOLAR_CHARGER) {
    publicarBateriaUAVCAN(dev->solar.batteryVoltage, dev->solar.batteryCurrent);
    Serial.println("[VICTRON] Dados MPPT publicados no UAVCAN.");
  }
}

static void onDalyData(BLERemoteCharacteristic* pChar, uint8_t* pData, size_t length, bool isNotify) {
  if (length == 13 && pData[0] == 0xA5) {
    float vBat = ((pData[4] << 8) | pData[5]) * 0.1f;
    float iBat = (((pData[8] << 8) | pData[9]) - 30000) * 0.1f;
    
    publicarBateriaUAVCAN(vBat, iBat);
    Serial.println("[DALY] Bateria Geral publicada no UAVCAN.");
  }
}

void conectarLerDaly() {
  BLEClient* pClient = BLEDevice::createClient();
  if (pClient->connect(dalyMac)) {
    BLERemoteService* pSvc = pClient->getService(dalyServiceUUID);
    if (pSvc) {
      BLERemoteCharacteristic* pRx = pSvc->getCharacteristic(dalyRxUUID);
      BLERemoteCharacteristic* pTx = pSvc->getCharacteristic(dalyTxUUID);
      if (pRx && pTx) {
        if(pRx->canNotify()) pRx->registerForNotify(onDalyData);
        pTx->writeValue(cmdDaly, 13);
        delay(300); // Aguarda Daly responder
      }
    }
    pClient->disconnect();
  }
  delete pClient;
}

// =========================================================================
// 6. RECEPÇÃO DE DADOS: CABO (MOTORES VIA MCP2515)
// =========================================================================

void lerMotoresEZControl() {
  long unsigned int rxId;
  unsigned char len = 0;
  unsigned char rxBuf[8];

  if(CAN_MSGAVAIL == motorCAN.checkReceive()) {
    motorCAN.readMsgBuf(&rxId, &len, rxBuf);
    
    // Filtro para ignorar pacotes que não sejam dos nossos 2 motores
    if(rxId == ID_CAN_MOTOR_1 || rxId == ID_CAN_MOTOR_2) {
      
      // Define quem é o motor na rede UAVCAN (0 = M1, 1 = M2)
      uint8_t index_motor = (rxId == ID_CAN_MOTOR_1) ? 0 : 1;
      
      // [PREENCHER] A decodificação abaixo é um formato J1939 genérico. 
      // Ajuste os bytes exatos [0, 1, 2...] conforme o manual EZControl v1.0
      long rpm = (rxBuf[1] << 8) | rxBuf[0]; 
      float volt = rxBuf[2] * 0.1f;
      float curr = rxBuf[3] * 0.1f;
      float temp = rxBuf[4] - 40; // EZControl geralmente tem offset de -40
      
      // Envia para o painel do barco
      publicarEscUAVCAN(index_motor, rpm, volt, curr, temp);
      
      Serial.printf("[MOTOR %d] Publicado! RPM: %d | %.1fV\n", index_motor, rpm, volt);
    }
  }
}

// =========================================================================
// 7. SETUP E LOOP PRINCIPAL
// =========================================================================

void setup() {
  Serial.begin(115200);
  delay(1000);
  BLEDevice::init(""); 

  // Inicia UAVCAN Nativo (Display) - Pinos 4 e 5 a 250kbps
  CAN.setPins(4, 5);
  if (!CAN.begin(250E3)) {
    Serial.println("ERRO: Rede UAVCAN Nativa falhou!");
  }

  // Inicia Motores EZControl (MCP2515 SPI) a 250kbps (Cristal 8MHz)
  if(motorCAN.begin(MCP_ANY, CAN_250KBPS, MCP_8MHZ) != CAN_OK) {
    Serial.println("ERRO: MCP2515 dos Motores falhou!");
  } else {
    motorCAN.setMode(MCP_LISTENONLY); // Modo sniffer seguro
    Serial.println("MCP2515 dos Motores Iniciado OK.");
  }

  // Inicia Victron
  victron.setCallback(onVictronData);
  victron.addDevice("MPPT", mppt_mac, mppt_key, DEVICE_TYPE_SOLAR_CHARGER);
  victron.begin();
}

void loop() {
  // 1. Lê a rede dos 2 motores sem travar o processador
  lerMotoresEZControl(); 

  // 2. Maestro do Bluetooth (Divide o tempo da antena)
  unsigned long tempoAtual = millis();
  if (lendoVictron) {
    victron.loop();
    if (tempoAtual - tempoAnteriorBLE > 8000) { // Ouve MPPT por 8 segundos
      lendoVictron = false;
      tempoAnteriorBLE = tempoAtual;
    }
  } else {
    conectarLerDaly(); // Pega dados da Bateria Principal ativamente
    lendoVictron = true;
    tempoAnteriorBLE = millis();
  }
}