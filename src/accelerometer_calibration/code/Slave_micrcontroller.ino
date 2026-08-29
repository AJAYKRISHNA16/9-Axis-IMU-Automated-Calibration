#include <SoftwareSerial.h>               // Use software serial for Bluetooth communication

#define BT_RX 9   // Arduino RX (to HC-05 TX)
#define BT_TX 10  // Arduino TX (to HC-05 RX)
SoftwareSerial bluetooth(BT_RX, BT_TX);   // Create software serial port on pins 9 & 10

void setup() {
  Serial.begin(115200);                   // Start hardware serial for debugging
  Serial.println("Starting Slave Device...");

  bluetooth.begin(9600);                  // Initialize Bluetooth serial at 9600 baud (default for HC-05)
  pinMode(LED_BUILTIN, OUTPUT);           // Set built-in LED as output
  digitalWrite(LED_BUILTIN, LOW);         // Turn LED off initially

  Serial.println("Slave Ready. Waiting for data...");
}

void loop() {
  static unsigned long lastBlink = 0;     // Track last blink time for status LED

  // Blink LED every 500ms as a heartbeat
  if (millis() - lastBlink > 500) {
    digitalWrite(LED_BUILTIN, !digitalRead(LED_BUILTIN)); // Toggle LED
    lastBlink = millis();
  }

  // Check if Bluetooth has received any data
  if (bluetooth.available()) {
    String data = bluetooth.readStringUntil('\n'); // Read until newline character
    data.trim();                                   // Remove any trailing/leading whitespace

    if (data.length() > 0) {
      processAccelData(data);           // Parse and print the accelerometer values
      digitalWrite(LED_BUILTIN, HIGH);  // Flash LED to show data received
      delay(50);
      digitalWrite(LED_BUILTIN, LOW);
    }
  }
}

void processAccelData(String data) {
  float values[3];                       // Store parsed float values (X, Y, Z)
  int index = 0;
  int lastIndex = 0;

  // Extract first two values separated by commas
  for (int i = 0; i < 2; i++) {
    index = data.indexOf(',', lastIndex);         // Find next comma
    if (index == -1) return;                      // Exit if not found
    values[i] = data.substring(lastIndex, index).toFloat(); // Convert substring to float
    lastIndex = index + 1;                        // Update last index
  }

  // Extract the last value (after second comma)
  values[2] = data.substring(lastIndex).toFloat();

  // Print values in CSV format (3 decimal places)
  Serial.print(values[0], 3); Serial.print(",");// accelerometer x,y,z axis data
  Serial.print(values[1], 3); Serial.print(",");
  Serial.println(values[2], 3);
}
