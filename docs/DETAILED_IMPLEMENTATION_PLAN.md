# StitchCraft Detailed Implementation Plan

**Status:** Proposed  
**Planning basis:** `docs/PROJECT_ANALYSIS.md`, `docs/PROJECT_IMPROVEMENT_PLAN.md`, `docs/PROJECT_REQUIREMENTS.md`, and the November 2026 implementation-review conversation  
**Scope:** Backend API, Supabase persistence, Flutter mobile app, React web app, deployment, tests, and operational documentation

## 1. Purpose and implementation principles

This plan converts the current audit into an executable sequence of engineering work. The objective is to make StitchCraft safe for daily workshop operations before expanding its feature surface.

The implementation must follow these principles:

1. **Protect data before adding features.** Synchronization, authorization, financial integrity, and tenant isolation take precedence over new modules.
2. **Keep the backend authoritative for business rules.** Web and mobile clients must use the same domain operations for payments, delivery, inventory, and permissions.
3. **Never silently lose or overwrite work.** Offline mutations, financial events, and inventory movements must be durable and auditable.
4. **Prefer additive migrations.** Existing `app_records` data must remain readable while new relational structures are introduced and verified.
5. **Ship in reversible increments.** Every phase needs tests, observability, a rollback path, and explicit release criteria.
6. **Preserve historical truth.** Measurement snapshots, payments, refunds, ledger entries, and inventory movements must not be rewritten to hide history.

The current audit is primarily code/documentation based. Production concurrency, real network interruptions, third-party delivery, and large-volume performance still require validation during implementation.

## 2. Current system and critical flows

### 2.1 Runtime topology

| Surface | Responsibility | Primary risk |
|---|---|---|
| React web | Administration, reporting, orders, finance, customer communication | Client/server contract drift, SPA deployment routing |
| Flutter mobile | Workshop operations, offline writes, camera/voice input, synchronization | Direct database writes bypass the mutation outbox |
| Express backend | Authentication, authorization, validation, business services, integrations | Service-role access makes API boundaries security-critical |
| Supabase | Auth, PostgreSQL, storage, relational migrations | Active adapter still writes JSON documents |
| External services | WhatsApp links, UPI intents/QR, FCM, signed media URLs | Link generation is not delivery or payment confirmation |

### 2.2 Business flows to preserve

1. **Onboarding:** registration → email verification → user/shop provisioning → shop configuration.
2. **Customer/order booking:** customer → current measurements → immutable order measurement snapshot → garment/material → karigar assignment → price and advance.
3. **Production:** Incoming → Measuring → Cutting → Stitching → Checking → Ready → Delivered, with Cancelled as an alternative terminal outcome.
4. **Collections:** advance/additional payment → immutable financial event → ledger entry → order paid/balance summary → Udhar recovery.
5. **Inventory:** stock purchase → reservation/consumption → low-stock alert → return/adjustment.
6. **Offline work:** local mutation → durable outbox → push → conflict/idempotency handling → pull/merge → visible sync status.
7. **Customer communication:** sanitized invoice → WhatsApp/UPI instructions → manual or verified payment reconciliation.
8. **Multi-user access:** authenticated identity → shop membership → role permission → resource/field authorization.

## 3. Priority and sequencing

### Priority definitions

- **P0:** Data loss, security bypass, financial corruption, or a production-blocking defect.
- **P1:** Core workflow is present but broken on one platform or because of an API contract mismatch.
- **P2:** Scalability, observability, export quality, UX friction, or incomplete secondary workflows.
- **P3:** Refactoring, dead-code removal, documentation, and process improvements.
- **P4:** New product capabilities after the reliability baseline.

### Dependency graph

```text
Baseline and test harness
        |
        +--> P0 runtime/security defects
        |
        +--> Sync foundation (outbox, versions, idempotency)
                    |
                    +--> Financial and inventory transactions
                    |
                    +--> Complete entity synchronization
        |
        +--> Permission and resource authorization
        |
        +--> Relational performance migration
        |
        +--> UX and requirement expansion
```

