# Special-request rules: local review

The corrected `firestore.special-requests.rules` is the current `firestore.rules`
plus only the original special-request candidate's `isMunicipalOfficer()` helper
and `/special_requests/{requestId}` match. Removing that added block reproduces
the baseline byte for byte. There are no duplicate collection matches or recursive
allow rules overlapping special requests. The schedule assignment validation,
verified driver identity helper, resident projection constraints,
`validTripAfterWrite()`, and all unrelated match blocks remain unchanged.

The older candidates are unsafe as wholesale replacements: the schedule candidate
broadens role/ownership handling and changes missed-report access; the old special
candidate additionally replaces atomic trip validation with `validTrip()` and
contains older assignment/link validation. None of those differences were imported.

Special requests require a non-anonymous authenticated identity and either a
trusted custom claim `role` or the existing `users/{auth.uid}.role` equal to
`officer` or `municipal_officer`. Client-submitted request fields do not grant
roles. Existing profile rules reject resident self-promotion. No new resident or
driver access to this admin collection was added. Existing resident-owned pickup
collections retain their baseline permissions.

## Exact local commands

Run from the repository root. The CLI always receives an explicit demo project.
The test clients independently reject non-local emulator hosts/non-demo projects.
No production configuration or backup file needs modification.

Baseline schedule suite:

```sh
firebase emulators:exec --only firestore --project demo-cleancycle-schedule --config firebase.schedule-test.json 'python3 scripts/test_schedule_save_permissions.py'
```

Generate the temporary candidate emulator configuration (no production targets):

```sh
python3 - <<'PY'
import json
from pathlib import Path
config = {
    'firestore': {'rules': str(Path('firestore.special-requests.rules').resolve())},
    'emulators': {
        'firestore': {'host': '127.0.0.1', 'port': 8085},
        'ui': {'enabled': False},
        'singleProjectMode': True,
    },
}
Path('/tmp/cleancycle-special-requests-test.json').write_text(json.dumps(config, indent=2))
PY
```

Candidate tracking plus focused access tests (both run even if tracking fails):

```sh
firebase emulators:exec --only firestore --project demo-cleancycle-schedule --config /tmp/cleancycle-special-requests-test.json 'python3 scripts/test_tracking_permissions.py; tracking_result=$?; python3 scripts/test_special_requests_permissions.py; special_result=$?; test "$tracking_result" -eq 0 && test "$special_result" -eq 0'
```

Reproduce tracking failures against the untouched baseline:

```sh
firebase emulators:exec --only firestore --project demo-cleancycle-schedule --config firebase.schedule-test.json 'python3 scripts/test_tracking_permissions.py'
```

Verify candidate schedule behavior and repeat focused access tests:

```sh
firebase emulators:exec --only firestore --project demo-cleancycle-schedule --config /tmp/cleancycle-special-requests-test.json 'python3 scripts/test_schedule_save_permissions.py && python3 scripts/test_special_requests_permissions.py'
```

## Actual results

| Rules | Suite | Passed | Failed |
| --- | --- | ---: | ---: |
| Baseline | Schedule save | 14 | 0 |
| Corrected candidate | Schedule save | 14 | 0 |
| Corrected candidate | Special requests | 9 | 0 |
| Corrected candidate | Tracking | 8 | 4 |
| Baseline | Tracking | 8 | 4 |

Nothing was skipped. The focused suite intentionally runs its nine own methods;
the entire twelve-test tracking suite runs separately. Focused tests exercise
both officer aliases through profiles and custom claims; get/list/query/create/
update/delete denials for residents, drivers, anonymous and unauthenticated
identities; missing/unrecognized roles; missing provider metadata; self-promotion;
forged request fields; subcollection denial; and exact additive preservation.

## Diagnosed tracking failures (unchanged baseline behavior)

1. `test_driver_can_read_only_own_verified_driver_record`: direct document get
   succeeds, but an `authUid`-only query returns 403. The driver read rule also
   calls `validDriverAuthLink(resource.data)` including record email/UID checks;
   an authUid-only query does not constrain all fields needed to establish that
   every potential matching document satisfies that rule. Rules are not filters.
2. `test_reassignment_revokes_old_driver_access`: after the source request changes
   driver, the old trip still contains the original UID. Its direct driver-get
   branch checks only that stale UID, without checking the current source. It
   returns 200 rather than the expected 403.
3. `test_revoked_internal_driver_link_removes_schedule_access`: deleting the driver
   record does not remove `assignedDriverUid` from the schedule. The baseline
   driver-read branch checks that UID alone, so access remains 200 instead of 403.
4. `test_schedule_assignment_requires_verified_internal_driver_link`: its initial
   standalone schedule write expects 200 but has no matching resident projection.
   `scheduleHasMatchingProjection()` correctly denies it with 403. The separate
   atomic schedule suite demonstrates that schedule/projection/trip writes work
   and forged assignments are rejected. The older tracking test fixture needs a
   valid atomic schedule/projection setup before it can reach its later identity
   assertions; the test was not changed, weakened or deleted in this review.

There is no additive special-request change that fixes these unrelated branches.
The first three need separately scoped driver-query and revocation rule work;
the fourth needs its fixture aligned with the required atomic write contract.
Those changes conflict with this task's instruction to add only one helper and
one match while preserving unrelated rules, so these failures remain explicit.
The complete security suite is **not** passing; do not treat this as blanket
production readiness or deploy without resolving the remaining issues.

Baseline rules, the schedule candidate, Firebase/rollback configurations and every
existing backup were checked against pre-edit SHA-256 hashes and remained intact.
Only the special-request candidate, the new focused test and this local testing
report were changed/created. No deployment, live Firebase access, production data
mutation, Git commit/push, or backup deletion was performed.
