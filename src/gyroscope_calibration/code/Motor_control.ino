// --- BTS7960 Motor control pins ---
const int RPWM = 5;     // Right PWM pin for motor direction
const int LPWM = 6;     // Left PWM pin for motor direction
const int R_EN = 7;     // Right motor enable pin
const int L_EN = 8;     // Left motor enable pin

// --- Encoder pins ---
const int encoderPinA = 2;  // Encoder channel A (must be interrupt-capable)
const int encoderPinB = 3;  // Encoder channel B (must be interrupt-capable)

// --- Encoder tracking ---
volatile long encoderCount = 0;  // Tracks total encoder counts
int lastEncoded = 0;             // Stores last encoded value for direction detection
long lastEncoderCount = 0;       // Stores last count for RPM calculation

// --- Motor speed control ---
int currentRPM = 10;       // Initial motor RPM
int targetRPM = 10;        // Target motor RPM
bool forward = true;       // Direction flag (true = forward)

// --- Timing ---
unsigned long lastRPMUpdate = 0;    // Last timestamp when RPM was updated
unsigned long lastSpeedCheck = 0;   // Last timestamp when speed was measured
const unsigned long stepDelay =  72UL * 1000UL; // 72 seconds per step

// --- PWM control ---
int pwmValue = 100;         // Initial PWM duty cycle
const int pwmMax = 255;     // Max allowed PWM
const int rpmStep = 40;     // How much to increase/decrease RPM per step
const int rpmMax = 60;      // Max allowed target RPM
const int rpmMin = 10;      // Minimum allowed target RPM

// --- Encoder constants ---
const int CPR = 5200;       // Counts Per Revolution (quadrature decoding)

void setup() {
  Serial.begin(115200);     // Initialize serial monitor

  // Motor control pin setup
  pinMode(RPWM, OUTPUT);
  pinMode(LPWM, OUTPUT);
  pinMode(R_EN, OUTPUT);
  pinMode(L_EN, OUTPUT);
  digitalWrite(R_EN, HIGH);  // Enable right motor driver
  digitalWrite(L_EN, HIGH);  // Enable left motor driver

  // Encoder pin setup
  pinMode(encoderPinA, INPUT_PULLUP);  // Enable pull-up for stability
  pinMode(encoderPinB, INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(encoderPinA), updateEncoder, CHANGE); // Interrupt on A
  attachInterrupt(digitalPinToInterrupt(encoderPinB), updateEncoder, CHANGE); // Interrupt on B

  Serial.println("Starting motor ramp: 10 → 100 RPM and back...");
  lastRPMUpdate = millis();    // Initialize RPM change timer
  lastSpeedCheck = millis();   // Initialize speed check timer
}

void loop() {
  unsigned long now = millis();  // Get current timestamp

  // --- Update measured RPM every second ---
  if (now - lastSpeedCheck >= 1000) {         //Checks if 1 second has passed since the last speed check.
    long currentCount = encoderCount;         // Capture current count
    long delta = currentCount - lastEncoderCount; // Count difference in 1s
    lastEncoderCount = currentCount;          // Calculates how many ticks occurred in the last second

    float measuredRPM = (delta * 60.0) / CPR; // Converts ticks per second into revolutions per minute (RPM)

    Serial.println(measuredRPM, 2);           // Print RPM with 2 decimals

    // --- Simple Proportional Control ---
    float error = targetRPM - abs(measuredRPM); // Calculate error(Calculates the difference between target and actual RPM)
    pwmValue += error * 2.0;                     // P-control adjustment
    pwmValue = constrain(pwmValue, 0, pwmMax);   // Clamp PWM within limits

    // --- Apply PWM to motor ---
    //Applies PWM to the appropriate motor driver pin depending on direction
    //Sets the other direction pin to 0 to prevent short circuit or braking
    if (forward) {
      analogWrite(RPWM, pwmValue);  // Drive forward
      analogWrite(LPWM, 0);
    } else {
      analogWrite(LPWM, pwmValue);  // Drive reverse
      analogWrite(RPWM, 0);
    }

    lastSpeedCheck = now;           // Reset timer
  }

  // --- Change RPM every 72 seconds ---
  if (now - lastRPMUpdate >= stepDelay) {  //After stepDelay (72 sec), change targetRPM.
    if (forward) {
      if (targetRPM < rpmMax) {
        targetRPM += rpmStep;         // Step up RPM
        Serial.print("Increased RPM to: ");
        Serial.println(targetRPM);
      } else {
        forward = false;              // Reached max, reverse direction
        Serial.println("Reached 100 RPM. Reversing direction to 100 → 10 RPM.");
      }
    } else {
      if (targetRPM > rpmMin) {
        targetRPM -= rpmStep;         // Step down RPM
        Serial.print("Decreased RPM to: ");
        Serial.println(targetRPM);
      } else {
        // Reached minimum → stop motor and halt program
        Serial.println("Completed full cycle. Stopping motor.");
        analogWrite(RPWM, 0);
        analogWrite(LPWM, 0);
        while (1); // Stop everything
      }
    }
    lastRPMUpdate = now;  // Reset RPM update timer
  }
}

// --- Encoder Interrupt Handler for Quadrature Decoding ---
void updateEncoder() {
  int MSB = digitalRead(encoderPinA);        // Reads the current state of Channel A
  int LSB = digitalRead(encoderPinB);        // Reads the current state of Channel B
  int encoded = (MSB << 1) | LSB;            // Combine into 2-bit value
  int sum = (lastEncoded << 2) | encoded;    // Combines previous state and current state into a 4-bit pattern
  //known valid transitions for clockwise movement based on quadrature encoding
  if (sum == 0b0001 || sum == 0b0111 || sum == 0b1110 || sum == 0b1000)
    encoderCount++;
  // known valid transitions for counter-clockwise movement based on quadrature encoding
  if (sum == 0b0010 || sum == 0b0100 || sum == 0b1101 || sum == 0b1011)
    encoderCount--;

  lastEncoded = encoded;                     // Store for next transition
}
