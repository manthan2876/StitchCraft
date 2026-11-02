# 🌐 StitchCraft Frontend

React web dashboard for the StitchCraft tailor shop management platform. Built with React 19, Vite 8, and TailwindCSS v4, featuring order management, customer tracking, measurements, karigar/machine monitoring, payments, khata ledger, and analytics.

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Framework | React 19.3.1 |
| Build Tool | Vite 8.3.5 |
| Styling | TailwindCSS v4.3.3 (via `@tailwindcss/vite`) |
| Routing | React Router DOM v7.18.5 |
| Icons | `react-icons` 5.7.0 |
| Storage & Auth | Supabase Client (`@supabase/supabase-js` 2.118.0) |
| Analytics | `@vercel/analytics` 2.0.1 |
| Validation | Form validators with safe non-backtracking regexes (`src/utils/formValidators.js`) |
| Testing | Node.js native test runner (`node --test`) for unit and validation suites |
| i18n | Custom `LanguageContext` (English, Hindi, Gujarati via locale JSONs) |
| Theme | Custom `ThemeContext` (Dark / Light mode) |

---

## 📂 Project Structure

```text
stitchcraft-frontend/
├── src/
│   ├── pages/                    # Full-page route components
│   │   ├── Dashboard.jsx         # Home — stats, charts, recent orders, reminders
│   │   ├── Orders.jsx            # Order list with status filter + search
│   │   ├── OrderDetails.jsx      # Order detail view + notes + payment ledger
│   │   ├── NewOrder.jsx          # 3-step order creation wizard
│   │   ├── EditOrder.jsx         # Edit existing order
│   │   ├── Customers.jsx         # Customer list + search
│   │   ├── CustomerDetails.jsx   # Customer profile + measurement history
│   │   ├── Karigars.jsx          # Karigar list + performance cards
│   │   ├── KarigarDetails.jsx    # Karigar detail + order history
│   │   ├── Machines.jsx          # Machine registry & maintenance status
│   │   ├── Inventory.jsx         # Inventory / accessories / aster stock
│   │   ├── Payments.jsx          # Payment tracking across orders
│   │   ├── Ledger.jsx            # Income & expense khata ledger with journal
│   │   ├── Invoices.jsx          # Invoice list
│   │   ├── InvoiceDetails.jsx    # Full printable invoice view
│   │   ├── PublicInvoice.jsx     # Shareable guest invoice (/invoice/share/:id)
│   │   ├── Delivery.jsx          # Delivery tracking & completion
│   │   ├── Notifications.jsx     # In-app shop alerts
│   │   ├── Profile.jsx           # User profile, shops, security, export/import
│   │   ├── Login.jsx             # User login
│   │   ├── Signup.jsx            # Shop & owner registration
│   │   ├── ForgotPassword.jsx    # Request password recovery email
│   │   ├── ResetPassword.jsx     # Set new password from recovery link
│   │   └── NotFound.jsx          # 404 fallback page
│   │
│   ├── features/                 # Modular feature domains
│   │   ├── dashboard/
│   │   │   ├── hooks/            # useDashboard.js
│   │   │   └── components/       # DashboardCalendar, PerformanceTracker, RemindersPanel, WeeklyStitchingChart
│   │   ├── orders/
│   │   │   ├── hooks/            # useOrderDetails.js, useNewOrder.js
│   │   │   └── components/       # PaymentModal.jsx, DeleteOrderModal.jsx
│   │   ├── inventory/
│   │   │   ├── hooks/            # useInventory.js
│   │   │   └── components/       # InventoryModal.jsx, InventoryDeleteModal.jsx
│   │   └── profile/
│   │       ├── hooks/            # useProfile.js (settings, shops, export/import, password)
│   │       └── components/       # ProfileTab, SettingsTab, ShopInfoTab, ChangePasswordTab,
│   │                             # ShopModal, DeleteShopModal, DataConflictModal,
│   │                             # PrivacyActionConfirmModal, DeletionReasonModal
│   │
│   ├── components/
│   │   ├── common/               # Shared atoms (Button, Card, InputField, Modal)
│   │   ├── layout/               # App shell (AppLayout, Sidebar, Topbar)
│   │   └── specific/             # Domain widgets (CustomerList, LedgerRow, MeasurementForm, RecentOrders, StatCard)
│   │
│   ├── context/                  # React context providers
│   │   ├── AuthContext.jsx       # Supabase session & user profile state
│   │   ├── ThemeContext.jsx      # Dark / light mode toggle
│   │   └── LanguageContext.jsx   # i18n — EN / HI / GU translations
│   │
│   ├── hooks/                    # Reusable React hooks
│   │   ├── useAuth.js            # Auth context consumer
│   │   ├── useCustomers.js       # Customer data management
│   │   └── useLedger.js          # Ledger & financial calculations
│   │
│   ├── services/
│   │   ├── api.js                # Fetch-based API client with auth interceptor
│   │   └── supabase.js           # Supabase client + signed URL helper
│   │
│   ├── utils/
│   │   ├── calculations.js       # Financial & measurement math helpers
│   │   ├── formatters.js         # formatCurrency (₹ INR) & formatDate helpers
│   │   ├── formValidators.js     # Field validation rules (ReDoS-safe email, phone, bounds)
│   │   ├── svgHelpers.js         # SVG asset helpers
│   │   ├── translations.js       # Dictionary translations
│   │   └── validators.js         # Schema validation helpers
│   │
│   ├── config/
│   │   ├── constants.js          # Apparel types, order statuses, units
│   │   └── locales/              # en.json, gu.json, hi.json
│   │
│   ├── styles/                   # Design system tokens & skeuomorphic accents
│   │   ├── variables.css
│   │   └── skeuomorphic.css
│   │
│   ├── App.jsx                   # Route hierarchy and navigation shell
│   ├── main.jsx                  # Application entry point with Vercel Analytics
│   └── index.css                 # TailwindCSS v4 imports & theme root
│
├── test/                         # Native Node.js test runner suites
│   ├── form_validators.test.js   # Form input validation rules & ReDoS safety
│   └── formatters.test.js        # Currency (INR) and date formatting
│
├── eslint.config.js              # ESLint configuration
└── vite.config.js                # Vite configuration with TailwindCSS plugin
```

