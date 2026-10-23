# Special collection request security verification

> Historical admin security notes. Use the current [Firestore local testing guide](../../docs/FIRESTORE_LOCAL_TESTING.md) for supported Python suites and review candidates. The npm rules-test commands and snapshot assertions below need separate reconciliation; they are not verified by the current Python suites.

## Repository findings

The web client and Flutter configuration point to `cleancyclemobileapp`.
The portal signs in with Firebase email/password authentication. `ensureOfficer()`
rejects anonymous sessions, accepts `officer` or `municipal_officer` in a trusted
Auth custom claim named `role`, or reads the same role from `users/{Auth UID}`.
These are alternative role sources, not a requirement for both to exist.
The signed-in browser account has not been inspected. A read-only check of the published default Firestore rules confirmed that `special_requests` has no allow rule.

The page uses `RecordManager` with `special_requests`. The service reads a bounded
query ordered by document ID, counts the collection for the dashboard, and uses
transactions for creates, updates, and deletes. The document ID is `requestId`.
Transactions read the target first, including a missing target on creation.
The officer rule supports those operations and does not introduce a new schema.

The checked-in rule originally allowed all authenticated accounts, but the published
rules deny `special_requests` entirely. This explains the live permission error.
The published rules also contain integrated user-directory, resident request,
schedule-projection, and driver-trip permissions absent from the local file.
Do not deploy the smaller local `firestore.rules` over those published rules.

`firestore.special-requests.rules` is the deployment candidate: it preserves the
published snapshot and inserts only `isMunicipalOfficer()` plus the
`special_requests` match. `firebase.special-requests.json` selects this candidate.
The candidate test verifies that removing the insertion restores the exact
normalized published snapshot hash, preserving every existing rule outside it.
Before a later deployment, re-read the current published rules to ensure no newer
changes would be overwritten. Neither file has been deployed.

The mobile special-pickup route is a placeholder. No resident submission service,
request-owner UID field, or lifecycle contract exists in the mobile implementation.
Resident submission to `special_requests` is therefore denied, rather than
granting access based on a resident name/phone or inventing ownership fields.
Existing deployed resident submission rules for `special_pickups` and
`collectionRequests` are preserved in the deployment candidate. Other resident/profile rules,
and driver, schedule, vehicle, staff and missed-report permissions are preserved.

## Safe local test steps

1. Install Node dependencies with `npm ci` in `admin_web`.
2. Have the Firebase CLI and a compatible Java runtime installed.
3. Run `npm run test:rules:candidate` from `admin_web` to verify the deployment candidate. Also run `npm run test:rules` to check the smaller local development rules.
   It starts only Firestore on `127.0.0.1:8085`, uses the demo project
   `demo-cleancycle-rules`, and loads `../firestore.special-requests.rules` through
   `../firebase.special-requests.json` (the local development suite uses
   `../firestore.rules` and `../firebase.rules-test.json`). It never uses the default production project.
   The tests refuse to run without that exact emulator host. Test identities and
   seeded records are confined to the emulator; no real account is provisioned.
4. Run `npm run lint`, `npm test`, and `npm run build`.

The emulator suite covers officer claim/profile aliases, collection queries and
counts, transaction updates and CRUD, missing-document reads on create,
unauthenticated/anonymous/non-officer denials, cross-UID profile isolation,
self-promotion prevention, and preserved existing collection permissions.

Do not deploy rules as part of these tests. Do not point the current browser app
at production to test create/update/delete actions.

## Review before a later, explicitly approved deployment

In Firebase Console, select `cleancyclemobileapp`, open Authentication → Users,
and identify the intended existing officer account and its UID without sharing
passwords or tokens. Check Firestore Database → Data → `users` → that UID for
`role: officer` or `role: municipal_officer`. If using custom claims instead,
have the trusted account administrator confirm the `role` claim; do not add an
in-app promotion flow or attempt to inspect/share raw tokens. Sign out and sign
back in after an administrator changes claims so the session gets a fresh token.

Open Firestore Database → Rules to compare the published rules with the proposed
file. Retain any additional deployed permissions absent from this repository;
do not blindly overwrite a different production ruleset. Review the test results
and the complete rules diff. Deployment and any account changes require separate
approval; neither was performed by this fix.
