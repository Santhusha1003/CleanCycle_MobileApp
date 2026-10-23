# CleanCycle – Waste Collection & Recycling Management App

## Project Overview

CleanCycle is a waste collection and recycling management application designed to improve waste management services for residents and municipal authorities. The application helps residents manage waste collection schedules, report missed collections, request special pickups, and locate recycling centres.

The system also supports municipal operations, collection tracking, and related waste management activities.

## Team Members

This project was developed by the following team members:

| Student ID | Name |
|---|---|
| IT23845732 | Dharmakeerthi BSM |
| IT23843998 | Ekanayaka GRG |
| IT23844360 | Somarathna MVW |
| IT23859524 | Sathruwan WGR |

## Technologies Used

- **Frontend:** Flutter and Dart
- **Backend Services:** Firebase
- **Authentication:** Firebase Authentication
- **Database:** Cloud Firestore
- **Testing:** Flutter Test, Python, Firebase Emulator Suite
- **Version Control:** Git and GitHub

## Main Features

- User registration and login
- User profile management
- Waste collection schedules
- Calendar-based collection views
- Waste category information
- Collection history
- Missed waste collection reporting
- Special waste pickup requests
- Recycling centre locator
- Municipal operations and schedule management
- Collection tracking functionality
- Firestore security rules and permission testing

## Prerequisites

Before running the project, install the following:

- Flutter SDK
- Git
- Firebase CLI
- Python 3
- A supported device or emulator

For Firebase Emulator Suite testing, Node.js and npm may also be required.

Check your Flutter setup:

```bash
flutter doctor
```

## Getting Started

### 1. Clone the Repository

Open a terminal and run:

```bash
git clone https://github.com/Santhusha1003/CleanCycle_MobileApp.git
```

Navigate to the project directory:

```bash
cd CleanCycle_MobileApp
```

### 2. Install Dependencies

Install the required Flutter packages:

```bash
flutter pub get
```

### 3. Configure Firebase

Configure the required Firebase project settings for your development environment.

Make sure the necessary Firebase platform configuration files and permissions are available. If access to a Firebase project is required, obtain it from the project administrator.

Do not add private credentials, service-account keys, or secret configuration values to GitHub.

### 4. Check Available Devices

Run:

```bash
flutter devices
```

Connect a supported device or start an emulator.

### 5. Run the Application

Run the Flutter application:

```bash
flutter run
```

## Running Tests

### Flutter Tests

Run the complete Flutter test suite:

```bash
flutter test
```

To run the driver lookup tests:

```bash
flutter test test/driver_lookup_test.dart
```

To run the municipal schedule and tracking assignment tests:

```bash
flutter test test/municipal_schedule_tracking_assignment_test.dart
```

## Firestore Security Rules Testing

The repository contains Firestore security rule candidates and Firebase Emulator configurations for local testing.

**Important:** The review candidate rules are intended for testing and review. They are not automatically deployed to production.

Run the following commands from the project root.

### 1. Test Baseline Schedule Rules

```bash
firebase emulators:exec --only firestore --project demo-cleancycle-schedule --config firebase.schedule-test.json "python3 scripts/test_schedule_save_permissions.py"
```

### 2. Test Tracking Rules Candidate

```bash
firebase emulators:exec --only firestore --project demo-cleancycle-schedule --config firebase.tracking-test.json "python3 scripts/test_schedule_save_permissions.py && python3 scripts/test_tracking_permissions.py"
```

### 3. Test Combined Firestore Rules Candidate

```bash
firebase emulators:exec --only firestore --project demo-cleancycle-schedule --config firebase.combined-test.json 'python3 scripts/test_schedule_save_permissions.py; schedule_result=$?; python3 scripts/test_tracking_permissions.py; tracking_result=$?; python3 scripts/test_special_requests_permissions.py --combined; special_result=$?; test "$schedule_result" -eq 0 && test "$tracking_result" -eq 0 && test "$special_result" -eq 0'
```

### 4. Test Special-Requests Rules Candidate

```bash
firebase emulators:exec --only firestore --project demo-cleancycle-schedule --config firebase.special-requests.json "python3 scripts/test_special_requests_permissions.py"
```

These commands use a local Firestore emulator and a `demo-` project ID to avoid connecting to production.

For additional instructions, see [Firestore Local Testing](docs/FIRESTORE_LOCAL_TESTING.md).

## Repository Structure

Important project files and directories include:

- `lib/` – Flutter application source code
- `test/` – Flutter automated tests
- `scripts/` – Security testing scripts
- `docs/` – Project documentation and testing instructions
- `firebase.json` – Firebase CLI configuration
- `firestore.rules` – Baseline Firestore security rules
- `firebase.tracking-test.json` – Tracking rules test configuration
- `firebase.combined-test.json` – Combined candidate test configuration
- `firestore.tracking-review.rules` – Tracking rules review candidate
- `firestore.combined-review.rules` – Combined rules review candidate

## Important Notes

- Run `flutter pub get` after cloning the repository.
- Complete any required Firebase setup before running the application.
- Use the Firebase Emulator Suite for local Firestore security testing.
- Use the documented `demo-` project ID when running emulator security tests.
- Keep private credentials out of the repository.
- Do not deploy review candidate rules directly to production.
- Keep backup and rollback files separate from the normal application source.

## GitHub Repository

[CleanCycle Mobile App](https://github.com/Santhusha1003/CleanCycle_MobileApp.git)

## Project Team

The CleanCycle project was developed collaboratively by the four team members listed above as a university project focused on waste collection and recycling management.
