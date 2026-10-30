# 🖥️ StitchCraft Backend

Node.js + Express REST API for the StitchCraft tailor shop management platform. Handles authentication, multi-tenant shop data, orders, payments, karigars, inventory, ledger, security controls, and file uploads.

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Runtime | Node.js 22 (ESM modules) |
| Framework | Express.js v5 |
| Database | Supabase PostgreSQL via the service-role API + `SupabaseModel` document adapter |
| Auth | Supabase Auth access tokens + role-based authorization |
| Security | Helmet (security headers), Express-Rate-Limit, Safe non-backtracking regexes |
| Validation | Two-tier validation: Request middleware + table/schema validators |
| File Storage | Supabase Storage (profile + maap images via signed URLs) |
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
│   ├── authController.js      # Register, login, me, update profile, data export/import
│   ├── orderController.js     # CRUD orders, payments, notes, public invoice
│   ├── customerController.js  # CRUD customers + measurements
│   ├── karigarController.js   # CRUD karigars + performance stats
│   ├── machineController.js   # CRUD machines
│   ├── inventoryController.js # CRUD inventory items & aster stock
│   ├── ledgerController.js    # Ledger entries (income/expense)
│   ├── deliveryController.js  # Delivery tracking per order
│   ├── dashboardController.js # Aggregated stats for dashboard
│   ├── notificationController.js # In-app notifications
│   ├── shopController.js      # Multi-shop management & shop switching
│   └── uploadController.js    # Supabase signed URL generation
│
├── middleware/
│   ├── authMiddleware.js      # Supabase Auth token verification & shop-scope guard
│   ├── errorMiddleware.js     # Centralized error handler
│   ├── securityMiddleware.js  # Multi-tier rate limiters & identifier validation
│   └── validationMiddleware.js# Comprehensive request-body validation & sanitization
│
├── models/                    # Supabase document adapters
│   ├── User.js
│   ├── Shop.js
│   ├── Order.js               # Includes notes[], measurementsSnapshot
│   ├── Customer.js
│   ├── Measurement.js         # Shirt + pant measurements per customer
│   ├── Karigar.js
│   ├── Machine.js
│   ├── Inventory.js
│   ├── Payment.js             # Recalculated from Transactions
│   ├── Transaction.js         # Immutable payment ledger per order
│   ├── LedgerEntry.js         # Shop-level income/expense entries
│   ├── Delivery.js
│   ├── Notification.js
│   └── ActionLog.js           # Audit trail for order status changes
│
├── routes/
│   ├── index.js               # Central router — mounts all sub-routes
│   ├── authRoutes.js          # /api/auth
│   ├── orderRoutes.js         # /api/orders
│   ├── customerRoutes.js      # /api/customers
│   ├── karigarRoutes.js       # /api/karigars
│   ├── machineRoutes.js       # /api/machines
│   ├── inventoryRoutes.js     # /api/inventory
│   ├── ledgerRoutes.js        # /api/ledger
│   ├── deliveryRoutes.js      # /api/deliveries
│   ├── notificationRoutes.js  # /api/notifications
│   ├── shopRoutes.js          # /api/shops
│   ├── dashboardRoutes.js     # /api/dashboard
│   └── uploadRoutes.js        # /api/upload
│
├── services/
│   ├── orderService.js        # createOrder, updateOrder, deleteOrder, syncPayment
│   ├── ledgerService.js       # Ledger aggregation logic
│   └── accountService.js      # Account deletion + data conflict resolution
│
├── test/                      # Automated test suites (Node.js test runner)
│   ├── ledger_and_expenses.test.js  # Ledger aggregation & balance tests
│   ├── order_lifecycle.test.js      # Order status transitions & financial math
│   ├── security_and_scoping.test.js # Auth, rate limiting & identifier tests
│   └── shop_isolation.test.js       # Multi-tenant cross-shop boundary tests
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
SUPABASE_URL=https://qggxfxttveafgptdlmfu.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
CLIENT_URL=http://localhost:5173
```

### 3. Run development server

```bash
npm run dev     # Hot-reload with nodemon (http://localhost:5000)
npm start       # Production server
npm run seed    # Seed database with sample shop and order data
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
- **General API**: 300 requests per 15-minute window per IP.
- **Authentication**: 10 requests per 15-minute window per IP (`/api/auth/login`, `/api/auth/register`).
- **File Uploads**: 30 requests per 15-minute window per IP (`/api/upload`).
- **Destructive Actions**: 10 requests per 15-minute window per IP (`/api/auth/me` DELETE, import).

