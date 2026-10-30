# 🧵 StitchCraft

[![CI](https://github.com/manthan2876/StitchCraft/actions/workflows/ci.yml/badge.svg)](https://github.com/manthan2876/StitchCraft/actions/workflows/ci.yml)
[![CodeQL](https://github.com/manthan2876/StitchCraft/actions/workflows/codeql.yml/badge.svg)](https://github.com/manthan2876/StitchCraft/actions/workflows/codeql.yml)

StitchCraft is a full-stack, multi-tenant tailor shop management platform designed for Indian masterji shops and boutiques. It unifies customer profiles, custom measurements, order workflows, karigar performance, machine maintenance, fabric/aster inventory, payments, delivery tracking, and the khata ledger across a web dashboard and a Flutter mobile app.

---

## 🏛️ Architecture

| Component | Technology | Directory |
| --- | --- | --- |
| **Backend API** | Node.js 22, Express v5, Supabase PostgreSQL, Supabase Auth/Storage, Helmet, Rate Limiter | [`stitchcraft-backend/`](./stitchcraft-backend/) |
| **Web Dashboard** | React 19, Vite 8, Tailwind CSS v4, React Router v7, Vercel Analytics | [`stitchcraft-frontend/`](./stitchcraft-frontend/) |
| **Mobile App** | Flutter, Dart, Supabase Auth, SQLite (`sqflite`), Firebase FCM (optional) | [`stitchcraft-mobile/`](./stitchcraft-mobile/) |

- The **Backend API** manages authentication, business logic, tenant isolation (`shopId`), and database mutations.
- The **Web Dashboard** offers an administrative workspace with real-time analytics, order pipelines, and public invoice sharing.
- The **Mobile App** provides workshop-floor tracking, quick order wizards, offline khata ledger access, and notification alerts.

For system boundaries, validation layers, and security architecture, see the [Architecture Guide](./docs/ARCHITECTURE.md).

---

## 📂 Repository Layout

```text
.
├── .github/                 # CI workflows, CodeQL scanning, and PR templates
├── docs/                    # Architecture and development documentation
├── stitchcraft-backend/     # Express API, Supabase models, validators, and tests
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
npm test        # Runs backend automated test suites
```

### 2. Web Dashboard (`stitchcraft-frontend`)

```bash
cd stitchcraft-frontend
npm ci
cp .env.example .env
npm run dev     # Starts Vite dev server on http://localhost:5173
npm test        # Runs frontend validation and formatter tests
npm run build   # Validates production build
```

### 3. Mobile App (`stitchcraft-mobile`)

```bash
cd stitchcraft-mobile
flutter pub get
cp .env.example .env
flutter run     # Launches on connected emulator or device
flutter test    # Runs unit and widget tests
```

---

## 🧪 Verification & CI

All pull requests run automated CI workflows defined in [`.github/workflows/ci.yml`](./.github/workflows/ci.yml). Run these commands locally before submitting:

```bash
# 1. Backend verification (syntax + tests)
cd stitchcraft-backend
find . -name node_modules -prune -o -type f -name '*.js' -print0 | xargs -0 -n1 node --check
npm test

# 2. Frontend verification (lint + tests + build)
cd ../stitchcraft-frontend
npm run lint
npm test
npm run build

# 3. Mobile verification (analyze + tests)
cd ../stitchcraft-mobile
flutter analyze
flutter test
```

---

## 🔒 Security & Code Quality

- **Zero Open CodeQL Alerts**: Validated against CodeQL code scanning, secret scanning, and Dependabot.
- **Two-Tier Validation**: Request validation middleware combined with schema-level table validators.
- **Safe Regular Expressions**: Linear-time, non-backtracking patterns with bounded input lengths to eliminate ReDoS vulnerabilities.
- **Multi-Tier Rate Limiting**: Strict limits on authentication, file uploads, destructive actions, and general API calls.
- **Tenant Isolation**: Every database interaction is scoped by `shopId` to prevent cross-tenant data access.

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
