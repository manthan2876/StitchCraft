# 🌐 StitchCraft Frontend

React web dashboard for the StitchCraft tailor shop management platform. Built with React 19, Vite 8, and TailwindCSS v4, featuring order management, customer tracking, measurements, karigar/machine monitoring, payments, khata ledger, and analytics.

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Framework | React 19 |
| Build Tool | Vite 8 |
| Styling | TailwindCSS v4 |
| Routing | React Router DOM v7 |
| Icons | `react-icons` |
| Storage & Auth | Supabase Client (Auth + media uploads) |
| Analytics | `@vercel/analytics` |
| Validation | Form validators with safe non-backtracking regexes (`src/utils/formValidators.js`) |
| Testing | Node.js native test runner (`node --test`) for unit and validation suites |
| i18n | Custom `LanguageContext` (English, Hindi, Gujarati) |
| Theme | Custom `ThemeContext` (Dark / Light mode) |

---

## 📂 Project Structure

```text
stitchcraft-frontend/
├── src/
│   ├── pages/                    # Full-page route components
│   │   ├── Dashboard.jsx         # Home — stats, charts, recent orders
│   │   ├── Orders.jsx            # Order list with status filter + search
│   │   ├── OrderDetails.jsx      # Order detail view + notes + payment
│   │   ├── NewOrder.jsx          # 3-step order creation wizard
│   │   ├── EditOrder.jsx         # Edit existing order
│   │   ├── Customers.jsx         # Customer list + search
│   │   ├── CustomerDetails.jsx   # Customer profile + measurement history
│   │   ├── Karigars.jsx          # Karigar list + performance cards
│   │   ├── KarigarDetails.jsx    # Karigar detail + order history
│   │   ├── Machines.jsx          # Machine registry
│   │   ├── Inventory.jsx         # Inventory / accessories / aster stock
│   │   ├── Payments.jsx          # Payment tracking across orders
│   │   ├── Ledger.jsx            # Income & expense ledger
│   │   ├── Invoices.jsx          # Invoice list
│   │   ├── InvoiceDetails.jsx    # Full invoice view
│   │   ├── PublicInvoice.jsx     # Shareable invoice (no login required)
│   │   ├── Delivery.jsx          # Delivery tracking
│   │   ├── Notifications.jsx     # In-app notifications
│   │   ├── Profile.jsx           # User profile + settings + shop management
│   │   ├── Login.jsx             # Login screen
│   │   ├── Signup.jsx            # Registration screen
│   │   └── NotFound.jsx          # 404 page
│   │
│   ├── features/                 # Feature-scoped logic (hooks + components)
│   │   ├── dashboard/
│   │   │   ├── hooks/            # useDashboard.js
│   │   │   └── components/       # Stat cards, charts, quick-action panels
│   │   ├── orders/
│   │   │   ├── hooks/            # useOrderDetails.js, useNewOrder.js
│   │   │   └── components/       # PaymentModal, DeleteOrderModal
│   │   ├── inventory/
│   │   │   └── hooks/            # useInventory.js
│   │   └── profile/
│   │       ├── hooks/            # useProfile.js (settings, shops, privacy, password)
│   │       └── components/       # ProfileTab, SettingsTab, ShopsTab, SecurityTab
│   │
│   ├── components/               # Shared UI components
│   │   └── common/
│   │       ├── Card.jsx          # Base card with consistent styling
│   │       ├── Layout.jsx        # App shell (sidebar + topbar)
│   │       └── ...
│   │
│   ├── context/                  # React context providers
│   │   ├── AuthContext.jsx       # User auth state via Supabase session
│   │   ├── ThemeContext.jsx      # Dark / light mode toggle
│   │   └── LanguageContext.jsx   # i18n — EN / HI / GU translations
│   │
│   ├── services/
│   │   ├── api.js                # Fetch-based API client (get, post, put, delete)
│   │   └── supabase.js           # Supabase client + getSignedUrl helper
│   │
│   ├── utils/
│   │   ├── formatters.js         # formatCurrency, formatDate helpers
│   │   └── formValidators.js     # Form field validations (email, phone, required, bounds)
│   │
│   ├── App.jsx                   # Route definitions + auth guards
│   ├── main.jsx                  # App entry point (Vercel Analytics init)
│   └── index.css                 # TailwindCSS v4 + global design tokens
│
├── test/                         # Unit tests
│   ├── form_validators.test.js   # Validation helper test suite
│   └── formatters.test.js        # Formatting helper test suite
│
├── eslint.config.js              # ESLint configuration
└── vite.config.js                # Vite configuration
```

