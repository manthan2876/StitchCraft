# StitchCraft Mobile Audit

Audit scope: `stitchcraft-mobile/`, with backend contract checks against
`stitchcraft-backend/`, the architecture document, and
`MOBILE_WEB_WIREFRAMES.md`. This is a read-only audit; no application source
was changed.

## Executive summary

| Screen / feature | Status | Worst severity | Reason |
|---|---|---:|---|
| Startup, splash, onboarding, language | Partially correct | Medium | Routes and locale/theme initialization exist, but authenticated routing and service readiness are not fully verifiable from the supplied path. |
| Login, registration, password reset | Partially correct | High | Supabase Auth is used, but the API profile mapping collapses roles to local `admin/staff` and registration/login contract behavior needs end-to-end verification. |
| Role confirmation and access control | Partially correct | High | The visible role selector is now non-selectable, but `/home` is directly routable and screen-level role gates are not evident; backend authorization is the real control. |
| Shop setup, shop hub, profile/settings | Partially correct | High | Profile, shop management, security, language/theme and danger actions are mixed; shop settings and profile both resolve to `/profile`. |
| Main navigation and dashboard | Partially correct | High | Navigation is clear and pipeline labels are backend-aligned in the order detail flow, but dashboard metrics are calculated from local heuristics rather than the backend stats contract. |
| Five-step order wizard | Broken | Critical | A record is marked pending locally, then directly created remotely without clearing the local pending state, so the later POST-only sync can duplicate it. |
| Orders list and order details | Partially correct | High | Local-first loading and backend status list are useful, but updates and local inventory/payment state are not transactionally reconciled. |
| Customers and measurements | Partially correct | High | Customer CRUD and measurement capture exist, but measurements have no independently synced table and customer fallback data can be fabricated. |
| Khata, udhar, expenses, payments | Partially correct | High | Local ledger calculations work for simple records, while payment mutations use a separate endpoint and the dashboard/ledger assumptions are not a single server-authoritative flow. |
| Deliveries | Partially correct | High | Route exists and the UI has a deliveries filter, but delivery actions and unpaid-balance policy are not fully traced. |
| Invoices, PDF, print/share | Partially correct | High | Invoice entry points exist and PDF generation exists, but invoice math reads a different response shape from local order data and uses non-Indian formatting. |
| Inventory and astar/lining | Broken | Critical | Inventory is mutated both at order creation and at later status changes, allowing double deduction; offline edits are not reliably synced as updates. |
| Karigars and machines | Partially correct | High | Backend CRUD and screens exist, but these entities are excluded from background sync and are fetched online only in key order flows. |
| Repairs | Prototype | High | Repair tickets are written to local SQLite, but there is no repair backend route or sync table. |
| Gallery/design assets | Prototype | Medium | Models/local DB helpers exist, but no mobile gallery screen or backend gallery API is wired. |
| Notifications and deep links | Broken | High | REST notification list/read works, but notification taps only log payload/data and never navigate to the referenced record. |
| Push notifications / FCM | Unverified | High | Firebase initialization and listeners exist, but device-token registration and backend-to-device delivery are not proven end to end. |
| Sync worker and offline status | Broken | Critical | Only customers, orders, expenses and inventory are synced; all upserts use collection POST, with no conflict/version strategy. |
| Localization | Partially correct | Medium | English/Gujarati/Hindi delegates exist, but many visible strings remain hardcoded English and overflow at translated/text-scaled sizes is untested. |
| Theme and accessibility | Partially correct | Medium | Light/dark themes and some semantics exist, but shrinking touch targets and text-scale/layout behavior are not tested. |
| Voice input | Unverified | Medium | `VoiceTextField` and `speech_to_text` are present, but permission/error/lifecycle behavior was not verified on device. |
| WhatsApp | Partially correct | Medium | External `wa.me` launch and reminders exist, but templates include legacy `Trial Ready` and failures are only logged. |
| Tests and code quality | Partially correct | High | `flutter test` passes 13 tests, but coverage is primarily theme/phone/widget smoke tests; analyzer reports 13 issues and no sync/API integration suite is present. |

