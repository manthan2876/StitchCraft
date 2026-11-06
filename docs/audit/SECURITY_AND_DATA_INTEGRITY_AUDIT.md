# 🛡️ StitchCraft — Security, Privacy & Data Integrity Audit

---

## 1. Security Architecture & Threat Model

StitchCraft processes personal data (customer names, phone numbers, body measurements, physical fit preferences) and financial data (daily revenues, tailor earnings, wholesale fabric costs, customer credit/udhar balances).

The security posture evaluates six primary threat boundaries:
1. **Tenant Cross-Contamination**: Preventing Shop A from reading or modifying Shop B's customers, orders, or financials.
2. **Public Invoice Link Exploitation**: Preventing unauthenticated internet users from scraping customer phone numbers, home addresses, or wholesale profit margins.
3. **Privilege Escalation**: Ensuring staff or karigars cannot assign themselves owner rights, alter shop UPI IDs, or delete accounts.
4. **Physical Device Compromise**: Protecting local customer databases on lost or stolen mobile devices.
5. **Denial of Service & Injection**: Guarding against ReDoS, SQL injection, NoSQL injection, and resource exhaustion.
6. **Financial Tampering**: Guaranteeing that payment balances, refunds, and cash book entries cannot be altered or fabricated.

---

## 2. Authentication & Session Management

