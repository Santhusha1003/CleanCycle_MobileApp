# CleanCycle Admin Web

React/Vite municipal portal for Firebase project `cleancyclemobileapp`, on `feature/admin-web`. Web fields follow `lib/models/` and `lib/services/municipal/`. No Flutter files or Firestore rules were changed.

## Run locally

From the repository root:

```sh
cd admin_web
npm run dev -- --host 127.0.0.1 --port 5173
```

Open the URL printed by Vite. Existing dependencies were available during implementation, so no install or lockfile change was needed. On a fresh checkout use `npm ci` from `admin_web`.

## Authentication and permissions

Sign in using an **existing Firebase email/password account**. Email/password authentication must be enabled by the authentication administrator. This portal does not create accounts, sign in anonymously, assign roles, or impersonate Municipal Officers.

Access requires either the trusted custom claim `role: officer` / `municipal_officer`, or the same role in the authenticated user's own `users/{uid}` document. These role strings follow the mobile enum. An administrator must provision the account/role; client user-profile creation currently permits only `resident`, and role changes are prohibited. The profile directory cannot be queried with the checked-in rules.

**Server security prerequisite:** the checked-in municipal rules still allow every authenticated account to read/write vehicles, drivers, staff and schedules. The web role gate is an interface guard, not server-side access control. Before production use, the backend owner must implement and deploy officer authorization rules. No rules were edited or deployed here; deployed rules were not independently inspected.

## Page capabilities

| Page | Implemented behavior | Prerequisite or limit |
| --- | --- | --- |
| Dashboard | Live status summaries, fleet/staff/driver/schedule totals, upcoming schedules, recent activity, navigation | Totals use server aggregation and refresh every minute or manually. Operational summaries use the loaded set. Unsupported metrics show unavailable, never zero. |
| User Management | Own email/profile role and directory access explanation | Other-user reads, role totals and role edits are denied by current rules; requires an authorized directory/account-management backend. |
| Vehicles | List, type/status/search filters, details, add/edit/delete, service-date alerts | Document ID is registration number; required vehicle type and nonnegative capacity. |
| Staff | List, zone/status/search filters, details, add/edit/delete | Staff are separate from drivers; email, phone, name and position are required. |
| Drivers | List, assignments, zone/status/search filters, details, add/edit/delete, licence alerts | Operational record identity is checked; Firebase Driver login/verification has no implementation in this repository. IDs are immutable. |
| Routes | Live zone and driver/vehicle assignment view, filters, details, link to schedule editor | Derived from schedules; no separate route paths, optimization or history. |
| Collection Schedule | CRUD, date/status/waste/search filters, current week/month list ranges, details, optional assignment checks | Dates/times use Asia/Colombo. Native time controls enforce HH:mm; end must follow start. |
| Live Collection Tracking | Live saved schedule status, assignment lookup, details | No GPS publisher/location schema/timestamp/ETA source. No map or invented movement. |
| Special Requests | Explicit model/permission prerequisites and link to schedules | Resident mobile screen is a placeholder; no collection/schema/lifecycle exists. No guessed queries or writes. |
| Notifications | Delivery-readiness explanation | Mobile code only requests FCM permission/token; no history schema, send backend or delivery result. No notification records or push messages are created. |
| Complaints & Feedback | Explicit complaint prerequisites; separate read-only missed-report identifier list | Rules define `missedCollectionReports` read/create, but no report model exists. No inferred fields, complaint counts or report responses. Update/delete is denied by current rules. |
| Reports | Schedule date-range/zone/waste filters, status/date/zone/waste breakdowns, assignment counts, current fleet/staff summaries, filtered CSV | Current fleet availability is not historical. Request, complaint, collected weight, fuel and duty metrics are unavailable. |

## Firebase reads and writes

- Reads: bounded real-time listeners for `vehicles`, `drivers`, `staff`, `schedules`, `missedCollectionReports`; own `users/{uid}` role; server total counts for the five operational/report collections.
- Writes: transaction-backed create/update/delete for vehicles, drivers, staff and schedules only. Creation checks duplicate identifiers atomically; updates/deletes require the record to exist. Updates preserve `createdAt` and unknown existing fields via merge. Private fields are neither displayed nor copied into forms.
- Schedule/vehicle driver assignments require an existing complete driver document with matching Driver ID, active availability, and a valid licence date when recorded. Schedule/driver vehicle assignments require matching registration and available/assigned vehicle status. A schedule's driver/vehicle pairing must agree with any existing pair assignment.
- This verifies **operational records**, not a Driver's Firebase Auth UID. The current mobile service has no Auth identity verification endpoint. No existing identity fields are erased, and Driver IDs cannot be edited.
- Success is displayed only after the Firebase transaction resolves. Denied/failed writes keep the form open; transactions require an online connection. Closing/cancelling while a mutation is pending is disabled.
- Assignments do not atomically modify the driver's/vehicle's status or prevent overlapping schedules; the mobile model/service defines no such workflow.
- Deletion confirms the selected record and warns that references in other records remain; no cascade deletion is performed.

## Data limits and unavailable states

Each listener loads at most **500 documents ordered by document ID**, with 20 rows per table page. Filters, reports, export and status summaries operate on this loaded set, rather than promising municipality-wide metrics. The cap is clearly disclosed at 500 rows; independent server total counts cover the whole collection. Larger datasets need server-filtered pagination/aggregation.

Cached data is labelled; missing cache entries are not described as an authoritative empty query. Listener failures show error/retry states rather than sample data. CSV export requires server-backed records without pending writes, exports the selected loaded set, quotes embedded delimiters/newlines and neutralizes spreadsheet formulas. Dates use Colombo calendar days, including when the officer's browser is in a different timezone.

## Verification

```sh
npm run lint
npm run test
npm run build
```

Optional browser regression check, when Playwright and its Chromium browser are already installed:

```sh
node tests/browser.smoke.mjs
```

The browser script uses an isolated Vite server on port 5176, injects **test-only** fixture services, and blocks external requests. Fixtures do not enter the product bundle or replace failed production queries.

Results during implementation:

- Lint: clean.
- Unit tests: 23 passed, covering validation, Colombo date boundaries, assignment checks, identity preservation, duplicate/existence protection, mutation failures and CSV safety.
- Production build: passed; Vite reports a nonblocking bundle-size warning because the main bundle includes Firebase.
- Browser checks: real unauthenticated sign-in screen; the portal routes with test fixtures; schedule create/edit/delete and failed save; confirmation cancellation; details; date filters; CSV download; tablet menu/navigation and overflow. No browser runtime errors were observed in these checks. Desktop/tablet screenshots were inspected.
- **Production Firebase reads, writes, sign-in and deployed authorization were not verified.** No officer account was supplied, and no production Firestore data was modified. Test adapters/browser fixtures are not evidence that Firebase permissions permit the operations.

## Changed files

- `README.md`, `package.json`, `index.html` in `admin_web`.
- `src/App.jsx`, `src/index.css`.
- `src/components/AuthenticatedApp.jsx`, `Sidebar.jsx`, `Operations.jsx`, `RecordManager.jsx`, `AssignmentView.jsx`, `MissedReports.jsx`.
- `src/layouts/AdminLayout.jsx`.
- All current `src/pages/*.jsx` pages.
- `src/hooks/useCollection.js`, `useCounts.js`.
- `src/services/firebase.js`, `firestoreService.js`, `domain.js`, `roles.js`, `display.js`.
- `src/styles/operations.css`.
- `tests/domain.test.js`, `tests/browser.smoke.mjs`.

No commit, push, deployment, branch switch, reset or stash operation was performed.
