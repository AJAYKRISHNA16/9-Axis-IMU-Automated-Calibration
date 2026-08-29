// === Motor Control Pins (BTS7960) ===
const int RPWM = 5;   // Right-direction PWM pin
const int LPWM = 6;   // Left-direction PWM pin
const int R_EN = 7;   // Right enable pin
const int L_EN = 8;   // Left enable pin

// === Encoder Pins ===
const int encoderPinA = 2;  // Encoder Channel A (uses interrupt)
const int encoderPinB = 3;  // Encoder Channel B (read for direction)

// === Encoder Tracking ===
volatile long encoderCount = 0;        // Total encoder pulse count
const int countsPerStep = 24;          // Pulses required per 10° step
const int stepsPerRevolution = 36;     // 360° / 10° = 36 steps
const int degreesPerStep = 10;         // Each step equals 10 degrees

int stepCount = 0;                     // Steps completed
int currentDegree = 0;                 // Current angle in degrees
unsigned long lastSendTime = 0;        // Last time degree was sent
const unsigned long sendInterval = 100; // Send data to serial every 100 ms

bool inMotion = false;                // True if motor is rotating
bool processDone = false;             // True after full 360° is completed

void setup() {
  Serial.begin(9600);                 // Initialize serial communication

  // Motor pin setup
  pinMode(RPWM, OUTPUT);
  pinMode(LPWM, OUTPUT);
  pinMode(R_EN, OUTPUT);
  pinMode(L_EN, OUTPUT);
  digitalWrite(R_EN, HIGH);          // Enable BTS7960 motor driver
  digitalWrite(L_EN, HIGH);

  // Encoder pin setup
  pinMode(encoderPinA, INPUT_PULLUP);  // Enable internal pull-up resistor
  pinMode(encoderPinB, INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(encoderPinA), encoderISR, RISING); // Trigger on rising edge

  Serial.println("Starting stepwise 360° motor rotation...");
}

void loop() {
  if (processDone) {     //If the rotation is complete
    // Send final degree value (360°) repeatedly every 100ms
    if (millis() - lastSendTime >= sendInterval) {
      Serial.println(currentDegree);    // Repeatedly send 360° as final state
      lastSendTime = millis();    // Reset timer
    }
    return; // Exit loop to stop motion permanently
  }

  // Start the next step if motor is not moving
  //If motor is stopped then Reset encoder counter and mark motor as moving and then start motor using PWM
  if (!inMotion) {
    encoderCount = 0;               // Reset encoder for new step
    inMotion = true;                // Mark motor as moving

    analogWrite(RPWM, 130);          // Start forward rotation
    analogWrite(LPWM, 0);          // Only RPWM active (forward)
  }

  // Stop the motor after one step is completed
  if (abs(encoderCount) >= countsPerStep && inMotion) {
    analogWrite(RPWM, 0);           // Stop motor
    analogWrite(LPWM, 0);

    stepCount++;                    // Increment step count(Track number of completed steps)
    currentDegree = stepCount * degreesPerStep;  // Update current angle
    inMotion = false;               // Mark motor as stopped
  //If all 36 steps (360°) are done then set process done is true
    if (stepCount >= stepsPerRevolution) { // Full 360° completed
      processDone = true;          // Mark process as done
    }

    delay(1000);                   // Pause before next step or finish
  }

  // If motor is idle then send current degree every 100ms to MATLAB
  if (!inMotion && millis() - lastSendTime >= sendInterval) {
    Serial.println(currentDegree);
    lastSendTime = millis();
  }
}

void encoderISR() {
  int b = digitalRead(encoderPinB);         // Read Channel B to determine direction
  encoderCount += (b == LOW) ? 1 : -1;      // Increment or decrement count
}