Do not enable broad offline payments or multi-device conflict resolution until the sync foundation and financial transaction boundaries are complete.

## 4. Phase 0 — Baseline, decisions, and safety net

**Priority:** P0  
**Estimate:** 1–2 days  
**Dependencies:** None  
**Owners:** Backend, mobile, web, QA

### 4.1 Establish a reproducible baseline

- Record the current commit, Node/Dart/Flutter versions, environment variables (names only), migration status, and test counts.
- Run backend tests, frontend tests/lint/build, and Flutter CI-equivalent checks where the local Flutter SDK is available.
- Capture known failures without changing unrelated code.
- Add a CI artifact containing test output and build versions.

### 4.2 Confirm product decisions before enforcing policy

Obtain explicit product approval for:

- Final role/permission matrix and whether managers can view ledger/profit data.
- Whether karigars can see customer names, phone numbers, order totals, or only assigned job details.
- Which local tables are authoritative synchronized entities versus caches/device-only data.
- Whether cancelled orders may accept payments.
- Refund rules and whether payment corrections are reversal events.
- Whether phone OTP is in scope for the next release or remains a future feature.
- Retention and deletion rules for customer photos and invoice tokens.

### 4.3 Baseline acceptance criteria

- Existing backend and web suites pass with no unexplained regression.
- A documented test environment can create a shop, customer, order, payment, delivery, and local mobile record.
- Every later phase can compare its test results with this baseline.

## 5. Phase 1 — P0 runtime and security fixes

**Priority:** P0/P1  
**Estimate:** 3–5 days  
**Dependencies:** Phase 0 decisions  
**Owners:** Backend, web, mobile

### 5.1 Fix deployment and cross-origin configuration

**Affected areas**

- `vercel.json`
- `stitchcraft-backend/config/cors.js`
- frontend deployment documentation

**Implementation**

1. Add a Vercel SPA catch-all rewrite so direct navigation and refresh work for `/dashboard`, `/orders`, and `/invoice/share/:token`.
2. Parse `CLIENT_URL` and any explicitly configured origins instead of relying only on hardcoded Vercel domains.
3. Reject unknown origins by default; keep local development origins explicitly configurable.
4. Add deployment smoke tests for the invoice route and a dashboard route.

**Acceptance criteria**

- Direct refresh of a client-side route returns the application shell.
- Requests from the configured production origin pass CORS.
- Unconfigured origins are rejected.

### 5.2 Remove the single-owner authentication block

**Affected areas**

- `stitchcraft-backend/middleware/authMiddleware.js`
- `stitchcraft-backend/controllers/authController.js`
- route-level authorization middleware and tests

**Implementation**

1. Make authentication validate identity and attach the active membership context; it must not reject non-owner roles.
2. Make `authorize(...roles)` enforce the roles supplied by each route.
3. Allow invited manager, staff, and karigar users to complete verification.
4. Add explicit membership validation when switching shops and when processing queued mutations.
5. Keep destructive operations owner-only.

**Acceptance criteria**

- Valid manager, staff, and karigar sessions authenticate.
- A route protected by `authorize('owner', 'manager')` admits only those roles.
- An unlisted role receives a clear `403`.
- Cross-shop access remains denied.

### 5.3 Close delivery-credit bypasses

**Affected areas**

- `stitchcraft-backend/services/orderService.js`
- `stitchcraft-backend/controllers/deliveryController.js`
- mobile delivery screen and API client

**Implementation**

1. Route all clients through one delivery operation.
2. When balance is outstanding, require `allowCredit === true` and a non-empty reason.
3. Reject direct order status changes to Delivered when the rule is not satisfied.
4. Store the reason as an auditable delivery event/note.
5. Add the same confirmation flow to mobile.

**Acceptance criteria**

- Unpaid delivery without explicit credit approval is rejected on every API path.
- Web and mobile produce the same audit record.
- Fully paid delivery remains one-step and backward compatible.

