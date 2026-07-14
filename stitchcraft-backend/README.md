# 🖥️ StitchCraft Backend

Node.js + Express REST API for the StitchCraft tailor shop management platform. Handles authentication, shop data, orders, payments, karigars, inventory, ledger, and file uploads.

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Runtime | Node.js (ESM modules) |
| Framework | Express.js v5 |
| Database | MongoDB via Mongoose v9 |
| Auth | JWT (`jsonwebtoken`) + bcrypt |
| File Storage | Supabase Storage (profile + maap images) |
| Environment | dotenv |
| Dev Server | nodemon |

---

## 📂 Project Structure

```
stitchcraft-backend/
├── config/
│   └── db.js                  # MongoDB connection (Mongoose)
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
│   └── authMiddleware.js      # JWT protect + shop-scope guard
│
├── models/                    # Mongoose schemas
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
│   └── Counter.js             # Auto-increment for order IDs (ORD-xxx)
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
└── server.js                  # App entry point (Express + MongoDB init)
```

---

## 🚀 Setup

### 1. Install dependencies

```bash
npm install
```

### 2. Create `.env`

```env
PORT=5000
NODE_ENV=development
MONGO_URI=mongodb+srv://<user>:<pass>@cluster.mongodb.net/stitchcraft
JWT_SECRET=your_super_secret_jwt_key

# Supabase (for image upload signed URLs)
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
```

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
| `POST` | `/login` | Login, returns JWT |
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
Orders get auto-incremented IDs like `ORD-001`, `ORD-002` using the `Counter` model with a Mongoose pre-save hook.

### Payment Sync
Payments are **never stored directly** — every payment creates a `Transaction` record. The `Payment` document is then **recalculated** from all transactions via `syncPaymentFromTransactions()`. This ensures an immutable audit trail.

### Measurement Snapshot
When an order is created, the customer's current measurements are **snapshotted** into `order.measurementsSnapshot`. This preserves historical accuracy even if measurements are updated later.

### Shop Scoping
Every document has a `shopId` field. The `protect` middleware injects `req.user.shopId` from the JWT, and all queries filter by it — ensuring complete data isolation between shops.

---

## 🌱 Seed Data

```bash
npm run seed
```

Creates a demo shop with sample karigars, machines, inventory items, customers, and orders. Useful for local development and testing.