## Detailed findings

### Startup, onboarding, and localization

The route table includes `/`, `/language`, `/onboarding`, `/login`,
`/role_selection`, `/shop_setup`, and `/home`
(`stitchcraft-mobile/lib/main.dart:135-143`). `main()` validates environment,
initializes Supabase, loads language/theme, and attempts Firebase, local
notifications, and Workmanager setup before `runApp`
(`stitchcraft-mobile/lib/main.dart:49-106`). This matches the offline-first
startup intent and uses `--dart-define` configuration through `AppEnv`.

What is wrong or incomplete:

* Startup service failures are logged and startup continues. That is reasonable
  for push/sync availability, but there is no user-visible readiness/offline
  explanation in this path.
* The supplied code does not establish that splash checks the current
  Supabase session and routes correctly for every account/shop state.
* Localized delegates exist, but the route screens contain many direct English
  labels; this is a consistency defect for Hindi/Gujarati.

What is right: supported locales are configured centrally, theme/language are
loaded before `runApp`, and environment validation is explicit.

**Verdict: Partially correct.**

### Authentication, session storage, and role confirmation

`AuthService` signs in/up through Supabase Auth, stores the token in
`FlutterSecureStorage`, removes the legacy plaintext `token` preference, and
refreshes expired sessions (`stitchcraft-mobile/lib/core/services/auth_service.dart:24-147`,
`stitchcraft-mobile/lib/core/services/auth_service.dart:202-273`). This is the
right source-of-truth direction and no service-role key is present in the
mobile source reviewed.

Problems:

* The API profile is mapped to local `UserRole.admin` or `UserRole.staff`
  instead of preserving owner/manager/staff/karigar
  (`auth_service.dart:55-61`, `auth_service.dart:112-117`). UI role decisions
  can therefore be wrong even when the backend role is correct.
* `RoleSelectionScreen` correctly says the role is assigned and offers no
  role choices (`role_selection_screen.dart:35-55`), refuting the known
  self-selectable-role issue in the current screen.
* `/home` is a public named route in the app table
  (`main.dart:142`); there is no route-level guard visible here. Backend
  `protect/authorize` remains authoritative, but direct navigation can expose
  UI before the session/role is resolved.

**Verdict: Partially correct; high-priority authorization hardening required.**

### Shop setup, shop hub, profile, settings, and security

`MoreHubScreen` exposes inventory, karigars, machines, repairs, invoices,
payments, deliveries, notifications and profile
(`stitchcraft-mobile/lib/features/dashboard/screens/more_hub_screen.dart:14-34`).
`ShopHubScreen` delegates to the shop-management tab
(`stitchcraft-mobile/lib/features/shop/screens/shop_hub_screen.dart:6-25`).
Profile loads API profile and shops, uploads an avatar, changes password, and
contains logout/danger surfaces (`profile_screen.dart:40-177`,
`profile_screen.dart:203-276`).

Problems:

* Both “Profile” and “Shop settings” in More resolve to `/profile`
  (`more_hub_screen.dart:29-34`), while the profile has four tabs and mixes
  identity, shops, settings, security and destructive actions. This conflicts
  with the wireframe’s separate account/shop-settings mental model.
* `ProfileScreen` creates a `TabController` and multiple `TextEditingController`s
  but the reviewed class has no corresponding `dispose` implementation
  (`profile_screen.dart:25-33`, `profile_screen.dart:370` is build, not dispose).
* Error handling logs or displays raw exception text in several paths; error
  messages can expose backend details to users.

What is right: password update is sent to the backend’s `PUT /api/auth/update-password`
contract (`stitchcraft-backend/routes/authRoutes.js:40-41`), and logout clears
local session markers.

**Verdict: Partially correct.**

### Main navigation and dashboard

The shell implements Home, Orders, Customers, Khata, More and a centered New
Order action (`main_navigation_container.dart:31-155`), closely matching the
wireframe. Invoices and payments are reachable from More
(`more_hub_screen.dart:22-27`) and payments are also linked from dashboard
(`dashboard_screen.dart:528`), refuting the known “no clear entry point”
issue.