### 5.4 Fix deterministic correctness defects

Implement and test the following surgical fixes:

- Use `createdAt` (with a validated fallback) for ledger journal entries and make invalid dates sort deterministically.
- Escape CSV fields containing commas, quotes, and newlines; add date-range filtering.
- Fix the mobile customer-detail “Book New Order” route to use a registered route and preserve the selected customer.
- Align staff role dropdown values with backend values (`manager`, `karigar`, `staff`); remove unsupported `admin`/`owner` invitation choices.
- Align password-reset flow between frontend recovery sessions and backend protected routes; do not require an already authenticated session for a recovery operation.
- Replace hard deletion of customers with an explicit business rule that preserves order history and prevents orphaned references.

**Acceptance criteria**

- Each identified user journey works on the platform where it is advertised.
- Regression tests cover the original defect and the successful path.

## 6. Phase 2 — Offline synchronization foundation

**Priority:** P0  
**Estimate:** 7–10 days  
**Dependencies:** Phase 0; Phase 1 authentication/membership behavior  
**Owners:** Mobile, backend, database

This is the highest-risk architectural phase. Do not repair pull behavior with a UI-only workaround.

### 6.1 Make repositories the only mobile write path

**Affected areas**

- `stitchcraft-mobile/lib/core/repositories/`
- `stitchcraft-mobile/lib/core/services/local_db_service.dart`
- feature screens currently calling `insertRecord`/`updateRecord` directly

**Implementation**

1. Define repository methods for each supported mutation.
2. Migrate screens to repositories incrementally: customers, orders, payments, expenses, inventory.
3. Remove or restrict direct table writes after migration.
4. Add instrumentation that reports writes occurring outside repositories during development/CI.

### 6.2 Build a durable mutation outbox

Use a local table with at least:

```sql
shop_id TEXT NOT NULL,
entity_type TEXT NOT NULL,
entity_id TEXT NOT NULL,
operation TEXT NOT NULL,
payload TEXT NOT NULL,
base_version INTEGER,
client_mutation_id TEXT NOT NULL UNIQUE,
status TEXT NOT NULL,
retry_count INTEGER NOT NULL DEFAULT 0,
last_error TEXT,
created_at TEXT NOT NULL,
updated_at TEXT NOT NULL
```

Rules:

- Generate stable client IDs before local persistence.
- Preserve the original `shop_id` and entity ID.
- Write the entity and outbox row in one SQLite transaction.
- Support explicit `pending`, `processing`, `synced`, `conflict`, and `failed` states.
- Never delete failed mutations without an intentional user/admin action.

### 6.3 Add optimistic concurrency and server idempotency

**Backend/database**

1. Add a version to every mutable synchronized entity.
2. Require `base_version` on updates.
3. Apply updates only when the current version matches.
4. Return `409 Conflict` with server version and current representation when it does not.
5. Add a server-side mutation table with a unique `(shop_id, mutation_id)` key.
6. Commit the mutation result and business change atomically.
7. Return the original result for safe retries; reject reuse of a key for a different operation.

**Conflict rules**

- Customer/order metadata: explicit conflict record and user resolution.
- Payments/refunds: immutable event plus idempotency; never last-write-wins.
- Inventory: transactional movement conflict; never silently overwrite stock.

### 6.4 Make push/pull ordering safe

Implement this sequence:

1. Validate authentication and shop membership.
2. Read pending outbox rows.
3. Group mutations by dependency.
4. Push mutations and classify success/conflict/retryable/permanent failure.
5. Mark successful rows only after confirmed server response.
6. Pull remote changes.
7. Merge only records without unresolved local mutations.
8. Update last-successful-sync and counts.

Rules:

- If push fails for a record, do not pull a replacement that can overwrite it.
- Never use unconditional `replace` for a local record with pending mutations.
- Use exponential backoff with jitter.
- Make app termination during sync restart-safe.

