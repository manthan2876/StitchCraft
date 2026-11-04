# StitchCraft Mobile Improvement Plan

This plan is ordered by risk for an offline-first ERP. Each milestone is
intended to merge as a small, independently reviewable PR.

## P0 — security and data-loss prevention

### M0.1 — Make order/customer create idempotent

- **Affected files:** `stitchcraft-mobile/lib/features/orders/screens/create_order/step5_details.dart`, `stitchcraft-mobile/lib/core/services/sync_service.dart`, backend order/customer controllers/routes.
- **Problem:** direct online POST succeeds while the local record remains pending, so a later sync POST can duplicate the order/customer.
- **Fix:** choose one owner for create (queue locally, then sync) or persist the server response immediately; reconcile server ID, mark `sync_status=0`, and use an idempotency key derived from the local UUID. Never fabricate a replacement customer.
- **Backend change:** Yes — accept and persist an idempotency key for order/customer create and return the existing resource on replay.
- **Acceptance criteria:** one offline order synced repeatedly creates exactly one backend order; online and offline paths produce the same local/server ID; retries after timeout are safe.
- **Test:** sync service idempotency test with a fake HTTP server; integration test for timeout-after-server-commit.
- **Effort:** L. **Dependencies:** none.

### M0.2 — Prevent double inventory deduction

- **Affected files:** `step5_details.dart`, `order_details_screen.dart`, inventory/order backend services.
- **Problem:** creation and later status transition both deduct lining; the deduction guard is not durable.
- **Fix:** move deduction to one backend transaction at the agreed lifecycle stage, persist a server-side `inventoryDeductedAt`/ledger event, and make retries idempotent. Local UI mirrors the server result.
- **Backend change:** Yes — atomic order-stage transition plus inventory ledger mutation.
- **Acceptance criteria:** each order consumes lining once; failed/retried status updates cannot decrement twice; concurrent devices cannot oversell.
- **Test:** backend transaction/concurrency test and Flutter order-status integration test.
- **Effort:** L. **Dependencies:** M0.1.

### M0.3 — Enforce session/role gates at navigation and UI boundaries

- **Affected files:** `main.dart`, `auth_service.dart`, profile/shop/admin screens.
- **Problem:** `/home` is directly routable and local roles collapse to admin/staff.
- **Fix:** preserve the backend role exactly, resolve active shop/session before protected routes, render capability-based actions, and treat backend 401/403 as explicit sign-in/permission states.
- **Backend change:** No, assuming existing `protect/authorize` remains authoritative; add API tests if gaps are found.
- **Acceptance criteria:** a signed-out user cannot reach operational screens; each role sees only permitted actions; forged local preferences do not grant access.
- **Test:** route guard/widget tests plus role matrix integration tests.
- **Effort:** M. **Dependencies:** M0.1.

## P1 — correctness and synchronization

### M1.1 — Replace POST-only sync with an idempotent mutation queue

- **Affected files:** `sync_service.dart`, local DB schema/extensions, sync status screen, backend resource routes.
- **Problem:** sync only covers four tables and POSTs updates to collection endpoints; failures do not consistently transition to durable retry state.
- **Fix:** queue operation type/resource ID/version/payload; use POST for creates, PUT for updates, DELETE for deletes; store attempts and next retry; reconcile returned IDs and server versions.
- **Backend change:** No for existing CRUD routes; Yes if an idempotency/version endpoint is needed.
- **Acceptance criteria:** create/update/delete for each supported entity survives process death, retry, token refresh and duplicate execution; pending counts reflect all queued entities.
- **Test:** unit tests for operation selection; fake-server retry/conflict tests; migration test.
- **Effort:** L. **Dependencies:** M0.1.

### M1.2 — Define sync scope and conflict policy for every domain

- **Affected files:** local schema/services, `sync_service.dart`, feature repositories.
- **Problem:** repairs, measurements, karigars, machines, deliveries, notifications and payments are not covered; pull blindly replaces records.
- **Fix:** publish a domain matrix, add operation adapters for supported domains, and use server `updatedAt`/version plus tombstones. Keep notifications server-driven, not in the business queue.
- **Backend change:** Yes for version/tombstone fields and missing repair/gallery APIs; No for notifications if server remains source of truth.
- **Acceptance criteria:** every offline-capable feature is explicitly supported or visibly online-only; conflicts are deterministic and observable.
- **Test:** per-domain offline scenario matrix.
- **Effort:** L. **Dependencies:** M1.1; product decision on offline scope.

