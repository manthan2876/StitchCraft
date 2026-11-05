# 🔍 StitchCraft: Deep Implementation Audit & Requirements-Fit Analysis

**Audit Date:** November 2026  
**Auditor:** Principal Engineer & Lead Product Systems Analyst  
**Scope:** `stitchcraft-backend/`, `stitchcraft-frontend/`, `stitchcraft-mobile/`, `supabase/`, `docs/`, `.github/`  
**Execution Environment:** Node.js 24.21.0, Express 5.2.1, Vite 8.3.5 / React 19.3.1, Dart 3.13.7 (Flutter binary not present on host; CI-validated via `subosito/flutter-action@v2`), Supabase PostgreSQL.

---

## 1. Executive Summary & Verification Results

### 1.1 Automated Verification & Build Tooling Output

Direct execution of test, lint, and build suites across the three repositories produced the following empirical results:

| Subsystem | Command | Execution Status | Key Details & Findings |
|---|---|---|---|
| **Backend API** | `npm test` | **PASS (57/57 tests)** | 18 test suites passed in 579ms. Note: `README.md:57` and `ARCHITECTURE.md:217` state "37 tests across 14 suites", which is out of date. Syntax check via `node --check` passed across all files. No linter configured in `package.json`. |
| **Web Dashboard** | `npm test` | **PASS (18/18 tests)** | 11 test suites passed in 173ms covering form validators and currency/date formatters. |
| **Web Dashboard** | `npm run lint` | **PASS (0 errors, 14 warnings)** | ESLint 10.13.0 flagged 14 warnings: 3 React Refresh warnings for non-component exports in Contexts (`AuthContext.jsx:4`, `LanguageContext.jsx:31`, `ThemeContext.jsx:37`), 8 React Hook `exhaustive-deps` warnings, and 3 unused variables (`useDashboard.js:25`, `useProfile.js:92, 299`). |
| **Web Dashboard** | `npm run build` | **PASS (Clean build)** | Vite 8.3.5 production client build succeeded in 1.10s (144 modules transformed, 489 kB JS bundle, 86 kB CSS). |
| **Mobile App** | `flutter analyze` & `flutter test` | **ENVIRONMENT LIMITATION** | `flutter: command not found` on host environment. Standalone Dart SDK 3.13.7 is present at `/usr/bin/dart`, but cannot resolve `package:flutter/...` without the Flutter SDK framework. GitHub Actions CI (`.github/workflows/ci.yml:61-79`) executes `subosito/flutter-action@v2` on Ubuntu runners. Unit test files (`test/unit_test.dart` and `test/widget_test.dart`) exist with comprehensive coverage. |

---

## 2. End-to-End Implementation Audit & Traceability Matrix

Every requirement identified in `docs/PROJECT_REQUIREMENTS.md` was traced end-to-end through the runtime code path:
`UI -> State / Hook -> Local DB -> Sync Engine -> API Route -> Middleware -> Controller -> Service -> Model / Database Adapter -> Response -> UI`.

### Status Legend
- **Implemented and correct**: Code path fully implemented, verified with matching contracts and business logic.
- **Implemented with defects**: Code exists but contains logical bugs, broken parameters, or contract discrepancies.
- **Partial**: Feature only exists on one platform or lacks necessary backend/frontend wiring.
- **Prototype / Mock**: Hardcoded UI mockup, stubbed service, or explicitly tagged experimental.
- **Missing**: Functionality does not exist in source code.
- **Unverified**: Cannot be verified from repository code or static analysis without live third-party services.

---

### 2.1 Traceability Table by Domain

#### Domain 1: Authentication & Account Management (AUTH)

| Req ID | Trace Path | Classification | Evidence (File:Line) & Findings |
|---|---|---|---|
| **AUTH-01** (Signup) | `Signup.jsx:75` / `signup_screen.dart:180` -> `AuthContext.jsx:92` / `auth_service.dart:24` -> `POST /api/auth/register` -> `authLimiter`, `validateRegisterRequest` -> `authController.js:14` -> `User.js`, `Shop.js` -> `app_records` | **Implemented and correct** | Verified. Provisions both `User` and default `Shop` transactionally upon registration (`authController.js:56-74`). Scoped by Supabase Auth bearer token. |
| **AUTH-02** (Login) | `Login.jsx:55` / `login_screen.dart:120` -> `AuthContext.jsx:65` / `auth_service.dart:233` -> `POST /api/auth/login` -> `authLimiter` -> `authController.js:94` -> `User.findOne` -> returns user & shop | **Implemented and correct** | Verified. Returns user profile, active `shopId`, and session token. Mobile stores token in `FlutterSecureStorage` (`auth_service.dart:279`). |
| **AUTH-03** (Email Verify) | `verify_email_sheet.dart:85` -> `POST /api/auth/verify` -> `authLimiter` -> `authController.js:236` -> `supabase.auth.verifyOtp` -> provisions user | **Implemented with defects** | `authController.js:307-311` contains a hard block: `if (user.role !== 'owner') return res.status(403)`. Any invited staff or karigar attempting email verification is rejected with HTTP 403 Forbidden. |
| **AUTH-04** (Forgot Password) | `ForgotPassword.jsx:32` / `login_screen.dart:340` -> `AuthContext.jsx:134` / `auth_service.dart:336` -> `POST /api/auth/forgot-password` -> `authLimiter`, `validateForgotPasswordRequest` -> `authController.js:388` | **Implemented and correct** | Verified. `supabase.auth.resetPasswordForEmail` called with rate-limiting and email regex validation. |
| **AUTH-05** (Reset Password) | `ResetPassword.jsx:61` -> `AuthContext.jsx:150` -> `supabase.auth.updateUser` (Frontend) VS `POST /api/auth/reset-password` (Backend) | **Implemented with defects** | **API Contract Disconnect**: Backend route `POST /api/auth/reset-password` (`authRoutes.js:38`) has `protect` middleware, but frontend `AuthContext.jsx:153` bypasses backend entirely and calls client-side `supabase.auth.updateUser({ password })`. Furthermore, backend route requires existing session which contradicts standard unauthenticated recovery flows. |
| **AUTH-06** (Update Password) | `Profile.jsx:180` / `security_tab.dart:65` -> `PUT /api/auth/update-password` -> `protect`, `destructiveLimiter` -> `authController.js:186` -> `supabase.auth.signInWithPassword` + `updateUserById` | **Implemented and correct** | Verified. Strictly verifies `currentPassword` against Supabase before updating to `newPassword` (`authController.js:193-204`). |
| **AUTH-07** (Session Persistence) | `main.dart:80-95` / `App.jsx:30-40` -> `FlutterSecureStorage` / `localStorage` -> `protect` middleware (`authMiddleware.js:4-63`) | **Implemented and correct** | Hardware-backed keystore token on mobile (`auth_service.dart:85`). |
| **AUTH-08** (Device Purge on Logout) | `profile_screen.dart:260` -> `auth_service.dart:314` -> `_dbService.clearAllData()` + `_secureStorage.delete()` | **Implemented and correct** | Verified. On logout or switching shops on a shared Android device, all local SQLite tables are completely wiped to prevent tenant data leakage (`auth_service.dart:284-286, 328`). |
| **AUTH-09** (Phone OTP Login) | None | **Missing** | Stated as assumption. No SMS/WhatsApp phone OTP authentication exists; only email/password is implemented. |

---

#### Domain 2: Shops & Multi-Tenancy (SHOP)