Problems:

* Dashboard metrics are derived from local orders/expenses and infer full
  payment from statuses such as `delivered`, `paid`, and `completed`
  (`dashboard_screen.dart:64-119`) instead of consuming
  `GET /api/dashboard/stats` (`stitchcraft-backend/routes/dashboardRoutes.js:6-8`).
  This can overstate collected cash when delivery is allowed with an unpaid
  balance.
* Dashboard code has an unused `_periodOrderCount` and analyzer warnings
  (`dashboard_screen.dart:38`).
* No `Trial` stage was found in the dashboard pipeline; the claim is refuted
  for the dashboard. Legacy `Trial Ready` remains in WhatsApp/order messaging
  (`whatsapp_service.dart:46-48`, `order_details_screen.dart:657-658`) and
  should not be reintroduced as a backend stage.

**Verdict: Partially correct.**

### Five-step order wizard and order creation

The route table exposes five order routes, although `/create_order_customer`
and `/create_order_step2` both construct `CustomerSelectionScreen`
(`main.dart:146-156`). The wizard captures garment, customer, measurements,
material, price/advance, assignment and due date. Step 5 validates positive
price and advance bounds (`step5_details.dart:178-204`) and saves locally
before attempting the backend (`step5_details.dart:271-300`), which is good
offline-first behavior.

Critical defect:

* The local order is inserted with `sync_status: 1`
  (`step5_details.dart:271-300`), then a direct `POST /orders` is made
  (`step5_details.dart:389-397`). On success, `syncedWithServer` is set but
  the local order is not marked synced or reconciled to the returned server
  ID (`step5_details.dart:397-426`). Later `SyncService` will POST that same
  pending record again (`sync_service.dart:135-143`, `sync_service.dart:333-350`).
  This is a concrete duplicate-order/data-loss risk.
* New customers have the same direct-post/local-pending split
  (`step5_details.dart:251-256`, `step5_details.dart:319-340`).
* The sample image upload and lining update are sequential side effects; a
  successful order followed by a failed inventory update leaves partial
  business state.
* Material and measurement values are carried through loosely typed maps. A
  missing field can silently become `Customer`, zero, or an empty URL.

Backend contract: create is correctly `POST /api/orders`
(`stitchcraft-backend/routes/orderRoutes.js:27-29`), but update is explicitly
`PUT /api/orders/:id` (`orderRoutes.js:31-35`).

**Verdict: Broken until idempotent create/reconciliation is implemented.**

### Orders list, details, statuses, deliveries, and payments

Order details loads local data first and then refreshes from
`GET /orders/:id` (`order_details_screen.dart:115-173`). Its status list is
exactly Incoming, Measuring, Cutting, Stitching, Checking, Ready, Delivered,
Cancelled (`order_details_screen.dart:101-109`), matching the backend model
contract and wireframe. Payment recording uses
`POST /orders/:id/payments` (`order_details_screen.dart:271-373`), matching
`orderRoutes.js:36`.

Problems:

* Status update performs remote PUT and then local mutation, but the local
  mutation is not marked pending when the network path fails; offline status
  changes can therefore be lost rather than queued
  (`order_details_screen.dart:175-220`).
* Inventory deduction is triggered when status reaches Checking/Ready/Delivered
  (`order_details_screen.dart:197-215`), while step 5 also deducts inventory
  immediately after order creation (`step5_details.dart:397-423`): the two
  flows can double deduct.
* Local payment fallback writes a local record, but reconciliation with the
  backend payment response and the order’s paid total is not fully proven.
* Deliveries use an order list filtered as `completed`
  (`main.dart:180-183`), while the backend contract is `GET /deliveries` and
  `PUT /deliveries/:id/deliver` (`deliveryRoutes.js:6-9`). The actual delivery
  action, unpaid-balance policy, and server response update are Unverified.

**Verdict: Partially correct, with high-risk offline mutation and payment
reconciliation gaps.**

### Customers and measurements

