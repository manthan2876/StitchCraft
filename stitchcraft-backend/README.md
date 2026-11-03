# 🖥️ StitchCraft Backend

Node.js + Express REST API for the StitchCraft tailor shop management platform. Handles authentication, multi-tenant shop data, orders, payments, karigars, inventory, ledger, security controls, push notifications, and file uploads.

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Runtime | Node.js 22 (ESM modules) |
| Framework | Express.js v5 |
| Database | Supabase PostgreSQL via the service-role API + `SupabaseModel` document adapter |
| Auth | Supabase Auth access tokens + role-based authorization (`owner`, `manager`, `karigar`, `staff`) |
| Security | Helmet (security headers), Express-Rate-Limit, Safe non-backtracking regexes |
| Validation | Two-tier validation: Request middleware + table/schema validators |
| File Storage | Supabase Storage (profile + maap images via signed URLs) |
| Push Notifications | Firebase Admin SDK (optional FCM push dispatch to mobile devices) |
| Test Runner | Node.js native test runner (`node --test`) |
| Environment | dotenv |
| Dev Server | nodemon |

---

## 📂 Project Structure

```text
stitchcraft-backend/
├── config/
│   ├── cors.js                # CORS configuration & origin whitelist
│   ├── db.js                  # Database connection & health checks
│   ├── supabase.js            # Supabase client initialization & test fallbacks
│   └── supabaseModel.js       # Document-to-table adapter with schema validation
│
├── controllers/               # Route handler logic
│   ├── accountController.js   # Data export, import, conflict resolution & account deletion
│   ├── authController.js      # Register, login, email verification, password management
│   ├── customerController.js  # CRUD customers + measurements
│   ├── dashboardController.js # Aggregated stats and metrics for dashboard
│   ├── deliveryController.js  # Delivery tracking and completion per order
│   ├── expenseController.js   # CRUD khata expense entries
│   ├── inventoryController.js # CRUD inventory items & aster stock
│   ├── karigarController.js   # CRUD karigars + performance metrics
│   ├── ledgerController.js    # Ledger summary, journal entries, order transactions
│   ├── machineController.js   # CRUD machine registry & maintenance states
│   ├── notificationController.js # In-app notifications & device FCM token registration
│   ├── orderController.js     # CRUD orders, payments, notes, public invoice & share tokens
│   ├── profileController.js   # User profile read/update & active shop switching
│   ├── shopController.js      # Multi-shop management & shop customization (UPI, GST, prefix)
│   ├── staffController.js     # Shop staff member invitation, role assignment & status
│   └── uploadController.js    # Supabase signed URL generation (upload + view)
│
├── middleware/
│   ├── authMiddleware.js      # Supabase Auth token verification & role authorization guard
│   ├── errorMiddleware.js     # Centralized error handler
│   ├── securityMiddleware.js  # Multi-tier rate limiters & identifier validation
│   └── validationMiddleware.js# Comprehensive request-body validation & sanitization
│
├── models/                    # Supabase document adapters
│   ├── ActionLog.js           # Audit trail for order status changes
│   ├── Customer.js
│   ├── Delivery.js
│   ├── Inventory.js
│   ├── Karigar.js
│   ├── LedgerEntry.js         # Shop-level income/expense entries
│   ├── Machine.js
│   ├── Measurement.js         # Shirt + pant measurements per customer
│   ├── Notification.js
│   ├── Order.js               # Includes notes[], measurementsSnapshot
│   ├── Payment.js             # Recalculated from Transactions
│   ├── Shop.js                # Includes upiId, gstin, invoicePrefix, logoUrl
│   ├── Transaction.js         # Immutable payment ledger per order
│   └── User.js                # Includes multi-tenant shop associations & roles
│
├── routes/
│   ├── index.js               # Central router — mounts sub-routes & global DELETE limiter
│   ├── authRoutes.js          # /api/auth
│   ├── customerRoutes.js      # /api/customers (includes /pending-balances)
│   ├── dashboardRoutes.js     # /api/dashboard
│   ├── deliveryRoutes.js      # /api/deliveries
│   ├── inventoryRoutes.js     # /api/inventory
│   ├── karigarRoutes.js       # /api/karigars
│   ├── ledgerRoutes.js        # /api/ledger
│   ├── machineRoutes.js       # /api/machines
│   ├── notificationRoutes.js  # /api/notifications
│   ├── orderRoutes.js         # /api/orders (includes public guest invoices)
│   ├── shopRoutes.js          # /api/shops
│   ├── staffRoutes.js         # /api/staff
│   └── uploadRoutes.js        # /api/upload
│
├── services/
│   ├── accountService.js      # Account deletion, data export & import conflict resolution
│   ├── customerService.js     # Scoped customer lookup & measurement relational sync
│   ├── ledgerService.js       # Ledger aggregation and cash journal calculations
│   ├── notificationService.js # In-app notifications & Firebase Cloud Messaging (FCM)
│   └── orderService.js        # createOrder, updateOrder, deleteOrder, syncPayment
│
├── test/                      # Automated test suites (37 tests across 14 suites)
│   ├── ledger_and_expenses.test.js  # Ledger aggregation & balance tests
│   ├── order_lifecycle.test.js      # Order status transitions & financial math
│   ├── pending_balances.test.js     # Udhar balance aggregation & WhatsApp reminders
│   ├── security_and_scoping.test.js # Auth, reset password, rate limiting & input tests
│   ├── shop_isolation.test.js       # Multi-tenant cross-shop boundary tests
│   └── staff_management.test.js     # Multi-role policies & staff assignment tests
│
├── utils/
│   ├── identifiers.js         # UUID & ObjectId validation
│   └── tableValidators.js     # Schema-level validation rules for all tables
│
├── scripts/
│   └── migrate_to_relational.js # Migration script to relational Supabase tables
│
├── seed.js                    # Seeds DB with demo shop, karigars, orders
└── server.js                  # App entry point (Express, Helmet, Rate Limiter)
```