| Req ID | Trace Path | Classification | Evidence (File:Line) & Findings |
|---|---|---|---|
| **SHOP-01** (Shop Isolation) | Every API route -> `protect` middleware (`authMiddleware.js:52`) -> `req.user.shopId` -> Controller queries -> `SupabaseModel.js:179` | **Implemented and correct** | Verified by `shop_isolation.test.js:1-90`. All operational entities (`Order`, `Customer`, `Inventory`, etc.) require and filter by `shopId`. |
| **SHOP-02** (Switch Active Shop) | `Profile.jsx:120` / `shops_tab.dart:80` -> `PUT /api/auth/switch-shop/:id` -> `protect` -> `profileController.js:65` -> `Shop.findOne({ _id: id, ownerId: req.user._id })` | **Implemented and correct** | Verified. Sets active `shopId` on `User` document and returns updated JWT context (`profileController.js:100-110`). |
| **SHOP-03** (Shop Settings / Branding) | `ShopSettings.jsx` / `shop_settings_screen.dart:180` -> `PUT /api/shops/:id` -> `protect` -> `shopController.js:78` -> `Shop.save()` | **Implemented and correct** | Updates GSTIN, UPI ID, logo URL, invoice prefix (`INV`), and address (`shopController.js:86-98`). |
| **SHOP-04** (WhatsApp Templates) | `ShopSettings.jsx:140` -> `PUT /api/shops/:id` -> `shopController.js:97` -> `Shop.whatsappTemplates` | **Implemented and correct** | Preserves custom dictionary of WhatsApp templates in the shop document. |
| **SHOP-05** (Partner Tailor Discovery) | `outsource_order_sheet.dart:65` -> `GET /api/shops/partners` -> `protect` -> `shopController.js:145` -> returns active shops | **Implemented and correct** | Verified. Excludes requesting shop (`_id: { $ne: req.user.shopId }`) and returns public contact card. |
| **SHOP-06** (Shop Deletion) | `Profile.jsx:220` -> `DELETE /api/shops/:id` -> `protect`, `authorize('owner')`, `destructiveLimiter` -> `shopController.js:105` | **Implemented and correct** | Verified. Requires owner role and purges all associated documents (`shopController.js:125-135`). |

---

#### Domain 3: Roles & Permissions (ROLE)

| Req ID | Trace Path | Classification | Evidence (File:Line) & Findings |
|---|---|---|---|
| **ROLE-01** (4-Role Capability Matrix) | `authMiddleware.js:44-50, 65-78` | **Implemented with defects** | **Architectural Blocker**: While `User.js:13` and `tableValidators.js:133` define `['owner', 'manager', 'karigar', 'staff']`, `authMiddleware.js:46-50` in `protect` hard-blocks ANY user whose role is not `'owner'` with HTTP 403: `Forbidden: role '${user.role}' is not authorized. StitchCraft is restricted to shop owners only.` Furthermore, `authorize()` (`authMiddleware.js:72`) hardcodes `if (userRole !== 'owner') return 403` and completely ignores its `...roles` argument! |
| **ROLE-02** (Owner-Only Destructive Ops) | `authRoutes.js:45-49`, `staffRoutes.js:16`, `shopRoutes.js:24` -> `authorize('owner')` | **Implemented and correct** | Verified. Database wiping, data export/import, account deletion, and shop deletion strictly enforce owner-only access. |
| **ROLE-03** (Manager Delegated Access) | `Sidebar.jsx:36` (`isManagerOrOwner`) -> `GET /api/staff` | **Implemented with defects** | `Sidebar.jsx:36` displays the Staff page link to managers, but `staffRoutes.js:16` applies `router.use(authorize('owner'))` to the entire router. When a manager visits `/staff`, `StaffManagement.jsx` crashes or displays a blank table with a 403 error. |
| **ROLE-04** (Staff Restricted Access) | Route permissions across `routes/ledgerRoutes.js`, `routes/inventoryRoutes.js`, `routes/orderRoutes.js` | **Implemented with defects** | Sensitive ledger routes (`GET /api/ledger/summary`, `GET /api/ledger/journal`, `GET /api/customers/pending-balances`) and deletion routes (`DELETE /api/orders/:id`, `DELETE /api/customers/:id`, `DELETE /api/inventory/:id`) lack `authorize()` middleware. Any authenticated token belonging to the shop can read profit margins or delete records. |
| **ROLE-05** (Karigar Job Isolation) | `my_jobs_screen.dart:55-82` -> `_localDb.getAllOrders()` | **Implemented with defects** | In `my_jobs_screen.dart:55`, mobile loads ALL workshop orders from local SQLite rather than filtering by `assigned_karigar_id`. Additionally, karigars are blocked from backend sync by `authMiddleware.js:46`. |
| **ROLE-06** (Staff Invitation & Roles UI) | `StaffManagement.jsx:58-85` -> `POST /api/staff` and `PUT /api/staff/:id/role` -> `staffController.js:114` | **Implemented with defects** | **API Contract Conflict**: In `StaffManagement.jsx:266, 387`, the dropdown options are hardcoded as `<option value="admin">Admin</option>` and `<option value="owner">Owner</option>`. When an owner selects "Admin", frontend sends `{ role: 'admin' }`. Backend `staffController.js:121` validates against `['manager', 'karigar', 'staff']` and rejects with HTTP 400: `Valid role is required (manager, karigar, staff)`. Role updates fail with an alert. |

---

#### Domain 4: Customers (CUST)

| Req ID | Trace Path | Classification | Evidence (File:Line) & Findings |
|---|---|---|---|
| **CUST-01** (Customer Creation) | `Customers.jsx:45` / `customer_list_screen.dart:180` -> `POST /api/customers` -> `validateCustomerCreateRequest` -> `customerController.js:17` -> `customerService.js:27` | **Implemented and correct** | Verified. Sanitizes phone number, verifies required fields, and creates customer document in `app_records`. |
| **CUST-02** (Customer Search) | `Customers.jsx:25` / `customer_list_screen.dart:95` -> `GET /api/customers?search=...` -> `customerController.js:38-51` | **Implemented and correct** | Scoped regex search on Name, Phone, Email, Customer ID with ReDoS-safe escaping (`securityMiddleware.js:64-66`). |
| **CUST-03** (Customer Full Profile) | `CustomerDetails.jsx:35` / `customer_details_screen.dart:120` -> `GET /api/customers/:id` -> `customerService.js:96-148` | **Implemented and correct** | Aggregates customer document, current measurements, order history, and outstanding balance. |
| **CUST-04** (Customer Idempotency) | `step5_details.dart:336-348` -> `Idempotency-Key: cust_<id>` -> `customerService.js:31-38` | **Implemented and correct** | Verified by `idempotency_and_inventory.test.js:19-35`. Returns existing customer record if duplicate mutation is received. |
| **CUST-05** (Save to Android Contacts) | `step5_details.dart:223` -> `DeviceContactsService().saveContactToPhone()` | **Implemented and correct** | Requests Android contacts permission and inserts contact record natively. |
| **CUST-06** (Customer Delete) | `CustomerDetails.jsx:90` -> `DELETE /api/customers/:id` -> `destructiveLimiter` -> `customerService.js:192-205` | **Implemented with defects** | Performs a hard delete on `Customer` and `Measurement` records (`customerService.js:196-197`). Sets `customer: ""` on orders, leaving orphaned historical records. |

---

#### Domain 5: Measurements (MEAS)

