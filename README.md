# 9-Axis IMU Automated Calibration

This repository contains the firmware and MATLAB programs developed for
an automated calibration setup for a 9-axis IMU. The setup automates
sensor-data acquisition by mechanically rotating the IMU and
synchronizing the sensor measurements with the known orientation or
motor speed.

The implementation uses an **Adafruit LSM9DS1 9-DOF IMU**, multiple
microcontrollers, a motor-driven rotary platform, an encoder, Bluetooth
communication, and MATLAB-based data logging and calibration.

## 1\. Overview

The automated calibration setup consists of:

* Aluminium base plate mounted on an acrylic plate
* Motor-driven rotary mechanism for automatic IMU rotation
* 360-degree protractor for visual angular reference
* Rotary encoder for measuring angular position
* BTS7960 motor driver
* Motor for rotating the platform
* Three microcontrollers
* Bluetooth communication modules
* Battery-powered electronics
* Adafruit LSM9DS1 9-axis IMU
* MATLAB programs for data acquisition and calibration

The IMU is mounted on the rotatable aluminium plate. The platform can be
rotated through different orientations about the three principal axes.
Sensor measurements are transmitted wirelessly to a computer, where
MATLAB records and processes the data.

## 2\. Why Three Microcontrollers Are Used

The automated setup uses three microcontrollers with separate
responsibilities.

### 2.1 Master Microcontroller

The master microcontroller is mounted on the rotating platform together
with the IMU.

It is responsible for:

* Interfacing with the LSM9DS1 IMU through I2C
* Reading accelerometer, gyroscope, magnetometer, and temperature data
* Formatting the measurements as CSV data
* Transmitting the sensor data through Bluetooth

The master is placed on the rotating platform, so a direct USB
connection to the computer is avoided.

### 2.2 Slave Microcontroller

The slave microcontroller is connected to the computer through its USB
serial interface and communicates wirelessly with the master through
Bluetooth.

Its main purpose is to provide a wireless bridge between the rotating
master unit and the computer.

This arrangement prevents a USB cable from becoming twisted during
platform rotation, which would otherwise restrict the rotation of the
calibration platform.

The slave receives the Bluetooth data and forwards the required sensor
measurements to the computer through the USB serial port.

### 2.3 Motor-Control Microcontroller

The third microcontroller is dedicated to the motor-control subsystem.

It interfaces with:

* BTS7960 motor driver
* DC motor
* Rotary encoder

It performs:

* Motor direction control
* PWM generation
* Encoder pulse counting
* Angular-position tracking for stepwise rotation
* Motor-speed measurement
* Closed-loop proportional speed adjustment

Separating motor control from sensor acquisition allows the IMU
data-collection system and the motor-control system to operate
independently.

## 3\. Hardware Architecture

The overall system can be represented as:

``` text
                    ROTATING PLATFORM
              ┌──────────────────────────┐
              │       LSM9DS1 IMU        │
              │            │             │
              │            ▼             │
              │    Master Microcontroller│
              │            │             │
              │       Bluetooth          │
              └────────────┼─────────────┘
                           │
                    Wireless Data Link
                           │
                           ▼
                  Slave Microcontroller
                           │
                         USB
                           │
                           ▼
                       Computer
                           │
                         MATLAB
                           │
                           ▼
                 Data Logging / Calibration


Motor-control subsystem:

Computer-independent motor control
              ┌──────────────────────────┐
              │ Motor-control MCU        │
              │        │                 │
              │        ▼                 │
              │   BTS7960 Driver        │
              │        │                 │
              │        ▼                 │
              │       Motor              │
              │        │                 │
              │        ▼                 │
              │ Rotary Encoder ──────────┘
              └──────────────────────────┘
```

## 4\. IMU Data Acquisition

The master microcontroller initializes the LSM9DS1 and configures:

* Accelerometer range: ±2 g
* Accelerometer data rate: 10 Hz
* Magnetometer gain: 4 gauss
* Gyroscope scale: 2000 dps

The IMU data are read periodically and transmitted as comma-separated
values.

The transmitted data format is:

``` text
ax,ay,az,gx,gy,gz,mx,my,mz,temperature
```

where:

* `ax, ay, az` = accelerometer measurements
* `gx, gy, gz` = gyroscope angular-rate measurements in degrees/s
* `mx, my, mz` = magnetometer measurements
* `temperature` = IMU temperature

The master transmits the data through Bluetooth at 9600 baud while the
USB serial interface is used for debugging.

## 5\. Automated Accelerometer Calibration

For accelerometer calibration, the IMU is automatically rotated about
each principal axis.

The platform is operated in 10-degree orientation increments over a full
360-degree rotation.

Three MATLAB acquisition programs are provided for:

``` text
accelerometer\_calibration/
├── accelerometer\_calibration\_along\_x.m
├── accelerometer\_calibration\_along\_y.m
├── accelerometer\_calibration\_along\_z.m
└── acc\_least\_square.m
```

### X-axis rotation

For rotation about the X-axis, the expected gravity vector used by the
data-logging program is:

``` text
gx = 0
gy = sin(theta)
gz = cos(theta)
```

where `theta` is the measured platform angle.

### Y-axis rotation

For rotation about the Y-axis:

``` text
gx = -sin(theta)
gy = 0
gz = cos(theta)
```

### Z-axis rotation

For rotation about the Z-axis:

``` text
gx = -sin(theta)
gy = cos(theta)
gz = 0
```

The expected gravity vector is generated from the measured angular
position and stored together with the raw accelerometer measurements.

## 6\. Accelerometer Calibration Model

The accelerometer calibration is formulated using a linear model
containing a 3×3 scale/misalignment matrix and a three-axis bias vector.

The calibration parameters are represented as:

``` text
M = \[M11 M12 M13
     M21 M22 M23
     M31 M32 M33]

b = \[bx
     by
     bz]
```

The MATLAB least-squares program constructs the system:

``` text
Y = W X
```

where `X` contains the nine elements of the calibration matrix and the
three bias terms.

The parameters are obtained using a least-squares solution:

``` text
X = (W'W)^(-1) W'Y
```

The resulting calibration matrix and bias vector are displayed in
MATLAB.

## 7\. Automated Gyroscope Calibration

The gyroscope calibration uses the motor-controlled rotation of the
platform.

The motor-control subsystem generates controlled rotation while the
encoder is used for position and speed measurement.

The gyroscope data are collected through the same master--slave
Bluetooth communication architecture.

The gyroscope calibration files are organized as:

``` text
gyroscope\_calibration/
├── gyro\_calibration\_along\_x.m
├── gyro\_calibration\_along\_y.m
├── gyro\_calibration\_along\_z.m
└── GYRO\_CAL\_LEAST\_SQUARE.m
```

During the experiment, the measured gyroscope angular-rate data are
combined with the motor speed information.

The MATLAB acquisition programs generate datasets containing the
gyroscope measurements together with the corresponding reference
rotation-rate information.

The stored format is based on:

``` text
gx,gy,gz,1,rpm,0,0
```

or the corresponding axis arrangement for the Y- and Z-axis experiments.

The motor-speed value is converted from revolutions per minute to
degrees per second in the MATLAB acquisition code using:

``` text
angular\_rate = RPM × 6
```

since:

``` text
1 revolution = 360 degrees
1 minute = 60 seconds
360 / 60 = 6 degrees/second per RPM
```

## 8\. Motor Control

The motor is driven using a BTS7960 motor driver.

The motor-control microcontroller uses:

``` text
RPWM = 5
LPWM = 6
R\_EN = 7
L\_EN = 8
```

The rotary encoder is connected to:

``` text
Encoder A = 2
Encoder B = 3
```

The encoder is processed using quadrature decoding.

The motor-control program measures the motor speed every second and
calculates the measured RPM from the encoder count:

``` text
RPM = (encoder count change × 60) / CPR
```

The implementation uses:

``` text
CPR = 5200
```

A proportional controller adjusts the PWM value according to the
difference between target RPM and measured RPM.

The programmed speed sequence increases the target speed from the
minimum value toward the maximum value and then decreases it again.

