# 🔍 StitchCraft — Project Gap Analysis & Defect Inventory

---

## 1. Implementation Status Matrix

The following matrix documents the verified status of every operational module across the Web frontend, Flutter mobile client, Express backend, database persistence, API integration, and automated test coverage.

| Functional Module | Web Frontend | Mobile Client | Express Backend | Database Layer | API Integration | Automated Tests | Verified Status |
|---|:---:|:---:|:---:|:---:|:---:|:---:|---|
| **Authentication & Profile** | Complete | Complete | Complete | Supabase Auth + JSONB | Complete | 6 Tests | **Complete & Verified** |
| **Multi-Tenancy Scoping** | Complete | Complete | Complete | `app_records` (`shopId`) | Complete | 6 Tests | **Complete & Verified** |
| **Role-Based Access (Owner)**| Complete | Complete | Complete | `users.role` + RLS | Complete | 5 Tests | **Complete & Verified** |
| **Multi-Role Staff/Karigar** | Partial (UI) | Partial (UI) | Partial | Documented, single-role enforced | Partial | 3 Tests | **Implemented with Limitations** |
| **Customer Management** | Complete | Complete | Complete | `customers` collection | Complete | 4 Tests | **Complete & Verified** |
| **Customer Measurements** | Complete | Complete | Complete | `measurements` collection | Complete | 2 Tests | **Complete & Verified** |
| **Order Production Pipeline**| Complete | Complete | Complete | `orders` (8 stages) | Complete | 6 Tests | **Complete & Verified** |
| **Measurement Snapshotting** | Complete | Complete | Complete | `order.measurementsSnapshot` | Complete | 2 Tests | **Complete & Verified** |
| **Inventory & Astar Deduction**| Complete | Complete | Complete | `inventory` collection | Complete | 7 Tests | **Complete & Verified** |
| **Payment Ledger & Balances**| Complete | Complete | Complete | `payments` + `transactions` | Complete | 3 Tests | **Complete & Verified** |
| **Udhar Recovery (Pending)** | Complete | Complete | Complete | Dynamic aggregation | Complete | 2 Tests | **Complete & Verified** |
| **Delivery Credit Gate** | Complete | Complete | Complete | `deliveries` (`creditConfirmed`) | Complete | 1 Test | **Complete & Verified** |
| **Public Tokenized Invoices**| Complete | N/A (Web guest) | Complete | `orders.shareToken` | Complete | 5 Tests | **Complete & Verified** |
| **WhatsApp Message Engine** | Complete | Complete | N/A | Deep link (`wa.me`) | Complete | 2 Tests | **Complete & Verified** |
| **Karigar Management** | Complete | Complete | Complete | `karigars` collection | Complete | 2 Tests | **Complete & Verified** |
| **Machine Registry** | Complete | **Missing** | Complete | `machines` collection | Complete | 1 Test | **Partial (Web Only)** |
| **Alterations & Repairs** | Partial | Complete | Complete | `repairs` collection | Complete | Not Tested | **Implemented with Limitations** |
| **Cash Book & Ledger Journal**| Complete | Complete | Complete | `ledger_entries` collection | Complete | 3 Tests | **Complete & Verified** |
| **In-App Notifications** | Complete | Complete | Complete | `notifications` collection | Complete | 3 Tests | **Complete & Verified** |
| **FCM Push Dispatch** | N/A | Complete | Complete | Graceful unconfigured fallback | Complete | 2 Tests | **Complete & Verified** |
| **Mobile Encrypted SQLite** | N/A | Complete | N/A | `sqflite_sqlcipher` AES-256 | N/A | Unit Tested | **Complete & Verified** |
| **Mobile Sync (4 Tables)** | N/A | Complete | Complete | Outbox + REST Push/Pull | Complete | Manual Verified | **Implemented with Limitations** |
| **Mobile Sync (All Entities)**| N/A | **Partial** | Complete | Omits measurements & karigars | Partial | Not Tested | **Partially Implemented** |
| **Localization (EN/HI/GU)** | Complete | Complete | N/A | 558 Web keys / 183 ARB keys | Complete | Unit Tested | **Complete & Verified** |
| **Storage Uploads (Signed)** | Complete | Complete | Complete | Private Supabase Buckets | Complete | Manual Verified | **Complete & Verified** |

---

## 2. Prioritized Defect & Gap Inventory

### Priority 0 — Critical (Data Loss, Financial Integrity, Security)

