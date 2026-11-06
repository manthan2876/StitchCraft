# 🧪 StitchCraft — Testing Strategy, Code Quality & Verification Audit

---

## 1. Testing Frameworks & Execution Overview

StitchCraft maintains automated test suites across its backend, web frontend, and mobile subprojects using native test runners without unnecessary third-party testing overhead.

| Module | Test Runner | Files Inspected | Test Count | Suite Count | Execution Result |
|---|---|---|---|---|---|
| **Backend** | Native Node.js Test Runner (`node --test`) | 9 test files | **57 Tests** | **18 Suites** | **57 Passed, 0 Failed (435ms)** |
| **Frontend** | Native Node.js Test Runner (`node --test`) | 2 test files | **18 Tests** | **11 Suites** | **18 Passed, 0 Failed (160ms)** |
| **Frontend Lint** | ESLint (`npm run lint`) | Full codebase | - | - | **0 Errors, 14 Warnings** |
| **Frontend Build** | Vite 8 (`npm run build`) | Production Rollup | - | - | **Success (884ms)** |
| **Mobile** | Flutter Test (`flutter test`) | 2 test files | 4 Tests | 2 Suites | *Local host has Dart SDK only; CI executes on GitHub Actions* |

---

## 2. Backend Automated Test Suite Audit (57 Tests)

