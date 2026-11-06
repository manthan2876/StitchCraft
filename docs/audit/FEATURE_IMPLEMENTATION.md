# ⚙️ StitchCraft — Feature & Functionality Implementation Inventory

---

## 1. Feature Catalog Overview

This document presents a comprehensive, evidence-based audit of every feature implemented in the StitchCraft platform. Each feature is traced through its presentation layer, state management, API route, middleware pipeline, business logic, and database persistence layer.

---

## 2. Core Functional Modules

### 2.1 Authentication & Multi-Tenancy

#### Purpose & Problem Solved
Allows masterjis to register, securely log in, verify email, switch between multiple shop branches, recover forgotten passwords, and isolate workshop data.

#### Implementation Trace
- **Web Frontend**: [`src/pages/Login.jsx`](file:///home/manthan/Projects/StitchCraft/stitchcraft-frontend/src/pages/Login.jsx), [`Signup.jsx`](file:///home/manthan/Projects/StitchCraft/stitchcraft-frontend/src/pages/Signup.jsx), [`ForgotPassword.jsx`](file:///home/manthan/Projects/StitchCraft/stitchcraft-frontend/src/pages/ForgotPassword.jsx), [`ResetPassword.jsx`](file:///home/manthan/Projects/StitchCraft/stitchcraft-frontend/src/pages/ResetPassword.jsx), state managed via [`AuthContext.jsx`](file:///home/manthan/Projects/StitchCraft/stitchcraft-frontend/src/context/AuthContext.jsx).
- **Mobile Client**: [`lib/features/auth/screens/login_screen.dart`](file:///home/manthan/Projects/StitchCraft/stitchcraft-mobile/lib/features/auth/screens/login_screen.dart), [`signup_screen.dart`](file:///home/manthan/Projects/StitchCraft/stitchcraft-mobile/lib/features/auth/screens/signup_screen.dart), [`role_selection_screen.dart`](file:///home/manthan/Projects/StitchCraft/stitchcraft-mobile/lib/features/auth/screens/role_selection_screen.dart).
- **API Endpoints**: `POST /api/auth/register`, `POST /api/auth/login`, `POST /api/auth/forgot-password`, `POST /api/auth/reset-password`, `PUT /api/auth/switch-shop/:id`.
- **Middleware**: `authLimiter` (10 req/15m), `validateRegisterRequest`, `protect`.
- **Backend Service & Controller**: [`controllers/authController.js`](file:///home/manthan/Projects/StitchCraft/stitchcraft-backend/controllers/authController.js), [`controllers/profileController.js`](file:///home/manthan/Projects/StitchCraft/stitchcraft-backend/controllers/profileController.js).
- **Database Entities**: `users`, `shops` collections in `app_records`.
- **Business Rules**:
  - Automatically provisions a default shop upon user registration.
  - Self-assigned roles in registration payloads are strictly ignored; initial registrant becomes `owner`.
  - Passwords require minimum 6 characters; email must comply with RFC 5321 length limits (<= 254 characters) with linear regex evaluation.
- **Implementation Status**: **Complete & Verified**.

---

### 2.2 Customer & Measurement Management

#### Purpose & Problem Solved
Replaces fragile physical "maap" (measurement) books. Stores customer contact details, preferences, measurement history across garment types (shirt, pant, kurta, suit), audio voice notes, and reference photos.

#### Implementation Trace
- **Web Frontend**: [`src/pages/Customers.jsx`](file:///home/manthan/Projects/StitchCraft/stitchcraft-frontend/src/pages/Customers.jsx), [`CustomerDetails.jsx`](file:///home/manthan/Projects/StitchCraft/stitchcraft-frontend/src/pages/CustomerDetails.jsx), hooks in [`useCustomers.js`](file:///home/manthan/Projects/StitchCraft/stitchcraft-frontend/src/hooks/useCustomers.js).
- **Mobile Client**: [`lib/features/orders/screens/customer_list_screen.dart`](file:///home/manthan/Projects/StitchCraft/stitchcraft-mobile/lib/features/orders/screens/customer_list_screen.dart), [`customer_details_screen.dart`](file:///home/manthan/Projects/StitchCraft/stitchcraft-mobile/lib/features/orders/screens/customer_details_screen.dart), voice input via `VoiceTextField`.
- **API Endpoints**: `GET /api/customers`, `POST /api/customers`, `GET /api/customers/:id`, `PUT /api/customers/:id`, `DELETE /api/customers/:id`.
- **Backend Service & Controller**: [`controllers/customerController.js`](file:///home/manthan/Projects/StitchCraft/stitchcraft-backend/controllers/customerController.js), [`services/customerService.js`](file:///home/manthan/Projects/StitchCraft/stitchcraft-backend/services/customerService.js).
- **Database Entities**: `customers`, `measurements` in `app_records` and SQLite `customers`, `measurements`.
- **Business Rules**:
  - Customer phone must contain 10–15 digits.
  - Automatically generates unique human-readable customer IDs (`CUST-XXXXXXXX`).
  - Supports idempotency keys (`idempotencyKey: cust_<UUID>`) to prevent duplicate customer creation during offline network replays.
  - Deleting a customer cascades to linked measurement records.
- **Implementation Status**: **Complete & Verified**.

---

### 2.3 Order Lifecycle & 8-Stage Production Engine

#### Purpose & Problem Solved
Eliminates lost orders and missed delivery deadlines by tracking garments through eight distinct stages from fabric receipt to customer handover.

#### Implementation Trace
- **Web Frontend**: [`src/pages/Orders.jsx`](file:///home/manthan/Projects/StitchCraft/stitchcraft-frontend/src/pages/Orders.jsx), [`NewOrder.jsx`](file:///home/manthan/Projects/StitchCraft/stitchcraft-frontend/src/pages/NewOrder.jsx), [`OrderDetails.jsx`](file:///home/manthan/Projects/StitchCraft/stitchcraft-frontend/src/pages/OrderDetails.jsx), [`EditOrder.jsx`](file:///home/manthan/Projects/StitchCraft/stitchcraft-frontend/src/pages/EditOrder.jsx).
- **Mobile Client**: 5-step wizard in [`lib/features/orders/screens/create_order/`](file:///home/manthan/Projects/StitchCraft/stitchcraft-mobile/lib/features/orders/screens/create_order/) (`step2_customer.dart` → `step1_garment.dart` → `step3_measurements.dart` → `step4_material.dart` → `step5_details.dart`), [`order_details_screen.dart`](file:///home/manthan/Projects/StitchCraft/stitchcraft-mobile/lib/features/orders/screens/order_details_screen.dart).
- **API Endpoints**: `GET /api/orders`, `POST /api/orders`, `GET /api/orders/:id`, `PUT /api/orders/:id`, `DELETE /api/orders/:id`, `POST /api/orders/:id/notes`.
- **Backend Service & Controller**: [`controllers/orderController.js`](file:///home/manthan/Projects/StitchCraft/stitchcraft-backend/controllers/orderController.js), [`services/orderService.js`](file:///home/manthan/Projects/StitchCraft/stitchcraft-backend/services/orderService.js).
- **Database Entities**: `orders`, `action_logs` in `app_records` and SQLite `orders`.
- **Business Rules & Stage Machine**:
  - Supported stages: `Incoming` → `Measuring` → `Cutting` → `Stitching` → `Checking` → `Ready` → `Delivered` (or `Cancelled`).
  - **Measurement Snapshotting**: When an order is created, the customer's current measurement set is frozen into `order.measurementsSnapshot`. Subsequent changes to the customer's profile do not alter existing orders.
  - **Internal Notes**: Notes appended to an order carry immutable timestamps and creator IDs.
  - **Partner Outsourcing**: Orders can be delegated to partner tailor shops via `POST /api/orders/:id/delegate`. The partner view automatically masks customer PII and adjusts the delivery commitment 1 day earlier.
- **Implementation Status**: **Complete & Verified**.

---

### 2.4 Inventory & Lining (Astar) Automation

#### Purpose & Problem Solved
Automates lining (*astar*) and fabric consumption, alerts masterjis when stock drops below minimum thresholds, and prevents active workshop stalls.

#### Implementation Trace
- **Web Frontend**: [`src/pages/Inventory.jsx`](file:///home/manthan/Projects/StitchCraft/stitchcraft-frontend/src/pages/Inventory.jsx), [`InventoryModal.jsx`](file:///home/manthan/Projects/StitchCraft/stitchcraft-frontend/src/features/inventory/components/InventoryModal.jsx).
- **Mobile Client**: [`lib/features/shop/screens/inventory_screen.dart`](file:///home/manthan/Projects/StitchCraft/stitchcraft-mobile/lib/features/shop/screens/inventory_screen.dart), [`inventory_details_screen.dart`](file:///home/manthan/Projects/StitchCraft/stitchcraft-mobile/lib/features/shop/screens/inventory_details_screen.dart).
- **API Endpoints**: `GET /api/inventory`, `POST /api/inventory`, `GET /api/inventory/:id`, `PUT /api/inventory/:id`, `DELETE /api/inventory/:id`, `POST /api/inventory/:id/adjust`.
- **Backend Service & Controller**: [`controllers/inventoryController.js`](file:///home/manthan/Projects/StitchCraft/stitchcraft-backend/controllers/inventoryController.js), [`services/orderService.js:120-160`](file:///home/manthan/Projects/StitchCraft/stitchcraft-backend/services/orderService.js#L120-L160).
- **Database Entities**: `inventory` in `app_records` and SQLite `inventory`.
- **Business Rules**:
  - `ASTAR_DEDUCT_STATUSES`: Inventory is deducted **once** when an order enters `['Stitching', 'Checking', 'Ready', 'Delivered']`.
  - Idempotency guard: `order.astarDeducted` prevents double-deduction.
  - Restoration: If an order in production is cancelled or deleted, the consumed inventory quantity is automatically restored.
  - Wastage & Adjustment: `POST /api/inventory/:id/adjust` records shrinkage, damage, or stock takes.
- **Implementation Status**: **Complete & Verified**.

---

### 2.5 Payments, Financial Transactions & Khata Ledger

#### Purpose & Problem Solved
Maintains an immutable financial audit trail. Replaces messy paper cash books with a running cash book journal, income/expense categorization, and payment balances.

#### Implementation Trace
- **Web Frontend**: [`src/pages/Ledger.jsx`](file:///home/manthan/Projects/StitchCraft/stitchcraft-frontend/src/pages/Ledger.jsx), [`Payments.jsx`](file:///home/manthan/Projects/StitchCraft/stitchcraft-frontend/src/pages/Payments.jsx), [`PaymentModal.jsx`](file:///home/manthan/Projects/StitchCraft/stitchcraft-frontend/src/features/orders/components/PaymentModal.jsx).
- **Mobile Client**: [`lib/features/khata/screens/khata_screen.dart`](file:///home/manthan/Projects/StitchCraft/stitchcraft-mobile/lib/features/khata/screens/khata_screen.dart), [`IncomeList.dart`](file:///home/manthan/Projects/StitchCraft/stitchcraft-mobile/lib/features/khata/widgets/income_list.dart), [`ExpensesList.dart`](file:///home/manthan/Projects/StitchCraft/stitchcraft-mobile/lib/features/khata/widgets/expenses_list.dart).
- **API Endpoints**: `GET /api/ledger/summary`, `GET /api/ledger/journal`, `GET /api/ledger/transactions`, `GET /api/ledger/expenses`, `POST /api/ledger/expenses`, `DELETE /api/ledger/expenses/:id`, `POST /api/orders/:id/payments`, `POST /api/orders/:id/refunds`.
- **Backend Service & Controller**: [`controllers/ledgerController.js`](file:///home/manthan/Projects/StitchCraft/stitchcraft-backend/controllers/ledgerController.js), [`controllers/expenseController.js`](file:///home/manthan/Projects/StitchCraft/stitchcraft-backend/controllers/expenseController.js), [`services/ledgerService.js`](file:///home/manthan/Projects/StitchCraft/stitchcraft-backend/services/ledgerService.js), [`services/orderService.js`](file:///home/manthan/Projects/StitchCraft/stitchcraft-backend/services/orderService.js).
- **Database Entities**: `payments`, `transactions`, `ledger_entries` in `app_records` and SQLite `expenses`, `order_payments`.
- **Business Rules**:
  - Payments are **never modified directly**. Every payment creates an immutable `Transaction` record.
  - `syncPaymentFromTransactions()` sums all transactions to compute `paidAmount`, `balanceAmount`, and status (`Pending`, `Partial`, `Paid`).
  - Supports refunds via `POST /api/orders/:id/refunds`, logging negative transaction adjustments without deleting historic payment entries.
  - Cash book journal computes running balance sequentially: `balance = previousBalance + income - expense`.
- **Implementation Status**: **Complete & Verified**.

---

### 2.6 Udhar (Pending Balances) Recovery & WhatsApp Engine

#### Purpose & Problem Solved
Stops informal credit leakage. Aggregates all outstanding balances across orders, groups them by customer, and enables one-tap WhatsApp payment reminders containing the shop's UPI VPA and exact due amount.

#### Implementation Trace
- **Web Frontend**: [`src/features/ledger/components/PendingBalancesTab.jsx`](file:///home/manthan/Projects/StitchCraft/stitchcraft-frontend/src/features/ledger/components/PendingBalancesTab.jsx).
- **Mobile Client**: [`lib/features/khata/widgets/udhar_list.dart`](file:///home/manthan/Projects/StitchCraft/stitchcraft-mobile/lib/features/khata/widgets/udhar_list.dart), [`whatsapp_service.dart`](file:///home/manthan/Projects/StitchCraft/stitchcraft-mobile/lib/core/services/whatsapp_service.dart).
- **API Endpoint**: `GET /api/customers/pending-balances`.
- **Backend Service & Controller**: [`controllers/customerController.js:115-180`](file:///home/manthan/Projects/StitchCraft/stitchcraft-backend/controllers/customerController.js#L115-L180).
- **Database Entities**: Evaluates `orders` and `payments` collections.
- **Business Rules**:
  - Filters active orders where payment status is `Pending` or `Partial` and `balanceAmount > 0`.
  - Groups balances by customer, summing total dues and unpaid order count.
  - Generates pre-formatted WhatsApp text with merchant name, customer name, total due, and payment link prompt.
- **Implementation Status**: **Complete & Verified**.

---

### 2.7 Delivery Verification & Credit Handover Guard

#### Purpose & Problem Solved
Prevents accidental delivery of unpaid garments without explicit shopkeeper acknowledgment. Ensures that if an order is handed over with an outstanding balance, a valid business reason is logged.

#### Implementation Trace
- **Web Frontend**: [`src/pages/Delivery.jsx`](file:///home/manthan/Projects/StitchCraft/stitchcraft-frontend/src/pages/Delivery.jsx).
- **Mobile Client**: [`lib/features/orders/screens/deliveries_screen.dart`](file:///home/manthan/Projects/StitchCraft/stitchcraft-mobile/lib/features/orders/screens/deliveries_screen.dart).
- **API Endpoints**: `GET /api/deliveries`, `PUT /api/deliveries/:id/deliver`.
- **Backend Controller**: [`controllers/deliveryController.js:25-80`](file:///home/manthan/Projects/StitchCraft/stitchcraft-backend/controllers/deliveryController.js#L25-L80).
- **Database Entities**: `deliveries`, `orders` in `app_records`.
- **Business Rules**:
  - If `order.payment.balanceAmount > 0`, marking as delivered requires `{ creditConfirmed: true, creditReason: "..." }`.
  - Missing confirmation or empty credit reason returns HTTP 400 with a descriptive warning.
  - Prevents duplicate delivery actions: already-delivered orders reject repeat delivery calls.
- **Implementation Status**: **Complete & Verified**.

---

### 2.8 Public Tokenized Invoices & UPI Settlement

#### Purpose & Problem Solved
Provides customers with a transparent, printable digital invoice accessible via SMS or WhatsApp link without requiring an account. Generates dynamic UPI payment QR codes for instant settlement while protecting shop privacy.

#### Implementation Trace
- **Web Frontend**: Public guest route [`/invoice/share/:id`](file:///home/manthan/Projects/StitchCraft/stitchcraft-frontend/src/App.jsx#L45) rendered by [`src/pages/PublicInvoice.jsx`](file:///home/manthan/Projects/StitchCraft/stitchcraft-frontend/src/pages/PublicInvoice.jsx).
- **API Endpoint**: `GET /api/orders/public/:token` (protected by `publicInvoiceLimiter`).
- **Backend Controller**: [`controllers/orderController.js:180-230`](file:///home/manthan/Projects/StitchCraft/stitchcraft-backend/controllers/orderController.js#L180-L230).
- **Database Entities**: `orders`, `shops` in `app_records`.
- **Business Rules & Data Sanitization**:
  - Lookups occur strictly via opaque base64url share tokens (or SHA-256 hash). Database internal IDs (`_id`) or sequential order IDs (`orderId`) are rejected with HTTP 404 to prevent ID enumeration.
  - **Sanitization**: Strips customer phone numbers, home addresses, customer body measurements, wholesale fabric costs, internal profit margins, and assigned karigar IDs.
  - **Dynamic UPI QR**: Constructs standard UPI deep-link: `upi://pay?pa=<shop.upiId>&pn=<shop.name>&am=<balanceAmount>&cu=INR&tn=Order-<orderId>`.
  - Returns HTTP 410 Gone if the link has expired (default: 30 days) or has been revoked by the masterji.
- **Implementation Status**: **Complete & Verified**.

---

### 2.9 Karigars & Sewing Machines Management

#### Purpose & Problem Solved
Tracks piece-rate artisans, work specializations (e.g., suit, pant, sherwani), contact numbers, active/inactive statuses, and machine maintenance records.

#### Implementation Trace
- **Web Frontend**: [`src/pages/Karigars.jsx`](file:///home/manthan/Projects/StitchCraft/stitchcraft-frontend/src/pages/Karigars.jsx), [`KarigarDetails.jsx`](file:///home/manthan/Projects/StitchCraft/stitchcraft-frontend/src/pages/KarigarDetails.jsx), [`Machines.jsx`](file:///home/manthan/Projects/StitchCraft/stitchcraft-frontend/src/pages/Machines.jsx).
- **Mobile Client**: [`lib/features/shop/screens/karigars_screen.dart`](file:///home/manthan/Projects/StitchCraft/stitchcraft-mobile/lib/features/shop/screens/karigars_screen.dart), [`karigar_details_screen.dart`](file:///home/manthan/Projects/StitchCraft/stitchcraft-mobile/lib/features/shop/screens/karigar_details_screen.dart).
- **API Endpoints**: `GET/POST/PUT/DELETE /api/karigars`, `GET/POST/PUT/DELETE /api/machines`.
- **Backend Controllers**: [`controllers/karigarController.js`](file:///home/manthan/Projects/StitchCraft/stitchcraft-backend/controllers/karigarController.js), [`controllers/machineController.js`](file:///home/manthan/Projects/StitchCraft/stitchcraft-backend/controllers/machineController.js).
- **Database Entities**: `karigars`, `machines` in `app_records`.
- **Important Audit Finding**: Machine registry is implemented **exclusively on the Web Dashboard**. The mobile application has no machines screen.
- **Implementation Status**: Karigars: **Complete & Verified** (Web & Mobile); Machines: **Complete & Verified** (Web only).

---

### 2.10 Alterations & Repair Management

#### Purpose & Problem Solved
Tracks minor alteration jobs (shortening, waist adjustment, zipper replacement) that do not require full custom bespoke order booking.

#### Implementation Trace
- **Web Frontend**: Accessible via order types.
- **Mobile Client**: Dedicated screen [`lib/features/repairs/repair_dashboard.dart`](file:///home/manthan/Projects/StitchCraft/stitchcraft-mobile/lib/features/repairs/repair_dashboard.dart).
- **API Endpoints**: `GET/POST/PUT/DELETE /api/repairs`.
- **Backend Controller**: [`controllers/repairController.js`](file:///home/manthan/Projects/StitchCraft/stitchcraft-backend/controllers/repairController.js).
- **Database Entities**: `repairs` in `app_records` and SQLite `repair_jobs`.
- **Implementation Status**: **Complete & Verified**.

---

### 2.11 Multi-Language Support (Localization / i18n)

#### Purpose & Problem Solved
Allows non-English literate shopkeepers and staff to operate the software natively in **Gujarati (`gu`)** and **Hindi (`hi`)** alongside **English (`en`)**.

#### Implementation Trace
- **Web Frontend**: Managed by [`src/context/LanguageContext.jsx`](file:///home/manthan/Projects/StitchCraft/stitchcraft-frontend/src/context/LanguageContext.jsx) with 558 synchronized translation keys loaded from [`src/config/locales/`](file:///home/manthan/Projects/StitchCraft/stitchcraft-frontend/src/config/locales/) (`en.json`, `gu.json`, `hi.json`).
- **Mobile Client**: Managed via Flutter ARB files ([`lib/l10n/app_en.arb`](file:///home/manthan/Projects/StitchCraft/stitchcraft-mobile/lib/l10n/app_en.arb), `app_gu.arb`, `app_hi.arb`) providing 183 translation keys per language through generated `AppLocalizations` delegates.
- **Implementation Status**: **Complete & Verified**.