### 6.5 Sync foundation acceptance tests

- A local entity update and its outbox row either both commit or both roll back.
- Remote pull never overwrites a pending local mutation.
- Retrying the same mutation produces one server result.
- Stale updates return `409`, not silent replacement.
- Switching from Shop A to Shop B does not rewrite a queued Shop A mutation.
- Killing the app during sync leaves the mutation recoverable.
- Failed/conflicted mutations remain visible and retryable.

## 7. Phase 3 — Financial and inventory integrity

**Priority:** P0  
**Estimate:** 5–8 days  
**Dependencies:** Phase 2 idempotency and versioning  
**Owners:** Backend, database, QA

### 7.1 Define the financial source of truth

Adopt these invariants unless product approval specifies otherwise:

```text
balance = total_amount - paid_amount
total_amount = paid_amount + balance
```

- Payments and refunds are immutable events.
- Ledger entries represent accounting impact.
- Order paid/balance fields are derived summaries.
- Corrections are reversal or adjustment events, not edits to original payments.
- Use integer paise or PostgreSQL `NUMERIC`; do not use floating-point money.

Document behavior for discounts, cancellations, refunds, partial payments, and credit deliveries.

### 7.2 Make payment and refund operations atomic

Expose one backend operation that:

1. Validates tenant, order ownership, amount, currency, method, and current state.
2. Checks the idempotency key.
3. Inserts the immutable payment/refund event.
4. Inserts the ledger entry.
5. Recalculates the order financial summary.
6. Stores the idempotent response.
7. Commits all changes together.

Any failure must roll back all writes.

### 7.3 Replace boolean inventory deduction with movements

Add an `inventory_movements` model/table containing tenant, item, optional order, movement type, signed quantity, reference, reason, and timestamp.

Movement types:

- Purchase: positive
- Return: positive
- Consumption: negative
- Adjustment: signed and reason-required
- Reservation/release: explicit if the product needs reserved stock

Use row locking or an atomic conditional update to prevent concurrent over-consumption. Keep a cached balance only if it is transactionally maintained.

### 7.4 Reconciliation and acceptance criteria

Add an administrative/scheduled report for:

- Payment events versus order summaries.
- Payments versus ledger entries.
- Refunds versus reversal entries.
- Inventory balance versus movement history.
- Negative balances or stock.
- Paid orders with outstanding balances.

The report must identify discrepancies without silently repairing history.

Acceptance:

- Duplicate payment requests create one payment.
- Refunds cannot exceed refundable amount.
- Payment, ledger, and order summary commit or fail together.
- Every inventory adjustment has an auditable movement.
- Concurrent deductions cannot create negative stock unless explicitly permitted.

## 8. Phase 4 — Authorization, resource isolation, and media security

**Priority:** P0/P1  
**Estimate:** 5–8 days  
**Dependencies:** Phase 1 role authentication; Phase 2 shop-aware mutations  
**Owners:** Backend, web, mobile, security QA

### 8.1 Define and centralize permissions

Create one permission registry and middleware such as `requirePermission(permission)`. The final matrix must be approved before enforcement.

Minimum permission groups:

- `shop.manage`, `staff.manage`
- `customers.read/create/update/delete`
- `orders.read/create/update/delete`
- `payments.read/create/refund`
- `ledger.read`, `reports.read`
- `inventory.read/manage`
- `assigned_orders.read/update_stage`

Apply checks to every route, not only navigation visibility.

### 8.2 Enforce resource and field authorization

- Scope every repository query by authenticated membership and tenant.
- Require karigar assignment for karigar order reads/updates.
- Restrict owner-only settings, deletion, exports, and role changes.
- Add role-specific response serializers so sensitive fields never reach unauthorized clients.
- Add cross-tenant and unassigned-resource tests for every entity family.

### 8.3 Secure media and public invoices

