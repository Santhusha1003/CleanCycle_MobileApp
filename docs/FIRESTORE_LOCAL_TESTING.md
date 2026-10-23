# Firestore rules: reproducible local verification

All commands below run from the repository root. They use only the Firestore
emulator at `127.0.0.1:8085` and the explicit demo project
`demo-cleancycle-schedule`. Never omit `--project`: `.firebaserc` defaults to a
real project. Run one emulator command at a time because they share port 8085.

## Prerequisites

- Python 3 (standard library only; no pip dependencies).
- Firebase CLI and a Java runtime compatible with its Firestore emulator.
  Verification used Firebase CLI 15.13.0 and Temurin Java 25.0.2.
- The Firebase CLI's Firestore emulator binary must be available. A first run
  can require a download; subsequent runs can use the cached emulator.

These commands do not initialize the Flutter app or admin web Firebase clients.
Python test clients reject non-local emulator hosts and non-demo project IDs.
Fixtures use the emulator's administrative seeding/reset endpoints only.

## Baseline, candidates, and production

| Files | Purpose |
| --- | --- |
| `firestore.rules`, `firebase.json` | Unchanged repository baseline and default deployment selection. This review did not inspect the policy currently published to production. |
| `firebase.schedule-test.json` | Local baseline test config. `firebase.rules-test.json` is an identical redundant config; prefer the documented schedule config. |
| `firestore.tracking-review.rules`, `firebase.tracking-test.json` | Separate tracking read/revocation candidate and its local config. |
| `firestore.special-requests.rules`, `firebase.special-requests.json` | Original additive special-request candidate; it does not contain tracking revocation fixes. |
| `firestore.combined-review.rules`, `firebase.combined-test.json` | Tracking candidate plus the special-request authorization block verbatim. Intended for review and local testing only. |
| `firestore.schedule-save.rules`, `firebase.schedule-save.json` | Historical schedule-only snapshot/configuration. Not the final combined policy; do not use it to replace a newer reviewed policy. |
| `backups/`, `firebase.schedule-save-rollback.json` | Local historical recovery material. Preserve locally; exclude from the proposed submission. |

None of these emulator settings prohibits deploying a config by some other
command. Only the emulator commands here are authorized by this workflow.
No candidate is being declared production-ready or deployed by this review.

## Tracking candidate: schedule and tracking suites

```sh
firebase emulators:exec --only firestore --project demo-cleancycle-schedule \
  --config firebase.tracking-test.json \
  'python3 scripts/test_schedule_save_permissions.py && python3 scripts/test_tracking_permissions.py'
```

## Combined candidate: all relevant Python security suites

This runs every suite even if a preceding suite fails and preserves a failing
exit code if any suite fails. No tests are removed or skipped for the candidate.

```sh
firebase emulators:exec --only firestore --project demo-cleancycle-schedule \
  --config firebase.combined-test.json \
  'python3 scripts/test_schedule_save_permissions.py; schedule_result=$?; python3 scripts/test_tracking_permissions.py; tracking_result=$?; python3 scripts/test_special_requests_permissions.py --combined; special_result=$?; test "$schedule_result" -eq 0 && test "$tracking_result" -eq 0 && test "$special_result" -eq 0'
```

The `--combined` flag keeps all nine special-request tests. It selects the
combined file for the composition assertion, uses the tracking candidate as its
base, and checks that the inserted officer authorization block equals the
original special-request block exactly. Removing it must reproduce the tracking
candidate byte for byte. Duplicate matches and recursive blanket grants remain
rejected by the structural assertions.

## Original special-request candidate (compatibility check)

```sh
firebase emulators:exec --only firestore --project demo-cleancycle-schedule \
  --config firebase.special-requests.json \
  'python3 scripts/test_special_requests_permissions.py'
```

## Baseline schedule verification

```sh
firebase emulators:exec --only firestore --project demo-cleancycle-schedule \
  --config firebase.schedule-test.json \
  'python3 scripts/test_schedule_save_permissions.py'
```

The unchanged baseline still has the known tracking revocation failures; its
tracking results must not be substituted for candidate verification.

## Results and limits

Local verification on 2026-10-23:

| Selected policy | Schedule-save suite | Tracking suite | Special-request suite |
| --- | --- | --- | --- |
| Tracking candidate | 14 passed, 0 failed | 15 passed, 0 failed | Not applicable: no special-request match |
| Combined candidate | 14 passed, 0 failed | 15 passed, 0 failed | 9 passed, 0 failed |
| Original special-request candidate | Not rerun in this change | Not rerun in this change | 9 passed, 0 failed |

The special-request suite confirms officer profile/claim aliases and denial for
residents, drivers, anonymous users (even with an officer claim/profile), absent
roles, unauthenticated users, self-promotion, and nested collection access.
The tracking and schedule suites retain ownership, identity, revoked-link,
reassignment, query scope, atomic projection/trip and forged-assignment checks.

These are local emulator results. They do not establish the current published
policy, production indexes, or successful live app operations. No production
documents were created/updated and no rules were deployed.

Older admin security notes refer to npm `test:rules` commands and a pinned
historical snapshot hash. Those npm scripts/dependencies are not currently
specified in `admin_web/package.json`; do not treat that older Node suite as
verified by the Python commands here. Repair/reconcile that separate harness
before relying on it in CI. It was not removed or weakened in this change.

## Proposed next commit

Include the new tracking/combined configs, combined candidate, updated
special-request test, this guide, and documentation links. Also include the
already prepared `firestore.tracking-review.rules` and
`firebase.schedule-test.json`, which remain untracked and are required by the
candidate comparison/baseline commands. Existing application fixes and Python
schedule/tracking suites are already tracked.

Leave the redundant `firebase.rules-test.json`, historical schedule-save
candidate/config, backup directory, and rollback config local. Do not stage them
with a blanket add. No backup or rollback files were changed or deleted.