The backend test suite is located in [`stitchcraft-backend/test/`](file:///home/manthan/Projects/StitchCraft/stitchcraft-backend/test/) and executes via `npm test`:

```text
▶ P0-03 & P1-05: Financial Integrity, Idempotency, and Delivery Credit (3 tests)
▶ Idempotency & Inventory Safety Specifications (7 tests)
▶ Ledger & Financial Auditing Logic (3 tests)
▶ Order Lifecycle & Financial Computations (6 tests)
▶ Udhar & Pending Balance Aggregation Logic (2 tests)
▶ P0-01: Public Invoice Hardening and Link Privacy (5 tests)
▶ Auth & Role Authorization Middleware (3 tests)
▶ Identifier Validation (2 tests)
▶ Public Invoice Sanitization Safety (2 tests)
▶ Outsourced Partner Order Privacy & Sanitization (1 test)
▶ Notification Dispatch Service (3 tests)
▶ Relational Schema Migration Transformation (1 test)
▶ Database Table Document Validations (3 tests)
▶ API Request Validation Middlewares (5 tests)
▶ Multi-Tenant Shop Isolation & Multi-Role Authorization (6 tests)
▶ Staff & Roles Management Security Policies (5 tests)
```

### 2.1 Detailed Suite Breakdown
1. **`financial_integrity.test.js`** (3 tests):
   - Verifies payment idempotency prevents duplicate transaction creation under network retries.
   - Asserts immutable refund transactions record debit adjustments without mutating historical payment entries.
   - Enforces credit delivery validation: rejects delivery of unpaid orders unless explicitly confirmed with a reason.
2. **`idempotency_and_inventory.test.js`** (7 tests):
   - Validates client `idempotencyKey` resolution for order and customer creation.
   - Verifies single-fire astar lining inventory deduction upon reaching active workshop stages (`Stitching`, `Checking`, `Ready`, `Delivered`).
   - Asserts inventory restoration if an in-production order is cancelled or deleted.
   - Tests Indian currency grouping format (`en_IN` format: ₹1,25,000).
   - Validates manual inventory adjustments, shrinkage logging, and stock-safe limits.
3. **`ledger_and_expenses.test.js`** (3 tests):
   - Validates financial summary calculations (total income, expenses, receivables, net profit).
   - Verifies sequential running cash book balance calculation (`balance = previousBalance + income - expense`).
   - Tests category-based expense filtering.
4. **`order_lifecycle.test.js`** (6 tests):
   - Validates total order value math across single and multi-item orders.
   - Computes payment status transitions (`Pending` → `Partial` → `Paid`).
   - Asserts sequential timestamped order notes do not overwrite previous history.
   - Verifies exclusion of cancelled orders from active production metrics.
   - Disallows outsourcing/delegation of completed, delivered, or cancelled orders.
5. **`pending_balances.test.js`** (2 tests):
   - Validates aggregation of outstanding balances across unpaid/partial orders.
   - Validates generation of URL-encoded WhatsApp reminder links with merchant details.
6. **`public_invoice_hardening.test.js`** (5 tests):
   - Validates acceptance of opaque share tokens and rejection of raw numeric or UUID identifiers.
   - Asserts strict payload sanitization: customer phone, address, body measurements, and wholesale costs are excluded from public responses.
   - Verifies HTTP 410 Gone on expired or revoked links.
   - Validates presence and configuration of `publicInvoiceLimiter`.
7. **`security_and_scoping.test.js`** (19 tests):
   - Tests authentication token verification and role authorization (`owner` vs non-owner).
   - Verifies ReDoS safe regex bounds.
   - Tests partner tailor order sanitization (1-day earlier due date, masked customer info).
   - Tests notification dispatch fallback when Firebase credentials are omitted.
   - Tests request validation middlewares and model-layer schema validators.
8. **`shop_isolation.test.js`** (6 tests):
   - Validates strict tenant boundary isolation between distinct `shopId` values.
   - Prevents cross-shop document leakage when querying by known primary ID.
9. **`staff_management.test.js`** (5 tests):
   - Enforces owner-only access on staff role updates, status toggling, and unlinking.
   - Asserts HTTP 403 Forbidden for managers, staff, and karigars.
   - Validates allowed role assignments (`owner`, `manager`, `staff`, `karigar`).

---

## 3. Frontend Automated Test Suite Audit (18 Tests)

Located in [`stitchcraft-frontend/test/`](file:///home/manthan/Projects/StitchCraft/stitchcraft-frontend/test/) and executes via `npm test`:

### 3.1 Suite Breakdown
1. **`form_validators.test.js`** (13 tests):
   - `validateRequired`: Rejects empty strings, undefined, null.
   - `validateMinLength`: Bounds check on string lengths.
   - `validateEmail`: Verifies linear-time regex evaluation against malformed emails and enforces RFC 5321 length limits (<= 254 characters).
   - `validatePhone`: Enforces 10–15 digit requirements; accepts Indian and international formats.
   - `validateNumber`: Validates positive currency prices and measurement numeric ranges.
   - `validateDate`: Validates ISO date formats and rejects invalid date strings.
   - `validatePassword`: Enforces minimum 6-character length requirement.
2. **`formatters.test.js`** (5 tests):
   - `formatCurrency`: Formats numbers into Indian Rupee strings (`₹1,200`, `₹0`).
   - `formatDate`: Formats ISO date strings into readable `"DD Mon YYYY"` representations.

---

## 4. Static Code Quality & Linter Audit

Running `npm run lint` in `stitchcraft-frontend` reported **0 Errors and 14 Warnings**:
- **Fast Refresh Warnings (3)**:
  - `AuthContext.jsx:4:14`: Fast refresh warning (exporting React context alongside components).
  - `LanguageContext.jsx:31:14`: Exporting context and constants from same file.
  - `ThemeContext.jsx:37:14`: Exporting context and hook from same file.
- **Unused Variables (3)**:
  - `useDashboard.js:25:14`: Unused error parameter `e`.
  - `useProfile.js:92:14` & `299:16`: Unused error parameters `_e` and `_err`.
- **React Hook Exhaustive Deps (8)**:
  - `useOrderDetails.js:44:6`: Missing `fetchOrderDetails` dependency in `useEffect`.
  - `CustomerDetails.jsx:67:6`: Missing `fetchCustomerDetails`.
  - `Delivery.jsx:50:6`: Missing `fetchDeliveries`.
  - `EditOrder.jsx:80:8`: Missing `tf` localization helper.
  - `KarigarDetails.jsx:54:6`: Missing `fetchKarigarDetails`.
  - `Ledger.jsx:70:6`: Missing `fetchJournal`.
  - `Payments.jsx:65:6`: Missing `fetchPayments`.
  - `useLedger.js:41:6`: Missing `loadData`.

---

## 5. Mock vs. Integration Test Gap Analysis

| Layer | Testing Approach | Verification Quality | Reality Gap / Risk |
|---|---|---|---|
| **API Endpoints** | Unit tests invoke route handlers with mocked `req`/`res` objects | High for business logic & status codes | Does not spin up live HTTP socket server during unit tests. |
| **Database Operations** | `SupabaseModel` queries execute against simulated in-memory document arrays in unit tests | High for functional correctness | Does not test actual PostgreSQL network latency, database connection pooling, or physical GIN index performance. |
| **Mobile Background Work** | `SyncWorker` tested via unit mocks | Medium | Background execution behavior under Android Doze mode or aggressive OEM battery savers (Xiaomi/Oppo) cannot be tested in unit tests. |
| **Hardware & Peripherals** | Untested | Low / Not Verified | Real camera autofocus on cloth, Bluetooth thermal receipt printers, and microphone speech-to-text require physical hardware testing. |

