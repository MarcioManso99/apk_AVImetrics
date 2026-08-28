/*
 * BALANÇA AVÍCOLA PRO - FIRMWARE ESP32 + HX711 + BLE
 * Envia string no formato:
 * "GALPAO:01;GAIOLA:03;PESO:2.45;DATA:12/01/2026;HORA:08:34"
 */

#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include "HX711.h"

// Pinos do Módulo HX711 (Célula de Carga Suspensa)
const int LOADCELL_DOUT_PIN = 16;
const int LOADCELL_SCK_PIN = 4;
HX711 scale;

// Fator de Calibração da Célula de Carga (Ajustar com peso padrão)
float calibration_factor = 2280.0; 

// UUIDs BLE
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

BLEServer* pServer = NULL;
BLECharacteristic* pCharacteristic = NULL;
bool deviceConnected = false;

class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
      Serial.println("[BLE] App Flutter Conectado!");
    };

    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
      Serial.println("[BLE] App Flutter Desconectado. Reiniciando anúncio...");
      pServer->getAdvertising()->start();
    }
};

// Callback para receber comandos de Tara enviados pelo App
class MyCharacteristicCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      std::string rxValue = pCharacteristic->getValue();
      if (rxValue.length() > 0) {
        Serial.print("[BLE CMD Recebido]: ");
        Serial.println(rxValue.c_str());
        if (rxValue.find("TARE") != std::string::npos || rxValue.find("ZERO") != std::string::npos) {
          scale.tare();
          Serial.println("[BALANCA] Tara executada com sucesso!");
        }
      }
    }
};

void setup() {
  Serial.begin(115200);
  Serial.println("Iniciando Balança Avícola Pro - ESP32...");

  // Inicializar HX711
  scale.begin(LOADCELL_DOUT_PIN, LOADCELL_SCK_PIN);
  scale.set_scale(calibration_factor);
  scale.tare(); // Zera no boot

  // Inicializar BLE
  BLEDevice::init("Balanca_Avicola_ESP32");
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  BLEService *pService = pServer->createService(SERVICE_UUID);

  pCharacteristic = pService->createCharacteristic(
                      CHARACTERISTIC_UUID,
                      BLECharacteristic::PROPERTY_READ   |
                      BLECharacteristic::PROPERTY_WRITE  |
                      BLECharacteristic::PROPERTY_NOTIFY
                    );

  pCharacteristic->addDescriptor(new BLE2902());
  pCharacteristic->setCallbacks(new MyCharacteristicCallbacks());

  pService->start();
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  BLEDevice::startAdvertising();
  
  Serial.println("BLE Anunciando. Aguardando conexão do App Flutter...");
}

void loop() {
  if (deviceConnected) {
    // Ler peso médio de 3 amostras do HX711
    float peso = scale.get_units(3);
    if (peso < 0) peso = 0.0; // Evitar valores negativos após tara

    // Montar string padrão solicitada
    // Formato: "GALPAO:01;GAIOLA:03;PESO:2.45;DATA:12/01/2026;HORA:08:34"
    char bleBuffer[100];
    snprintf(bleBuffer, sizeof(bleBuffer), "GALPAO:01;GAIOLA:03;PESO:%.2f;DATA:12/01/2026;HORA:08:34", peso);

    pCharacteristic->setValue(bleBuffer);
    pCharacteristic->notify();

    Serial.print("Enviado BLE: ");
    Serial.println(bleBuffer);

    delay(200); // Taxa de atualização: 5Hz
  } else {
    delay(500);
  }
}