### M1.3 — Make order, payment, delivery and ledger totals server-authoritative

- **Affected files:** dashboard, order details, Khata widgets, invoice/PDF services, repositories.
- **Problem:** delivered status is treated as full payment, while invoices use advance balance; dashboard ignores `/dashboard/stats`.
- **Fix:** consume canonical payment/ledger totals, display delivery and payment independently, and block or explicitly confirm delivery with unpaid balance according to policy.
- **Backend change:** Yes if delivery/payment response lacks canonical balance and policy enforcement.
- **Acceptance criteria:** dashboard, order detail, Khata and invoice show identical totals for partial, full, refunded and delivered-unpaid orders.
- **Test:** unit tests for Indian-currency balance cases and integration tests across each screen.
- **Effort:** L. **Dependencies:** product decision on unpaid delivery.

### M1.4 — Remove fabricated data fallbacks

- **Affected files:** `sync_service.dart`, order/customer/inventory forms and mappers.
- **Problem:** invalid phones become `9999999999`; missing fields become walk-in/customer/material defaults and zero amounts.
- **Fix:** validate required fields at the boundary, retain null/unknown states where allowed, and block sync for invalid records with field-level errors.
- **Backend change:** No, unless validation schemas need explicit optional fields.
- **Acceptance criteria:** no synthetic customer phone or price is written; invalid pending records remain visible with actionable repair UI.
- **Test:** mapper validation tests for missing/invalid payloads.
- **Effort:** M. **Dependencies:** M1.1.

## P2 — UX and navigation

### M2.1 — Separate profile, shop settings, security and danger zones

- **Affected files:** `more_hub_screen.dart`, `profile_screen.dart`, profile widgets, routes.
- **Problem:** profile and shop settings both open `/profile`; unrelated danger actions are mixed into account settings.
- **Fix:** create distinct destinations/tabs with explicit headings, role visibility, confirmations and success/error states.
- **Backend change:** No.
- **Acceptance criteria:** a user can find shop settings, profile, sync and logout without ambiguity; owner-only actions are hidden and 403-safe.
- **Test:** navigation/widget tests for each role and destructive confirmation.
- **Effort:** M. **Dependencies:** M0.3.

### M2.2 — Implement notification registration and deep links

- **Affected files:** `notification_service.dart`, `notifications_screen.dart`, `main.dart`.
- **Problem:** FCM token is acquired but not registered; taps only log payload/data.
- **Fix:** register/refresh token at authenticated startup, define typed payloads, and route order/customer notification taps to detail screens with missing-record fallback.
- **Backend change:** No if `POST /notifications/register-device` is complete; verify/update sender payloads as needed.
- **Acceptance criteria:** foreground/background/terminated notification tap opens the intended record; invalid payload opens notifications safely; token rotation is handled.
- **Test:** payload parsing unit tests and Android/iOS integration tests.
- **Effort:** M. **Dependencies:** M0.3; FCM verification.

### M2.3 — Standardize localization, currency and responsive states

- **Affected files:** all feature screens with direct strings, localization ARB/generated source, shared formatters/widgets.
- **Problem:** many English literals remain; currency is not Indian-grouped; loading/empty/error/offline states are inconsistent.
- **Fix:** add translation keys, `NumberFormat.currency(locale: 'en_IN', symbol: '₹')`, shared state widgets, and test long translated labels/text scale.
- **Backend change:** No.
- **Acceptance criteria:** no user-facing hardcoded English in supported flows; all lists have loading/empty/error/retry/offline states; amounts use Indian grouping.
- **Test:** locale widget tests at 1x/2x text scale and formatter unit tests.
- **Effort:** L. **Dependencies:** M2.1.

### M2.4 — Make delivery, payment and invoice actions discoverable and safe

