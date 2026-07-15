/*
 * MG90S single-servo sweep test on GPIO 12
 * ESP32 Arduino core 3.x (ledcAttach + ledcWrite)
 *
 * Serial: 115200
 * Expected PWM: 50 Hz -> 20 ms period
 * Duty map (12-bit): 0 deg -> 102 (~0.5 ms), 180 deg -> 492 (~2.4 ms)
 */

#include "Arduino.h"

#define SERVO_PIN 12
#define PWM_FREQ_HZ 50
#define PWM_RES_BITS 12
#define PWM_MAX_DUTY ((1 << PWM_RES_BITS) - 1)  // 4095

// MG90S-friendly pulse window (matches glove firmware)
#define DUTY_MIN_US_EQUIV 102  // ~0.5 ms
#define DUTY_MAX_US_EQUIV 492  // ~2.4 ms

#define SWEEP_STEP_DEG 10
#define STEP_DELAY_MS 400

static const float PERIOD_MS = 1000.0f / PWM_FREQ_HZ;  // 20.0 ms @ 50 Hz

int angleToDuty(int angle) {
  angle = constrain(angle, 0, 180);
  return map(angle, 0, 180, DUTY_MIN_US_EQUIV, DUTY_MAX_US_EQUIV);
}

float dutyToPulseMs(int duty) {
  return (duty * PERIOD_MS) / (float)(PWM_MAX_DUTY + 1);
}

void writeServo(int angle) {
  int duty = angleToDuty(angle);
  float pulseMs = dutyToPulseMs(duty);

  ledcWrite(SERVO_PIN, duty);

  Serial.print(F("angle="));
  Serial.print(angle);
  Serial.print(F(" deg | ledcWrite(pin "));
  Serial.print(SERVO_PIN);
  Serial.print(F(", duty="));
  Serial.print(duty);
  Serial.print(F(") | period="));
  Serial.print(PERIOD_MS, 2);
  Serial.print(F(" ms ("));
  Serial.print(PWM_FREQ_HZ);
  Serial.print(F(" Hz) | pulse~="));
  Serial.print(pulseMs, 3);
  Serial.print(F(" ms | dutyFrac="));
  Serial.println(duty / (float)(PWM_MAX_DUTY + 1), 4);
}

void setup() {
  Serial.begin(115200);
  delay(500);

  if (!ledcAttach(SERVO_PIN, PWM_FREQ_HZ, PWM_RES_BITS)) {
    Serial.println(F("ERROR: ledcAttach failed on GPIO 12"));
  }

  Serial.println();
  Serial.println(F("=== MG90S test-servo (GPIO 12) ==="));
  Serial.print(F("Target: "));
  Serial.print(PWM_FREQ_HZ);
  Serial.print(F(" Hz / "));
  Serial.print(PWM_RES_BITS);
  Serial.print(F("-bit (max duty "));
  Serial.print(PWM_MAX_DUTY);
  Serial.println(F(")"));
  Serial.print(F("Theoretical period: "));
  Serial.print(PERIOD_MS, 2);
  Serial.println(F(" ms"));
  Serial.print(F("Duty range: "));
  Serial.print(DUTY_MIN_US_EQUIV);
  Serial.print(F(" (~"));
  Serial.print(dutyToPulseMs(DUTY_MIN_US_EQUIV), 3);
  Serial.print(F(" ms) -> "));
  Serial.print(DUTY_MAX_US_EQUIV);
  Serial.print(F(" (~"));
  Serial.print(dutyToPulseMs(DUTY_MAX_US_EQUIV), 3);
  Serial.println(F(" ms)"));
  Serial.println(F("Starting continuous 0 <-> 180 sweep..."));
  Serial.println();
}

void loop() {
  // 0 -> 180
  for (int angle = 0; angle <= 180; angle += SWEEP_STEP_DEG) {
    writeServo(angle);
    delay(STEP_DELAY_MS);
  }

  delay(500);

  // 180 -> 0
  for (int angle = 180; angle >= 0; angle -= SWEEP_STEP_DEG) {
    writeServo(angle);
    delay(STEP_DELAY_MS);
  }

  delay(500);
}
