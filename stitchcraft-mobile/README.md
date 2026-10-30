# 📱 StitchCraft Mobile

The Flutter mobile application for **StitchCraft** — a full-featured tailor shop management platform for Indian masterji shops.

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart SDK) |
| Backend API | REST via `http` package with bearer token authentication |
| Auth & Storage | Supabase (`supabase_flutter` for authentication; backend-signed storage uploads) |
| Local Storage | SQLite (`sqflite`) for Khata (offline ledger) & caching |
| Push Notifications | Firebase Cloud Messaging (FCM, optional) |
| PDF Generation | `pdf` + `printing` packages |
| Charts | `fl_chart` |
| i18n | Flutter Localizations (English, Hindi, Gujarati) |
| Theme | Custom `AppTheme` (Masterji Dark and Light themes) |

---

## ✨ Features

- **Order Management** — Create orders via a 3-step wizard (Garment → Measurements → Material & Lining).
- **Order Pipeline** — Track all 8 stages from *Incoming* to *Delivered*.
- **Customers & Measurements** — Maintain customer records with measurement histories and maap snapshots.
- **Invoices & Receipts** — View, generate, and share order receipts and invoices.
- **Khata (Ledger)** — Offline-capable income and expense tracker powered by local SQLite.
- **Shop Resources** — Manage karigars, machines, and fabric/aster inventory.
- **Repairs Dashboard** — Track alterations and repair requests.
- **Push & Local Notifications** — Order deadline alerts and shop updates.
- **Onboarding Flow** — Splash screen → Language selection → Feature carousel → Auth.
- **Multi-Language Support** — Seamless runtime switching between English, Hindi, and Gujarati.

---

## 📂 Project Structure

```text
stitchcraft-mobile/
├── lib/
│   ├── core/
│   │   ├── config/          # ApiConfig (reads BACKEND_API_URL from .env), database tables
│   │   ├── localization/    # ARB files & generated localization helpers
│   │   ├── models/          # Dart data models (User, Order, Customer, Khata)
│   │   ├── services/        # AuthService, DatabaseService, ApiService, NotificationService
│   │   ├── theme/           # AppTheme design tokens and palettes
│   │   ├── utils/           # Shared formatters and validators
│   │   └── widgets/         # Reusable NeoCard, buttons, and custom inputs
│   │
│   ├── features/
│   │   ├── auth/            # Login, registration, role selection
│   │   ├── dashboard/       # Home dashboard with overview cards
│   │   ├── orders/          # Order list, 3-step create wizard, invoices, customers
│   │   ├── shop/            # Karigars, machines, inventory management
│   │   ├── khata/           # Expense & income ledger (SQLite)
│   │   ├── repairs/         # Repair dashboard
│   │   ├── profile/         # User profile and shop preferences
│   │   └── onboarding/      # Splash, language selector, onboarding carousel
│   │
│   ├── firebase_options.dart.example # Template for Firebase platform setup
│   ├── l10n/                # Localization source files (app_en.arb, app_hi.arb, app_gu.arb)
│   └── main.dart            # Application entry point, environment loading, Supabase init
│
└── test/
    ├── unit_test.dart       # Unit tests (theming, models)
    └── widget_test.dart     # Widget interaction tests
```

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK compatible with `pubspec.yaml` (`flutter --version`)
- Android SDK with device or emulator (API 21+) / iOS simulator with Xcode (macOS)
- Configured Supabase project

### 1. Environment Configuration

Copy the example environment file and fill in your credentials:

```bash
cp .env.example .env
```

Configure the following variables in `stitchcraft-mobile/.env`:

```env
BACKEND_API_URL=http://10.0.2.2:5000/api  # Android emulator localhost (or local network IP)
SUPABASE_URL=https://qggxfxttveafgptdlmfu.supabase.co
SUPABASE_ANON_KEY=your_supabase_anon_key
```

> [!NOTE]
> `ApiConfig.baseUrl` dynamically reads `BACKEND_API_URL` from `.env`. Never commit the `.env` file.

### 2. Install dependencies & run

```bash
# Get dependencies
flutter pub get

# Run on a connected device/emulator
flutter run

# Run in release mode
flutter run --release
```

### 3. Verification & Testing

```bash
# Analyze Dart code for issues
flutter analyze

# Run unit and widget tests
flutter test
```

---

## 🔔 Optional Firebase Setup (FCM Notifications)

If you plan to use Firebase Cloud Messaging for push notifications:

1. Create a project in the [Firebase Console](https://console.firebase.google.com/).
2. For Android: Download `google-services.json` and place it in `android/app/`.
3. For iOS: Download `GoogleService-Info.plist` and place it in `ios/Runner/`.
4. Copy `lib/firebase_options.dart.example` to `lib/firebase_options.dart` and populate with your Firebase credentials.
5. In CI or local development without push notifications, the example placeholder allows builds and tests to pass cleanly.

---

## 🌍 Localization

ARB files reside in `lib/l10n/`:
- `app_en.arb` (English)
- `app_hi.arb` (Hindi)
- `app_gu.arb` (Gujarati)

To update strings:
1. Update entries in all three `.arb` files.
2. Run `flutter gen-l10n` to regenerate localization classes.
3. Access translated strings via `context.loc.<stringKey>`.

---

## 📦 Building for Production

```bash
# Android APK
flutter build apk --release

# Android App Bundle (Google Play Store)
flutter build appbundle --release
```
