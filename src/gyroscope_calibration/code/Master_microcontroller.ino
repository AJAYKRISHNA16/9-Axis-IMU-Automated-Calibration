#include <Adafruit_LSM9DS1.h>       // library for the LSM9DS1 sensor
#include <Adafruit_Sensor.h>        // Base class for Adafruit sensor APIs
#include <Wire.h>                   // Required for I2C communication
#include <SoftwareSerial.h>         // Enables serial communication on other digital pins

#define BT_RX 11                    // create pin 11 as Bluetooth RX pin
#define BT_TX 10                    // create pin 10 as Bluetooth TX pin
SoftwareSerial bluetooth(BT_RX, BT_TX);  // Create Bluetooth serial using software serial

Adafruit_LSM9DS1 lsm = Adafruit_LSM9DS1();  // Create LSM9DS1 sensor object

unsigned long lastSendTime = 0;     // Store last time data was sent
const int SEND_INTERVAL = 50;       // Define interval between data sends in milliseconds

// Setup function for configuring the sensor
void setupSensor() {
  lsm.setupAccel(lsm.LSM9DS1_ACCELRANGE_2G, lsm.LSM9DS1_ACCELDATARATE_10HZ);  // Set accelerometer range and data rate
  lsm.setupMag(lsm.LSM9DS1_MAGGAIN_4GAUSS);                                   // Set magnetometer gain
  lsm.setupGyro(lsm.LSM9DS1_GYROSCALE_2000DPS);                               // Set gyroscope scale for higher angular velocity range
}

// Arduino setup function: runs once at boot
void setup() {
  Serial.begin(115200);                  // Start USB serial for debugging
  bluetooth.begin(9600);                // Start Bluetooth serial communication
  pinMode(LED_BUILTIN, OUTPUT);         // Set built-in LED pin as output

  Serial.println("Initializing LSM9DS1...");  // Notify serial monitor

  if (!lsm.begin()) {                   // Try to initialize the sensor
    Serial.println("Failed to detect LSM9DS1. Check wiring.");  // Sensor not found
    while (1) {                         // Infinite loop to signal error
      digitalWrite(LED_BUILTIN, HIGH);  // Blink LED on
      delay(100);                       // Wait
      digitalWrite(LED_BUILTIN, LOW);   // Blink LED off
      delay(100);                       // Wait
    }
  }

  Serial.println("Found LSM9DS1 9DOF");  // Sensor successfully initialized
  setupSensor();                        // Call sensor configuration

  bluetooth.println("AT");              // Send AT command to check Bluetooth connection
  delay(100);                           // Short delay to wait for response

  if (bluetooth.available()) {          // If response from Bluetooth
    Serial.print("BT Response: ");      // Output prefix
    while (bluetooth.available())       // While data available
      Serial.write(bluetooth.read());   // Echo Bluetooth response to serial
  } else {
    Serial.println("No BT response.");  // No response from Bluetooth module
  }
}

// Arduino loop function: runs continuously
void loop() {
  static unsigned long lastBlink = 0;   // Track last blink time

  if (millis() - lastBlink > 500) {     // Toggle LED every 500ms
    digitalWrite(LED_BUILTIN, !digitalRead(LED_BUILTIN));  // Toggle LED state
    lastBlink = millis();               // Update last blink time
  }

  if (millis() - lastSendTime >= SEND_INTERVAL) {  // Time to send new sensor data
    sendSensorData();                   // Read and send sensor data
    lastSendTime = millis();            // Update last send timestamp
  }
}

// Reads all sensor data and transmits it over Bluetooth
void sendSensorData() {
  lsm.read();                           // Trigger reading from all sensors

  sensors_event_t accel, mag, gyro, temp;  // Declare event structures
  lsm.getEvent(&accel, &mag, &gyro, &temp);  // Populate sensor readings

  // Convert gyroscope readings from radians/sec to degrees/sec
  float gx = gyro.gyro.x * (180.0 / PI);
  float gy = gyro.gyro.y * (180.0 / PI);
  float gz = gyro.gyro.z * (180.0 / PI);

  // Create CSV-formatted string of sensor data
  String data =
    String(accel.acceleration.x, 3) + "," +
    String(accel.acceleration.y, 3) + "," +
    String(accel.acceleration.z, 3) + "," +
    String(gx, 3) + "," +
    String(gy, 3) + "," +
    String(gz, 3) + "," +
    String(mag.magnetic.x, 3) + "," +
    String(mag.magnetic.y, 3) + "," +
    String(mag.magnetic.z, 3) + "," +
    String(temp.temperature, 1);

  bluetooth.println(data);              // Send data over Bluetooth
  Serial.println("Sent: " + data);      // Print data to serial for debugging
}