- Use tenant-specific private storage paths.
- Validate MIME type and size server-side.
- Generate randomized object names.
- Issue short-lived signed URLs only after authorization.
- Define retention/deletion policy for customer photos and attachments.
- Use high-entropy, revocable invoice tokens and avoid exposing unnecessary customer data.

### 8.4 Acceptance criteria

- Every protected API operation has a permission test.
- Staff cannot read owner-only margins or delete records.
- Karigars see only assigned jobs and approved fields.
- Cross-shop IDs return the standard not-found/forbidden response without data leakage.
- Revoked memberships stop API and sync access.
- Storage URLs cannot bypass tenant authorization.

## 9. Phase 5 — Complete and observable synchronization coverage

**Priority:** P1  
**Estimate:** 4–7 days  
**Dependencies:** Phase 2 and Phase 3  
**Owners:** Mobile, backend, product

### 9.1 Create a sync registry

Define one registry entry per entity with:

- Local and cloud storage names.
- Primary key and tenant key.
- Supported create/update/delete operations.
- Dependencies and upload order.
- Serialization rules.
- Version/conflict policy.
- Idempotency strategy.
- Media handling policy.

Initial decisions:

| Entity | Default policy |
|---|---|
| Customers | Versioned record |
| Measurements | Versioned child of customer |
| Karigars | Versioned shop member |
| Orders | Versioned record; depends on customer/karigar |
| Payments | Immutable event; depends on order |
| Inventory | Transactional movement |
| Expenses | Versioned financial record |
| Repairs/machines/lining/gallery | Product decision before sync |

### 9.2 Respect dependencies and triggers

Upload order:

```text
Shop/membership → customers/karigars → measurements/inventory
→ orders/repairs → payments/expenses → delivery/events/media
```

Trigger sync on launch, resume, successful online mutation, connectivity restoration, and periodic background opportunity. Document that mobile background scheduling is best-effort, not a real-time guarantee.

### 9.3 Build sync status UX

Display:

- Last successful sync.
- Pending count.
- Failed count.
- Conflict count.
- Current status.
- Retry action.
- Actionable error message.

Do not display “Up to date” while unresolved mutations exist. Localize status and errors in supported languages.

## 10. Phase 6 — Database scalability and relational migration

**Priority:** P1/P2  
**Estimate:** 7–12 days, staged  
**Dependencies:** Phases 2–5  
**Owners:** Backend, database, operations

### 10.1 Stop unsafe in-memory query behavior

Short-term:

- Ensure tenant predicates are always pushed to the database.
- Remove `$or` query shapes that bypass adapter filtering.
- Replace N+1 payment/delivery lookups with batched queries or joins.
- Add bounded limits and deterministic ordering.
- Add query timing and result-size metrics.

### 10.2 Introduce relational tables incrementally

Start with high-volume/high-integrity entities:

`shops`, `shop_memberships`, `customers`, `measurements`, `orders`, `payments`, `transactions`, `ledger_entries`, `inventory_items`, `inventory_movements`, `sync_mutations`.

Keep flexible garment metadata in JSONB where appropriate. Do not leave a migration that copies data once while runtime writes continue only to `app_records`.

### 10.3 Dual-write/read verification strategy

1. Add schema, constraints, indexes, and tenant-aware foreign keys.
2. Backfill and validate counts/checksums.
3. Introduce a feature flag for dual-write.
4. Compare old/new reads in shadow mode.
5. Migrate one entity at a time.
6. Keep rollback reads from the old source until verification passes.
7. Remove dual-write only after an agreed observation window.

### 10.4 Required indexes and constraints

At minimum, evaluate:

- `(shop_id, created_at DESC)`
- `(shop_id, status)`
- `(shop_id, phone)`
- `(shop_id, order_id)` for payments
- Foreign keys and tenant-consistent references
- Unique client mutation IDs
- Check constraints for amounts, quantities, and valid states

Acceptance:

- Query latency and memory remain bounded as fixture volume grows.
- No request downloads all shops’ documents.
- Relational and legacy representations remain consistent during migration.

## 11. Phase 7 — Product-fit and workflow improvements