Customer list loads SQLite first and populates it from `GET /customers` when
empty (`customer_list_screen.dart:39-89`); the backend supports matching CRUD
routes (`customerRoutes.js:14-26`). The measurement screen validates positive
numbers, parses fractions, supports body/sample mode, and disposes its field
controllers (`step3_measurements.dart:116-185`, `step3_measurements.dart:220-226`).

Problems:

* Customer sync replaces invalid/missing phone values with `9999999999`
  (`sync_service.dart:238-245`), creating false PII and duplicate customers.
* Measurements are stored as nested order snapshots in sync
  (`sync_service.dart:249-267`), but there is no measurements backend route or
  independent conflict/reconciliation flow. The full contract is Unverified.
* Customer list deduplicates by phone locally, which can hide legitimate
  customers sharing a family/shop phone.

**Verdict: Partially correct.**

### Khata, udhar, expenses, payments, and invoice calculations

Khata presents udhar, income and expenses tabs and adds expenses locally
(`khata_screen.dart:23-116`). Expense sync maps to
`/api/ledger/expenses`, which matches backend POST/GET
(`sync_service.dart:136-140`, `ledgerRoutes.js:16-23`). Invoice list computes
total, advance and balance from local orders (`invoice_screen.dart:38-50`).

Problems:

* The dashboard treats delivered/completed as full collection
  (`dashboard_screen.dart:101-113`), whereas the ledger/invoice uses
  `total - advance`; unpaid delivery can disagree across screens.
* The UI uses `toStringAsFixed(0)` and raw `₹` strings
  (`invoice_screen.dart:115-151`) rather than Indian grouping and a shared
  currency formatter.
* Expense deletion is locally supported, but backend deletion is owner-only
  (`ledgerRoutes.js:22-23`); role behavior and rejected-delete UX are
  Unverified.
* There is no evidence of a server-authoritative ledger refresh before
  reporting balances.

**Verdict: Partially correct.**

### Invoices, PDF, print, share, and WhatsApp

Invoice list and details routes exist (`main.dart:174`, `main.dart:184`), and
`PdfService` supports PDF creation, printing and `share_plus`
(`core/services/pdf_service.dart:1-10`). Order details exposes an invoice
action (`order_details_screen.dart:685-688`, `order_details_screen.dart:1138`).
WhatsApp uses an external `wa.me` URL and Indian `+91` normalization
(`core/services/whatsapp_service.dart:10-31`).

Problems:

* `PdfService` expects backend-shaped `price`, `payment.paidAmount`,
  `deliveryDate`, and ISO date fields, while local invoice records use
  `total_amount`, `advance_amount`, and epoch milliseconds
  (`pdf_service.dart:17-52`, `invoice_screen.dart:105-113`). Offline PDF
  correctness is therefore not established.
* Invoice/PDF text is hardcoded English and uses non-grouped numeric output.
* WhatsApp launch failures are caught and only logged
  (`whatsapp_service.dart:33-38`); users receive no actionable fallback.

**Verdict: Partially correct.**

### Inventory and astar/lining

Inventory fetches the backend and caches records locally
(`inventory_screen.dart:31-83`); the backend uses POST/GET collection and
PUT/DELETE item routes (`inventoryRoutes.js:13-23`). Order creation sends
lining fields and then performs a direct inventory PUT
(`step5_details.dart:370-423`).

Critical problems:

* Inventory is also decremented during order status transitions
  (`order_details_screen.dart:197-215`); the guard is only an in-memory
  `asterDeducted` field and is not durably persisted with the order.
* Sync pushes all pending inventory records with POST to `/inventory`
  (`sync_service.dart:333-350`), although backend updates require PUT
  `/inventory/:id` (`inventoryRoutes.js:19-23`). Offline edits can create
  duplicates or fail validation.
* Local fallback hardcodes unit to `meters`
  (`inventory_screen.dart:70-78`), which can misrepresent thread/accessory
  stock.

**Verdict: Broken.**

### Karigars, machines, and staff permissions

Karigar and machine screens and detail routes are registered
(`main.dart:163-175`) and backend CRUD is protected
(`karigarRoutes.js:13-22`, `machineRoutes.js:13-22`). Order creation loads both
lists before assignment (`step5_details.dart:98-133`).