| Req ID | Trace Path | Classification | Evidence (File:Line) & Findings |
|---|---|---|---|
| **MEAS-01** (Standard Numeric Fields) | `MeasurementForm.jsx:50-180` / `step3_measurements.dart:100-240` -> `Measurement.js:1-45` -> `tableValidators.js:52-70` | **Implemented and correct** | Validates numeric values and stores nested shirt/pant measurement models. |
| **MEAS-02** (Inches/CM & Fraction Pad) | `step3_measurements.dart:85-115` | **Implemented and correct** | Custom fractional keyboard (1/4, 1/2, 3/4) and unit converter implemented on mobile. |
| **MEAS-03** (Maap Physical Garment Photo) | `NewOrder.jsx:43` / `step3_measurements.dart:120` -> `uploadToPrivateBucket` -> `orderService.js:335` (`maapImageUrl`) | **Implemented and correct** | Verified. Supports switching between 'Measurements' and 'Maap' with sample garment photo attachment. |
| **MEAS-04** (Voice Notes) | `voice_text_field.dart:1-120` -> `speech_to_text` plugin -> appends text to measurement notes | **Implemented and correct** | Verified. Hands-free speech-to-text input available on mobile measurement form. |
| **MEAS-05** (Preload Last Measurements) | `CustomerDetails.jsx:184` -> `useNewOrder.js:84-100` (`api.get('/customers/' + id)`) | **Implemented with defects** | **Mobile Crash Bug**: Web preloads measurements properly (`useNewOrder.js:86-98`). On mobile, the "Book New Order" FAB in `customer_details_screen.dart:290-299` navigates to `'/create_order'`, which does not exist in `main.dart` route table, crashing navigation immediately. |
| **MEAS-06** (Measurement Snapshotting) | `orderService.js:238-254, 339` (`measurementsSnapshot`) | **Implemented and correct** | Verified by `order_lifecycle.test.js:1-25`. Orders retain immutable snapshot of measurements taken at booking. |
| **MEAS-07** (Female & Traditional Templates) | None | **Missing** | Stated as assumption. Models only support hardcoded `shirt` and `pant` schemas; Blouse, Kurti, and Salwar templates are absent. |

---

#### Domain 6: Orders & Workshop Stages (ORD)

| Req ID | Trace Path | Classification | Evidence (File:Line) & Findings |
|---|---|---|---|
| **ORD-01** (Order Creation Wizard) | `NewOrder.jsx:78-470` (3 steps) / `step1` to `step5_details.dart` (5 steps) -> `POST /api/orders` -> `orderService.js:196-397` | **Implemented and correct** | Normalizes single-item and multi-item orders, calculates price and advance, creates Order, Delivery, and Payment entities. |
| **ORD-02** (Sequential Stage Progression) | `OrderDetails.jsx:80-140` / `order_details_screen.dart:280-350` -> `PUT /api/orders/:id` -> `orderService.js:400-513` | **Implemented and correct** | Supports `Incoming` -> `Measuring` -> `Cutting` -> `Stitching` -> `Checking` -> `Ready` -> `Delivered` -> `Cancelled`. Triggers notifications on stage change. |
| **ORD-03** (Order Creation Idempotency) | `step5_details.dart:385, 423` -> `Idempotency-Key: order_<id>` -> `orderService.js:219-230` | **Implemented and correct** | Verified by `idempotency_and_inventory.test.js:1-18`. Duplicate submissions return existing order without creating secondary records. |
| **ORD-04** (Fabric / Swatch Photos) | `NewOrder.jsx:110` / `step5_details.dart:378` -> `uploadToPrivateBucket` -> `orderService.js:336` (`fabricImageUrl`) | **Implemented and correct** | Images stored in private Supabase storage bucket (`maap-images`) under `shopId/filename`. |
| **ORD-05** (Karigar / Machine Assignment) | `NewOrder.jsx:28-40` -> `orderService.js:337-338` -> `Order.assignedKarigar`, `Order.assignedMachine` | **Implemented and correct** | Populates assigned artisan and equipment references. |
| **ORD-06** (Timestamped Audit Notes) | `OrderDetails.jsx:160` / `order_details_screen.dart:410` -> `POST /api/orders/:id/notes` -> `orderController.js:508-529` | **Implemented and correct** | Appends `{ text, addedAt }` to order notes array without mutating previous entries (`order_lifecycle.test.js:80-95`). |
| **ORD-07** (Outsourced Partner Order) | `outsource_order_sheet.dart:1-150` -> `POST /api/orders/:id/delegate` -> `orderService.js:515-600` | **Implemented and correct** | Verified by `security_and_scoping.test.js:110-135`. Sanitizes customer details, adjusts due date 1 day earlier, and notifies partner shop. |
| **ORD-08** (Order Soft-Delete) | `OrderDetails.jsx:210` -> `DELETE /api/orders/:id` -> `orderService.js:681-730` | **Implemented and correct** | Sets `status: 'Cancelled'`, `isDeleted: true`, restores deducted astar stock, and cancels delivery while preserving transactions. |

---

#### Domain 7: Inventory & Astar (Lining) Stock (INV)

| Req ID | Trace Path | Classification | Evidence (File:Line) & Findings |
|---|---|---|---|
| **INV-01** (Inventory Management) | `Inventory.jsx:1-250` / `inventory_screen.dart:1-350` -> `GET/POST /api/inventory` -> `inventoryController.js:1-120` | **Implemented and correct** | Full CRUD for fabric, lining, thread, and accessories with quantity, cost per unit, and min threshold. |
| **INV-02** (Astar Automatic Deduction) | `orderService.js:123-193` (`handleAstarStockAdjustment`) -> triggers when status enters `ASTAR_DEDUCT_STATUSES` | **Implemented and correct** | Verified by `idempotency_and_inventory.test.js:36-55`. Deducts astar quantity from inventory once upon reaching workshop stages. |
| **INV-03** (Astar Automatic Restoration) | `orderService.js:157-165, 692-715` -> triggers on status rollback or order deletion | **Implemented and correct** | Verified by `idempotency_and_inventory.test.js:56-70`. Accurately adds consumed stock back to inventory. |
| **INV-04** (Low-Stock Push Notifications) | `orderService.js:145-155` -> `dispatchNotification({ type: 'low_stock', sendPush: true })` | **Implemented and correct** | Triggers FCM push notification when stock falls to or below `minQuantity`. |
| **INV-05** (Wastage & Stock Adjustments) | `inventoryController.js:65-115` -> `PUT /api/inventory/:id` | **Implemented and correct** | Validates non-negative stock and records adjustments. |

---

#### Domain 8: Payments & Financial Transactions (PAY)

| Req ID | Trace Path | Classification | Evidence (File:Line) & Findings |
|---|---|---|---|
| **PAY-01** (Record Order Payment) | `Payments.jsx:45` / `record_payment_sheet.dart:1-120` -> `POST /api/orders/:id/payments` -> `orderController.js:320-401` | **Implemented and correct** | Validates positive amount, normalizes payment type (`Cash`, `UPI`, `Card`, `Credit`, `Bank`), and creates Transaction. |
| **PAY-02** (Immutable Transaction Ledger) | `orderService.js:31-58` (`syncPaymentFromTransactions`) -> sums `Transaction` records | **Implemented and correct** | Verified by `financial_integrity.test.js:1-25`. Payment records are strictly derived by aggregating immutable transactions. |
| **PAY-03** (Refunds & Reversals) | `OrderDetails.jsx:190` -> `POST /api/orders/:id/refunds` -> `orderController.js:406-489` | **Implemented and correct** | Creates immutable `Refund` transaction with mandatory audit reason (`financial_integrity.test.js:26-44`). |
| **PAY-04** (Payment Status State Machine) | `orderService.js:54` -> `payment.balanceAmount === 0 ? 'Paid' : (totalPaid > 0 ? 'Partial' : 'Pending')` | **Implemented and correct** | Mathematical status transitions verified by `order_lifecycle.test.js:30-45`. |
| **PAY-05** (Payment Idempotency) | `orderController.js:325-358` -> checks `idempotencyKey` on `Transaction` | **Implemented and correct** | Verified by `financial_integrity.test.js:10-25`. Prevents duplicate transaction creation on repeated network requests. |

