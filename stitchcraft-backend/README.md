# 🖥️ StitchCraft Backend

Node.js + Express REST API for the StitchCraft tailor shop management platform. Handles authentication, shop data, orders, payments, karigars, inventory, ledger, and file uploads.

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Runtime | Node.js (ESM modules) |
| Framework | Express.js v5 |
| Database | Supabase PostgreSQL via the service-role API |
| Auth | Supabase Auth access tokens |
| File Storage | Supabase Storage (profile + maap images) |
| Environment | dotenv |
| Dev Server | nodemon |

---

## 📂 Project Structure

```
stitchcraft-backend/
├── config/
│   └── db.js                  # Supabase database configuration check
│
├── controllers/               # Route handler logic
│   ├── authController.js      # Register, login, me, update profile
│   ├── orderController.js     # CRUD orders, payments, notes, public invoice
│   ├── customerController.js  # CRUD customers + measurements
│   ├── karigarController.js   # CRUD karigars + performance stats
│   ├── machineController.js   # CRUD machines
│   ├── inventoryController.js # CRUD inventory items
│   ├── ledgerController.js    # Ledger entries (income/expense)
│   ├── deliveryController.js  # Delivery tracking per order
│   ├── dashboardController.js # Aggregated stats for dashboard
│   ├── notificationController.js # In-app notifications
│   ├── shopController.js      # Multi-shop management
│   └── uploadController.js    # Supabase signed URL generation
│
├── middleware/
│   └── authMiddleware.js      # Supabase Auth protect + shop-scope guard
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
│   ├── Payment.js             # Synced from Transactions
│   ├── Transaction.js         # Immutable payment ledger per order
│   ├── LedgerEntry.js         # Shop-level income/expense entries
│   ├── Delivery.js
│   ├── Notification.js
│   ├── ActionLog.js           # Audit trail for order status changes
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
│   └── accountService.js     # Account deletion + data conflict resolution
│
├── seed.js                    # Seeds DB with demo shop, karigars, orders
└── server.js                  # App entry point (Express + Supabase init)
```

---

## 🚀 Setup

### 1. Install dependencies

```bash
npm ci
```

### 2. Create `.env`

```env
PORT=5000
NODE_ENV=development
# Supabase database, authentication, and storage
SUPABASE_URL=https://qggxfxttveafgptdlmfu.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
CLIENT_URL=http://localhost:5173
```

### Render deployment

The backend now uses Supabase as its only application database. Configure:

```text
SUPABASE_URL=https://qggxfxttveafgptdlmfu.supabase.co
SUPABASE_SERVICE_ROLE_KEY=<server-only-service-role-key>
CLIENT_URL=<frontend-origin>
```

Apply the SQL migration in `supabase/migrations` before deploying. The Render
start command must be `node server.js` (or `npm start`), not `npm run dev`.

### 3. Run

```bash
npm run dev     # Development with nodemon hot-reload
npm start       # Production
npm run seed    # Seed database with demo data
```

Server starts on **http://localhost:5000**.

---

## 📡 API Reference

All protected routes require `Authorization: Bearer <token>` header.

### Auth — `/api/auth`
| Method | Path | Description |
|---|---|---|
| `POST` | `/register` | Register new user + create shop |
| `POST` | `/login` | Login through Supabase Auth |
| `GET` | `/me` | Get current user profile |
| `PUT` | `/me` | Update profile (name, phone, avatar) |
| `PUT` | `/me/password` | Change password |
| `POST` | `/me/export` | Export all shop data as JSON |
| `POST` | `/me/import` | Import shop data from JSON |
| `DELETE` | `/me` | Delete account + all shop data |

### Orders — `/api/orders`
| Method | Path | Description |
|---|---|---|
| `GET` | `/` | List all orders (filter: status, urgency) |
| `POST` | `/` | Create new order |
| `GET` | `/:id` | Get order details (with payment, measurements, transactions) |
| `GET` | `/public/:id` | Public order details (no auth — for customer invoice link) |
| `PUT` | `/:id` | Update order (status, karigar, fields) |
| `DELETE` | `/:id` | Delete order + cascade cleanup |
| `POST` | `/:id/payments` | Record a payment transaction |
| `POST` | `/:id/notes` | Add internal note to order |

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
| `GET` | `/:id` | Karigar details + order performance |
| `PUT` | `/:id` | Update karigar |
| `DELETE` | `/:id` | Delete karigar |

### Other Resources
| Prefix | Resource |
|---|---|
| `/api/machines` | Machine registry CRUD |
| `/api/inventory` | Inventory items CRUD |
| `/api/ledger` | Income/expense ledger entries |
| `/api/deliveries` | Delivery tracking per order |
| `/api/notifications` | In-app notifications |
| `/api/shops` | Multi-shop management |
| `/api/dashboard` | Aggregated stats (revenue, order counts, upcoming) |
| `/api/upload` | Supabase signed URL for image uploads |
| `/api/status` | Health check |

---

## 🗄️ Key Data Patterns

### Order Auto-ID
Orders receive application-level public IDs such as `ORD-001` while the record itself
is persisted by the Supabase document adapter.

### Payment Sync
Payments are **never stored directly** — every payment creates a `Transaction` record. The `Payment` document is then **recalculated** from all transactions via `syncPaymentFromTransactions()`. This ensures an immutable audit trail.

### Measurement Snapshot
When an order is created, the customer's current measurements are **snapshotted** into `order.measurementsSnapshot`. This preserves historical accuracy even if measurements are updated later.

### Shop Scoping
Every document has a `shopId` field. The `protect` middleware validates the
Supabase Auth bearer token, resolves the application profile, and all queries
filter by the active shop to ensure data isolation.

---

## 🌱 Seed Data

```bash
npm run seed
```

Creates a demo shop with sample karigars, machines, inventory items, customers, and orders. Useful for local development and testing.
