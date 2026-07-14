# 🌐 StitchCraft Frontend

React web dashboard for the StitchCraft tailor shop management platform. Built with Vite + TailwindCSS v4, featuring full order management, customer tracking, karigar/machine management, payments, ledger, and more.

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Framework | React 19 |
| Build Tool | Vite 8 |
| Styling | TailwindCSS v4 |
| Routing | React Router DOM v7 |
| Icons | `react-icons` |
| Storage | Supabase (avatar + maap image uploads) |
| i18n | Custom `LanguageContext` (EN / HI / GU) |
| Theme | Custom `ThemeContext` (light / dark) |

---

## 📂 Project Structure

```
src/
├── pages/                    # Full-page route components
│   ├── Dashboard.jsx         # Home — stats, charts, recent orders
│   ├── Orders.jsx            # Order list with status filter + search
│   ├── OrderDetails.jsx      # Order detail view + notes + payment
│   ├── NewOrder.jsx          # 3-step order creation wizard
│   ├── EditOrder.jsx         # Edit existing order
│   ├── Customers.jsx         # Customer list + search
│   ├── CustomerDetails.jsx   # Customer profile + measurement history
│   ├── Karigars.jsx          # Karigar list + performance cards
│   ├── KarigarDetails.jsx    # Karigar detail + order history
│   ├── Machines.jsx          # Machine registry
│   ├── Inventory.jsx         # Inventory / accessories
│   ├── Payments.jsx          # Payment tracking across orders
│   ├── Ledger.jsx            # Income & expense ledger
│   ├── Invoices.jsx          # Invoice list
│   ├── InvoiceDetails.jsx    # Full invoice view
│   ├── PublicInvoice.jsx     # Shareable invoice (no login required)
│   ├── Delivery.jsx          # Delivery tracking
│   ├── Notifications.jsx     # In-app notifications
│   ├── Profile.jsx           # User profile + settings + shop management
│   ├── Login.jsx             # Login screen
│   ├── Signup.jsx            # Registration screen
│   └── NotFound.jsx          # 404 page
│
├── features/                 # Feature-scoped logic (hooks + components)
│   ├── dashboard/
│   │   ├── hooks/            # useDashboard.js
│   │   └── components/       # Stat cards, charts, quick-action panels
│   ├── orders/
│   │   ├── hooks/            # useOrderDetails.js, useNewOrder.js
│   │   └── components/       # PaymentModal, DeleteOrderModal
│   ├── inventory/
│   │   └── hooks/            # useInventory.js
│   └── profile/
│       ├── hooks/            # useProfile.js (settings, shops, privacy, password)
│       └── components/       # ProfileTab, SettingsTab, ShopsTab, SecurityTab
│
├── components/               # Shared UI components
│   └── common/
│       ├── Card.jsx          # Base card with consistent styling
│       ├── Layout.jsx        # App shell (sidebar + topbar)
│       └── ...
│
├── context/                  # React context providers
│   ├── AuthContext.jsx       # User auth state + login/logout
│   ├── ThemeContext.jsx      # Dark / light mode toggle
│   └── LanguageContext.jsx   # i18n — EN / HI / GU translations
│
├── services/
│   ├── api.js                # Fetch-based API client (get, post, put, delete)
│   └── supabase.js           # Supabase client + getSignedUrl helper
│
├── utils/
│   └── formatters.js         # formatCurrency, formatDate helpers
│
├── App.jsx                   # Route definitions + auth guards
├── main.jsx                  # App entry point
└── index.css                 # TailwindCSS v4 + global design tokens
```

---

## 🚀 Setup

### 1. Install dependencies

```bash
npm install
```

### 2. Create `.env`

```env
# Backend API (local dev)
VITE_API_URL=http://localhost:5000/api

# For production, use your Render URL:
# VITE_API_URL=https://stitchcraft-backend.onrender.com/api

# Supabase (for image uploads from the browser)
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your_supabase_anon_key
```

### 3. Run

```bash
npm run dev       # Dev server with HMR (http://localhost:5173)
npm run build     # Production build → dist/
npm run preview   # Preview production build locally
npm run lint      # ESLint
```

---

## 🔑 Key Pages & Features

### Dashboard
- Revenue stats, order counts, upcoming deliveries
- Quick-action buttons (New Order, View Karigars)
- Configurable widgets (toggleable via Settings)

### Orders (`/orders`)
- Table view with search (ID / customer / apparel)
- Status filter chips: **All → Incoming → Measuring → Cutting → Stitching → Checking → Ready → Delivered → Cancelled**
- Inline status change dropdown per row

### Order Details (`/orders/:id`)
- Full order info: garment, karigar, machine, material
- Maap (measurement image) viewer
- Payment section: record payment, view balance
- Internal Notes timeline — add timestamped notes per order
- Status change controls

### New Order Wizard (`/new-order`)
- **Step 1** — Garment details (type, price, delivery date, urgency)
- **Step 2** — Measurements (shirt / pant, with maap image upload)
- **Step 3** — Material / astar assignment

### Profile (`/profile`)
- **Profile tab** — Name, phone, avatar upload (Supabase)
- **Settings tab** — Dashboard widget toggles, theme, language
- **Shops tab** — Create / edit / delete / switch shops
- **Security tab** — Change password, export data, delete account

### Public Invoice (`/invoice/share/:id`)
- No login required — shareable link for customers
- Shows full order details, payment status, and shop branding

---

## 🌍 Internationalization

Language is managed via `LanguageContext`. Translations live in:

```
src/context/LanguageContext.jsx  →  translations object (en / hi / gu)
```

To add a new key:
1. Add it to all three language objects in `LanguageContext.jsx`
2. Use `const { t } = useLanguage()` and call `t('yourKey')` in the component

---

## 🎨 Design System

- **Color tokens** defined in `index.css` as CSS custom properties
- **Dark / Light** mode via `.dark` class on `<html>`, toggled by `ThemeContext`
- **Card component** — base container used consistently across all pages
- **btn-tactile** — primary button class with gradient + shadow

---

## 🚢 Deployment (Vercel)

The `vercel.json` at the repo root rewrites all routes to `index.html` for SPA routing.

```bash
# Set these in Vercel dashboard:
VITE_API_URL=https://stitchcraft-backend.onrender.com/api
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your_anon_key
```

Vercel auto-detects Vite and runs `npm run build` on every push to `main`.
