# 📱 StitchCraft Mobile

The Flutter mobile app for **StitchCraft** — a tailor shop management platform for Indian masterji shops.

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) |
| Backend API | REST via `http` package |
| Local Storage | SQLite (`sqflite`) for Khata / offline data |
| Auth | Firebase Auth + JWT (backend) |
| Push Notifications | Firebase Cloud Messaging (FCM) |
| PDF Generation | `pdf` + `printing` packages |
| Charts | `fl_chart` |
| i18n | Flutter Localizations (EN / HI / GU) |

---

## ✨ Features

- **Order Management** — Create orders via 3-step wizard (Garment → Measurements → Material)
- **Order List** — Filter by all 8 production stages (Incoming → Delivered)
- **Customers** — Customer profiles with measurement history
- **Invoices** — View and share order invoices
- **Khata (Ledger)** — Expense and income tracking (local SQLite)
- **Karigars, Machines, Inventory** — Full shop resource management
- **Repair Dashboard** — Log and track repair orders
- **Notifications** — FCM push + local notification support
- **Onboarding** — Splash → Language → Carousel → Login/Register
- **Localization** — English, Hindi, Gujarati (switchable at runtime)
- **Dark/Light Theme** — System-aware theming via `AppTheme`

---

## 📂 Project Structure

```
lib/
├── core/
│   ├── config/          # App config constants
│   ├── localization/    # ARB files + generated localizations
│   ├── services/        # API, Local DB, Notification, Localization services
│   ├── theme/           # AppTheme (masterji dark theme)
│   └── utils/           # Shared helpers
│
├── features/
│   ├── auth/            # Login, role selection screens
│   ├── dashboard/       # Home dashboard screen
│   ├── orders/          # Order list, create wizard (3 steps), invoices, customers
│   ├── shop/            # Inventory, karigars, machines, shop setup
│   ├── khata/           # Expense & income ledger (local SQLite)
│   ├── repairs/         # Repair dashboard
│   ├── profile/         # Profile screen
│   ├── onboarding/      # Splash, language, carousel screens
│   └── posts/           # (In development)
│
└── main.dart            # App entry point + route map
```

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK **3.10+** (`flutter --version` to check)
- Android SDK with a device/emulator (API 21+)
- Firebase project configured (for push notifications)

### Setup

```bash
# Install dependencies
flutter pub get

# Run on a connected device
flutter run

# Run in release mode
flutter run --release
```

### Firebase Setup

1. Create a project on [Firebase Console](https://console.firebase.google.com/)
2. Add an Android app with your package name
3. Download `google-services.json` and place it in `android/app/`
4. Enable **Firebase Cloud Messaging** in the console

### API Configuration

The backend API base URL is set in:
```
lib/core/config/
```

For local development, set it to your machine's local IP:
```dart
static const String baseUrl = 'http://192.168.x.x:5000/api';
```

---

## 📦 Building

```bash
# Android APK
flutter build apk --release

# Android App Bundle (for Play Store)
flutter build appbundle --release
```

---

## 🌍 Localization

ARB files are in `lib/l10n/`. To add or edit strings:

1. Edit `app_en.arb`, `app_hi.arb`, `app_gu.arb`
2. Run `flutter gen-l10n` to regenerate the localization classes
3. Access strings via `context.loc.yourKey`

---

## 🐛 Common Issues

| Error | Fix |
|---|---|
| `Gradle requires JVM 17` | Set `JAVA_HOME` to JDK 17 or run `flutter config --jdk-dir "path/to/jdk17"` |
| `minSdkVersion` error | Ensure `android/local.properties` has `flutter.minSdkVersion=21` |
| Firebase init crash | Confirm `google-services.json` is in `android/app/` |
| Locale not loading | Run `flutter clean` then `flutter pub get` |
