# 🧵 StitchCraft

[![CI](https://github.com/manthan2876/StitchCraft/actions/workflows/ci.yml/badge.svg)](https://github.com/manthan2876/StitchCraft/actions/workflows/ci.yml)
[![CodeQL](https://github.com/manthan2876/StitchCraft/actions/workflows/codeql.yml/badge.svg)](https://github.com/manthan2876/StitchCraft/actions/workflows/codeql.yml)

StitchCraft is a full-stack, multi-tenant tailor shop management platform designed for Indian masterji shops and boutiques. It unifies customer profiles, custom measurements, order workflows, karigar performance, machine maintenance, fabric/aster inventory, payments, delivery tracking, staff and role management, udhar / pending balance recovery, and the khata ledger across a web dashboard and a Flutter mobile app with full tri-lingual localization (English, Gujarati, Hindi).

---

## 🏛️ Architecture

| Component | Technology | Directory |
| --- | --- | --- |
| **Backend API** | Node.js 22, Express v5, Supabase PostgreSQL, Supabase Auth/Storage, Helmet, Multi-tier Rate Limiting | [`stitchcraft-backend/`](./stitchcraft-backend/) |
| **Web Dashboard** | React 19, Vite 8, Tailwind CSS v4, React Router v7, Vercel Analytics, Tri-lingual i18n | [`stitchcraft-frontend/`](./stitchcraft-frontend/) |
| **Mobile App** | Flutter, Dart, Supabase Auth, Encrypted SQLite (`sqflite_sqlcipher`), Workmanager, WhatsApp integration, Localizations | [`stitchcraft-mobile/`](./stitchcraft-mobile/) |

- The **Backend API** manages authentication, password recovery, business logic, tenant isolation (`shopId: req.user.shopId`), multi-role access control (`owner`, `manager`, `karigar`, `staff`), shop staff invitation and role delegation, udhar balance aggregation, and transactional database mutations.
- The **Web Dashboard** offers an administrative workspace with real-time analytics, staff management, udhar recovery with WhatsApp reminders, shop branding & invoice configuration (UPI QR, GSTIN, invoice prefixes), a 3-step order wizard, sanitized tokenized guest public invoices (`/invoice/public/:token`), full i18n (`en`, `gu`, `hi`), and data export/conflict-checked import tools.
- The **Mobile App** provides workshop-floor tracking, a 5-step order creation wizard with voice notes, an offline AES-encrypted khata ledger, udhar balances with one-tap WhatsApp reminders, cloud sync status monitor, role selection, periodic background sync via `workmanager`, direct customer WhatsApp updates, and PDF receipt printing.

For system boundaries, validation layers, and security architecture, see the [Architecture Guide](./docs/ARCHITECTURE.md).

---

## 📂 Repository Layout

```text
.
├── .github/                 # CI workflows, CodeQL scanning, and PR templates
├── docs/                    # Architecture and development documentation
├── stitchcraft-backend/     # Express API, Supabase models, validators, services, and tests
├── stitchcraft-frontend/    # React/Vite web dashboard with TailwindCSS v4
├── stitchcraft-mobile/      # Flutter cross-platform mobile application
├── supabase/                # PostgreSQL relational database migrations
├── render.yaml              # Render backend deployment specification
└── vercel.json              # Vercel web deployment and SPA rewrite rules
```

---

## 🚀 Quick Start & Local Development

### Prerequisites

- **Node.js**: `v22.x` or newer and npm
- **Flutter SDK**: `v3.10+` compatible with Dart constraint in [`pubspec.yaml`](./stitchcraft-mobile/pubspec.yaml)
- **Supabase Project**: Configured with PostgreSQL, Auth, and Storage

### 1. Backend (`stitchcraft-backend`)

```bash
cd stitchcraft-backend
npm ci
cp .env.example .env
npm run dev     # Starts server on http://localhost:5000
npm test        # Runs 37 automated tests across 14 test suites
```

### 2. Web Dashboard (`stitchcraft-frontend`)

```bash
cd stitchcraft-frontend
npm ci
cp .env.example .env
npm run dev     # Starts Vite dev server on http://localhost:5173
npm test        # Runs 18 validation and formatter unit tests
npm run build   # Validates production build
```

### 3. Mobile App (`stitchcraft-mobile`)

```bash
cd stitchcraft-mobile
cp .env.example .env
cp lib/firebase_options.dart.example lib/firebase_options.dart
flutter pub get
flutter run     # Launches on connected emulator or device
flutter test    # Runs unit and widget tests
```

---

## 🧪 Verification & CI

All pull requests run automated CI workflows defined in [`.github/workflows/ci.yml`](./.github/workflows/ci.yml). Run these commands locally before submitting:

```bash
# 1. Backend verification (syntax check + 37 automated tests)
cd stitchcraft-backend
find . -name node_modules -prune -o -type f -name '*.js' -print0 | xargs -0 -n1 node --check
npm test

# 2. Frontend verification (ESLint + 18 unit tests + production build)
cd ../stitchcraft-frontend
npm run lint
npm test
npm run build

# 3. Mobile verification (analyze + tests)
cd ../stitchcraft-mobile
cp lib/firebase_options.dart.example lib/firebase_options.dart
cp env/env.example.json env/dev.json
flutter analyze
flutter test
```

---

## 🔒 Security & Code Quality

- **Zero Open CodeQL Alerts**: Validated against CodeQL code scanning, secret scanning, and Dependabot.
- **Two-Tier Validation**: Request validation middleware combined with schema-level table validators across all collections.
- **Safe Regular Expressions**: Linear-time, non-backtracking patterns with bounded input lengths to eliminate ReDoS vulnerabilities.
- **Multi-Tier Rate Limiting**: Strict limits on authentication & password recovery (10 / 15m), file uploads (30 / 15m), destructive actions (10 / 15m; applies to account deletion, data import, and all `DELETE` endpoints), and general API calls (300 / 15m).
- **Tenant Isolation & Role Delegation**: Every database interaction is scoped by `shopId: req.user.shopId` to prevent cross-tenant data access, with role-based policies (`owner`, `manager`, `staff`, `karigar`).
- **Data Sanitization**: Guest-accessible public invoice endpoints (`/api/invoices/public/:token`) strictly strip internal profit margins, wholesale fabric costs, and staff assignments while providing dynamic UPI payment QR codes.
- **Tri-Lingual Localization**: Native English, Gujarati, and Hindi support across Web (558 synchronized translation keys) and Mobile (118 AppLocalizations getters).

For vulnerability reporting guidelines, see [`SECURITY.md`](./SECURITY.md).

---

## 📖 Further Documentation

- [Development Guide](./docs/DEVELOPMENT.md) — Step-by-step setup, coding conventions, and PR guidelines.
- [Architecture Guide](./docs/ARCHITECTURE.md) — System boundaries, validation pipeline, and deployment topology.
- [Contributing Guidelines](./CONTRIBUTING.md) — Guidelines for contributing code and improvements.
- [Backend Documentation](./stitchcraft-backend/README.md) — API endpoints, schema models, and database patterns.
- [Frontend Documentation](./stitchcraft-frontend/README.md) — Component architecture, state management, and design system.
- [Mobile Documentation](./stitchcraft-mobile/README.md) — Flutter architecture, offline khata, and device setup.

---

## 📄 License

No license has been declared for this repository. Do not redistribute or reuse the source without permission from the project owner.