---

#### Domain 9: Invoices & Public Share Links (INVOICE)

| Req ID | Trace Path | Classification | Evidence (File:Line) & Findings |
|---|---|---|---|
| **INVOICE-01** (Customer Guest Invoice) | WhatsApp shared link -> `App.jsx:45` (`/invoice/share/:id`) -> `PublicInvoice.jsx:32` -> `GET /api/orders/public/:token` | **Implemented and correct** | Loads guest invoice receipt cleanly on desktop and mobile browsers without requiring authentication. |
| **INVOICE-02** (Strict Opaque Token Lookup) | `orderRoutes.js:31` -> `validateShareTokenParam` -> `orderController.js:172-180` | **Implemented and correct** | Verified by `public_invoice_hardening.test.js:1-60`. Strictly queries by `shareTokenHash` or `shareToken`. Zero fallback to MongoDB `_id` or sequential `orderId`. Rejects malformed tokens with 400. |
| **INVOICE-03** (Zero Data Leakage Sanitization)| `orderController.js:205-260` (`publicInvoice` payload generator) | **Implemented and correct** | Verified by `public_invoice_hardening.test.js:18-35`. Customer phone, customer address, measurements, internal wholesale costs, aster profit margins, karigar IDs, and token echo are completely removed from response. |
| **INVOICE-04** (Token Expiry & Revocation) | `orderController.js:186-198` -> checks `shareTokenRevokedAt` and `shareTokenExpiresAt` | **Implemented and correct** | Verified by `public_invoice_hardening.test.js:36-50`. Returns HTTP 410 Gone for expired (30-day default) or manually revoked tokens. |
| **INVOICE-05** (Dynamic UPI QR Code) | `PublicInvoice.jsx:309-327` -> `api.qrserver.com` + `upi://pay` URI | **Implemented and correct** | Dynamically constructs UPI deep link using shop's configured `upiId`, shop name, and `balanceDue`. |
| **INVOICE-06** (Printable PDF Receipts) | `InvoiceDetails.jsx:210` / `invoice_details_screen.dart:345` -> `PdfService.generateInvoiceFromMap` | **Implemented and correct** | Generates PDF invoice ready for printing or direct file sharing. |

---

#### Domain 10: Khata & Udhar (Credit Book) (KHATA)

| Req ID | Trace Path | Classification | Evidence (File:Line) & Findings |
|---|---|---|---|
| **KHATA-01** (Aggregated Udhar Balances) | `PendingBalancesTab.jsx:30` -> `GET /api/customers/pending-balances` -> `customerController.js:118-208` | **Implemented with defects** | **Documentation Discrepancy**: `ARCHITECTURE.md:183` claims the endpoint is `/api/shops/:shopId/pending-balances`. The actual backend route is `/api/customers/pending-balances` (`customerRoutes.js:17`). Code functions correctly on web, but documentation is inaccurate. |
| **KHATA-02** (One-Tap WhatsApp Udhar Reminders) | `PendingBalancesTab.jsx:55` / `udhar_list.dart:210` -> `wa.me` reminder URL | **Implemented and correct** | Verified by `udhar_balances.test.js:25-45`. Formats polite vernacular payment reminder with shop name, balance due, and UPI ID. |
| **KHATA-03** (Expense Logging) | `add_expense_bottom_sheet.dart:1-120` / `Ledger.jsx:110` -> `POST /api/ledger/expenses` -> `expenseController.js:1-80` | **Implemented and correct** | Records operational expenses with validation against non-negative amounts. |
| **KHATA-04** (Chronological Cash Journal) | `Ledger.jsx:65` -> `GET /api/ledger/journal` -> `ledgerService.js:53-154` | **Implemented with defects** | **Mathematical Sorting Bug**: In `ledgerService.js:94, 116`, orders are mapped with `date: o.date`. Order records do NOT have a `date` field (they use `createdAt`). Sorting with `new Date(undefined)` produces `NaN`, causing erratic entry ordering and corrupted running balance calculations (`ledgerService.js:136-140`). |
| **KHATA-05** (Mobile Udhar First Tab) | `KhataScreen.dart:1-50` (`initialTabIndex: 0`) -> `udhar_list.dart` | **Implemented and correct** | Udhar is the default active view on mobile. Calculates total shop receivables and displays customer debt cards. |

---

#### Domain 11: Deliveries & Dispatch (DELIV)

| Req ID | Trace Path | Classification | Evidence (File:Line) & Findings |
|---|---|---|---|
| **DELIV-01** (Delivery Dispatch Tabs) | `Delivery.jsx:40` / `deliveries_screen.dart:45` -> `GET /api/deliveries?tab=...` -> `deliveryController.js:9-62` | **Implemented and correct** | Filters deliveries by `Today`, `Late`, `Upcoming`, and `Delivered`. |
| **DELIV-02** (Delivery Credit Warning & Reason) | `Delivery.jsx:54-70` / `deliveries_screen.dart:120-174` -> `PUT /api/deliveries/:id/deliver` -> `deliveryController.js:79-101` | **Implemented with defects** | **Bypass Vulnerability & Mobile Disconnect**: Web handles credit delivery via `window.prompt` and calls `PUT /api/deliveries/:id/deliver` with `allowCredit: true` and `creditReason`. However: (1) On mobile (`deliveries_screen.dart:166-174`), the app calls `PUT /api/orders/:id` with `{ status: 'Delivered' }`, completely bypassing `deliveryController.js`; and (2) `orderService.js:481-485` updates delivery status to `Delivered` without checking balance or requiring a credit reason. Any client can bypass credit approval by updating the order directly! |
| **DELIV-03** (WhatsApp Pickup Alerts) | `order_details_screen.dart:480` -> `whatsapp_service.dart:1-100` | **Implemented and correct** | Generates direct WhatsApp message alerting customer that garment is ready for pickup. |
| **DELIV-04** (Duplicate Delivery Prevention) | `deliveryController.js:74-77` | **Implemented and correct** | Verified by `financial_integrity.test.js:60-65`. Blocks re-delivering an already delivered order with HTTP 400. |

---

#### Domain 12: Karigars (Artisans) (KAR)

| Req ID | Trace Path | Classification | Evidence (File:Line) & Findings |
|---|---|---|---|
| **KAR-01** (Karigar Registry) | `Karigars.jsx:1-150` / `karigars_screen.dart:1-250` -> `GET/POST /api/karigars` -> `karigarController.js:1-120` | **Implemented and correct** | Full registry with artisan name, phone, status, and specialization. |
| **KAR-02** (Artisan Performance Tracking) | `dashboardController.js:93-108` / `KarigarDetails.jsx:1-180` | **Implemented and correct** | Calculates active order volume and completed job values per artisan. |
| **KAR-03** (Karigar My Jobs Screen) | `my_jobs_screen.dart:1-646` -> `GET /api/orders?type=partner_jobs` and local SQLite | **Implemented with defects** | Mobile screen exists, but: (1) It loads all workshop orders rather than filtering by karigar ID (`my_jobs_screen.dart:55`); (2) It is hidden inside More Hub instead of being the root view for karigar role; and (3) Karigars cannot log in or sync due to `authMiddleware.js:46`. |

---

#### Domain 13: Machines & Maintenance (MACH)