---

## 🚀 Setup & Commands

### 1. Install dependencies

```bash
npm ci
```

### 2. Configure `.env`

Copy `.env.example` to `.env`:

```bash
cp .env.example .env
```

Set the required values in `.env`:

```env
PORT=5000
NODE_ENV=development
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
CLIENT_URL=http://localhost:5173
```

*(Optional for push notifications)*:
```env
FIREBASE_SERVICE_ACCOUNT={"type":"service_account",...}
```

### 3. Run development server

```bash
npm run dev     # Hot-reload with nodemon (http://localhost:5000)
npm start       # Production server
npm run seed    # Seed database with sample shop, karigars, and orders
```

### 4. Run tests and syntax verification

```bash
# Run all automated test suites
npm test

# Check syntax on all backend files (excluding node_modules)
find . -name node_modules -prune -o -type f -name '*.js' -print0 | xargs -0 -n1 node --check
```

---

## 🔒 Security & Validation Architecture

### 1. Two-Tier Validation
- **Request-Level Middleware (`validationMiddleware.js`)**: Validates input formats, required parameters, string bounds, and enum states before handlers run. Rejects invalid requests early with descriptive 400 errors.
- **Table/Schema Validation (`tableValidators.js`)**: Validates document structure and field types inside `SupabaseModel` before persisting to Supabase PostgreSQL, ensuring database integrity.

### 2. Multi-Tier Rate Limiting
Configured using `express-rate-limit` to prevent abuse and denial-of-service:
- **General API**: 300 requests per 15-minute window per IP across `/api`.
- **Authentication**: 10 requests per 15-minute window per IP (`/api/auth/login`, `/api/auth/register`, `/api/auth/verify`).
- **File Uploads**: 30 requests per 15-minute window per IP (`/api/upload/*`).
- **Destructive Actions**: 10 requests per 15-minute window per IP (`/api/auth/account/*`, `/api/auth/update-password`, `/api/auth/verify-password`, and **all HTTP `DELETE` requests** routed through `/api`).

### 3. Multi-Tenant Shop Isolation
All operational collections (`Order`, `Customer`, `Karigar`, `Inventory`, `Machine`, `LedgerEntry`, `Payment`, `Transaction`, `Delivery`) enforce strict tenant boundaries by filtering on `shopId: req.user.shopId`. The `protect` middleware ensures users can only access records belonging to their active shop. Users can switch their active shop context via `PUT /api/auth/switch-shop/:id`.

### 4. Safe Regular Expressions (ReDoS Protection)
All regex patterns (such as email and phone validation) use bounded lengths and deterministic, non-backtracking patterns:
```javascript
/^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$/
```
Inputs exceeding RFC 5321 length limits (254 characters) are rejected before evaluation.

---

## 📡 API Reference

All protected routes require an `Authorization: Bearer <token>` header.

### System & Health Check
| Method | Path | Description | Access | Rate Limit |
|---|---|---|---|---|
| `GET` | `/api/status` | Health check endpoint returning API operational status | Public | 300 / 15m |

