# CleanCycle — Authentication, Profile & Communication

Flutter mobile app module for IT3060 HCI Milestone 03. **State management: Provider** (less setup than Riverpod, easier to walk through in a viva).

## How to run

```bash
flutter pub get
flutter run
```

Use an Android emulator/device or iOS simulator. Enable Windows **Developer Mode** if plugin builds fail with a symlink error.

On first launch without Firebase configured, the Login screen still appears and shows that Firebase is not set up.

## Firebase setup

1. Create a Firebase project and add Android (`com.example.cleancycle_mobileapp`) and iOS apps.
2. Enable **Authentication** providers:
   - Email/Password
   - Google
   - (Apple is UI-only until an Apple Developer account exists)
3. Create a **Cloud Firestore** database (test mode while developing, then deploy `firestore.rules`).
4. Enable **Cloud Messaging**.
5. From the project root:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

6. In `lib/main.dart`, replace `Firebase.initializeApp()` with:

```dart
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
```

7. Deploy rules:

```bash
firebase deploy --only firestore:rules
```

8. **Google Sign-In (Android)** needs the SHA-1 of your debug keystore:

```bash
cd android
./gradlew signingReport
```

Add the SHA-1 (and SHA-256) in Firebase Console → Project settings → your Android app, then download a fresh `google-services.json`.

iOS Google Sign-In: add the `REVERSED_CLIENT_ID` URL scheme from `GoogleService-Info.plist` in Xcode.

9. Create at least one **driver** and one **municipal_officer** user in Firestore (`users/{uid}.role`) — registration always creates `resident`.

## Tests

```bash
flutter test
```

Manual CRUD cases: `docs/FUNCTIONAL_TEST_CASES.md`. Prototype deviations: `DEVIATIONS.md`.