### 2.1 Token Lifecycle & Verification
- **Identity Provider**: Supabase GoTrue Auth issuing signed asymmetric JSON Web Tokens (JWT).
- **Backend Verification**: Implemented in [`stitchcraft-backend/middleware/authMiddleware.js:15-35`](file:///home/manthan/Projects/StitchCraft/stitchcraft-backend/middleware/authMiddleware.js#L15-L35). The API verifies the cryptographic signature of the Bearer token against Supabase public keys via `supabase.auth.getUser(token)`.
- **Session Expiration**: Tokens expire according to Supabase project settings (typically 1 hour). The mobile client (`services/sync_service.dart:255-270`) catches HTTP 401, invokes `_authService.refreshToken()`, and automatically retries pending sync operations once without crashing.

### 2.2 Password Security & Reset Mechanics
- **Hashing**: Managed by Supabase GoTrue Auth using industry-standard bcrypt with adaptive salt cost factors.
- **Recovery Workflow**: Initiated via `POST /api/auth/forgot-password` and completed via `POST /api/auth/reset-password`.
- **Token Boundaries**: Reset requests generate time-bounded recovery sessions; direct database password injection is impossible.
- **Input Bounds**: Minimum 6 characters enforced; email format strictly validated with non-backtracking regular expressions.

---

## 3. Multi-Tenant Partitioning & Authorization

### 3.1 Tenant Scoping Implementation
Every private API route passes through `protect` middleware, which resolves the authenticated user document and attaches `req.user.shopId`.
- In controllers, database queries enforce:
  ```javascript
  const records = await Model.find({ shopId: req.user.shopId, ...filters });
  ```
- Direct primary key lookups enforce shop isolation:
  ```javascript
  const record = await Model.findOne({ _id: id, shopId: req.user.shopId });
  if (!record) return res.status(404).json({ message: 'Record not found' });
  ```
- Verified empirically by automated test suite [`stitchcraft-backend/test/shop_isolation.test.js`](file:///home/manthan/Projects/StitchCraft/stitchcraft-backend/test/shop_isolation.test.js), proving that knowledge of another shop's document UUID never leaks data across tenants.

### 3.2 Role-Based Access Control (RBAC) Enforcement
- Guarded by `authorize(...roles)` in [`stitchcraft-backend/middleware/authMiddleware.js:45-55`](file:///home/manthan/Projects/StitchCraft/stitchcraft-backend/middleware/authMiddleware.js#L45-L55).
- **Owner-Restricted Operations**:
  - Staff management & role assignment: `router.use(authorize('owner'))` on `/api/staff`.
  - Shop expense deletion: `DELETE /api/ledger/expenses/:id`.
  - Account deletion & database wiping: `/api/auth/account/*`.
  - Shop branch deletion: `DELETE /api/shops/:id`.
- **Audit Finding**: On routes where `authorize` is omitted (e.g. `/api/inventory`, `/api/customers`, `/api/orders`), any authenticated user belonging to that shopId has read/write capability. Full multi-role delegation across staff/karigar requires completing field-level role policies.

---

## 4. Public Invoice Security & Privacy Hardening

### 4.1 Vulnerability Background & Resolution
Historically, public invoices could be accessed by guessing sequential order numbers or UUIDs. Furthermore, the invoice response exposed internal wholesale fabric rates and customer phone numbers.

### 4.2 Verified Hardening Controls (`P0-01`)
1. **Opaque Token Gating**: The public route `GET /api/orders/public/:token` validates the token format using [`middleware/securityMiddleware.js:validateShareTokenParam`](file:///home/manthan/Projects/StitchCraft/stitchcraft-backend/middleware/securityMiddleware.js). Direct UUID or order ID lookups are rejected.
2. **Dedicated Rate Limiter**: `publicInvoiceLimiter` restricts IP requests to 60 per 15 minutes, neutralizing brute-force token enumeration.
3. **Payload Sanitization**: The controller strictly constructs a sanitized payload:
   ```javascript
   // Sensitive fields explicitly stripped:
   delete sanitizedOrder.customerPhone;
   delete sanitizedOrder.customerAddress;
   delete sanitizedOrder.measurements;
   delete sanitizedOrder.wholesaleCost;
   delete sanitizedOrder.fabricCostPerUnit;
   delete sanitizedOrder.internalNotes;
   delete sanitizedOrder.assignedKarigar;
   ```
4. **Token Revocation & Expiration**: Tokens expire automatically after 30 days (`shareTokenExpiresAt`) or can be revoked immediately by the masterji (`shareTokenRevoked: true`), returning HTTP 410 Gone.

---

## 5. Local Storage & Device Security (Mobile)

### 5.1 SQLCipher Database Encryption
- **Encryption Standard**: 256-bit AES encryption in CBC mode.
- **Key Protection**: Key is generated dynamically per-device and persisted in `FlutterSecureStorage` (backed by Android Keystore and iOS Keychain).
- **Integrity**: SQLite database files extracted from device storage are encrypted and unreadable without access to the hardware keystore.

### 5.2 Cache Sanitization & Web Storage Limitations
- The Flutter mobile web target uses an in-memory compatibility store. Because browser WebSQL/IndexedDB lacks uniform SQLCipher encryption, local offline storage is only supported on native mobile devices.

---

## 6. Financial Integrity & Idempotency Audit

### 6.1 Mathematical Integrity Rules
- **Order Financial Invariant**: `totalAmount = paidAmount + balanceAmount`.
- **Payment Deduplication**: Payment transactions support an `Idempotency-Key` header. If a mobile network retry submits the same key, the server returns the existing transaction rather than deducting/recording duplicate payments.
- **Refund Integrity**: `POST /api/orders/:id/refunds` creates an immutable `Transaction` of type `Refund` and reduces the recorded `paidAmount`, while preserving the original historical payment records for financial auditability.

### 6.2 Inventory Stock Protection
- **Single-Fire Astar Deduction**: `order.astarDeducted` boolean flag ensures stock is deducted exactly once when reaching active workshop stages.
- **Restoration on Cancellation**: Cancelling or deleting an order restores the exact consumed meterage back into active inventory records.

---

## 7. Security Findings & Vulnerability Matrix

| Finding ID | Severity | Category | Description & Evidence | Remediation Status |
|---|---|---|---|---|
| **SEC-01** | **P0 - Critical** | Broken Access Control | Public invoice endpoint previously accepted raw order IDs without tokens, exposing order status to third parties. | **Fixed & Verified**: Hardened with opaque base64url share tokens, 60 req/15m rate limiting, and PII stripping (`test/public_invoice_hardening.test.js`). |
| **SEC-02** | **P0 - Critical** | Denial of Service | Unbounded DELETE endpoints lacked rate limits, leaving destructive operations vulnerable to rapid automated repetition. | **Fixed & Verified**: Applied `destructiveLimiter` across every HTTP `DELETE` method globally in `routes/index.js:21-24`. |
| **SEC-03** | **P1 - High** | Privilege Escalation | User registration accepted a user-supplied `role` parameter, potentially allowing self-assigned administrative permissions. | **Fixed & Verified**: Server-side user model overrides registration role to `owner` on primary shop setup; team members must be invited by an existing owner. |
| **SEC-04** | **P1 - High** | Data Integrity | Unpaid garments could be delivered accidentally without shopkeeper confirmation or record of debt reasoning. | **Fixed & Verified**: Delivery endpoint requires `creditConfirmed: true` and `creditReason` string whenever balance > 0 (`controllers/deliveryController.js:45-55`). |
| **SEC-05** | **P2 - Medium** | Security Architecture | Supabase service-role key is utilized by the backend, bypassing PostgreSQL RLS entirely. | **Planned**: Acceptable for current single-tier API gateway architecture; direct Supabase client access is disabled. Relational cutover must define explicit RLS policies if client direct querying is introduced. |
| **SEC-06** | **P2 - Medium** | Injection Safety | Email and phone regular expressions previously lacked bounded lengths, risking catastrophic backtracking (ReDoS). | **Fixed & Verified**: Form validators and backend middleware enforce linear-time regexes and bounded input lengths (RFC 5321 length check <= 254 characters). |

