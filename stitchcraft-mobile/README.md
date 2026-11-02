# 📱 StitchCraft Mobile

The Flutter mobile application for **StitchCraft** — a full-featured tailor shop management platform for Indian masterji shops and boutiques.

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart SDK `^3.10.7`) |
| Backend API | REST client via `http` package with bearer token authentication |
| Auth & Storage | Supabase (`supabase_flutter` 2.16.0 for auth; signed Supabase Storage URLs) |
| Local Database | Encrypted SQLite via `sqflite_sqlcipher` 3.0.1 (AES encryption) |
| Background Sync | `workmanager` 0.10.10 (periodic 15-minute background REST sync) |
| WhatsApp Integration | `url_launcher` 6.3.1 (direct customer order updates via `wa.me`) |
| Push & Local Alerts | `firebase_messaging` 16.1.1 + `flutter_local_notifications` 18.0.1 |
| PDF & Printing | `pdf` 3.11.1 + `printing` 5.13.2 (receipt and invoice generation) |
| Scanning & Voice | `mobile_scanner` 5.0.0 (QR/barcode) + `speech_to_text` 7.0.0 (voice notes) |
| Image Compression | `flutter_image_compress` 2.3.0 + `image_picker` 1.0.7 |
| State & Charts | `provider` 6.0.0 + `fl_chart` 1.3.0 |
| i18n | Flutter Localizations (English, Hindi, Gujarati via ARB files) |
| Theme | Custom `AppTheme` (Masterji Dark and Light themes) |

---

## ✨ Features

- **5-Step Order Creation Wizard**:
  - **Step 1 — Garment Selection**: Choose apparel category and preset styles.
  - **Step 2 — Customer Selection**: Select existing client or register a new customer profile.
  - **Step 3 — Measurement Input**: Body measurements with voice input support (`VoiceTextField`) and photo attachment.
  - **Step 4 — Material Selection**: Fabric details, lining (astar) assignment, and karigar selection.
  - **Step 5 — Order Confirmation**: Final pricing, advance payment, delivery date, and urgency settings.
- **Order Pipeline & Tracking**: Track all 8 stages from *Incoming* to *Delivered*.
- **Offline-First Khata Ledger**: Local SQLite database with AES encryption (`sqflite_sqlcipher`) for tracking income and expenses even without internet connectivity.
- **Automated Background Sync**: `SyncWorker` powered by `workmanager` automatically syncs pending local records when network connectivity is restored.
- **Customer WhatsApp Updates**: Send one-click order confirmations, trial-ready notices, and delivery updates directly to customer WhatsApp numbers.
- **Invoices & Receipts**: Generate, preview, and print PDF invoices or share via system share sheets.
- **Shop Management**: Manage karigars, sewing machines, fabric/aster inventory, and alteration/repair jobs.
- **Multi-Language Support**: Runtime language switching between English (`en`), Hindi (`hi`), and Gujarati (`gu`).
- **Onboarding Flow**: Splash screen → Language picker → Feature introduction carousel → Login/Register → Role & Shop Setup.

---

## 📂 Project Structure

```text
stitchcraft-mobile/
├── lib/
│   ├── core/
│   │   ├── config/          # ApiConfig (reads BACKEND_API_URL from .env), database_tables.dart, theme.dart
│   │   ├── localization/    # AppLocalizations delegates & extension helpers
│   │   ├── models/          # Dart domain models (CustomerModel, OrderModel, MeasurementModel, UserModel, RepairJobModel, LiningItemModel)
│   │   ├── services/
│   │   │   ├── auth_service.dart          # Supabase auth & session persistence
│   │   │   ├── database_service.dart      # High-level database orchestrator
│   │   │   ├── database/                  # Modular SQLite extension mixins (customer, measurement, order, user, others)
│   │   │   ├── local_db_service.dart      # SQLCipher-encrypted SQLite connection (v5 schema)
│   │   │   ├── sync_service.dart          # REST API bi-directional sync logic
│   │   │   ├── sync_worker.dart           # Workmanager background sync callback
│   │   │   ├── whatsapp_service.dart      # WhatsApp URL launcher integration
│   │   │   ├── pdf_service.dart           # PDF document generator and printing handler
│   │   │   ├── notification_service.dart  # Local notification scheduler & FCM handler
│   │   │   ├── profile_service.dart       # User profile and shop preferences
│   │   │   ├── localization_service.dart  # Locale notifier (en, hi, gu)
│   │   │   └── theme_service.dart         # Theme mode notifier
│   │   ├── theme/           # AppTheme color palettes, typography, button styles
│   │   ├── utils/           # Database seeder, parsing helpers
│   │   └── widgets/         # NeoCard, PrimaryButton, CustomAppBar, VoiceTextField
│   │
│   ├── features/
│   │   ├── auth/            # LoginScreen, RoleSelectionScreen
│   │   ├── dashboard/       # MainNavigationContainer, DashboardScreen, MetricCard, DrawerMenu
│   │   ├── orders/
│   │   │   ├── screens/create_order/
│   │   │   │   ├── step1_garment.dart     # Step 1: Garment selection
│   │   │   │   ├── step2_customer.dart    # Step 2: Customer selection
│   │   │   │   ├── step3_measurements.dart# Step 3: Measurement input
│   │   │   │   ├── step4_material.dart    # Step 4: Material & lining selection
│   │   │   │   └── step5_details.dart     # Step 5: Confirmation & pricing
│   │   │   └── screens/                   # OrderListScreen, OrderDetailsScreen, CustomerListScreen, InvoiceScreen
│   │   ├── khata/           # KhataScreen, IncomeList, ExpensesList, AddExpenseBottomSheet
│   │   ├── shop/            # ShopHubScreen, ShopSetupScreen, KarigarsScreen, MachinesScreen, InventoryScreen
│   │   ├── repairs/         # RepairDashboard
│   │   ├── profile/         # ProfileScreen with profile, shops, settings, and security tabs
│   │   ├── notifications/   # NotificationsScreen
│   │   └── onboarding/      # SplashScreen, LanguageSelectionScreen, OnboardingCarouselScreen
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
BACKEND_API_URL=http://10.0.2.2:5000/api  # Android emulator localhost (or your local IP / production URL)
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_supabase_anon_key
DB_ENCRYPTION_KEY=your_secure_local_database_key_here
```

> [!NOTE]
> `ApiConfig.baseUrl` dynamically reads `BACKEND_API_URL` from `.env`. Never commit the `.env` file.

### 2. Firebase Placeholder (for builds and tests without active FCM)

```bash
cp lib/firebase_options.dart.example lib/firebase_options.dart
```

### 3. Install dependencies & run

```bash
# Get dependencies
flutter pub get

# Run on a connected device/emulator
flutter run

# Run in release mode
flutter run --release
```

### 4. Verification & Testing

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