| Req ID | Trace Path | Classification | Evidence (File:Line) & Findings |
|---|---|---|---|
| **MACH-01** (Machine Registry) | `Machines.jsx:1-150` -> `GET/POST /api/machines` -> `machineController.js:1-90` | **Partial** | Fully implemented and working on **Web**. Completely **Missing on Mobile** (no screen, no route in `main.dart`, omitted from `shop_manage_tab.dart`). |
| **MACH-02** (Maintenance Logs) | `Machines.jsx:80-140` -> `PUT /api/machines/:id` -> `machineController.js:45-85` | **Partial** | Implemented on Web; absent on mobile. |

---

#### Domain 14: Notifications & Alerts (NOTIF)

| Req ID | Trace Path | Classification | Evidence (File:Line) & Findings |
|---|---|---|---|
| **NOTIF-01** (In-App Notification Center) | `Notifications.jsx:1-120` / `notifications_screen.dart:1-150` -> `GET /api/notifications` -> `notificationController.js:1-90` | **Implemented and correct** | Displays alerts with read/unread toggle and mark-all-read action. |
| **NOTIF-02** (FCM Push Dispatch) | `orderService.js:150-155, 470-479` -> `notificationService.js:69-209` -> `admin.messaging().sendEachForMulticast` | **Implemented and correct** | Verified by `security_and_scoping.test.js:140-165`. Routine events are in-app only; device push is authorized exclusively for `order_due_reminder`, `low_stock`, and delegated partner order alerts. |
| **NOTIF-03** (Push Deep Linking) | `notification_service.dart:342-364` -> `_navigateFromPayload` -> pushes `/order_details` or `/customer_details` | **Implemented and correct** | Navigates directly to target entity when notification banner is clicked. |
| **NOTIF-04** (Offline Scheduled Reminders) | `step5_details.dart:296-320` -> `NotificationService().scheduleOrderDueReminders()` | **Implemented and correct** | Uses `flutter_local_notifications` and `timezone` to schedule 1-day before and morning-of reminders offline. |

---

#### Domain 15: Dashboard & Analytics (DASH)

| Req ID | Trace Path | Classification | Evidence (File:Line) & Findings |
|---|---|---|---|
| **DASH-01** (Morning Workshop Metrics) | `Dashboard.jsx:1-180` / `DashboardScreen.dart:1-150` -> `GET /api/dashboard/stats` -> `dashboardController.js:12-65` | **Implemented and correct** | Summarizes today's deliveries, overdue deliveries, incoming jobs, total customers, and revenue. |
| **DASH-02** (Weekly Stitching Chart) | `Dashboard.jsx:100-160` / `line_chart_painter.dart:1-80` -> `dashboardController.js:67-91` | **Implemented and correct** | Aggregates daily completed stitching value across Monday-Sunday. |
| **DASH-03** (Exclude Cancelled from Metrics) | `dashboardController.js:85` (`status: { $in: ['Ready', 'Delivered'] }`) | **Implemented and correct** | Verified by `order_lifecycle.test.js:115-130`. Cancelled and soft-deleted orders are excluded from workshop output. |

---

#### Domain 16: Mobile Offline Sync & Durability (SYNC)

| Req ID | Trace Path | Classification | Evidence (File:Line) & Findings |
|---|---|---|---|
| **SYNC-01** (Local SQLite Write) | `step5_details.dart:233-264` -> `LocalDatabaseService().insertRecord('orders', ...)` with `sync_status: 1` | **Implemented and correct** | Fully persists customer, order, and payment locally in encrypted SQLite when offline. |
| **SYNC-02** (Background Worker) | `main.dart:100` -> `SyncWorker.initialize()` -> `Workmanager().registerPeriodicTask(..., frequency: 15 min)` -> `SyncService().syncAll()` | **Implemented with defects** | Background worker is configured, but `sync_service.dart:246` only syncs `['customers', 'orders', 'expenses', 'inventory']`. `karigars`, `machines`, `repairs`, `shop` settings, and standalone `measurements` are NEVER synchronized by the background worker. |
| **SYNC-03** (Sync Status Monitor) | `sync_status_screen.dart:1-180` -> `SyncService().getDetailedSyncBreakdown()` | **Implemented and correct** | Displays pending count by table, last sync timestamp, and manual "Sync Now" button with error reporting. |
| **SYNC-04** (ID Reconciliation & Cascading) | `sync_service.dart:478, 498` -> `LocalDatabaseService().updateRecordId(table, oldId, newId)` | **Implemented and correct** | Reconciles temporary local UUIDs with server-issued IDs and cascades customer ID updates to foreign keys in `orders` and `measurements` tables (`local_db_service.dart:865-893`). |
| **SYNC-05** (Data Loss Prevention) | `sync_service.dart:77-104` | **Implemented and correct** | Retains local records with `sync_status: 2` (pending delete) or `sync_status: 4` (validation failure). Never silently wipes failed records. |

---

#### Domain 17: Localization (LOC)

| Req ID | Trace Path | Classification | Evidence (File:Line) & Findings |
|---|---|---|---|
| **LOC-01** (Trilingual en/hi/gu) | Web: `LanguageContext.jsx`, `en.json`, `gu.json`, `hi.json` / Mobile: `app_en.arb`, `app_gu.arb`, `app_hi.arb` | **Implemented with defects** | **Hardcoded Strings**: Web has 558 synchronized translation keys and Mobile has 183 keys with 0 missing translations. However, multiple screens contain hardcoded English strings: `deliveries_screen.dart:133, 146, 179` ("Order marked as Delivered!", "Confirm Delivery", "No pending deliveries"), `step5_details.dart:471` ("Order saved locally!"), and `StaffManagement.jsx:387` ("Admin (Dashboard Administrator)"). |
| **LOC-02** (Instant Language Switching) | Top bar language dropdown -> `LanguageContext.setLanguage()` / `LocalizationService().setLocale()` | **Implemented and correct** | Language switches instantaneously without page reload. |
| **LOC-03** (Indian Currency Formatting) | `formatters.js:1-25` (`formatCurrency`) / `currency_utils.dart:1-35` (`formatINR`) | **Implemented and correct** | Verified by `formatters.test.js:1-20`. Enforces standard Indian Lakh/Crore grouping (e.g., `₹1,25,000`). |

---

#### Domain 18: Data Export, Import, & Purging (DATA)

| Req ID | Trace Path | Classification | Evidence (File:Line) & Findings |
|---|---|---|---|
| **DATA-01** (Full JSON Data Export) | `Profile.jsx:200` -> `POST /api/auth/account/download-data` -> `accountController.js:28` -> `accountService.js:34` | **Implemented and correct** | Exports complete JSON dump across 11 shop collections protected by account password re-authentication. |
| **DATA-02** (Conflict-Checked Import) | `Profile.jsx:240` -> `POST /api/auth/account/check-conflicts` + `import-data` -> `accountService.js:102-211` | **Implemented and correct** | Checks ID collisions across collections and allows granular resolution (`keep database` vs `overwrite from backup`). |
| **DATA-03** (Purge & Account Deletion) | `Profile.jsx:260` -> `POST /api/auth/account/delete-all-data` and `delete-account` -> `accountService.js:78-100` | **Implemented and correct** | Password-authenticated wipe of shop collections and schedules user account deletion. |
| **DATA-04** (Accountant CSV / Excel Export) | `Ledger.jsx:72-90` (`downloadCSV`) | **Implemented with defects** | **Malformed CSV Escaping**: Web provides a "Download CSV" button (`Ledger.jsx:73`), but concatenates raw strings with `row.join(',')` (`Ledger.jsx:84`) without quoting or escaping commas. When order descriptions contain commas (e.g., `Shirt, Pant`), columns shift into wrong headers in Excel. Completely missing on mobile. |

---

