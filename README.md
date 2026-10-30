# 🧵 StitchCraft

[![CI](https://github.com/manthan2876/StitchCraft/actions/workflows/ci.yml/badge.svg)](https://github.com/manthan2876/StitchCraft/actions/workflows/ci.yml)
[![CodeQL](https://github.com/manthan2876/StitchCraft/actions/workflows/codeql.yml/badge.svg)](https://github.com/manthan2876/StitchCraft/actions/workflows/codeql.yml)

StitchCraft is a full-stack tailor shop management platform for Indian masterji
shops. It helps teams manage customers, orders, measurements, karigars,
machines, inventory, payments, deliveries, and the khata ledger from a web
dashboard and a Flutter mobile app.

## Architecture

| Component | Technology | Directory |
| --- | --- | --- |
| Backend API | Node.js, Express, MongoDB/Mongoose, Supabase integrations | [`stitchcraft-backend/`](./stitchcraft-backend/) |
| Web dashboard | React, Vite, Tailwind CSS | [`stitchcraft-frontend/`](./stitchcraft-frontend/) |
| Mobile app | Flutter, Dart, Firebase, Supabase, SQLite | [`stitchcraft-mobile/`](./stitchcraft-mobile/) |

The backend owns authentication, business rules, and persistence. The web
dashboard and mobile app consume the backend API and provide tailored workflows
for shop owners and staff. The mobile app also supports offline data and
device-native notifications where configured.

See the [architecture guide](./docs/ARCHITECTURE.md) for boundaries,
integration points, and deployment notes.

## Repository layout

```text
.
├── .github/                 # CI, CodeQL, Dependabot, and contribution templates
├── docs/                    # Architecture and development documentation
├── stitchcraft-backend/     # Express API and data services
├── stitchcraft-frontend/    # React/Vite web dashboard
├── stitchcraft-mobile/      # Flutter mobile application
├── render.yaml              # Backend deployment configuration
└── vercel.json              # Repository/web deployment configuration
```

## Local development

### Prerequisites

- Node.js 22 or newer and npm
- Flutter SDK compatible with the Dart constraint in
  [`pubspec.yaml`](./stitchcraft-mobile/pubspec.yaml)
- MongoDB and/or the configured Supabase project
- Firebase project credentials for mobile features

### Backend

```bash
cd stitchcraft-backend
npm install
# Create .env locally and add the required values.
npm run dev
```

Configure the variables expected by
[`config/db.js`](./stitchcraft-backend/config/db.js),
[`config/supabase.js`](./stitchcraft-backend/config/supabase.js), and the
authentication middleware. Never commit the resulting `.env` file.

### Web dashboard

```bash
cd stitchcraft-frontend
npm ci
npm run dev
```

Use `npm run lint` and `npm run build` before submitting frontend changes.
The production build is enforced in CI; existing lint findings should be
addressed in focused frontend cleanup changes.

### Mobile app

```bash
cd stitchcraft-mobile
flutter pub get
cp lib/firebase_options.dart.example lib/firebase_options.dart
# Replace the example values with credentials for your Firebase project.
flutter run
```

The generated Firebase configuration and platform signing files are ignored by
Git. See the [mobile README](./stitchcraft-mobile/README.md) for platform
setup details.

## Verification

Run the checks relevant to the area you changed:

```bash
# Backend syntax verification
cd stitchcraft-backend
for file in $(find . -maxdepth 1 -name '*.js' -o -path './config/*.js' -o -path './controllers/*.js' -o -path './middleware/*.js' -o -path './models/*.js' -o -path './routes/*.js' -o -path './services/*.js'); do
  node --check "$file"
done

# Frontend
cd ../stitchcraft-frontend
npm ci
npm run lint
npm run build

# Mobile
cd ../stitchcraft-mobile
flutter pub get
flutter analyze
flutter test
```

Pull requests should describe user-visible changes, configuration or migration
requirements, and the validation performed. See
[`CONTRIBUTING.md`](./CONTRIBUTING.md).

## Deployment

- The backend deployment is described in [`render.yaml`](./render.yaml).
- Frontend deployment settings live in
  [`stitchcraft-frontend/vercel.json`](./stitchcraft-frontend/vercel.json).
- Production credentials must be stored in the hosting provider's secret
  manager, never in the repository.

## Security

Please report vulnerabilities privately as described in
[`SECURITY.md`](./SECURITY.md). Do not open a public issue for a security
vulnerability.

## License

No license has been declared for this repository. Do not redistribute or
reuse the source without permission from the project owner.
