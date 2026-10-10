# CleanCycle Mobile App

CleanCycle is a Flutter app for municipal waste collection. It provides Resident, Driver, and Municipal Officer workflows for schedules, collection requests, tracking, and municipal operations.

## Prerequisites

- Git
- Flutter with a bundled Dart SDK satisfying the project constraint `^3.11.1` (check with `flutter --version`)
- Android Studio or the Android command-line tools, Android SDK/platform tools, and an Android emulator; alternatively, use a USB-connected Android device with USB debugging enabled
- Firebase access for the configured project when using authenticated or Firestore-backed features

Run `flutter doctor` and resolve the Android toolchain issues it reports before building.

## Fresh checkout and run (Android)

```bash
git clone https://github.com/Santhusha1003/CleanCycle_MobileApp.git
cd CleanCycle_MobileApp
flutter pub get
flutter devices
flutter run
```

Start an Android emulator in Android Studio or connect/unlock an Android device and accept its USB debugging prompt before `flutter run`. Select a device if Flutter lists more than one.

## Firebase setup

The repository currently includes FlutterFire options and native Firebase configuration for project **`cleancyclemobileapp`**. `lib/main.dart` initializes Firebase using `DefaultFirebaseOptions`; a fresh checkout does not need `flutterfire configure` to run against that configured project. The Android application ID is `com.example.cleancycle_mobileapp`.

Before testing Firebase-backed features, the project owner must ensure the Firebase project has the required services enabled and correctly configured:

- Firebase Authentication with the sign-in providers used by the app
- Cloud Firestore with the application's security rules deployed by an authorized maintainer
- Firebase Cloud Messaging for push notifications
- Any required Firestore user profiles and role/feature records provisioned through the project's authorized administrative workflow

Use authorized team test accounts. Registration creates Resident accounts; Driver and Municipal Officer access depends on the corresponding authorized role/profile records and, for Driver assignment, the verified Driver-to-Auth-UID mapping. Do not promote an account by editing its role from an ordinary client. Firebase Console permissions, deployed rules, and backend data are managed separately from this mobile repository. Do not use Firestore test mode or broaden rules to make the app run.

The login flow implements Email/Password and Google sign-in; Apple sign-in is currently a placeholder. For Google sign-in on Android, a maintainer must register the development signing certificate SHA-1 (and SHA-256) for the Android app in Firebase Console. The debug certificate fingerprints can be obtained with:

```bash
cd android
./gradlew signingReport
```

If Firebase Console configuration is changed, keep the downloaded Android `google-services.json` and FlutterFire options aligned with this project and application ID.

The checked-in Firebase client configuration identifies the project but is not a Firebase Admin credential. Never add service-account keys, private credentials, or personal local configuration to Git. If a maintainer intentionally changes Firebase projects, they should use FlutterFire CLI to regenerate the appropriate platform options/configuration and review the project IDs before sharing that change.

## Development checks

```bash
flutter pub get
flutter analyze
flutter test
```

Firestore rules tests that use the Firebase Emulator require the Firebase CLI and the configured emulator dependencies. They do not deploy rules or modify production data.

## Project references

- Manual CRUD cases: [`docs/FUNCTIONAL_TEST_CASES.md`](docs/FUNCTIONAL_TEST_CASES.md)
- Prototype deviations: [`DEVIATIONS.md`](DEVIATIONS.md)
- Firestore rules source: [`firestore.rules`](firestore.rules)

This is an academic HCI project. No open-source license is specified unless one is added to the repository.