- **Affected files:** order list/details, deliveries, Khata, invoice screens.
- **Problem:** entry points exist but delivery action/contract and offline behavior are not fully explicit.
- **Fix:** add clear primary actions, unpaid-balance confirmation/policy, retry/error feedback, and server/local reconciliation after mutations.
- **Backend change:** Yes if delivery policy is not enforced server-side.
- **Acceptance criteria:** user can move from order to payment, invoice and delivery; every mutation shows authoritative result and retry state.
- **Test:** widget navigation and integration tests for partial-payment delivery.
- **Effort:** M. **Dependencies:** M1.3.

## P3 — quality, tests and performance

### M3.1 — Establish repository/data-layer boundaries

- **Affected files:** feature screens and core services.
- **Problem:** screens directly call HTTP and SQLite, duplicate mapping, and make business decisions in widgets.
- **Fix:** introduce typed repositories/use cases for auth, orders, customers, ledger, inventory and notifications; centralize DTO mapping and error types.
- **Backend change:** No.
- **Acceptance criteria:** screens depend on typed state/repositories; each API call has one contract mapper; no duplicate endpoint strings.
- **Test:** repository contract tests with fake HTTP/local DB.
- **Effort:** L. **Dependencies:** M1.1-M1.3.

### M3.2 — Fix analyzer/lifecycle issues and controller disposal

- **Affected files:** analyzer-reported files, especially `profile_screen.dart`, `device_contacts_service.dart`, dashboard/Khata/order/inventory screens.
- **Problem:** analyzer reports 13 issues; profile controller disposal is missing.
- **Fix:** resolve async context guards, dead code, unused members/imports, deprecated form API, and dispose all controllers/subscriptions.
- **Backend change:** No.
- **Acceptance criteria:** `flutter analyze` exits clean with no new warnings; route transitions do not leak controllers/listeners.
- **Test:** analyzer CI check and widget lifecycle tests.
- **Effort:** S. **Dependencies:** none.

### M3.3 — Add ERP-grade automated coverage

- **Affected files:** `stitchcraft-mobile/test/`, test fixtures and fake servers.
- **Problem:** current 13 passing tests do not cover sync, API contracts, roles or business rules.
- **Fix:** add unit, widget, integration and golden/state tests around the acceptance criteria above.
- **Backend change:** No, except shared contract fixtures.
- **Acceptance criteria:** CI covers create/update/delete retries, conflict handling, payment math, inventory once-only deduction, role gates, translations, notifications and PDF mapping.
- **Test:** this task is the test suite itself.
- **Effort:** L. **Dependencies:** M0-M2.

### M3.4 — Verify background work and performance

- **Affected files:** `sync_worker.dart`, database services, list screens.
- **Problem:** Workmanager behavior, N+1 queries, and large-list performance are not verified.
- **Fix:** instrument batch queries, paginate server/local lists, verify background constraints/retry, and keep heavy mapping off the UI thread where needed.
- **Backend change:** Possibly — pagination/filter endpoints if absent.
- **Acceptance criteria:** 1,000-order/customer datasets remain responsive; background sync retries after process kill/network loss without duplicate writes.
- **Test:** Android background integration and performance scenario.
- **Effort:** M. **Dependencies:** M1.1.

## P4 — new features

### M4.1 — Decide and deliver repairs

- **Affected files:** `repair_dashboard.dart`, repair models/DB, new repository/screen tests.
- **Problem:** repair tickets are local-only with hardcoded service catalog and no backend route.
- **Fix:** either label repairs explicitly as local-only MVP, or add backend CRUD, pricing configuration, customer/order linkage and sync.
- **Backend change:** Yes for the complete feature.
- **Acceptance criteria:** selected product decision is visible in UX; complete mode survives another device and sync.
- **Test:** repair CRUD/sync integration tests.
- **Effort:** L. **Dependencies:** product decision; M1.2.

### M4.2 — Decide and deliver gallery/design library

- **Affected files:** gallery model/DB helpers, new gallery screens and repositories.
- **Problem:** local gallery model/helpers exist without a route or backend.
- **Fix:** either remove/hide the prototype or implement Supabase Storage/backend metadata, shop scoping, upload/view/delete and offline cache.
- **Backend change:** Yes for shared gallery.
- **Acceptance criteria:** users can browse/add/delete shop-scoped designs and use one in an order without losing it offline.
- **Test:** storage permission, scoping and offline-cache tests.
- **Effort:** L. **Dependencies:** product decision; M1.2.

