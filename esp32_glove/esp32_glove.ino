#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <ESP32Servo.h>

// The standard Nordic UART Service (NUS) UUIDs
#define SERVICE_UUID           "6E400001-B5A3-F393-E0A9-E50E24DCCA9E" // UART Service
#define CHARACTERISTIC_UUID_RX "6E400002-B5A3-F393-E0A9-E50E24DCCA9E" // RX Characteristic (ESP32 Receives)

#define SERVO_CMD_FORWARD '1'
#define SERVO_CMD_STOP '3'

#define SERVO_PIN_1 4
#define SERVO_PIN_2 5
#define SERVO_PIN_3 6
#define SERVO_PIN_4 7
#define SERVO_PIN_5 15

#define VIBRATE_PIN_1 16
#define VIBRATE_PIN_2 17
#define VIBRATE_PIN_3 18
#define VIBRATE_PIN_4 8
#define VIBRATE_PIN_5 3

#define BAUD_RATE 9600

// 180 Servo limits (Degrees)
#define SERVO_MIN 0
#define SERVO_MAX 180

// Microsecond bounds for attach()
#define MIN_MICROS 500
#define MAX_MICROS 2400

#define NUM_SERVOS 5

// --- NEW: Arrays for cleaner multi-servo management ---
Servo myServos[NUM_SERVOS]; // Array of 5 servo objects
int servoPins[NUM_SERVOS] = {SERVO_PIN_1, SERVO_PIN_2, SERVO_PIN_3, SERVO_PIN_4, SERVO_PIN_5};

// Server Callbacks to handle reconnecting
class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      Serial.println("Client Connected!");
    };

    void onDisconnect(BLEServer* pServer) {
      Serial.println("Client Disconnected. Restarting advertising...");
      BLEDevice::startAdvertising(); 
    }
};

class MyCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      String rxValue = pCharacteristic->getValue();

      if (rxValue.length() > 0) {
        Serial.print("Received from Python: ");
        for (int i = 0; i < rxValue.length(); i++) {
          Serial.print(rxValue[i]);
          
          if (rxValue[i] == SERVO_CMD_FORWARD) {
                // Loop through all 5 servos and set to MAX (180 deg)
                for(int s = 0; s < NUM_SERVOS; s++) {
                    myServos[s].write(SERVO_MAX);
                }
          } else if (rxValue[i] == SERVO_CMD_STOP) {
                // Loop through all 5 servos and set to MIN (0 deg)
                for(int s = 0; s < NUM_SERVOS; s++) {
                    myServos[s].write(SERVO_MIN);
                }
          }
        }
        Serial.println(); // Add a newline in the serial monitor
      }
    }
};

void startupSweep() {
  Serial.println("Performing startup servo sweep on ALL servos...");
  
  // Set all to MIN
  for(int s = 0; s < NUM_SERVOS; s++) {
      myServos[s].write(SERVO_MIN);
  }
  delay(500); // Wait for servos to reach position
  
  // Set all to MAX
  for(int s = 0; s < NUM_SERVOS; s++) {
      myServos[s].write(SERVO_MAX);
  }
  delay(500);
  
  // Set all back to MIN
  for(int s = 0; s < NUM_SERVOS; s++) {
      myServos[s].write(SERVO_MIN);
  }
  delay(500);
  
  Serial.println("Sweep complete.");
}

void setup() {
  Serial.begin(BAUD_RATE);

  ESP32PWM::allocateTimer(0);
  ESP32PWM::allocateTimer(1);
  ESP32PWM::allocateTimer(2);
  ESP32PWM::allocateTimer(3);

  // Initialize and attach all 5 servos using a loop
  for (int i = 0; i < NUM_SERVOS; i++) {
    myServos[i].setPeriodHertz(50); // Standard 50Hz
    // Attach using the pin from our array, and standard microsecond bounds
    myServos[i].attach(servoPins[i], MIN_MICROS, MAX_MICROS); 
  }

  startupSweep();

  // Name the device
  BLEDevice::init("ESP32S3_BLE_UART");

  // Create the BLE Server
  BLEServer *pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  // Create the BLE Service using the NUS UUID
  BLEService *pService = pServer->createService(SERVICE_UUID);

  // Create a BLE Characteristic for Receiving Data (RX)
  BLECharacteristic *pRxCharacteristic = pService->createCharacteristic(
                       CHARACTERISTIC_UUID_RX,
                       BLECharacteristic::PROPERTY_WRITE
                     );

  pRxCharacteristic->setCallbacks(new MyCallbacks());
  pService->start();

  // Start advertising
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  BLEDevice::startAdvertising();
  
  Serial.println("ESP32-S3 BLE UART Started. Waiting for connections...");
}

void loop() {
  delay(2000); 
}