Problems:

* Neither entity is in `SyncService`’s four-table list
  (`sync_service.dart:45`, `sync_service.dart:135`), so offline create/edit
  behavior is not available even though the app is offline-first.
* Role-sensitive UI visibility is not demonstrated in these screens. Backend
  authorization must remain the only effective control.

**Verdict: Partially correct.**

### Repairs and gallery/design features

Repair dashboard contains hardcoded service/prices
(`repair_dashboard.dart:17-27`) and creates both a local customer and
`repair_jobs` record (`repair_dashboard.dart:163-185`). There is no repair route
in the backend route index (`stitchcraft-backend/routes/index.js:31-43`).
Repair records are also absent from sync tables. This confirms the known repair
prototype issue.

Gallery models and local helpers exist (`core/services/database/others_db_extension.dart:115-155`),
but no gallery screen is registered in `main.dart` and no backend gallery route
exists. This is a local prototype, not a complete feature.

**Verdict: Prototype.**

### Notifications and FCM

The notification screen fetches `/notifications`, marks all/read items through
the backend routes, and shows local alerts (`notifications_screen.dart:24-103`,
`notificationRoutes.js:6-11`). Initialization subscribes to foreground and
opened-app FCM events (`notification_service.dart:83-84`).

Problems:

* Local tap handling only logs `response.payload`; FCM tap handling only logs
  `message.data` (`notification_service.dart:185-191`). There is no
  `Navigator` deep link to an order/customer, confirming the known issue.
* The mobile code gets an FCM token but does not call backend
  `POST /notifications/register-device` (`notification_service.dart:88-93`,
  `notificationRoutes.js:8-10`).
* Background/terminated delivery, token rotation, iOS configuration, and
  backend sender behavior are Unverified.

**Verdict: Broken for actionable notification UX; end-to-end push is
Unverified.**

### Sync, encryption, offline/error behavior

SQLite is SQLCipher-backed and its generated key is stored in secure storage
(`local_db_service.dart:12-70`). The sync status screen exposes pending counts,
manual sync and failures (`sync_status_screen.dart:13-91`), which is good UX
intent.

Critical problems:

* `syncAll` and `getSyncStatus` cover only customers, orders, expenses and
  inventory (`sync_service.dart:45-45`, `sync_service.dart:135-135`).
  Repairs, measurements, karigars, machines, deliveries, notifications and
  payments are excluded.
* Every pending non-delete record is sent with `http.post` to the collection
  endpoint (`sync_service.dart:333-350`), never PUT by record ID. Backend
  routes explicitly require PUT for update (`orderRoutes.js:31-35`,
  `inventoryRoutes.js:19-23`, `customerRoutes.js:23-26`).
* Failed non-2xx pushes are logged but their sync state is not consistently
  changed to a durable retry/backoff state (`sync_service.dart:352-365`).
* Pull applies remote records with `insertRecord(...replace)` and no
  `updated_at` conflict comparison or tombstone/version resolution
  (`sync_service.dart:390-485`).
* The known `price: 100` and `Standard Cotton` literals were not found in the
  current mobile sync code. The current fallbacks are zero, `Customer Provided`,
  `Material Item`, and similar values (`sync_service.dart:279-281`,
  `sync_service.dart:292-315`); those defaults are still risky when required
  data is absent.

**Verdict: Broken.**

### Theme, accessibility, voice input, and quality

Theme and localization services are initialized centrally, and voice input is
encapsulated in `VoiceTextField`. The measurement screen disposes its
controllers, but profile does not show disposal. The navigation item provides
some semantics (`main_navigation_container.dart:101-125`).

Analyzer result:

```text
flutter analyze
13 issues found:
1 use_build_context_synchronously
2 unused_field
3 unused_import
4 unused_element
2 dead_code
3 dead_null_aware_expression
2 deprecated_member_use
```