---

## 🚀 Setup & Commands

### 1. Install dependencies

```bash
npm ci
```

### 2. Configure `.env`

Copy `.env.example` or create `.env`:

```env
# Backend API URL
VITE_API_URL=http://localhost:5000/api

# For production, point to the Render backend:
# VITE_API_URL=https://stitchcraft-backend.onrender.com/api

# Supabase (for image uploads and browser authentication)
VITE_SUPABASE_URL=https://qggxfxttveafgptdlmfu.supabase.co
VITE_SUPABASE_ANON_KEY=your_supabase_publishable_or_anon_key
```

### 3. Run

```bash
npm run dev       # Start development server with HMR (http://localhost:5173)
npm run lint      # Run ESLint across code files
npm test          # Run frontend unit tests (form validators, formatters)
npm run build     # Compile production build to dist/
npm run preview   # Preview production build locally
```

---

## 🛡️ Form Validation & Security

Frontend form inputs are validated using [`src/utils/formValidators.js`](./src/utils/formValidators.js):
- **Email Validation**: Protected against Polynomial ReDoS using deterministic regular expressions and an RFC 5321 length check (`<= 254` characters).
- **Phone Validation**: Ensures valid Indian and international mobile numbers (10 digits).
- **Password Strength**: Minimum 6 characters required.
- **Numeric & Range Checks**: Validates prices, quantities, and measurement dimensions.
- **Sensitive Data Storage**: Session tokens are managed securely through Supabase Auth's session state, avoiding raw credential persistence in `localStorage`.

---

## 🔑 Key Pages & Features

### Dashboard
- Revenue statistics, active orders by production stage, upcoming delivery deadlines.
- Quick action controls (New Order, Add Karigar, View Khata).
- Configurable widgets (toggleable in Settings).

### Orders (`/orders`)
- Table and card views with live search (order ID, customer, apparel).
- Production status workflow: **Incoming → Measuring → Cutting → Stitching → Checking → Ready → Delivered → Cancelled**.
- Quick status change dropdown and filtering.

### Order Details (`/orders/:id`)
- Order specifications: apparel type, fabric, karigar, machine, and aster requirements.
- Customer measurements snapshot and maap (measurement) image attachment.
- Payment tracker with balance calculator and payment modal.
- Internal timestamped order notes timeline.

### New Order Wizard (`/new-order`)
- **Step 1 — Garment Details**: Apparel category, pricing, delivery date, urgency.
- **Step 2 — Measurements**: Shirt, pant, or custom measurements + maap photo upload.
- **Step 3 — Material & Assignment**: Fabric type, astar lining assignment, karigar assignment.

### Public Invoice (`/invoice/share/:id`)
- Shareable client-facing invoice link requiring no login.
- Displays shop branding, order items, payment status, and balance.

---

## 🌍 Internationalization

Supported languages:
- **English** (`en`)
- **Hindi** (`hi`)
- **Gujarati** (`gu`)

Translations are maintained in [`src/context/LanguageContext.jsx`](./src/context/LanguageContext.jsx). Use the `useLanguage` hook:

```jsx
const { t } = useLanguage();
return <button>{t('save')}</button>;
```

---

## 🚢 Deployment (Vercel)

The repository root includes [`vercel.json`](../vercel.json) for client-side SPA routing rewrites.

Set these environment variables in the Vercel Project Settings:

```text
VITE_API_URL=https://stitchcraft-backend.onrender.com/api
VITE_SUPABASE_URL=https://qggxfxttveafgptdlmfu.supabase.co
VITE_SUPABASE_ANON_KEY=your_supabase_publishable_or_anon_key
```
