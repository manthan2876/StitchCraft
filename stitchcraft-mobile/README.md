# 📱 StitchCraft Mobile

The Flutter mobile application for **StitchCraft** — a full-featured tailor shop management platform for Indian masterji shops and boutiques.

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart SDK `^3.10.7`) |
| Backend API | REST client via `http` package with Supabase bearer-token authentication |
| Auth & Storage | Supabase (`supabase_flutter` 2.16.0 for authentication and sessions; signed Supabase Storage URLs) |
| Local Database | Encrypted SQLite via `sqflite_sqlcipher` 3.0.1 with per-device secure keys |
| Background Sync | `workmanager` 0.10.10; authenticated 15-minute sync on connected networks |
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
- **Offline-First Khata Ledger & Udhar Tracking**: Local SQLite database with AES encryption (`sqflite_sqlcipher`) for tracking income and expenses even without internet connectivity. Includes a dedicated **Udhar (Pending Balances)** ledger displaying customer dues with one-tap WhatsApp payment reminders.
- **Cloud Sync Status Monitor**: `SyncStatusScreen` provides visibility into offline queues (orders, customers, expenses, and inventory), last successful sync timestamps, failed mutation details, and a manual "Sync Now" trigger.
- **Automated Background Sync**: `SyncWorker` is initialized at mobile startup and registers one authenticated, connected periodic task. Failed tasks return failure so the platform can retry.
- **Loss-aware synchronization**: pending creates are pushed, local deletions use authenticated DELETE requests, malformed responses and failed HTTP operations are surfaced, and remote pulls never automatically delete local records.
- **Customer WhatsApp Updates**: Send one-click order confirmations, trial-ready notices, delivery updates, and balance reminders directly to customer WhatsApp numbers.
- **Invoices & Receipts**: Generate, preview, and print PDF invoices or share via system share sheets.
- **Shop & Staff Management**: Manage karigars, sewing machines, fabric/aster inventory, alteration/repair jobs, and multi-role access control (`owner`, `manager`, `staff`, `karigar`).
- **Authentication & Security**: Email/password authentication with password visibility toggles, forgot/reset password recovery dialogs, and AES-encrypted local storage.
- **Multi-Language Support**: Runtime language switching between English (`en`), Hindi (`hi`), and Gujarati (`gu`) using generated localization classes.
- **Onboarding Flow**: Splash screen → Language picker → Feature introduction carousel → Login/Register → Role & Shop Setup.

---

## 📂 Project Structure

```text
stitchcraft-mobile/
├── lib/
│   ├── core/
│   │   ├── config/          # Compile-time environment/API config, database tables, and theme
│   │   ├── localization/    # AppLocalizations delegates and extension helpers
│   │   │   └── generated/   # app_localizations.dart, app_localizations_en.dart, app_localizations_gu.dart, app_localizations_hi.dart
│   │   ├── models/          # Dart domain models (CustomerModel, OrderModel, MeasurementModel, UserModel, RepairJobModel, LiningItemModel)
│   │   ├── services/
│   │   │   ├── auth_service.dart          # Supabase auth & session persistence
│   │   │   ├── database_service.dart      # High-level database orchestrator
│   │   │   ├── database/                  # Modular SQLite extension mixins (customer, measurement, order, user, others)
│   │   │   ├── local_db_service.dart      # SQLCipher-encrypted SQLite connection (v5 schema, foreign keys enabled)
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
│   │   ├── auth/            # LoginScreen (password toggle & reset dialog), RoleSelectionScreen
│   │   ├── dashboard/       # MainNavigationContainer, DashboardScreen, MetricCard, DrawerMenu
│   │   ├── orders/
│   │   │   ├── screens/create_order/
│   │   │   │   ├── step1_garment.dart     # Step 1: Garment selection
│   │   │   │   ├── step2_customer.dart    # Step 2: Customer selection
│   │   │   │   ├── step3_measurements.dart# Step 3: Measurement input
│   │   │   │   ├── step4_material.dart    # Step 4: Material & lining selection
│   │   │   │   └── step5_details.dart     # Step 5: Confirmation & pricing
│   │   │   └── screens/                   # OrderListScreen, OrderDetailsScreen, CustomerListScreen, InvoiceDetailsScreen
│   │   ├── khata/           # KhataScreen, IncomeList, ExpensesList, UdharList (pending balances + WhatsApp reminder)
│   │   ├── shop/            # ShopHubScreen, ShopSetupScreen, KarigarsScreen, MachinesScreen, InventoryScreen
│   │   ├── repairs/         # RepairDashboard
│   │   ├── profile/         # ProfileScreen (profile, shops, settings, security tabs), SyncStatusScreen
│   │   ├── notifications/   # NotificationsScreen
│   │   └── onboarding/      # SplashScreen, LanguageSelectionScreen, OnboardingCarouselScreen
│   │
│   ├── firebase_options.dart.example # Template for Firebase platform setup
│   ├── l10n/                # Localization source files (app_en.arb, app_hi.arb, app_gu.arb)
│   └── main.dart            # Application entry point, compile-time config, Supabase/mobile service init
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
- Firebase configuration for push notifications (optional during local development)
- Production Android keystore and `android/key.properties` for release builds

### 1. Environment Configuration

Copy the example environment configuration file:

```bash
cp env/env.example.json env/dev.json
```

Configure the following variables in `stitchcraft-mobile/env/dev.json`:

```json
{
  "BACKEND_API_URL": "http://10.0.2.2:5000/api",
  "SUPABASE_URL": "https://your-project.supabase.co",
  "SUPABASE_ANON_KEY": "your_supabase_anon_key"
}
```

Use HTTP only for local development. Release builds reject non-HTTPS backend URLs.

> [!NOTE]
> Environment variables are injected at compile time using `--dart-define-from-file=env/dev.json`. No raw `.env` files are bundled inside the APK. Local database encryption is generated dynamically per-device and protected via `FlutterSecureStorage` (Android Keystore / iOS Keychain).

### 2. Firebase configuration (optional)

For local builds without FCM, keep the example configuration. For push notifications,
create platform configuration files locally; they are ignored by Git:

```bash
cp lib/firebase_options.dart.example lib/firebase_options.dart
# Add android/app/google-services.json when using Android FCM.
# Add ios/Runner/GoogleService-Info.plist when using iOS FCM.
```

### 3. Install dependencies & run

```bash
flutter pub get
flutter run --dart-define-from-file=env/dev.json
```

Release builds also require `android/key.properties` and a production keystore;
they intentionally fail instead of falling back to the debug signing key. Release
backend configuration must use HTTPS. Never commit real environment files, Firebase
files, or keystores.

### 4. Verification & Testing

```bash
# Analyze Dart code for issues
flutter analyze