---

## 🚀 Setup & Commands

### 1. Install dependencies

```bash
npm ci
```

### 2. Configure `.env`

Copy `.env.example` or create `.env`:

```bash
cp .env.example .env
```

Ensure `.env` contains:

```env
# Backend API URL
VITE_API_URL=http://localhost:5000/api

# For production, point to the Render backend:
# VITE_API_URL=https://stitchcraft-backend.onrender.com/api

# Supabase (for authentication and media uploads)
VITE_SUPABASE_URL=https://your-project.supabase.co
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
- **Phone Validation**: Validates Indian and international mobile numbers (10 to 15 digits).
- **Password Strength**: Minimum 6 characters required.
- **Numeric & Range Checks**: Validates prices, quantities, and measurement dimensions.
- **Sensitive Data Storage**: Session tokens are managed securely through Supabase Auth's session state, avoiding raw credential persistence in `localStorage`.

---

## 🔑 Key Pages & Workflows

### Dashboard (`/dashboard`)
- Revenue statistics, active orders by production stage, upcoming delivery deadlines.
- Interactive calendar, weekly stitching activity chart, artisan performance tracker, and reminder feed.
- Quick action shortcuts (New Order, Add Karigar, View Khata).

### Orders Pipeline (`/orders`)
- Table and card views with live search (order ID, customer, apparel).
- Production status progression: **Incoming → Measuring → Cutting → Stitching → Checking → Ready → Delivered → Cancelled**.
- Quick status change dropdown and filtering.

### Order Details (`/orders/:id`)
- Garment specifications, fabric, assigned karigar, machine, and aster requirements.
- Customer measurements snapshot and maap (measurement) image preview.
- Payment tracker with balance calculator and payment modal.
- Internal timestamped order notes timeline.

### New Order Wizard (`/new-order`)
A streamlined 3-step creation wizard:
- **Step 1 — Garment Details**: Apparel category, pricing, delivery deadline, urgency flag.
- **Step 2 — Measurements**: Shirt, pant, or custom measurements + maap photo upload.
- **Step 3 — Material & Assignment**: Fabric type, astar (lining) assignment, karigar assignment.

### Public Invoice (`/invoice/share/:id`)
- Shareable client-facing invoice link requiring no login.
- Resolves by order ID or secure share token.
- Strips internal wholesale costs, profit margins, and artisan assignments to present only customer-facing line items and balance.

### Khata Ledger (`/ledger`)
- Financial summary: total sales, fabric profit, shop expenses, and net profit.
- Chronological journal entries (running cash book).
- Order transaction ledger and category-based expense management.

### Profile & Shop Hub (`/profile`)
- **Profile Tab**: Update personal contact information and avatar.
- **Shop Info & Shops Tab**: Switch active shop branches, create new shops, or delete branches.
- **Settings Tab**: Customizable dashboard widgets.
- **Change Password Tab**: Password updates with verification checks.
- **Data Privacy & Portability**: Export all shop data as JSON, import data with conflict checking (`DataConflictModal`), and account deletion workflows.

---

## 🌍 Internationalization

Supported languages:
- **English** (`en`)
- **Hindi** (`hi`)
- **Gujarati** (`gu`)

Translations are maintained in [`src/config/locales/`](./src/config/locales/) and loaded through [`src/context/LanguageContext.jsx`](./src/context/LanguageContext.jsx). Use the `useLanguage` hook:

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
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your_supabase_publishable_or_anon_key
```