### M4.3 — Complete voice and WhatsApp workflows

- **Affected files:** `voice_text_field.dart`, `whatsapp_service.dart`, order/customer actions.
- **Problem:** device-specific voice behavior is unverified and WhatsApp failures/legacy Trial Ready text are not product-safe.
- **Fix:** define supported locales and fallback, expose actionable launch errors, update templates to backend stages, and add opt-in/PII guidance.
- **Backend change:** No for external WhatsApp; possibly yes for approved message templates/notification audit.
- **Acceptance criteria:** Hindi/Gujarati voice failure is understandable; all templates use valid stages; users can retry/cancel.
- **Test:** service unit tests and device integration tests.
- **Effort:** M. **Dependencies:** M2.3.

## Product-owner decisions

1. **Offline scope:** recommended default is offline create/edit for orders,
   customers, measurements, expenses and inventory, with karigars/machines and
   notifications online-only until their adapters exist.
2. **Unpaid delivery:** recommended default is allow delivery only after an
   explicit owner/manager confirmation and record the outstanding balance.
3. **Repair/gallery release:** recommended default is hide both prototypes from
   production navigation until backend contracts and sync are delivered.
4. **Inventory deduction stage:** recommended default is one backend deduction
   at `Ready`, not at create and not repeatedly at status transition.
5. **Customer duplicate policy:** recommended default is warn on normalized
   phone match and let staff explicitly merge/select, never fabricate a phone.

## Milestones

1. **M0 — Data safety/security:** M0.1, M0.2, M0.3.
2. **M1 — Sync and authoritative business state:** M1.1-M1.4.
3. **M2 — Usable daily workflows:** M2.1-M2.4.
4. **M3 — Maintainability and confidence:** M3.1-M3.4.
5. **M4 — Product-approved expansion:** M4.1-M4.3.

## Test plan

### Unit

- DTO mapping for local/backend order, customer, payment, inventory and
  measurement shapes.
- Sync operation selection, idempotency key, retry/backoff, conflict/version
  resolution and invalid-record validation.
- Indian currency/date formatting, payment balance, unpaid delivery policy and
  once-only inventory deduction.
- Notification payload parsing and route target resolution.

### Widget

- Route guards and capability-based action visibility for owner, manager,
  staff and karigar.
- Five-step wizard validation and exact local record/pending state.
- Loading, empty, error, offline and retry states for each list/detail screen.
- Hindi/Gujarati strings at 200% text scale, minimum 48dp controls and
  profile/shop/danger navigation separation.
- Invoice/PDF action availability and payment/delivery confirmation dialogs.

### Integration

- Supabase login/profile/role/shop setup against a test backend.
- Order create online, offline, timeout-after-commit, token refresh and replay.
- Customer duplicate warning, measurement save/reload and order status update.
- Payment, partial balance, delivery and invoice consistency across screens.
- Inventory deduction under retries and concurrent status transitions.
- Notification token registration and foreground/background/terminated deep link.

### Offline-sync scenarios

1. Create each supported entity offline, kill the app, reconnect and sync.
2. Edit a pending record twice before reconnect; assert one final mutation.
3. Delete offline, then pull a stale server record; assert tombstone wins.
4. Expire the Supabase token during a batch; assert refresh and resume without
   duplicate writes.
5. Fail one record in a batch; assert other records continue and the failed
   record has visible retry/error state.
6. Resolve simultaneous server/device edits using the documented version policy.

## Risk list

- Duplicate orders or inventory oversell during rollout if old pending rows are
  not migrated/idempotency-reconciled.
- Changing payment semantics can alter reported revenue and customer balances;
  run a data reconciliation before release.
- Role preservation may expose existing accounts whose local role was flattened;
  force a fresh server profile read.
- SQLCipher key migration failures can make local data unavailable; test backup,
  restore and legacy-key migration before schema changes.
- FCM and storage integrations depend on platform credentials/configuration not
  fully visible in this source audit.
- Large localization changes can introduce truncation or changed business
  terminology; review Hindi/Gujarati copy with native users.
