# InfalsusTouch

InfalsusTouch is a cross-platform remote control application that turns your Android or iOS device into a powerful touchpad and keyboard for your Windows PC. It uses high-performance UDP communication to minimize latency, making it ideal for gaming or productivity.

## Project Structure

This repository contains three main components:

- **`android/`**: The Android client application (Kotlin).
- **`ios/`**: The iOS client application (SwiftUI).
- **`pc/`**: The server-side receiver application (C++).

## Features

- **Multi-Touch Support**: Use your phone/tablet screen as a trackpad.
- **Low Latency**: Direct UDP communication over local Wi-Fi.
- **Cross-Platform**: Works on both Android and iOS devices.
- **Customizable Protocol**: Simple text-based protocol for movement and key presses.
- **Absolute & Relative Input**: Supports both absolute positioning (mapping screen to screen) and relative mouse movement.

## Getting Started

### 1. PC Receiver (Windows)

The receiver runs on your Windows computer and translates network packets into mouse/keyboard input.

**Prerequisites:**
- MinGW (g++) compiler for Windows.

**Compilation:**
Run the following command in the `pc/` directory to compile the receiver statically (ensures compatibility across different Windows machines):

```bash
g++ receiver.cpp -o receiver.exe -lws2_32 -static
```

**Usage:**
1. Run `receiver.exe`.
2. Allow the application through the Windows Firewall if prompted.
3. The receiver will listen on UDP Port **8888**.

### 2. Android Client

**Prerequisites:**
- Android Studio or Gradle.
- JDK 17 (Included in modern Android builds).

**Build:**
Open the `android/` folder in Android Studio and build the project. A signed release configuration is included in `build.gradle` using `release.jks`.

**Usage:**
1. Install the APK on your Android device.
2. Enter your PC's local IP address and connect.

### 3. iOS Client

**Prerequisites:**
- macOS with Xcode installed.

**Build:**
1. Open `ios/InfalsusTouch.xcodeproj` in Xcode.
2. Select your target device (Simulator or physical iPad/iPhone).
3. Build and Run (`Cmd + R`).

**Usage:**
1. Launch the app on your iPhone or iPad.
2. Enter the target PC IP address in the settings field.

## Protocol Details

The app communicates using simple UDP string messages:

- **Relative Mouse Move**: `X` (float) -> e.g., `10.5` (Move X by 10 pixels).
- **Absolute Mouse Move**: `A` + `0.0-1.0` -> e.g., `A0.5` (Move X to 50% of screen width).
- **Keyboard Event**: `K` + `D/U` (Down/Up) + `Char` -> e.g., `KDw` (Press 'w' key).

## License

[MIT License]
