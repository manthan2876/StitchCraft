# 🧵 StitchCraft

**StitchCraft** is a full-stack tailor shop management platform built for Indian masterji shops. It helps tailors manage orders, customers, karigars, machines, inventory, payments, and the khata (ledger) — all in one place, with a web dashboard and a Flutter mobile app.

---

## 🏗️ Architecture & Tech Stack

The platform is split into three components:

| Component | Technology |
|---|---|
| **Backend** | Node.js + Express.js + MongoDB (Mongoose) |
| **Web Frontend** | React 19 + Vite + TailwindCSS v4 |
| **Mobile App** | Flutter (Dart) + Firebase + SQLite (local) |
| **Auth & Storage** | Supabase (JWT auth + profile image bucket) |
| **Deployment** | Render (backend) + Vercel (frontend) |

---

## ✨ Features

### 🧾 Order Management
- Multi-step order creation wizard (garment → measurements → material)
- Full order lifecycle: `Incoming → Measuring → Cutting → Stitching → Checking → Ready → Delivered → Cancelled`
- Auto-generated order IDs (e.g. `ORD-901`)
- Edit order details, assign karigar & machine
- Internal notes/comments timeline per order

### 👥 Customers & Karigars
- Customer profiles with measurement history (shirt + pant)
- Maap image upload (stored in Supabase)
- Karigar (tailor worker) profiles with performance tracking
- Machine registry

### 💰 Payments & Khata (Ledger)
- Payment recording per order (Cash / UPI / Card)
- Ledger view with income and expense tracking
- Full transaction history per order

### 🧾 Invoices
- Auto-generated invoices per order
- Shareable public invoice link (`/invoice/share/:id`) — no login required for customers

### 📦 Inventory
- Track fabric, accessories, and lining (astar) stock
- Automatic deduction for astar when linked to an order

### 🔔 Notifications
- In-app notifications for payment events and status changes

### 🏪 Shop Management
- Multi-shop support — one account can manage multiple shops
- Shop switching from Profile

### 🌐 Internationalization
- Full i18n support: **English**, **Hindi (हिन्दी)**, **Gujarati (ગુજરાતી)**

### 🎨 Theme
- Light / Dark mode toggle, persisted per user

---

## 📂 Repository Structure

```
StitchCraft/
├── stitchcraft-backend/     # Node.js REST API
│   ├── controllers/         # Route handlers (orders, karigars, inventory, etc.)
│   ├── models/              # Mongoose models (Order, Customer, Karigar, ...)
│   ├── routes/              # Express route definitions
│   ├── services/            # Business logic (order, ledger, account)
│   ├── middleware/          # JWT auth middleware
│   ├── config/              # DB connection
│   ├── seed.js              # Database seeding script
│   └── server.js            # App entry point
│
├── stitchcraft-frontend/    # React web dashboard
│   └── src/
│       ├── pages/           # Full-page views (Dashboard, Orders, Karigars, ...)
│       ├── features/        # Feature-scoped hooks & components
│       │   ├── orders/
│       │   ├── profile/
│       │   ├── dashboard/
│       │   └── inventory/
│       ├── components/      # Shared UI components (Card, Layout, ...)
│       ├── context/         # Auth, Theme, Language context providers
│       ├── services/        # API client + Supabase helpers
│       └── utils/           # Formatters, helpers
│
├── stitchcraft-mobile/      # Flutter mobile app
│   └── lib/
│       ├── features/        # Feature modules
│       │   ├── auth/        # Login, role selection
│       │   ├── orders/      # Order list, create (3-step wizard), invoices
│       │   ├── shop/        # Inventory, karigars, machines
│       │   ├── khata/       # Expenses & income ledger (local SQLite)
│       │   ├── repairs/     # Repair dashboard
│       │   ├── dashboard/
│       │   └── profile/
│       └── core/            # Theme, localization, services
│
├── render.yaml              # Render.com backend deployment config
└── vercel.json              # Vercel frontend deployment config
```

---

## 🚀 Getting Started

### Prerequisites