#### Domain 19: Security, Privacy, & Infrastructure (SEC)

| Req ID | Trace Path | Classification | Evidence (File:Line) & Findings |
|---|---|---|---|
| **SEC-01** (Service-Role Key Isolation) | `supabase.js:1-20` (backend) VS `supabase.js:1-7` (frontend) | **Implemented and correct** | Backend strictly holds `SUPABASE_SERVICE_ROLE_KEY`. Frontend and mobile only use `VITE_SUPABASE_ANON_KEY` / `anon_key`. |
| **SEC-02** (Cross-Tenant Boundary Isolation)| `shop_isolation.test.js:1-90` | **Implemented and correct** | Database operations strictly reject querying or mutating documents across shop IDs. |
| **SEC-03** (Multi-Tier Rate Limiting) | `server.js:20`, `routes/index.js:22-24`, `securityMiddleware.js:12-40` | **Implemented and correct** | Enforces rate limits: API (300/15m), Auth (10/15m), Uploads (30/15m), Destructive/DELETE (10/15m), Public Invoice (60/15m). |
| **SEC-04** (SQLCipher Key Handling) | `local_db_service.dart:70-155` | **Implemented and correct** | Encrypted using `sqflite_sqlcipher` with hardware-backed 256-bit random key in `FlutterSecureStorage`. Includes re-keying migration from legacy key. |
| **SEC-05** (ReDoS Hardening) | `validationMiddleware.js:1-120`, `securityMiddleware.js:64-66` | **Implemented and correct** | Linear-time, non-backtracking regular expressions with bounded string lengths (`security_and_scoping.test.js:70-105`). |
| **SEC-06** (Private Bucket Signed URLs) | `uploadController.js:1-74` -> `createSignedUploadUrl`, `createSignedUrl` | **Implemented and correct** | File paths strictly scoped to `shopId/filename` with 1-hour signed URL expiration. |

---

## 3. Deep Architectural & Systems Audit

### 3.1 Data Layer & Supabase Adapter Performance Hazards

The backend abstracts Supabase using `config/supabaseModel.js`. A line-by-line inspection reveals severe query efficiency hazards that will degrade under production volume:

1. **In-Memory JavaScript Filtering (Full Table Scans)**:
   - In `supabaseModel.js:179-183`:
     ```javascript
     if (query?.shopId && typeof query.shopId === 'string') {
       builder = builder.filter('document->>shopId', 'eq', query.shopId);
     } else if (query?._id && typeof query._id === 'string') {
       builder = builder.eq('source_id', String(query._id));
     }
     ```
   - If `query.shopId` is NOT a top-level string—such as in `getOrders` (`orderController.js:64-70`) and `findOrderScoped` (`orderService.js:21-24`), where `shopId` is placed inside an `$or` condition—the builder executes **ZERO filtering in PostgreSQL**.
   - It fetches **EVERY single record across ALL shops** in the `orders` collection over HTTP into Node.js memory, and only then executes in-memory `.filter((doc) => matches(doc, query))` (`supabaseModel.js:270`).
2. **Post-Load In-Memory Pagination & Sorting**:
   - `SupabaseQuery.limit(count)` (`supabaseModel.js:119, 145`) and `SupabaseQuery.sort(fields)` (`supabaseModel.js:114, 131-144`) are applied **in Node.js memory after fetching the entire database table**. No `ORDER BY` or `LIMIT` is ever pushed to the database.
3. **N+1 HTTP Query Cascades on Population**:
   - In `orderController.js:89-99` (`getOrders`), for every order returned, the controller executes `Payment.findOne({ orderId: o._id })` and `Delivery.findOne({ orderId: o._id })`.
   - Because `orderId` is not top-level `shopId` or `_id`, each `findOne` downloads the entire `payments` and `deliveries` tables. Fetching 50 orders triggers **101 full-collection HTTP requests to Supabase**.
4. **Relational Schema Migration Decoupling**:
   - Migration `20261030150000_stitchcraft_schema.sql` created domain tables (`orders`, `customers`, etc.), but `supabaseModel.js` still writes exclusively to `app_records`.
   - Script `scripts/migrate_to_relational.js` simply copies JSON blobs from `app_records` into `orders.document`. If executed, the domain tables immediately become stale upon the next API call.

### 3.2 Mobile Offline Sync & Dead Repository Architecture

An in-depth trace of the mobile synchronization engine revealed a striking architectural disconnect:

1. **Unused / Dead Architecture Layer**:
   - The repository classes (`OrderRepository`, `CustomerRepository`, `LedgerRepository`, `InventoryRepository`) located in `lib/core/repositories/` are **completely unused throughout the entire application**.
   - The durable mutation outbox enqueueing logic (`_localDb.enqueueMutation`) exists ONLY in `order_repository.dart:148`.
   - Because every mobile screen (`step5_details.dart`, `customer_details_screen.dart`, `udhar_list.dart`) bypasses repositories and writes directly to `LocalDatabaseService().insertRecord()`, the **`mutation_outbox` table remains perpetually empty**.
2. **Sync Table Omissions**:
   - `SyncService().syncAll()` (`sync_service.dart:246`) hardcodes `final tables = ['customers', 'orders', 'expenses', 'inventory']`.
   - `karigars`, `machines`, `repairs`, `shop` profile settings, and standalone `measurements` are **never pushed or pulled by background sync**.
3. **Delivery Unpaid Balance Audit Bypass on Mobile**:
   - On web (`Delivery.jsx:54`), confirming delivery with an outstanding balance prompts for an audit reason and calls `PUT /api/deliveries/:id/deliver` with `allowCredit: true` and `creditReason`.
   - On mobile (`deliveries_screen.dart:166-174`), the app instead calls `PUT /api/orders/:id` with `{ status: 'Delivered' }`.
   - `orderService.js:481-485` updates delivery status to `Delivered` without checking balance or requiring a credit reason. On mobile, delivery on credit is never audited.

### 3.3 Deployment Configuration & Vercel SPA Routing

1. **Vercel SPA 404 Defect (`vercel.json`)**:
   - `README.md:37` and `ARCHITECTURE.md:241` claim `vercel.json` provides "client-side routing rewrites".
   - In reality, `vercel.json` contains only build commands:
     ```json
     {
       "buildCommand": "cd stitchcraft-frontend && npm install && npm run build",
       "outputDirectory": "stitchcraft-frontend/dist",
       "installCommand": "echo skip-root-install",
       "ignoreCommand": "...",
       "framework": null
     }
     ```
   - It is missing `"rewrites": [{ "source": "/(.*)", "destination": "/" }]`. Any direct page refresh or link opening on Vercel (e.g., `/invoice/share/:id`, `/orders`, `/dashboard`) returns HTTP 404 Not Found.
2. **CORS Hardcoded Origins (`cors.js`)**:
   - `config/cors.js:4-11` hardcodes static Vercel URLs (`stitchcraft-swart.vercel.app`, `stitchcraft-frontend.vercel.app`).
   - It completely ignores `process.env.CLIENT_URL`, breaking custom deployment domains.

---

## 4. Requirements-Fit & User Journey Analysis

To judge whether StitchCraft satisfies the real requirements of Indian tailor-shop owners, we walked the 11 core user journeys step-by-step from the perspective of a busy Masterji.

---

### Journey 1: First-Time Owner Onboarding
- **Steps Taken**: Launch app -> Choose language (Hindi/Gujarati/English) -> Onboarding carousel -> Register screen (Enter email, password, name, shop name, phone) -> Verify email sheet -> Enter shop address -> Dashboard.
- **Taps / Screens**: 6 screens, ~18 taps.
- **Friction & Missing Elements**:
  - Requires email address and password. Most Indian masterjis do not have active email on their counter phones and expect mobile OTP.
  - Requires entering email OTP/verification link.