### Auth & Account — `/api/auth`
| Method | Path | Description | Access | Rate Limit |
|---|---|---|---|---|
| `POST` | `/register` | Register new user + provision shop | Public | 10 / 15m |
| `POST` | `/login` | Login through Supabase Auth | Public | 10 / 15m |
| `POST` | `/verify` | Verify email address | Public | 10 / 15m |
| `POST` | `/forgot-password` | Send password reset recovery link via email | Public | 10 / 15m |
| `POST` | `/reset-password` | Set new password using recovery bearer session | Protected | 10 / 15m |
| `GET` | `/profile` | Get current user profile and associated shops | Protected | 300 / 15m |
| `PUT` | `/profile` | Update profile (name, phone, avatar) | Protected | 300 / 15m |
| `PUT` | `/switch-shop/:id` | Switch active shop context | Protected | 300 / 15m |
| `PUT` | `/update-password` | Change user password | Protected | 10 / 15m |
| `POST` | `/verify-password` | Verify password confirmation | Protected | 10 / 15m |
| `POST` | `/account/download-data` | Export all shop data as JSON | Owner only | 10 / 15m |
| `POST` | `/account/check-conflicts` | Pre-check entity conflicts before data import | Owner only | 10 / 15m |
| `POST` | `/account/import-data` | Import shop data with conflict resolution | Owner only | 10 / 15m |
| `POST` | `/account/delete-all-data` | Wipe all shop records without deleting account | Owner only | 10 / 15m |
| `POST` | `/account/delete-account` | Delete user account and cascade delete shops | Owner only | 10 / 15m |

### Orders — `/api/orders`
| Method | Path | Description | Access | Rate Limit |
|---|---|---|---|---|
| `GET` | `/public/:id` | Public order receipt/invoice (lookup by shareToken or order ID; strips internal costs) | Public | 300 / 15m |
| `GET` | `/` | List all orders (filters: status, urgency, search) | Protected | 300 / 15m |
| `POST` | `/` | Create new order (validates schema + snapshots measurements) | Protected | 300 / 15m |
| `GET` | `/:id` | Get order details (payment, measurements, notes, transactions) | Protected | 300 / 15m |
| `PUT` | `/:id` | Update order (status, karigar, garments, aster deduction) | Protected | 300 / 15m |
| `DELETE` | `/:id` | Delete order + cascade transactions & payments | Protected | 10 / 15m |
| `POST` | `/:id/payments` | Record a payment transaction (recalculates payment ledger) | Protected | 300 / 15m |
| `POST` | `/:id/notes` | Add timestamped internal workshop note | Protected | 300 / 15m |
| `POST` | `/:id/share-token` | Generate or retrieve shareable guest invoice token | Protected | 300 / 15m |

### Customers — `/api/customers`
| Method | Path | Description | Access | Rate Limit |
|---|---|---|---|---|
| `GET` | `/pending-balances` | Aggregated pending balances (Udhar) across all unpaid/partial customer orders | Protected | 300 / 15m |
| `GET` | `/` | List all customers (supports search) | Protected | 300 / 15m |
| `POST` | `/` | Create customer with optional initial measurements | Protected | 300 / 15m |
| `GET` | `/:id` | Get customer profile + measurement history | Protected | 300 / 15m |
| `PUT` | `/:id` | Update customer contact & address info | Protected | 300 / 15m |
| `DELETE` | `/:id` | Delete customer | Protected | 10 / 15m |

### Karigars (Artisans) — `/api/karigars`
| Method | Path | Description | Access | Rate Limit |
|---|---|---|---|---|
| `GET` | `/` | List all karigars | Protected | 300 / 15m |
| `POST` | `/` | Create karigar | Protected | 300 / 15m |
| `GET` | `/:id` | Karigar details + order performance stats | Protected | 300 / 15m |
| `PUT` | `/:id` | Update karigar details, specialization, status | Protected | 300 / 15m |
| `DELETE` | `/:id` | Delete karigar | Protected | 10 / 15m |

### Machines — `/api/machines`
| Method | Path | Description | Access | Rate Limit |
|---|---|---|---|---|
| `GET` | `/` | List all machines | Protected | 300 / 15m |
| `POST` | `/` | Register new machine | Protected | 300 / 15m |
| `GET` | `/:id` | Get machine details | Protected | 300 / 15m |
| `PUT` | `/:id` | Update machine type or maintenance status (`Working`, `Under Maintenance`, `Broken`) | Protected | 300 / 15m |
| `DELETE` | `/:id` | Delete machine | Protected | 10 / 15m |

### Inventory & Lining (Aster) — `/api/inventory`
| Method | Path | Description | Access | Rate Limit |
|---|---|---|---|---|
| `GET` | `/` | List inventory items (filter by `itemType`) | Protected | 300 / 15m |
| `POST` | `/` | Create inventory item (stock quantity, unit, alert threshold) | Protected | 300 / 15m |
| `GET` | `/:id` | Get inventory item details | Protected | 300 / 15m |
| `PUT` | `/:id` | Update inventory item | Protected | 300 / 15m |
| `DELETE` | `/:id` | Delete inventory item | Protected | 10 / 15m |