| Tool | Version |
|---|---|
| Node.js | v18+ |
| npm | v9+ |
| Flutter SDK | v3.10+ |
| MongoDB Atlas | (cloud) or local MongoDB |

---

## ⚙️ 1. Backend Setup

```bash
cd stitchcraft-backend
npm install
```

Create your `.env` file:

```env
PORT=5000
NODE_ENV=development
MONGO_URI=your_mongodb_atlas_connection_string
JWT_SECRET=your_super_secret_jwt_key

# Supabase (for profile image uploads)
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key
```

Start the dev server:

```bash
npm run dev        # Development (nodemon hot-reload)
npm start          # Production
```

Seed the database with sample data (optional):

```bash
npm run seed
```

The backend runs on **http://localhost:5000**.

---

## 🖥️ 2. Frontend Setup

```bash
cd stitchcraft-frontend
npm install
```

Create your `.env` file:

```env
VITE_API_URL=http://localhost:5000/api

# Supabase (for avatar uploads from the web)
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your_supabase_anon_key
```

Start the dev server:

```bash
npm run dev        # Development (Vite HMR)
npm run build      # Production build
npm run preview    # Preview production build locally
```

The frontend runs on **http://localhost:5173**.

---

## 📱 3. Mobile App Setup

```bash
cd stitchcraft-mobile
flutter pub get
```

The mobile app uses **Firebase** for push notifications. Place your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) in the appropriate platform directories.

The API base URL is configured in:
```
stitchcraft-mobile/lib/core/config/
```

Run the app:

```bash
flutter run                    # Run on connected device / emulator
flutter build apk              # Build Android APK
flutter build ios              # Build iOS
```

---

## 🌐 Deployment

### Backend → Render
The `render.yaml` at the repo root configures automatic deployment to [Render.com](https://render.com):
- **Build command**: `npm install`
- **Start command**: `npm start`
- Set all environment variables in the Render dashboard.

### Frontend → Vercel
The `vercel.json` at the repo root configures deployment to [Vercel](https://vercel.com):
- Set `VITE_API_URL` to your Render backend URL (e.g. `https://stitchcraft-backend.onrender.com/api`)
- Vercel auto-detects Vite and handles SPA routing.

---

## 📡 Key API Endpoints

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/api/auth/register` | Register a new user |
| `POST` | `/api/auth/login` | Login, returns JWT |
| `GET` | `/api/orders` | Get all orders (filtered by shop) |
| `POST` | `/api/orders` | Create a new order |
| `PUT` | `/api/orders/:id` | Update order status / details |
| `POST` | `/api/orders/:id/payments` | Record a payment |
| `POST` | `/api/orders/:id/notes` | Add an internal note to an order |
| `GET` | `/api/orders/public/:id` | Public invoice (no auth) |
| `GET` | `/api/customers` | List all customers |
| `GET` | `/api/karigars` | List all karigars |
| `GET` | `/api/inventory` | List inventory items |
| `GET` | `/api/dashboard` | Aggregated dashboard stats |
| `GET` | `/api/ledger` | Ledger entries |

---

## 🗃️ Data Models

| Model | Key Fields |
|---|---|
| `User` | name, email, phone, role, shopId |
| `Shop` | shopName, phone, address, plan |
| `Order` | orderId, customer, apparelType, status, deliveryDate, price, karigar, machine, notes[] |
| `Customer` | name, phone, address |
| `Measurement` | customerId, shirt{}, pant{} |
| `Karigar` | name, phone, specialization |
| `Machine` | name, type, status |
| `Inventory` | itemName, itemType, quantity, costPerUnit |
| `Payment` | orderId, paidAmount, totalAmount, balanceAmount |
| `Transaction` | orderId, amount, paymentType, type |
| `LedgerEntry` | shopId, type, amount, description |
| `Notification` | shopId, message, isRead |

---

## 🌍 Supported Languages

| Language | Code |
|---|---|
| English | `en` |
| Hindi | `hi` |
| Gujarati | `gu` |

Language is persisted per user via `localStorage` (web) and `SharedPreferences` (mobile).

---

## 📝 License

This project is private and proprietary. All rights reserved.
