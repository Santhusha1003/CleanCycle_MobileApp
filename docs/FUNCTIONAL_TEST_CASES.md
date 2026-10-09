# Functional test cases — Auth, Profile & Communication

| ID | Steps | Expected result | Mapped requirement |
|----|--------|-----------------|-------------------|
| TC-01 | Open app with Firebase configured | Login screen: Google, Apple, email, password, Forgot, Sign Up, role links | Login UI / Variant 2 |
| TC-02 | Enter invalid email, leave password empty | LOGIN disabled; inline errors after submit | Error prevention |
| TC-03 | Valid email/password for a **resident** | Firestore profile read; `lastLogin` updated; Resident home placeholder | Login READ + UPDATE lastLogin |
| TC-04 | Wrong password | Snackbar: incorrect email or password; stay on Login | Error messages |
| TC-05 | Airplane mode, tap LOGIN | Snackbar about no network | No-network handling |
| TC-06 | Continue with Google (new user) | Auth user + `users/{uid}` with `role: resident` | Google login + CREATE profile |
| TC-07 | Continue with Apple | Snackbar: coming soon | Apple deviation |
| TC-08 | Login as Driver with a resident account | Signed out; error that this portal is for drivers | Role mismatch |
| TC-09 | Login as Driver with `role: driver` | Driver home placeholder | Role routing |
| TC-10 | Login as Municipal Officer with matching role | Officer dashboard placeholder | Role routing |
| TC-11 | Sign Up with valid form + terms | Auth user created; Firestore doc `role=resident`, addressZone, prefs; verification email sent | Create Account CREATE Auth + Firestore |
| TC-12 | Sign Up with email already in use | Snackbar: already registered | Email-in-use error |
| TC-13 | Weak password on Sign Up | Strength = Weak; Create Account stays disabled until rules met | Password strength |
| TC-14 | Unverified email after register | Verification screen; resend disabled for 30s | Verification READ status |
| TC-15 | Open verification link, tap I've verified | `emailVerified` true in Auth and Firestore; enter app | Verification UPDATE |
| TC-16 | Change Email on verification | Signed out; back to Login | Change email |
| TC-17 | Forgot Password with valid email | Reset email sent; Create a New Password screen | Forgot SEND email |
| TC-18 | Reset rules: type until all three checks are green | Reset button enables | Live rules checklist |
| TC-19 | Logged-in Change Password with current + new | Re-auth then password updated | Reset UPDATE password |
| TC-20 | Account tab | Avatar, name, email, phone, settings list, bottom nav | Account Settings READ |
| TC-21 | Edit Profile: change name/phone/zone, save | Firestore fields updated; Account tab reflects stream | Profile UPDATE |
| TC-22 | Tap avatar, pick photo | `avatarUrl` stored (local path) | Avatar UPDATE |
| TC-23 | Language → Sinhala | `language` saved | Language UPDATE |
| TC-24 | Notification Settings toggles | `notificationPrefs` updated | Prefs UPDATE |
| TC-25 | Logout | `fcmToken` cleared; Login shown | Logout + token clear |
| TC-26 | Privacy → Delete account with password | Firestore doc gone; Auth user gone; Login shown | DELETE account |
| TC-27 | After login, grant notifications | `users/{uid}.fcmToken` set; refresh updates it | FCM token |
| TC-28 | Send a test FCM while app is open | Local notification appears | Foreground messages |
| TC-29 | Send a test FCM while app is backgrounded | System/local notification appears | Background messages |