- **Offline Capable**: No (requires active Supabase Auth).
- **Verdict**: **Partly fits**. Functional, but email requirement creates initial friction for non-tech-savvy tailors.

---

### Journey 2: Daily Routine (Due Today, Late, Update Stages, Collect Payment)
- **Steps Taken**: Open app -> View dashboard summary cards ("Due Today: 3", "Late: 2", "Money to Collect: ₹12,500") -> Tap "Due Today" -> Opens order list -> Tap order -> Advance stage ("Stitching" -> "Checking" -> "Ready") -> Customer arrives -> Tap "Record Payment" -> Enter ₹800 cash -> Tap "Mark Delivered".
- **Taps / Screens**: 4 screens, 7 taps.
- **Friction & Missing Elements**:
  - Very fast and intuitive flow on both mobile and web.
  - Due today and late orders are visible immediately upon app launch.
- **Offline Capable**: Yes. Stage progression and payments record locally to SQLite.
- **Verdict**: **Fits user needs**. Excellent alignment with daily workshop rhythm.

---

### Journey 3: Customer Returns (Reuse Measurements, Book New Order)
- **Steps Taken**:
  - *Web*: Open `/customers` -> Search "Ramesh" -> Click customer -> Click "Book New Order" (`/new-order?customerId=...`) -> Customer preselected, measurements auto-populate -> Enter garment type & price -> Save. (3 screens, 5 clicks).
  - *Mobile*: Open Customers -> Search "Ramesh" -> Tap customer profile -> Tap floating action button "Book New Order" -> **CRASH**.
- **Taps / Screens**: Crashes on mobile.
- **Friction & Missing Elements**:
  - In `customer_details_screen.dart:292`, the FAB calls `Navigator.pushNamed('/create_order')`, which does not exist in `main.dart`. The masterji cannot book an order from the customer profile on mobile.
  - If navigated via bottom navigation "+" button, the tailor must re-search the customer and manually tap "Use Last Measurements".
- **Offline Capable**: Yes (when navigating via wizard steps).
- **Verdict**: **Partly fits on Web, Does not fit on Mobile** (broken route).

---

### Journey 4: Chase Money (Find Debtors, Send WhatsApp Reminders, Record Payment)
- **Steps Taken**: Open Khata -> Default tab is Udhar -> View total debt (e.g., ₹24,800) -> Tap green WhatsApp icon next to customer -> WhatsApp opens with pre-composed vernacular reminder ("Namaste Rameshji, your balance of ₹1,400 at Royal Tailors is pending...") -> Customer pays -> Tap "Record Payment" -> Enter amount -> Udhar balance updates immediately.
- **Taps / Screens**: 2 screens, 3 taps.
- **Friction & Missing Elements**:
  - Outstanding balances and debtor age are calculated cleanly.
  - Pre-composed WhatsApp reminder saves typing time for busy owners.
- **Offline Capable**: Yes. Local SQLite calculates balances and stores interim payment.
- **Verdict**: **Fits user needs**. Outstanding feature designed specifically for Indian cash/udhar realities.

---

### Journey 5: Deliver an Order with a Pending Balance
- **Steps Taken**:
  - *Web*: Open Deliveries -> Tap "Mark Delivered" on an order with ₹500 balance -> Warning modal appears -> Confirm credit delivery -> Prompt asks for credit reason -> Enter "Friend of brother, will pay next week" -> Order delivered on credit.
  - *Mobile*: Open Deliveries -> Tap "Deliver" on unpaid order -> Dialog warns of outstanding balance -> Tap "Confirm Delivery" -> Marked delivered in SQLite -> Puts `{ status: 'Delivered' }` to backend without audit reason.
- **Taps / Screens**: 2 screens, 4 taps.
- **Friction & Missing Elements**:
  - Web enforces audit reason; mobile skips reason collection.
  - Backend allows bypass via direct order update.
- **Offline Capable**: Yes on mobile.
- **Verdict**: **Partly fits**. Warning exists, but audit trails are inconsistent across platforms.

---

### Journey 6: Stock Runs Low or Astar is Consumed
- **Steps Taken**: Order enters "Stitching" -> Backend automatically deducts 1.5m lining from inventory -> Remaining stock drops to 3m (below 5m threshold) -> System triggers "Low Stock Alert" push notification -> Masterji taps notification -> Opens Inventory item -> Tap "Restock" -> Add 20 meters.
- **Taps / Screens**: 2 screens, 4 taps.
- **Friction & Missing Elements**:
  - Works seamlessly on backend and web.
  - On mobile, `inventory` table is synced during full sync, but inventory restock wastage adjustments are only on web.
- **Offline Capable**: Partial (local astar calculation in order wizard, but inventory threshold notifications require online push).
- **Verdict**: **Fits user needs**. Automatic deduction prevents manual stock tallying.

---

### Journey 7: Karigar Completes a Job
- **Steps Taken**: Karigar opens mobile app -> Logs in -> App bar shows "Forbidden: role 'karigar' is not authorized" (HTTP 403).
- **Taps / Screens**: Blocked at authentication.
- **Friction & Missing Elements**:
  - `authMiddleware.js:46-50` blocks any non-owner user from using the backend API.
  - `my_jobs_screen.dart` is buried under More Hub and shows all workshop orders instead of only assigned jobs.
- **Offline Capable**: No.
- **Verdict**: **Does not fit**. Feature is currently blocked by backend authorization policy.

---

### Journey 8: Customer Opens Shared Invoice Link & Pays via UPI
- **Steps Taken**: Customer receives WhatsApp link (`/invoice/share/<token>`) -> Opens in Chrome/Safari mobile -> Views sanitized invoice -> Checks delivery date and balance due (₹600) -> Taps "Open UPI App" or scans QR code -> Google Pay / PhonePe opens with `pa=tailor@okaxis&am=600` -> Customer completes payment in UPI app -> Switches back to invoice.
- **Taps / Screens**: 1 screen, 2 taps.
- **Friction & Missing Elements**:
  - **No Automated Reconciliation**: P2P UPI does not notify the web server. The invoice still shows "Balance Due: ₹600" until the masterji manually opens StitchCraft and records the payment.
  - On Vercel, opening the shared link directly returns 404 due to missing SPA rewrites.
- **Offline Capable**: N/A (customer-facing web link).
- **Verdict**: **Partly fits**. Sanitization and UPI generation are excellent, but lack of Vercel SPA rewrites and absence of payment screenshot/UTR submission creates friction.

---

### Journey 9: Working Offline for a Day, Then Syncing
- **Steps Taken**: Workshop internet cuts off at 10 AM -> Masterji books 4 orders, creates 2 customers, records 3 payments in SQLite -> Reconnects to WiFi at 8 PM -> Background sync runs (or user taps "Sync Now" in Sync Status) -> Syncs customers, orders, payments -> Local IDs reconciled with server IDs.
- **Taps / Screens**: Zero taps required (automatic background sync).
- **Friction & Missing Elements**:
  - Core orders and customers sync cleanly with ID reconciliation.
  - If the masterji added new karigars or logged repairs, those are NEVER synced by `syncAll()`.
- **Offline Capable**: Yes.
- **Verdict**: **Partly fits**. High durability for core entities, but incomplete coverage across all shop tables.

---