### 3. Multi-Tenant Shop Isolation
All operational collections (`Order`, `Customer`, `Karigar`, `Inventory`, `Machine`, `LedgerEntry`, etc.) enforce strict tenant boundaries by filtering on `shopId`. The `protect` middleware ensures users can only access records belonging to their active shop.

### 4. Safe Regular Expressions (ReDoS Protection)
All regex patterns (such as email validation) use bounded lengths and deterministic, non-backtracking patterns:
```javascript
/^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$/
```
Inputs exceeding RFC 5321 length limits (254 characters) are rejected before evaluation.

---

## 📡 API Reference

All protected routes require `Authorization: Bearer <token>` header.

### Auth — `/api/auth`
| Method | Path | Description | Rate Limit |
|---|---|---|---|
| `POST` | `/register` | Register new user + provision shop | 10 / 15m |
| `POST` | `/login` | Login through Supabase Auth | 10 / 15m |
| `GET` | `/me` | Get current user profile and shops | 300 / 15m |
| `PUT` | `/me` | Update profile (name, phone, avatar) | 300 / 15m |
| `PUT` | `/me/password` | Change password | 10 / 15m |
| `POST` | `/me/export` | Export all shop data as JSON | 10 / 15m |
| `POST` | `/me/import` | Import shop data from JSON | 10 / 15m |
| `DELETE` | `/me` | Delete account + cascade shop data | 10 / 15m |

### Orders — `/api/orders`
| Method | Path | Description |
|---|---|---|
| `GET` | `/` | List all orders (filter: status, urgency, search) |
| `POST` | `/` | Create new order (validates schema + snapshots measurements) |
| `GET` | `/:id` | Get order details (payment, measurements, notes, transactions) |
| `GET` | `/public/:id` | Public order details (no auth — for customer invoice link) |
| `PUT` | `/:id` | Update order (status, karigar, fields, aster deduction) |
| `DELETE` | `/:id` | Delete order + cascade transactions & payments |
| `POST` | `/:id/payments` | Record a payment transaction (recalculates payment) |
| `POST` | `/:id/notes` | Add timestamped internal note |

### Customers — `/api/customers`
| Method | Path | Description |
|---|---|---|
| `GET` | `/` | List all customers |
| `POST` | `/` | Create customer |
| `GET` | `/:id` | Get customer + measurement history |
| `PUT` | `/:id` | Update customer |
| `DELETE` | `/:id` | Delete customer |

### Karigars — `/api/karigars`
| Method | Path | Description |
|---|---|---|
| `GET` | `/` | List all karigars |
| `POST` | `/` | Create karigar |
| `GET` | `/:id` | Karigar details + order performance stats |
| `PUT` | `/:id` | Update karigar |
| `DELETE` | `/:id` | Delete karigar |

### Other Resources
| Prefix | Resource | Description |
|---|---|---|
| `/api/machines` | Machine registry | Machine management & maintenance tracking |
| `/api/inventory` | Inventory & Accessories | Fabric, thread, and lining (astar) stock tracking |
| `/api/ledger` | Ledger (Khata) | Income/expense ledger entries with category breakdown |
| `/api/deliveries` | Delivery tracking | Courier and in-person delivery status per order |
| `/api/notifications` | In-app notifications | Shop alert feed |
| `/api/shops` | Multi-shop management | Create, switch, and manage multiple boutique branches |
| `/api/dashboard` | Dashboard stats | Aggregated revenue, active orders, and upcoming deliveries |
| `/api/upload` | Supabase storage | Generates signed URLs for secure media uploads |
| `/api/status` | Health check | Returns API status and database connectivity |

---

## 🗄️ Key Data Patterns

### Order Auto-ID
Orders receive formatted human-readable identifiers such as `ORD-001` alongside UUID primary keys.

### Payment Synchronization
Payments are **never updated directly**. Every payment creates an immutable `Transaction` record, and `syncPaymentFromTransactions()` recalculates total paid, balance, and status (`Pending`, `Partial`, `Paid`).

### Measurement Snapshotting
When an order is created, the customer's current measurement set is snapshotted into `order.measurementsSnapshot`. Subsequent alterations to customer measurements do not modify historic orders.

### Aster (Lining) Inventory Integration
When an order moves to cutting/stitching statuses, required aster quantity is automatically deducted from inventory.
