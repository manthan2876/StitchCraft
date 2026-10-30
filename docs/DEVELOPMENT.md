# 🛠️ StitchCraft Development Guide

This guide outlines the local development setup, workflow standards, testing commands, and environment configuration for StitchCraft.

---

## 📋 Prerequisites

- **Node.js**: `v22.x` or newer (`node -v`)
- **npm**: `v10.x` or newer (`npm -v`)
- **Flutter SDK**: `v3.10+` compatible with Dart constraint in `pubspec.yaml` (`flutter --version`)
- **Supabase Account**: A Supabase project with PostgreSQL, Auth, and Storage enabled
- **Git**: Configured with proper user details

---

## 🚀 Local Setup

### 1. Clone the repository

```bash
git clone https://github.com/manthan2876/StitchCraft.git
cd StitchCraft
```

### 2. Backend Setup (`stitchcraft-backend`)

```bash
cd stitchcraft-backend
npm ci

# Configure environment
cp .env.example .env
```

Ensure `.env` contains:
```env
PORT=5000
NODE_ENV=development
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-supabase-service-role-key
CLIENT_URL=http://localhost:5173
```

Start backend services:
```bash
npm run dev     # Starts with nodemon at http://localhost:5000
npm run seed    # (Optional) Populates sample shop, customer, and order data
```

### 3. Frontend Setup (`stitchcraft-frontend`)

```bash
cd ../stitchcraft-frontend
npm ci

# Configure environment
cp .env.example .env
```

Ensure `.env` contains:
```env
VITE_API_URL=http://localhost:5000/api
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-supabase-anon-key
```

Start the frontend dashboard:
```bash
npm run dev     # Starts Vite dev server at http://localhost:5173
```

### 4. Mobile Setup (`stitchcraft-mobile`)

```bash
cd ../stitchcraft-mobile
flutter pub get

# Configure environment
cp .env.example .env
```

Ensure `.env` contains:
```env
BACKEND_API_URL=http://10.0.2.2:5000/api  # Android emulator (or your local IP)
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key
```

Run on a connected simulator or device:
```bash
flutter run
```

---

## 🧪 Testing & Verification

Always run the verification commands for the modules you touched before submitting a pull request:

### Backend Checks
```bash
cd stitchcraft-backend

# 1. Run automated test suites (order lifecycle, ledger, security, shop isolation)
npm test

# 2. Check JavaScript syntax on backend files
find . -name node_modules -prune -o -type f -name '*.js' -print0 | xargs -0 -n1 node --check
```

### Frontend Checks
```bash
cd stitchcraft-frontend

# 1. Run ESLint
npm run lint

# 2. Run unit tests (form validators, formatters)
npm test

# 3. Verify production build
npm run build
```

### Mobile Checks
```bash
cd stitchcraft-mobile

# 1. Analyze Dart code
flutter analyze

# 2. Run unit and widget tests
flutter test
```

---

## 🌿 Git & Pull Request Workflow

1. **Branch Naming**:
   - `feat/feature-name`
   - `fix/issue-description`
   - `docs/documentation-update`
   - `refactor/component-name`
   - `ci/workflow-change`
2. **Commit Messages**:
   Follow conventional commits:
   - `feat: add order status transition hooks`
   - `fix(security): resolve polynomial ReDoS in email validator`
   - `docs: update development guide`
   - `test: add tenant isolation unit test`
3. **Pull Request Checklist**:
   - Link related issue (e.g., `Closes #21`).
   - Describe what changed and why.
   - Confirm all module checks and tests passed.
   - Verify that **no secrets, API keys, or `.env` files** are included in commits.