The analyzer’s concrete locations include
`core/services/device_contacts_service.dart:481`,
`dashboard/screens/dashboard_screen.dart:38`,
`features/khata/screens/khata_screen.dart:11,124`,
`features/orders/screens/customer_details_screen.dart:307-308`,
`features/orders/screens/invoice_details_screen.dart:327,340`,
`features/orders/screens/order_details_screen.dart:1104`, and
`features/shop/screens/inventory_details_screen.dart:199`,
`features/shop/screens/inventory_screen.dart:168`.

`flutter test` result:

```text
00:00 +13: All tests passed!
```

The tests are limited to theme/phone/environment unit checks and a `NeoCard`
widget smoke test (`stitchcraft-mobile/test/unit_test.dart`,
`stitchcraft-mobile/test/widget_test.dart`). There are no API contract,
database migration, sync idempotency, role, offline, notification deep-link,
PDF, or order business-rule tests.

**Verdict: Partially correct; quality and coverage are insufficient for a
data-bearing offline ERP.**

## Known issues: verified or refuted

| Claim | Result | Evidence |
|---|---|---|
| Sync uses POST for updates and covers only four domains | Verified | `sync_service.dart:45`, `sync_service.dart:135`, `sync_service.dart:333-350`; backend update routes use PUT. |
| Sync hardcodes price 100 and “Standard Cotton” | Refuted literally; broader fallback risk remains | No current matches; current defaults are in `sync_service.dart:279-315`. |
| Dashboard shows Trial stage | Refuted for dashboard | No Trial in dashboard pipeline; legacy WhatsApp/order message remains at `whatsapp_service.dart:46-48`. |
| Role selection lets user choose own role | Refuted in current screen | `role_selection_screen.dart:35-55` only confirms assigned role. Direct `/home` route still needs guarding. |
| Payments/invoices have no navigation entry | Refuted | `more_hub_screen.dart:22-27`, `dashboard_screen.dart:528`, `order_details_screen.dart:685-688`. |
| Notification taps may not deep-link | Verified | `notification_service.dart:185-191` only logs. |
| FCM end-to-end is unverified | Verified as a gap | Listener/token acquisition exists, registration/backend sender/device validation is absent from the mobile path. |
| Repairs/gallery are prototypes without backend | Verified | Local repair insert at `repair_dashboard.dart:163-185`; no repair/gallery route in `routes/index.js`. |
| Profile duplicates shop settings and mixes danger actions | Verified | Both hub entries target `/profile`; profile contains multi-tab settings/security/shop/danger surfaces. |

## Unverified items and evidence needed

1. Splash session routing and first-run persistence: run the app with expired,
   valid, no-shop, invited-staff and multi-shop Supabase sessions; inspect
   `splash_screen.dart` behavior and route outcomes.
2. Exact runtime Authorization header construction: run a test request with a
   non-secret test account and capture only method/path/status, not tokens.
3. Full API response shapes for profile, dashboard, customers, orders,
   payments, inventory, karigars, machines, deliveries and notifications:
   execute contract tests against a seeded backend or inspect OpenAPI/fixtures.
4. Supabase RLS/shop isolation and backend role enforcement from the mobile
   client: test each role against each destructive/administrative action.
5. Delivery unpaid-balance behavior: create an unpaid order and attempt the
   delivery action on API and UI.
6. Measurement persistence and server representation: create a body and sample
   measurement, sync, then reload from a clean device.
7. Conflict handling: edit the same order/customer offline and server-side,
   then sync in both directions and inspect final state.
8. FCM: register Android/iOS device tokens, verify backend registration,
   send a real test notification, and test foreground/background/terminated
   taps with order/customer payloads.
9. Voice input: test microphone permission denial, interruption, locale
   switching, disposal, and Hindi/Gujarati recognition on physical devices.
10. PDF/print/share: generate from local and server-shaped orders, verify
    amounts, dates, Unicode, print target, and shared file contents.
11. Accessibility: test 200% text scale, screen readers, keyboard/focus,
    minimum 48dp hit targets, and RTL/long Hindi/Gujarati labels.
12. Background Workmanager execution: verify periodic scheduling, process
    restart, retry/backoff, auth expiry and battery/network constraints on
    Android and iOS.