**Priority:** P2/P4  
**Estimate:** After reliability phases  
**Owners:** Product, web, mobile, backend

Implement only after the release gates above:

1. **Mobile workflow repair:** customer profile → new order with customer and last measurements preselected.
2. **Month-end reporting:** reliable CSV, date ranges, and mobile export policy.
3. **Invoice reliability:** SPA routing, sanitized content, payment UTR/screenshot workflow if manual reconciliation is desired.
4. **Offline parity:** restocking, repairs, karigar assignments, and shop settings according to the sync registry.
5. **Phone OTP:** separate product/security project; do not infer it from the current email-based contract.
6. **Garment templates:** configurable blouse, kurti, salwar, and other templates with versioned measurement schemas.
7. **Karigar wages:** piece-rate ledger only after role and order assignment security is reliable.
8. **Machine registry:** retain, simplify, or defer based on evidence from active shops; do not expand it automatically.

## 12. Testing strategy and release gates

### 12.1 Backend

- Unit tests for permission resolution, money calculations, conflict classification, idempotency, ledger sorting, and CSV escaping.
- Integration tests for tenant isolation, role routes, payment transactions, delivery credit, inventory concurrency, and public invoice authorization.
- Property-based or table-driven tests for financial invariants.
- Load tests for list/search endpoints with multiple shops and realistic record counts.

### 12.2 Mobile

- SQLite transaction tests for entity plus outbox atomicity.
- Restart/interruption tests during push and pull.
- Conflict and retry tests.
- Repository adoption guard preventing direct feature-screen writes.
- Widget tests for sync status, delivery credit reason, and customer-to-order navigation.

### 12.3 Web and deployment

- Route contract tests for roles and password recovery.
- CSV fixture tests with commas, quotes, newlines, and Unicode.
- Production-like SPA refresh smoke tests.
- CORS allow/deny tests.
- Build and lint checks with warnings tracked and reduced.

### 12.4 Release gates

Do not release a phase if:

- Any cross-tenant test fails.
- A payment can be duplicated by retry.
- A pending local mutation can be overwritten by pull.
- A role can access an unauthorized resource or field.
- Financial reconciliation reports unexplained discrepancies.
- Migration verification has not completed.

## 13. Observability and operational controls

Add structured events for:

- Authentication/membership denial.
- Mutation ID, entity, tenant, outcome, retry count, and conflict.
- Payment/refund idempotency result.
- Inventory movement and rejection.
- Reconciliation discrepancy.
- Signed URL issuance and public invoice access.
- Sync duration, counts, and last success.

Never log passwords, tokens, full payment secrets, or customer data unnecessarily. Add dashboards/alerts for repeated sync failures, conflict spikes, payment idempotency collisions, negative stock, and elevated authorization failures.

## 14. Rollout and rollback

For each phase:

1. Ship schema changes before code that depends on them.
2. Keep new behavior behind a feature flag where data migration or client rollout is involved.
3. Release backend compatibility before mobile updates.
4. Monitor one controlled shop or internal tenant first.
5. Verify reconciliation and sync metrics.
6. Expand gradually.
7. Roll back behavior flags before reverting migrations.

Rollback must preserve outbox rows, immutable financial events, and audit records. Never roll back by deleting accepted payments or rewriting historical balances.

## 15. Definition of done

The reliability milestone is complete when:

- All P0/P1 defects in the audit have regression tests.
- Manager, staff, and karigar flows work end-to-end with approved permissions.
- Offline mutations are durable, tenant-bound, idempotent, versioned, and conflict-visible.
- Payments, refunds, ledger entries, delivery credit, and inventory movements are atomic and reconcilable.
- No cloud pull overwrites unresolved local work.
- High-volume queries are tenant-scoped and database-bounded.
- Direct invoice and dashboard routes work in production deployment.
- Documentation, API contracts, migrations, and test counts reflect the shipped implementation.

Only after this milestone should major new feature development be prioritized.