#### GAP-P0-01: In-Memory Sorting & Pagination in `SupabaseModel` Adapter
- **Affected File**: [`stitchcraft-backend/config/supabaseModel.js:131-147 & 173-188`](file:///home/manthan/Projects/StitchCraft/stitchcraft-backend/config/supabaseModel.js#L131-L147)
- **Problem**: `load()` fetches all records matching `shopId` from Supabase over the network into Node.js heap memory, where `values.sort()` and `values.slice()` execute in-memory.
- **Impact**: While acceptable for shops with a few hundred orders, a busy workshop with 5,000+ orders will experience severe memory exhaustion, high latency (1–3s per request), and potential Node.js process crashes (OOM).
- **Remediation**: Transition backend queries to direct Supabase PostgREST queries with SQL-level `.order('created_at', { ascending: false }).range(start, end)` pagination.

#### GAP-P0-02: Remote Pull Overwrite Risk During Interrupted Sync
- **Affected File**: [`stitchcraft-mobile/lib/core/services/sync_service.dart:667`](file:///home/manthan/Projects/StitchCraft/stitchcraft-mobile/lib/core/services/sync_service.dart#L667)
- **Problem**: During Phase 3 (pulling remote records), `SyncService` inserts remote records via `_localDb.insertRecord(table, sqliteRecord)`, which uses SQLite `ConflictAlgorithm.replace`. If Phase 1 push failed due to a sudden network disconnection, local offline edits with `sync_status = 1` or `3` can be overwritten by stale server data.
- **Impact**: Potential loss of offline order edits, pricing changes, or notes recorded on the shop floor.
- **Remediation**: Update `insertRecord()` during sync pull to check existing local `sync_status`. If `local.sync_status != 0`, retain local record and mark row in `mutation_outbox` as a conflict requiring user review.

---

### Priority 1 — High (Core Architectural & Functional Gaps)

#### GAP-P1-01: Standalone Measurements & Karigars Omitted from Mobile Background Sync
- **Affected File**: [`stitchcraft-mobile/lib/core/services/sync_service.dart:45 & 246`](file:///home/manthan/Projects/StitchCraft/stitchcraft-mobile/lib/core/services/sync_service.dart#L45)
- **Problem**: `syncAll()` defines: `final tables = ['customers', 'orders', 'expenses', 'inventory'];`. Standalone customer measurements and mobile karigar records are completely omitted from the push/pull loop.
- **Impact**: If a tailor adds measurements for a customer on mobile without creating an immediate order, those measurements never sync to the web dashboard.
- **Remediation**: Add `'measurements'` and `'karigars'` to the `tables` array in `SyncService` with corresponding payload mappers.

#### GAP-P1-02: Absence of Machines Management Screen on Mobile
- **Affected File**: [`stitchcraft-mobile/lib/main.dart`](file:///home/manthan/Projects/StitchCraft/stitchcraft-mobile/lib/main.dart)
- **Problem**: While `Machines.jsx` and machine API routes exist on Web and Backend, no Flutter screen or route exists for machines in mobile navigation.
- **Impact**: Tailors cannot check or update machine maintenance status (`Working`, `Under Maintenance`, `Broken`) from the shop floor using the mobile app.
- **Remediation**: Implement `MachinesScreen` under `features/shop/screens/` and register route `/machines` in mobile `main.dart`.

#### GAP-P1-03: Single-Role Enforcement Blocking Multi-Role Capabilities
- **Affected File**: [`stitchcraft-backend/middleware/authMiddleware.js:46-55`](file:///home/manthan/Projects/StitchCraft/stitchcraft-backend/middleware/authMiddleware.js#L46-L55)
- **Problem**: Sensitive endpoints currently apply `authorize('owner')`. Non-owner roles (`manager`, `staff`, `karigar`) receive HTTP 403 on staff management, shop editing, and expense deletion. Furthermore, granular field-level permissions (e.g. karigar restricted to status updates only) are not yet enforced in `orderController.js`.
- **Impact**: Multi-user shops cannot safely give karigars or assistants their own logins without either granting full access or locking them out of daily workflows.
- **Remediation**: Implement the full RBAC permission evaluator matching the architecture matrix.

---

### Priority 2 — Medium (Usability, Performance & Technical Debt)

#### GAP-P2-01: React Hook Missing Dependency Warnings (ESLint)
- **Affected Files**: `useOrderDetails.js`, `CustomerDetails.jsx`, `Delivery.jsx`, `EditOrder.jsx`, `KarigarDetails.jsx`, `Ledger.jsx`, `Payments.jsx`, `useLedger.js`.
- **Problem**: Eight React components omit data-fetching callback functions from `useEffect` dependency arrays, causing ESLint exhaustive-deps warnings.
- **Impact**: Risk of stale closures or redundant re-fetching under future React 19 concurrent feature updates.
- **Remediation**: Wrap fetching helpers in `useCallback` and list them in `useEffect` dependency arrays.

#### GAP-P2-02: Missing SPA Routing Rewrites in `vercel.json`
- **Affected File**: [`vercel.json`](file:///home/manthan/Projects/StitchCraft/vercel.json)
- **Problem**: `vercel.json` specifies build and output directories but lacks client-side rewrite rules (`"routes": [{ "handle": "filesystem" }, { "src": "/.*", "dest": "/index.html" }]`).
- **Impact**: Refreshing deep routes on Vercel (e.g. `/orders/ORD-001` or `/invoice/share/token`) returns 404 unless rewrites are configured out-of-band in Vercel project settings.
- **Remediation**: Add explicit SPA fallback rewrites directly into `vercel.json`.

---

### Priority 3 — Low (Minor UX & Operational Enhancements)

#### GAP-P3-01: Automated Payment Gateway Webhooks
- **Affected Files**: `orderController.js`, `PaymentModal.jsx`.
- **Problem**: UPI payment verification is manual. The masterji must verify their bank SMS or soundbox and manually click "Record Payment".
- **Impact**: Operational friction; small risk of masterji forgetting to record a received payment.
- **Remediation**: Integrate an optional automated UPI payment aggregator webhook (e.g. Cashfree / Razorpay) for automated settlement matching.