## 9\. Angular-Position Control

A separate motor-control program is included for stepwise angular
positioning.

The platform is divided into:

``` text
360° / 10° = 36 steps
```

Each step corresponds to:

``` text
10°
```

The encoder count is reset at the beginning of each step. Once the
required encoder count is reached, the motor is stopped and the platform
proceeds to the next angular position.

The programmed sequence therefore provides angular positions:

``` text
0°, 10°, 20°, 30°, ..., 350°, 360°
```

This allows sensor measurements to be associated with known platform
orientations.

## 10\. MATLAB Data Acquisition

MATLAB communicates with two serial interfaces:

``` text
IMU serial port  → Bluetooth/Slave → IMU data
Motor serial port → Motor-control MCU → Position/RPM data
```

The MATLAB programs:

1. Open the required serial ports.
2. Configure the serial terminators.
3. Read IMU measurements.
4. Read angular position or RPM.
5. Generate the corresponding reference quantity.
6. Combine the measured and reference data.
7. Store the data in CSV format.
8. Use the collected data for calibration.

The COM-port numbers in the MATLAB files are examples and must be
changed according to the computer's actual serial-port assignment.

For example:

``` matlab
imuPort = 'COM5';
rpmPort = 'COM3';
```

These values should be modified before running the acquisition programs.

## 11\. Repository Structure

The repository is organized as follows:

``` text
9-Axis-IMU-Automated-Calibration/
│
├── README.md
│
├── src/
│   ├── accelerometer\_calibration/
│   │   ├── acc\_least\_square.m
│   │   ├── accelerometer\_calibration\_along\_x.m
│   │   ├── accelerometer\_calibration\_along\_y.m
│   │   ├── accelerometer\_calibration\_along\_z.m
│   │   ├── Master\_microcontroller.ino
│   │   └── Slave\_microcontroller.ino
│   │
│   ├── gyroscope\_calibration/
│   │   ├── GYRO\_CAL\_LEAST\_SQUARE.m
│   │   ├── gyro\_calibration\_along\_x.m
│   │   ├── gyro\_calibration\_along\_y.m
│   │   ├── gyro\_calibration\_along\_z.m
│   │   ├── Master\_microcontroller.ino
│   │   ├── Slave\_microcontroller.ino
│   │   └── Motor\_control.ino
│   │
│   └── Magnetometer\_calibration/
│       └── Ellipsoidal\_fitting\_code.m
│
├── Accelerometer\_calibration/
│   └── Experimental setup images
│
├── Gyroscope\_calibration/
│   └── Experimental setup images
│
└── Static\_and\_Dynamic\_Calibration\_of\_9-Axis\_IMU\_Using\_UKF.pdf
```

The exact folder names may be adjusted according to the final repository
organization.

## 12\. Magnetometer Calibration

The repository also contains MATLAB code for magnetometer calibration
based on ellipsoidal fitting.

The corresponding program is:

``` text
Ellipsoidal\_fitting\_code.m
```

The code is intended to process magnetometer measurements and estimate
the parameters required to compensate for distortions in the measured
magnetic-field data.

## 13\. Software Requirements

The following software is required:

* Arduino IDE
* MATLAB
* Adafruit LSM9DS1 Arduino library
* Adafruit Unified Sensor library
* Arduino `Wire` library
* Arduino `SoftwareSerial` library

The required Arduino libraries can be installed through the Arduino IDE
Library Manager.

## 14\. Basic Setup Procedure

### Step 1 --- Assemble the mechanical setup

Mount the aluminium plate on the acrylic base and connect the
motor-driven rotation mechanism.

Mount the LSM9DS1 IMU securely on the rotating platform.

### Step 2 --- Connect the master microcontroller

Connect the master microcontroller to:

* LSM9DS1 IMU
* Bluetooth module

Upload:

``` text
Master\_microcontroller.ino
```

### Step 3 --- Connect the slave microcontroller

Connect the slave microcontroller to:

* Bluetooth module
* Computer through USB

Upload:

``` text
Slave\_microcontroller.ino
```

