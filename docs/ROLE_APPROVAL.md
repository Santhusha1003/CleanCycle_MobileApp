# Signup role requests and trusted role assignment

Public signup cannot grant Driver or Municipal Officer privileges. Existing
`firestore.rules` permits only Resident profile creation and prevents clients
from changing `users/{uid}.role`. Keep these protections.

- Resident signup stores `requestedRole: resident` and `role: resident`.
- Driver signup stores `requestedRole: driver` and `role: resident` pending approval.
- Municipal Officer signup stores `requestedRole: municipal_officer` and
  `role: resident` pending approval.
- First-time Google signup is Resident and stores both fields as `resident`.
- Email verification still applies. Requested roles grant no access.

A trusted administrator must independently verify eligibility before assigning
privileged access. The project has no automatic approval backend; the public
signup dropdown must never be treated as authorization.

## Assign an approved role

Use the local administrator command from the repository root, after signing in
to Google Cloud CLI with an account authorized to read/update Firestore through
IAM. This command is not part of the Flutter application and does not give
ordinary Firebase Authentication users permission to change their roles.

```sh
python3 scripts/assign_user_role.py --uid '<existing Firebase UID>' --role driver
```

Supported assignments: `resident`, `driver`, `municipal_officer`. The command is
fixed to `cleancyclemobileapp`, database `(default)`. It reads the existing
profile, then updates **both** `role` and `requestedRole` in one conditional PATCH.
A concurrent document change causes failure rather than an overwrite. It never
creates missing profiles or changes verification flags, other profile fields,
or Firestore rules. Tokens are obtained internally and never printed.

After assignment, both role fields equal the administrator-selected role. On
subsequent login, the existing AuthController reads the stored role and AuthGate
opens Resident HomeDashboardScreen, Driver TrackingDashboardScreen, or
MunicipalShell. The command also supports legitimate administrator role changes;
ordinary users remain unable to change their assigned role.

This implements manual trusted provisioning, not an automated approval UI.
Retaining both fields does not provide an immutable history of previous requests.
No approval command should be invoked solely because a client requested a role.

## Local tests (no live Firestore changes)

```sh
python3 -m unittest scripts.test_assign_user_role
flutter test test/auth_startup_test.dart test/login_form_test.dart
```

The command has been tested using local HTTP doubles. Running it against the
live project requires an authorized administrator; development tests do not
perform live assignments.