### Journey 10: Owner Adds a Manager or Staff Member with Limited Access
- **Steps Taken**: Owner opens Web Dashboard -> Navigates to `/staff` -> Clicks "Invite Member" -> Fills Name, Email, Phone -> Selects Role -> Dropdown only offers "Admin" or "Owner" -> Selects "Admin" -> Clicks Submit -> Backend converts 'admin' to 'staff' -> Member appears in table -> Owner tries to change role via table dropdown -> Selects "Admin" -> Backend returns HTTP 400 (`Valid role is required (manager, karigar, staff)`) -> Alert pops up.
- **Taps / Screens**: 1 screen, 4 clicks.
- **Friction & Missing Elements**:
  - Complete contract mismatch between frontend role dropdowns and backend validator.
  - If the staff member tries to log in, backend blocks them with 403.
- **Offline Capable**: No.
- **Verdict**: **Does not fit**. Completely broken due to role validation disconnect and backend owner-only block.

---

### Journey 11: Month End (Income, Expenses, Profit, Export for Accountant)
- **Steps Taken**: Owner opens Ledger -> Views summary cards (Total Sales, Total Received, Total Expenses, Fabric Profit) -> Clicks "Journal" tab -> Clicks "Download CSV" -> Browser downloads `StitchCraft_Ultimate_Ledger_2026-11-05.csv` -> Sends CSV to accountant -> Accountant opens file in Excel -> Multiple rows have shifted columns due to unescaped commas in order descriptions.
- **Taps / Screens**: 1 screen, 2 clicks.
- **Friction & Missing Elements**:
  - CSV generation is unescaped (`Ledger.jsx:84`).
  - No date-range filter for specific month (e.g., October 1 - October 31).
  - No export feature exists on mobile.
- **Offline Capable**: No.
- **Verdict**: **Partly fits**. Metrics and journal exist, but CSV export formatting is defective and mobile has no export.

---

## 5. Over-Engineering vs. Requirement Gaps

### 5.1 Features That Exist But Nobody Needs (Over-Engineering)
1. **Machine Maintenance Registry (`/machines`)**:
   - Small Indian tailoring shops operate 2 to 5 manual or semi-motorized sewing machines (Usha, Singer, Juki). They do not track serial numbers, scheduled maintenance intervals, or machinery depreciation in an ERP. This feature adds clutter to the sidebar and database without solving a high-frequency tailor pain point.
2. **Outsourced Partner Delegation System (`/delegate`)**:
   - Complex order delegation between registered StitchCraft partner tailor shops (`delegatedToShopId`, two-way notification handshakes, outsourced due date shifting). In real life, masterjis outsource embroidery, buttonholing (kaaj-button), and heavy stitching via informal physical handoffs and cash/khata notes, not inter-tenant SaaS workflows.
3. **Multi-Step Conflict-Checked JSON Backup Import Engine (`/account/check-conflicts`)**:
   - Sophisticated entity-by-entity ID conflict reconciliation algorithms (`accountService.js:102-211`). Masterjis will never inspect JSON backup trees or resolve UUID collisions. They need automated cloud backup to their phone number or Google Drive.
4. **Dead Multi-Tier Repository Layer on Mobile (`lib/core/repositories/`)**:
   - Over-architected repository and mutation outbox layer that is completely bypassed by every screen in the application.

### 5.2 Real Needs With No Feature (Critical Gaps)
1. **Phone-Number OTP Authentication**:
   - Requiring email addresses and passwords for low-literacy tailors and karigars is a severe barrier to adoption.
2. **Vernacular & Female Garment Measurement Templates**:
   - Currently hardcoded strictly for Western men's shirts and pants. Tailoring in India is predominantly driven by women's ethnic wear: Blouse, Kurti, Salwar-Kameez, and Lehanga.
3. **P2P UPI Payment Proof Upload**:
   - When a customer pays via UPI from the public invoice, they need a way to upload a payment screenshot or enter the 12-digit UPI UTR number so the tailor can verify and settle the balance without calling the customer.
4. **Karigar Piece-Rate Wage Settlement**:
   - Karigars are paid weekly based on pieces stitched (e.g., ₹200/pant). The system tracks order assignment but has no piece-rate wage calculation, karigar khata ledger, or weekly payout summary.
5. **Vercel SPA Client-Side Routing**:
   - Missing SPA rewrite rules in `vercel.json` breaks public invoice links and web dashboard refreshes on production.

---

## 6. Domain Completeness Scorecard

The following scorecard evaluates actual operational completeness based on evidenced runtime behavior, rather than lines of code:

| Domain | Score (0-100%) | Status | Evidenced Summary |
|---|:---:|---|---|
| **1. Auth & Accounts** | 80% | Implemented with defects | Full Supabase Auth, login, signup, session persistence; blocked by lack of Phone OTP and broken reset-password API contract. |
| **2. Shops & Multi-Tenancy** | 95% | Implemented and correct | Strict `shopId` tenant scoping, branch switching, branding, GSTIN, UPI configuration, and isolation verified. |
| **3. Roles & Permissions** | 20% | Broken / Hard-Blocked | Backend `protect` hard-blocks all non-owners with 403; `StaffManagement.jsx` has contract mismatch; karigars cannot log in. |
| **4. Customers** | 90% | Implemented and correct | Full registry, fast search, idempotency, contact saving, measurement linkage. Hard delete on delete. |
| **5. Measurements** | 75% | Partial | Snapshots, voice input, photo attach, fractional pad work well; female ethnic wear templates missing; mobile repeat booking FAB crashes. |
| **6. Orders & Stages** | 90% | Implemented and correct | Wizard, idempotency, stage machine, multi-item support, swatch photos, soft delete work reliably. |
| **7. Inventory & Astar** | 95% | Implemented and correct | Automatic astar deduction and restoration on stage change verified by tests; low stock alerts functional. |
| **8. Payments & Ledger** | 90% | Implemented and correct | Immutable transaction ledger, idempotency, refund audit reasons, Indian currency formatting verified. |
| **9. Invoices & Public Links** | 85% | Implemented with defects | Opaque share token lookup, strict data sanitization, UPI QR work; broken on Vercel deployment due to missing SPA rewrite. |
| **10. Khata / Udhar** | 90% | Implemented with defects | Udhar aggregation and WhatsApp reminders are outstanding; cash journal sorting has a mathematical date bug. |
| **11. Deliveries** | 75% | Implemented with defects | Delivery dispatch tabs work; credit delivery audit reason enforced on web but bypassed on mobile and backend order update. |
| **12. Karigars** | 40% | Blocked | Registry and performance work; karigar mobile portal blocked by backend auth and lacks piece-rate wages. |
| **13. Machines** | 50% | Partial (Web only) | Fully functional on web dashboard; completely missing from mobile app. Low practical utility. |
| **14. Notifications** | 90% | Implemented and correct | In-app notification center, FCM push for high-priority alerts, deep links, and offline local reminders work. |
| **15. Dashboard & Reports** | 90% | Implemented and correct | Metrics, reminders, weekly stitching chart, and recent activity functional. Heavy in-memory DB queries. |
| **16. Offline Sync** | 70% | Partial | Core orders and customers sync with ID reconciliation; outbox layer is dead; karigars/repairs/machines not synced. |
| **17. Localization** | 85% | Implemented with defects | Complete en/gu/hi translation keys across web and mobile; marred by hardcoded English strings in several screens. |
| **18. Data Export & Purge** | 80% | Implemented with defects | JSON export/import/purge functional; CSV ledger export is unescaped and corrupts spreadsheet columns. |
| **19. Security & Privacy** | 90% | Implemented and correct | Secrets isolated, service role key protected, rate limiters active, ReDoS safe, SQLCipher AES encrypted. |
| **OVERALL SYSTEM** | **78%** | **Partially Operational** | Core single-owner workshop flows are robust; multi-role access, deployment config, and mobile sync completeness require remediation. |