Pair/configure the Bluetooth modules so that the master can transmit
data to the slave.

### Step 4 --- Configure the motor-control system

Connect:

* Motor
* BTS7960 motor driver
* Rotary encoder
* Motor-control microcontroller

Upload:

``` text
Motor\_control.ino
```

Verify the motor direction and encoder operation before performing
calibration.

### Step 5 --- Configure MATLAB

Open the appropriate MATLAB acquisition script and change the
serial-port numbers:

``` matlab
imuPort = 'COM5';
rpmPort = 'COM3';
```

Use the COM ports assigned by the operating system.

### Step 6 --- Collect calibration data

Run the appropriate acquisition program for the desired calibration
axis.

For accelerometer calibration, collect data for:

``` text
X-axis rotation
Y-axis rotation
Z-axis rotation
```

For gyroscope calibration, collect data while the platform is rotated at
controlled speeds.

### Step 7 --- Perform calibration

After sufficient data have been collected, run the corresponding
calibration algorithm.

For accelerometer calibration:

``` text
acc\_least\_square.m
```

For gyroscope calibration:

``` text
GYRO\_CAL\_LEAST\_SQUARE.m
```

For magnetometer calibration:

``` text
Ellipsoidal\_fitting\_code.m
```

## 15\. Data Files

The MATLAB programs generate CSV files containing the collected
calibration data.

Typical accelerometer data follow the structure:

``` text
ax,ay,az,1,gx,gy,gz
```

Typical gyroscope data follow the structure:

``` text
gx,gy,gz,1,rpm,0,0
```

The exact filename can be changed inside the corresponding MATLAB
script.

Generated experimental datasets can be kept separate from the source
code to maintain a clean repository structure.

## 16\. Important Configuration Notes

Before running the system:

* Verify the IMU wiring.
* Verify the Bluetooth pairing.
* Confirm the master and slave baud rates.
* Confirm the MATLAB COM-port assignments.
* Verify the motor direction.
* Verify encoder counting.
* Ensure that the IMU is firmly mounted on the rotating platform.
* Ensure that the platform can rotate freely through the required
range.
* Verify that cables connected to the rotating assembly do not
restrict movement.
* Check the motor speed and mechanical limits before beginning a
complete calibration cycle.

## 17\. Experimental Concept

The main concept of the automated system is to replace manual IMU
orientation and data recording with a controlled electromechanical
process.

Instead of manually rotating the IMU and recording measurements at
individual orientations, the developed setup:

``` text
Command/Control
      ↓
Motor Rotation
      ↓
Encoder Measurement
      ↓
Known Platform Orientation / Rotation Rate
      ↓
IMU Measurement
      ↓
Bluetooth Transmission
      ↓
Slave Microcontroller
      ↓
Computer
      ↓
MATLAB Data Logging
      ↓
Calibration Algorithm
      ↓
Calibration Parameters
```

This provides a repeatable framework for collecting the measurements
required for accelerometer, gyroscope, and magnetometer calibration.

## 18\. Research Reference

This repository accompanies the research work:

**"Static and Dynamic Calibration of 9-Axis IMU Using UKF"**

The repository provides the implementation and experimental software
associated with the automated calibration setup and data-processing
procedures.

The research paper should be consulted for the complete mathematical
formulation, calibration methodology, experimental analysis, and
discussion of the proposed approach.

## 19\. Disclaimer

This repository contains research and experimental code developed for an
automated IMU calibration setup. Hardware pin assignments, COM-port
settings, motor parameters, encoder parameters, and timing values may
need to be modified for a different hardware configuration.

Always verify the mechanical and electrical operation of the setup at
low speed before performing a complete automated calibration cycle.

## 20\. Author

\*\*R. C. Ajay Krishna\*\*

Researcher and Developer of the automated 9-axis IMU calibration system.

The repository provides the hardware-control firmware, automated calibration setup, 

MATLAB data-acquisition programs, and calibration algorithms developed as part of this research.

The accompanying research paper presents the complete mathematical formulation, 

calibration methodology, experimental procedure, and performance analysis of the proposed approach.

