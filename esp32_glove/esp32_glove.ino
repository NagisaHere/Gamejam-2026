#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

// The standard Nordic UART Service (NUS) UUIDs
#define SERVICE_UUID           "6E400001-B5A3-F393-E0A9-E50E24DCCA9E" // UART Service
#define CHARACTERISTIC_UUID_RX "6E400002-B5A3-F393-E0A9-E50E24DCCA9E" // RX Characteristic (ESP32 Receives)

#define CMD_THUMB    '0'
#define CMD_INDEX    '1'
#define CMD_MIDDLE   '2'
#define CMD_RING     '3'
#define CMD_PINKY    '4'
#define CMD_STOP_ALL '5' // Added to replace the old SERVO_CMD_STOP
#define CMD_START    'S'

#define SERVO_PIN_1 4
#define SERVO_PIN_2 5
#define SERVO_PIN_3 12
#define SERVO_PIN_4 13
#define SERVO_PIN_5 14

#define VIBRATE_PIN_1 16
#define VIBRATE_PIN_2 17
#define VIBRATE_PIN_3 18
#define VIBRATE_PIN_4 8
#define VIBRATE_PIN_5 3

#define BAUD_RATE 9600

// 180 Servo limits (Degrees)
#define SERVO_MIN 0
#define SERVO_MAX 180

#define NUM_SERVOS 5
#define NUM_VIBS 5 // Fixed missing definition

int servoPins[NUM_SERVOS] = {SERVO_PIN_1, SERVO_PIN_2, SERVO_PIN_3, SERVO_PIN_4, SERVO_PIN_5};
int vibratePins[NUM_VIBS] = {VIBRATE_PIN_1, VIBRATE_PIN_2, VIBRATE_PIN_3, VIBRATE_PIN_4, VIBRATE_PIN_5}; // Fixed missing array

// --- Native ESP32 v3 writeServo Helper ---
void writeServo(int pin, int angle) {
  angle = constrain(angle, 0, 180);
  int dutyCycle = map(angle, 0, 180, 102, 492);
  analogWrite(pin, dutyCycle);
}

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


void startupSweep() {
  Serial.println("Performing startup servo sweep sequentially...");
  
  // Loop through each servo one by one
  for(int s = 0; s < NUM_SERVOS; s++) {
      Serial.print("Testing Servo on Pin: ");
      Serial.println(servoPins[s]);

      // Set to 0 degrees
      writeServo(servoPins[s], SERVO_MIN);
      delay(1000); 
      
      // Set to 180 degrees
      writeServo(servoPins[s], SERVO_MAX);
      delay(1000);
      
      // Set back to 0 degrees
      writeServo(servoPins[s], SERVO_MIN);
      delay(1000);
  }
  
  Serial.println("Sequential sweep complete.");
}

class MyCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      String rxValue = pCharacteristic->getValue();

      if (rxValue.length() > 0) {
        Serial.print("Received from Python: ");
        
        for (int i = 0; i < rxValue.length(); i++) {
          char cmd = rxValue[i];
          Serial.print(cmd);
          
          switch (cmd) {
            case CMD_THUMB:
              writeServo(servoPins[0], SERVO_MAX);
              break;
              
            case CMD_INDEX:
              writeServo(servoPins[1], SERVO_MAX);
              break;
              
            case CMD_MIDDLE:
              writeServo(servoPins[2], SERVO_MAX);
              break;
              
            case CMD_RING:
              writeServo(servoPins[3], SERVO_MAX);
              break;
              
            case CMD_PINKY:
              writeServo(servoPins[4], SERVO_MAX);
              break;
              
            case CMD_STOP_ALL:
              // Reset all servos to minimum (0 deg)
              for(int s = 0; s < NUM_SERVOS; s++) {
                  writeServo(servoPins[s], SERVO_MIN);
              }
              break;
            case CMD_START:
              startupSweep();
              break;
              
            default:
              // Ignore any unexpected characters (like newline characters)
              break;
          }
        }
        Serial.println(); // Add a newline in the serial monitor
      }
    }
};


void setup() {
  Serial.begin(BAUD_RATE);

  // Initialize and configure all 5 servos using native v3 API
  for (int i = 0; i < NUM_SERVOS; i++) {
    pinMode(servoPins[i], OUTPUT);
    analogWriteFrequency(servoPins[i], 50); 
    analogWriteResolution(servoPins[i], 12); 
  }

  // Fixed the loop logic: changed i++ to j++ and used the new vibratePins array
  for (int j = 0; j < NUM_VIBS; j++) {
    pinMode(vibratePins[j], OUTPUT);
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