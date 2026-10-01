#include <Arduino.h>
#include <SPI.h>
#include <NimBLEDevice.h>
#include "mbedtls/aes.h"

const std::string MAC_MPPT1 = "ff:8b:3a:10:f6:e6";

// A chave que você pegou no App
const uint8_t KEY_MPPT1[16] = {0x9b, 0x7b, 0x3c, 0xd5, 0x58, 0x27, 0x6c, 0xca, 0x07, 0x57, 0x5e, 0x1d, 0x8f, 0x7c, 0xd0, 0xcf};

// Função que descriptografa e caça a tensão de 31.98V
void procurar_tensao(const uint8_t* key, const uint8_t* dados_brutos, int tamanho, String nome_teste) {
    mbedtls_aes_context aes;
    mbedtls_aes_init(&aes);
    mbedtls_aes_setkey_enc(&aes, key, 128); 
    
    uint8_t nonce_counter[16] = {0};
    nonce_counter[0] = dados_brutos[3];
    nonce_counter[1] = dados_brutos[4];

    size_t nc_off = 0;
    uint8_t stream_block[16] = {0};
    uint8_t desc[32] = {0};
    int tam_cripto = tamanho - 5;

    mbedtls_aes_crypt_ctr(&aes, tam_cripto, &nc_off, nonce_counter, stream_block, &dados_brutos[5], desc);
    mbedtls_aes_free(&aes);

    Serial.printf("\n[%s] DEC: ", nome_teste.c_str());
    for(int i = 0; i < tam_cripto; i++) {
        Serial.printf("%02X ", desc[i]);
    }
    Serial.println();

    bool achou = false;
    // Varre todos os bytes descriptografados procurando ~31.98V
    for(int i = 0; i < tam_cripto - 1; i++) {
        // Testa leitura Little-Endian (Padrão Victron)
        uint16_t val_little = desc[i] | (desc[i+1] << 8);
        float volts_l = val_little / 100.0;
        
        // Testa leitura Big-Endian
        uint16_t val_big = (desc[i] << 8) | desc[i+1];
        float volts_b = val_big / 100.0;

        // Se achar qualquer tensão entre 31.00V e 32.50V, nós achamos o tesouro!
        if(volts_l >= 31.0 && volts_l <= 32.5) {
            Serial.printf("  => BINGO!!! Tensao %.2fV encontrada no offset %d (Little-Endian)\n", volts_l, i);
            achou = true;
        }
        if(volts_b >= 31.0 && volts_b <= 32.5) {
            Serial.printf("  => BINGO!!! Tensao %.2fV encontrada no offset %d (Big-Endian)\n", volts_b, i);
            achou = true;
        }
    }
    
    if(!achou) {
        Serial.println("  -> Falhou. Tensao da fonte nao encontrada neste teste.");
    }
}

class BLECallbacks : public NimBLEAdvertisedDeviceCallbacks {
    void onResult(NimBLEAdvertisedDevice* advertisedDevice) {
        std::string mac = advertisedDevice->getAddress().toString();
        
        if (mac == MAC_MPPT1 && advertisedDevice->haveManufacturerData()) {
            std::string payload = advertisedDevice->getManufacturerData();
            const uint8_t* dados_brutos = (const uint8_t*)payload.data();
            int tamanho = payload.length();

            if (tamanho > 10 && dados_brutos[0] == 0xE1 && dados_brutos[1] == 0x02 && dados_brutos[2] == 0x01) {
                Serial.println("\n==================================================");
                Serial.printf("Pacote capturado do MAC: %s\n", mac.c_str());
                
                // 1. Testa a chave normal
                procurar_tensao(KEY_MPPT1, dados_brutos, tamanho, "TESTE 1 - CHAVE NORMAL");

                // 2. Testa a chave de trás pra frente (Reverse Endianness)
                uint8_t rev_key[16];
                for(int i=0; i<16; i++) rev_key[i] = KEY_MPPT1[15-i];
                procurar_tensao(rev_key, dados_brutos, tamanho, "TESTE 2 - CHAVE INVERTIDA");
            }
        }
    }
};

void setup() {
    Serial.begin(115200);
    Serial.println("\n--- INICIANDO CAÇA-TESOURO DA TENSAO (31.98V) ---");
    Serial.println("Aguardando pacotes...");

    NimBLEDevice::init("");
    NimBLEScan* pBLEScan = NimBLEDevice::getScan();
    pBLEScan->setAdvertisedDeviceCallbacks(new BLECallbacks());
    pBLEScan->setActiveScan(true); 
    pBLEScan->setInterval(100);
    pBLEScan->setWindow(99); 
}

void loop() {
    NimBLEDevice::getScan()->start(5, false);
    NimBLEDevice::getScan()->clearResults();
}