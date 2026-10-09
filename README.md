# CleanCycle – Waste Collection & Recycling Scheduling App

CleanCycle is a Flutter-based mobile application designed to improve waste collection and recycling management. It aims to help residents access waste collection schedules, receive reminders, report missed collections, locate recycling centres, and request special waste pickups. The application also supports waste collection drivers and municipal officers through relevant management interfaces.

## Project Objectives

- Improve access to waste collection schedules and related information.
- Help residents manage waste collection activities more conveniently.
- Support recycling awareness and responsible waste disposal.
- Provide relevant interfaces for residents, drivers, and municipal officers.

## Main Features

### Resident Features
- User registration and login
- Profile management
- Waste collection schedules and calendar views
- Collection reminders and notifications
- Missed collection reporting
- Recycling information and recycling centre locator
- Special waste pickup requests
- Collection history

### Driver Features
- Access to relevant collection tasks
- View collection information
- Update collection status where supported

### Municipal Officer Features
- Collection schedule management
- Vehicle management
- Driver management
- Collection analytics and overview

*Feature availability may vary depending on the implemented version of the application.*

## Technology Stack

| Technology | Purpose |
|---|---|
| Flutter | Mobile application frontend |
| Dart | Application programming language |
| Firebase Authentication | User authentication |
| Cloud Firestore | Cloud database |
| Firebase Cloud Messaging (FCM) | Push notifications |
| Google Maps Flutter / Google Maps API | Maps and location-related features |
| Git and GitHub | Version control and source code management |

## Prerequisites

Before running the project, ensure that you have installed:

- Flutter SDK
- Dart SDK (included with Flutter)
- Visual Studio Code or Android Studio
- Android emulator or a compatible physical device
- Git

Some features may also require Firebase project configuration and a valid Google Maps API key.

## Installation and Setup

### 1. Clone the Repository

Open your terminal and run:

```bash
git clone https://github.com/Santhusha1003/CleanCycle_MobileApp.git
```

### 2. Navigate to the Project Directory

```bash
cd CleanCycle_MobileApp
```

### 3. Check the Flutter Environment

```bash
flutter doctor
```

Resolve any required setup issues before continuing.

### 4. Install Dependencies

```bash
flutter pub get
```

### 5. Configure Firebase and Google Maps

Ensure the project is connected to the correct Firebase project and that the required configuration files are available.

Depending on the existing project setup, configuration may include:

- Firebase configuration for Android and/or iOS
- Firebase Authentication and Cloud Firestore setup
- Firebase Cloud Messaging configuration
- Google Maps API key configuration

If the project uses FlutterFire CLI, Firebase configuration may be generated with:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Run the configuration command only if it is appropriate for the existing Firebase project. Do not replace existing configuration files unnecessarily.

**Important:** Do not commit private credentials, service-account keys, or other secrets to the public repository. Configure API keys and credentials securely.

## Running the Application

### 1. Check Available Devices

```bash
flutter devices
```

Start an emulator or connect a compatible physical device.

### 2. Run the Application

```bash
flutter run
```

To build an Android APK, run:

```bash
flutter build apk
```

The generated APK can be found under:

```text
build/app/outputs/flutter-apk/
```

Build output locations may vary depending on the Flutter configuration.

## Troubleshooting

- **Dependencies fail to resolve:** Run `flutter pub get` and check your internet connection.
- **Firebase errors:** Verify that the Firebase configuration files match the correct Firebase project and application identifiers.
- **Google Maps does not load:** Check the API key, API enablement, and billing/configuration requirements.
- **No device is detected:** Run `flutter devices` and confirm that the emulator or physical device is available.
- **Build errors:** Run `flutter doctor` and review the error messages in the terminal.

## Version Control

This project uses Git and GitHub for version control and collaboration.

Repository: https://github.com/Santhusha1003/CleanCycle_MobileApp

## Project Purpose

CleanCycle was developed as an academic project for the Human-Computer Interaction (HCI) module. It applies user-centred design principles to a practical waste collection and recycling management problem.

## License

This project was developed for academic purposes. No open-source license is specified unless one is added to the repository.