# Run unit and widget tests
flutter test
```

The current tests cover theme values, phone normalization, environment validation,
and `NeoCard` interaction. Device/backend validation is still required for Firebase
notifications, Workmanager execution, API contracts, and release signing.

---

## 🔔 Firebase Setup (FCM Notifications)

If you plan to use Firebase Cloud Messaging for push notifications:

1. Create a project in the [Firebase Console](https://console.firebase.google.com/).
2. For Android: Download `google-services.json` and place it in `android/app/`.
3. For iOS: Download `GoogleService-Info.plist` and place it in `ios/Runner/`.
4. Copy `lib/firebase_options.dart.example` to `lib/firebase_options.dart` and populate with your Firebase credentials.
5. On mobile startup, Firebase, local notifications, and Workmanager initialize
   independently. A failure is logged and does not prevent the app from launching.

The app requests notification permission on mobile. Camera and contacts permissions
are requested by their feature flows; legacy external-storage and full-screen-intent
permissions are not declared globally.

---

## 🌍 Localization

ARB files reside in `lib/l10n/`:
- `app_en.arb` (English)
- `app_hi.arb` (Hindi)
- `app_gu.arb` (Gujarati)

The application provides tri-lingual coverage through generated localization keys.

To update or add strings:
1. Update entries in all three `.arb` files (`app_en.arb`, `app_hi.arb`, `app_gu.arb`).
2. Run Flutter localization generation and review the generated classes in
   `lib/core/localization/generated/`; do not hand-edit generated files.
3. Access translated strings in any widget via `context.loc.<stringKey>`.

---

## 📦 Building for Production

```bash
# Android APK
flutter build apk --release

# Android App Bundle (Google Play Store)
flutter build appbundle --release
```

Before a release build:

1. Create `android/key.properties` locally with production keystore values.
2. Verify `BACKEND_API_URL` uses `https://`.
3. Provide production Firebase files when FCM is enabled.
4. Run `flutter analyze`, `flutter test`, and the Android release build.

The Gradle configuration fails `assembleRelease` and `bundleRelease` when
`android/key.properties` is missing, preventing accidental debug-signed releases.

## Data and recovery behavior

- Local SQLite data is encrypted with a per-device key stored in secure platform storage.
- SQLite foreign-key enforcement is enabled.
- If database recovery or legacy-key migration fails, the existing database is preserved
  and an explicit error is raised; the app does not silently recreate an empty database.
- Remote sync does not prune local records merely because a pull response omits them.
- Web storage is an in-memory compatibility store and is not durable across page reloads;
  Android/iOS are the supported offline-first targets.