### Ledger (Khata) & Expenses — `/api/ledger`
| Method | Path | Description | Access | Rate Limit |
|---|---|---|---|---|
| `GET` | `/summary` | Aggregated financial summary (income, expenses, receivables, payables, net profit) | Protected | 300 / 15m |
| `GET` | `/journal` | Chronological running cash book journal entries | Protected | 300 / 15m |
| `GET` | `/transactions` | Order payment transaction ledger | Protected | 300 / 15m |
| `GET` | `/expenses` | List shop expenses (filterable by category) | Protected | 300 / 15m |
| `POST` | `/expenses` | Record a shop expense | Protected | 300 / 15m |
| `DELETE` | `/expenses/:id` | Delete shop expense | Owner only | 10 / 15m |

### Deliveries — `/api/deliveries`
| Method | Path | Description | Access | Rate Limit |
|---|---|---|---|---|
| `GET` | `/` | List delivery tracking records | Protected | 300 / 15m |
| `PUT` | `/:id/deliver` | Mark order delivery as completed | Protected | 300 / 15m |

### Notifications & Push — `/api/notifications`
| Method | Path | Description | Access | Rate Limit |
|---|---|---|---|---|
| `GET` | `/` | List in-app notifications | Protected | 300 / 15m |
| `POST` | `/register-device` | Register/update FCM device token for mobile push | Protected | 300 / 15m |
| `PUT` | `/mark-read` | Mark all notifications as read | Protected | 300 / 15m |
| `PUT` | `/:id/read` | Mark a single notification as read | Protected | 300 / 15m |

### Multi-Shop Management — `/api/shops`
| Method | Path | Description | Access | Rate Limit |
|---|---|---|---|---|
| `GET` | `/` | List all shops associated with the user | Protected | 300 / 15m |
| `POST` | `/` | Create a new shop branch | Protected | 300 / 15m |
| `GET` | `/:id` | Get shop branch details | Protected | 300 / 15m |
| `PUT` | `/:id` | Update shop details (name, phone, address, UPI ID, GSTIN, invoice prefix, logo URL) | Protected | 300 / 15m |
| `DELETE` | `/:id` | Delete shop branch | Owner only | 10 / 15m |

### Staff & Role Management — `/api/staff`
| Method | Path | Description | Access | Rate Limit |
|---|---|---|---|---|
| `GET` | `/` | List team members and assigned roles (`owner`, `manager`, `staff`, `karigar`) | Owner / Manager | 300 / 15m |
| `POST` | `/` | Link or invite new team member to active shop | Owner / Manager | 300 / 15m |
| `PUT` | `/:id/status` | Toggle staff member active/inactive status | Owner / Manager | 300 / 15m |
| `PUT` | `/:id/role` | Update team member role assignment | Owner only | 300 / 15m |
| `DELETE` | `/:id` | Unlink team member from shop | Owner only | 10 / 15m |

### Dashboard Analytics — `/api/dashboard`
| Method | Path | Description | Access | Rate Limit |
|---|---|---|---|---|
| `GET` | `/stats` | Aggregated revenue, active orders by stage, upcoming delivery deadlines, karigar & machine stats | Protected | 300 / 15m |

### Storage Uploads — `/api/upload`
| Method | Path | Description | Access | Rate Limit |
|---|---|---|---|---|
| `POST` | `/get-upload-url` | Generate signed Supabase storage upload URL (scoped by shop) | Protected | 30 / 15m |
| `GET` | `/view-url` | Generate signed download/view URL via query parameter | Protected | 30 / 15m |
| `GET` | `/view-url/:bucket/:path` | Generate signed download/view URL via path parameters | Protected | 30 / 15m |

---

## 🗄️ Key Data Patterns

### Order Auto-ID
Orders receive formatted human-readable identifiers such as `ORD-001` alongside UUID primary keys.

### Payment Synchronization
Payments are **never updated directly**. Every payment creates an immutable `Transaction` record, and `syncPaymentFromTransactions()` recalculates total paid, balance, and status (`Pending`, `Partial`, `Paid`).

### Measurement Snapshotting
When an order is created, the customer's current measurement set is snapshotted into `order.measurementsSnapshot`. Subsequent alterations to customer measurements do not modify historic orders.

### Aster (Lining) Inventory Integration
When an order moves into active production stages defined by `ASTAR_DEDUCT_STATUSES` (`['Stitching', 'Checking', 'Ready', 'Delivered']`), the required aster quantity is automatically deducted from active inventory records. Cancelling an order restores the deducted quantity.

### Udhar (Pending Balances) Aggregation
The `/api/customers/pending-balances` endpoint aggregates outstanding balances across all unpaid or partially paid orders grouped by customer. It calculates the total shop receivable and formats WhatsApp reminder links for quick collection.

### Tokenized Public Guest Invoices
Guest invoices accessible via `/api/orders/public/:id` (using shareToken or Order ID) strictly strip wholesale fabric costs, profit margins, internal karigar assignments, and audit logs. The response provides sanitized customer-facing order items, financial balances, and shop UPI details for instant QR settlement.
