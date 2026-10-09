# Deviations from the Milestone 02 high-fidelity prototype

| # | Screen / item | Prototype | Implementation | Justification |
|---|----------------|-----------|----------------|---------------|
| 1 | Verification | 6-digit email OTP boxes + Verify | Firebase **email verification link**. Same layout (branding, resend countdown, Change Email, I've verified). Boxes are decorative. | Firebase Auth has no built-in 6-digit email OTP. A custom OTP would be extra backend work outside the allowed stack. |
| 2 | Apple Sign-In | Working Apple button | Button shown; snackbar **“Apple Sign-In is coming soon.”** | Requires an Apple Developer account and `sign_in_with_apple` setup that this group does not have. |
| 3 | Create Account | No address field | **Address / Zone** field added | Milestone 03 CRUD requires storing address/zone at registration. |
| 4 | Forgot → New password | In-app form sets the password | Firebase sends a **reset email**. Logged-out Reset screen matches Figma and validates rules; the email link applies the password. Logged-in Change Password uses re-auth + `updatePassword`. | Firebase cannot `updatePassword` without a session or oob code from the email link. |
| 5 | Create Account role picker | (none on Figma; roles exist in the product) | Role is **never** chosen in the client. Always `resident`. Driver/Officer login entry points check Firestore and sign out on mismatch. | Spec: role is stored server-side; self-promotion is forbidden (also in `firestore.rules`). |
| 6 | Avatar | Cloud avatar | Gallery image saved **on device**; path stored in `avatarUrl` | Firebase Storage is not in the agreed stack (Auth, Firestore, FCM). |
| 7 | Schedule / Track / role homes | Full product screens | Placeholder screens + bottom nav | Other members own schedule, tracking and municipal dashboards. |
| 8 | Bottom nav on Account Settings | Shown on the profile mock | Shared `AppShell` tab bar on Home / Schedule / Track / Account | Needed so the profile tab matches Figma without building other members’ features. |

No extra product features were added beyond this module’s auth, profile, notifications and the placeholders required for hand-off.
