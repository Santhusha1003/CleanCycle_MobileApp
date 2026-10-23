# Schedule save: deployed rule fix; live schedule writes unverified

> Historical deployment record. For current baseline/candidate selection and reproducible demo-only testing, see [Firestore local testing](FIRESTORE_LOCAL_TESTING.md). The historical schedule candidate below is not the combined tracking/special-request policy.

The previous published rules for `cleancyclemobileapp` were backed up and compared
with the candidate. The candidate was deployed using the explicitly authorized
rules-only command below. Successful schedule saves were tested in the emulator
only; no production document writes were performed.

## Confirmed failures

The form calls `ScheduleService.createSchedule` or `updateSchedule`. Each saves
`schedules/{scheduleId}` and `resident_schedules/{scheduleId}` in one batch. A
verified, compatible Driver account plus vehicle also adds
`driver_trips/schedules_{scheduleId}` in that batch. Creation sets the main
document without merging; updates merge the main document. Projections and trips
are replaced. Removing a previous tracking assignment deletes its trip in the
same batch. New dates remain Firestore timestamps and times remain `HH:mm`;
updates retain the supported legacy date representation.

The published `validScheduleAssignment` rejects a selected municipal Driver ID
without an Auth UID. That explains the two-document save denial. The resident
projection succeeds in isolation against the published policy. A separate
published trip-rule defect uses `get()` against the source schedule before the
batch writes it, denying new verified assignments and reassignment batches.

Authorization uses Firebase Authentication's current UID and the actual
`users/{uid}.role`: `municipal_officer` or `officer`. An email, displayed role,
or `requestedRole` does not grant access. The current live account's profile was
not reread as part of this verification; no user accounts were modified.

## Prepared deployment candidate

`firestore.schedule-save.rules` starts from the inspected published rules,
preserving unrelated collection permissions. Its only differences are:

1. `validScheduleAssignment`: officers can store any existing municipal driver
   and vehicle independently, or neither. An authenticated assignment still
   requires the verified Driver profile, record link, vehicle, and compatible
   stored assignments. Planning assignments grant no Driver account access.
2. `validTripAfterWrite` and the two officer trip write expressions: schedule
   trip validation uses `getAfter()` and matches Driver ID, Auth UID, and vehicle
   against the source after the batch. Non-schedule trips and Driver location
   updates keep their existing validation.
3. `validDriverAuthLink`: profile document ID is the canonical Auth UID; the
   legacy redundant `uid` field may be absent but must agree when present.
   Emails are compared with trimmed, lowercase values. The actual profile role
   must still be `driver`. This matches the app's verified-link step, which can
   update `drivers/{driverId}` before the schedule batch.

Resident projections retain their field allowlist and post-batch source checks.
The existing local `firestore.rules` also includes other pending changes. The
candidate lets the schedule fix be reviewed independently of those changes.

## Safe local verification

Run from the repository root; these commands use a localhost demo project:

```sh
firebase emulators:exec --only firestore --project demo-cleancycle-schedule \
  --config firebase.schedule-save.json \
  'python3 scripts/test_schedule_save_permissions.py'

flutter test --no-pub test/schedule_management_save_test.dart \
  test/municipal_schedule_tracking_assignment_test.dart \
  test/municipal_schedule_service_test.dart \
  test/resident_collection_schedule_ui_test.dart \
  test/resident_tracking_test.dart test/special_pickup_tracking_test.dart
```

The rules test harness refuses non-localhost hosts and non-demo project IDs.
Tests cover all four assignments, actual Municipal Officer role, creation,
updates, projection equality, trip creation/removal, atomic failures, and
resident/Driver/unauthenticated denials.

Verified results for this candidate: 14 security tests passed against the
candidate, the same 14 passed against local `firestore.rules`, and 98 Flutter
tests passed. Against the unmodified published rules, the selected-driver
creation and verified schedule/trip batch regressions fail as expected; the
isolated resident projection test passes. This establishes the rule differences
as the cause without performing live schedule writes.

## Rules deployment and rollback

After explicit user approval, the published policy was checked again and matched
the reviewed baseline. All 98 Flutter tests and 14 candidate security tests
passed again. This rules-only command was executed successfully:

```sh
firebase deploy --only firestore:rules --project cleancyclemobileapp \
  --config firebase.schedule-save.json
```

The explicit project is `cleancyclemobileapp`; `.firebaserc` has the same default.
The deployment config points to `firestore.schedule-save.rules`. No application,
indexes, hosting, or other Firebase resources were deployed. The repository's
main `firestore.rules` retains its other existing pending changes.

After deployment, the published rules were fetched read-only and matched the
candidate exactly. The verified release points to ruleset
`f6095799-5000-4409-af3c-a1fab4a82ac0`. Its source and verification result are
saved in `backups/firestore-schedule-save/published-after.rules` and
`deployment-result.json`.

The pre-deployment backup and release metadata are in
`backups/firestore-schedule-save/published-before.rules` and `release-before.json`.
The prepared rollback command is below (not executed; it restores the old policy
and its schedule-save restrictions):

```sh
firebase deploy --only firestore:rules --project cleancyclemobileapp \
  --config firebase.schedule-save-rollback.json
```

## Remaining live verification

The user prohibited production-data modifications. Creating or updating live
test schedules would modify that data, so no app-level live save was attempted.
After permission for those test writes, use an authorized officer to create and
update assigned and unassigned test schedules in the app. Confirm the main
document, resident projection, and eligible trip, along with the form closing,
success message, and refreshed list. If a denial remains, inspect the signed-in
UID's actual role and reported failed stage; an atomic batch error alone cannot
identify its rejected document. Do not weaken permissions to make the test pass.
