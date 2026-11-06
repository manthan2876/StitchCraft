# 🏛️ StitchCraft — System Architecture Specification

---

## 1. High-Level Architecture Topology

StitchCraft employs a distributed multi-tier architecture consisting of two client presentation applications (React Web Dashboard and Flutter Mobile App), a hardened Express 5 API gateway, and cloud infrastructure hosted on Supabase and Firebase.

```mermaid
graph TB
    subgraph Clients["Presentation Layer (Clients)"]
        Web["Web Dashboard (React 19 / Vite 8 / Tailwind v4)"]
        Mobile["Mobile App (Flutter / Dart / SQLCipher / Workmanager)"]
        PublicUser["Customer Guest (Browser - Public Invoice)"]
    end

    subgraph Edge["Security & Gateway Boundary"]
        CORS["CORS Policy (cors.js)"]
        Helmet["Security Headers (Helmet)"]
        RateLimiters["Rate Limiters (express-rate-limit)"]
        AuthGuard["Auth & Scope Guard (authMiddleware.js)"]
    end

    subgraph BackendAPI["Backend Core (Express 5 / Node.js 22)"]
        Routes["Modular Routers (15 Routers / 70 Endpoints)"]
        Controllers["Controllers (15 Domain Controllers)"]
        Services["Domain Services (Order, Ledger, Customer, Notification, Account)"]
        ModelAdapter["SupabaseModel Document Adapter (config/supabaseModel.js)"]
        Validators["Validation Tier (tableValidators.js & validationMiddleware.js)"]
    end

    subgraph DataCloud["Cloud & Persistence Infrastructure"]
        SupaPostgres[("Supabase PostgreSQL (app_records JSONB + Relational)")]
        SupaAuth["Supabase Auth (GoTrue JWT)"]
        SupaStorage["Supabase Storage (Signed URLs: profile-images, maap-images)"]
        FirebaseFCM["Firebase Cloud Messaging (FCM Push Service)"]
        WhatsAppAPI["WhatsApp Protocol (wa.me Deep Links)"]
        UPIEngine["UPI VPA Protocol (upi://pay Links & QR)"]
    end

    Web -->|HTTPS REST| CORS
    Mobile -->|HTTPS REST| CORS
    PublicUser -->|HTTPS GET /orders/public/:token| CORS

    CORS --> Helmet
    Helmet --> RateLimiters
    RateLimiters --> AuthGuard
    AuthGuard --> Routes

    Routes --> Controllers
    Controllers --> Services
    Controllers --> Validators
    Services --> ModelAdapter
    ModelAdapter -->|Service Role PostgREST SQL| SupaPostgres

    Controllers -->|Upload/View Signed URLs| SupaStorage
    Services -->|HTTP v1 Push Dispatch| FirebaseFCM
    Mobile -->|Intent Launcher| WhatsAppAPI
    Web -->|Web / Desktop Direct| WhatsAppAPI
    Web -->|Dynamic QR Render| UPIEngine
    Mobile -->|Client Auth JWT| SupaAuth
    Web -->|Client Auth JWT| SupaAuth
```

---

## 2. Core Architectural Patterns

1. **Multi-Tenant Scoped Architecture**: Tenant partitioning is enforced logically at the query level using `shopId`. Every request authenticated by `protect` middleware resolves the user's active `shopId` (`req.user.shopId`), which is injected into all subsequent database queries and writes.
2. **Document-to-Table Model Adapter Pattern (`config/supabaseModel.js`)**: An abstraction layer that emulates document-database interfaces (`find`, `findOne`, `findById`, `save`, `populate`, `sort`, `limit`) over a single Supabase PostgreSQL table (`app_records`) storing JSONB documents with GIN indexing.
3. **Local-First Mobile Architecture**: The Flutter client persists data to an encrypted on-device SQLite database (`LocalDatabaseService` using `sqflite_sqlcipher`). Operations execute locally with zero network latency; an asynchronous outbox worker (`SyncService` / `workmanager`) reconciles pending mutations with the backend REST API.
4. **Three-Tier Validation Pipeline**: Input sanitization and bounds checking occur at the client UI (`formValidators.js`), HTTP middleware boundary (`validationMiddleware.js`), and database model layer (`tableValidators.js`).
5. **Immutable Financial Transaction Ledger**: Payments are never modified in place. Every monetary exchange records an append-only `Transaction` document, from which parent `Payment` balances (`paidAmount`, `balanceAmount`, `status`) are deterministically recomputed.

---

## 3. Detailed Component Decomposition

### 3.1 Backend Service (`stitchcraft-backend/`)
- **Technology**: Node.js `22.x`, Express.js `5.2.1` (ESM module format).
- **Entry Point**: [`server.js`](file:///home/manthan/Projects/StitchCraft/stitchcraft-backend/server.js).
- **Responsibilities**: Authentication verification, multi-tenant scoping, business logic execution (order lifecycle, material deductions, financial math, udhar aggregation), input validation, rate limiting, and push dispatch.
- **Dependencies**: `@supabase/supabase-js`, `express`, `express-rate-limit`, `helmet`, `cors`, `firebase-admin`, `dotenv`.
- **Deployment Location**: Render Web Service (configured via [`render.yaml`](file:///home/manthan/Projects/StitchCraft/render.yaml)).
- **Failure Impact**: Complete loss of cloud synchronization, web dashboard access, and public invoice rendering. Mobile clients continue operating offline on cached SQLite data.

### 3.2 Web Dashboard (`stitchcraft-frontend/`)
- **Technology**: React `19.3.1`, Vite `8.3.5`, TailwindCSS `v4.3.3`, React Router DOM `v7.18.5`.
- **Entry Point**: [`src/main.jsx`](file:///home/manthan/Projects/StitchCraft/stitchcraft-frontend/src/main.jsx) and [`src/App.jsx`](file:///home/manthan/Projects/StitchCraft/stitchcraft-frontend/src/App.jsx).
- **Responsibilities**: Full administrative workspace, real-time analytics, staff delegation, workshop Kanban tracking, customer measurement logging, PDF printing, and public invoice viewing.
- **Dependencies**: `@supabase/supabase-js`, `@vercel/analytics`, `react-icons`, `tailwindcss`.
- **Deployment Location**: Vercel (configured via [`vercel.json`](file:///home/manthan/Projects/StitchCraft/vercel.json)).
- **Failure Impact**: Administrative users cannot access dashboard via browser; mobile client remains functional.

### 3.3 Mobile Application (`stitchcraft-mobile/`)
- **Technology**: Flutter SDK (Dart `^3.10.7`), SQLCipher SQLite, Workmanager.
- **Entry Point**: [`lib/main.dart`](file:///home/manthan/Projects/StitchCraft/stitchcraft-mobile/lib/main.dart).
- **Responsibilities**: Workshop-floor order booking, 5-step order creation wizard with voice input, camera maap capture, offline khata ledger, WhatsApp messaging, and periodic background synchronization.
- **Dependencies**: `sqflite_sqlcipher`, `workmanager`, `supabase_flutter`, `http`, `firebase_messaging`, `flutter_local_notifications`, `pdf`, `printing`, `url_launcher`, `provider`.
- **Deployment Target**: Android APK / AppBundle (API 21+) and iOS Runner.
- **Failure Impact**: Isolated to single physical device; server and web dashboard unaffected.

---

## 4. Architectural Flows & Diagrams

### 4.1 Authentication & Authorization Flow

```mermaid
sequenceDiagram
    autonumber
    actor User as Masterji / Staff
    participant Client as Web / Mobile UI
    participant SupaAuth as Supabase GoTrue Auth
    participant API as Express API (/api/auth)
    participant AuthMW as protect & authorize Middleware
    participant DB as PostgreSQL (app_records)

    User->>Client: Enters Email & Password
    Client->>SupaAuth: signInWithPassword(email, password)
    SupaAuth-->>Client: Returns GoTrue Session { access_token, user_id }
    Client->>API: HTTP Request with Header: Authorization: Bearer <access_token>
    API->>AuthMW: protect(req, res, next)
    AuthMW->>SupaAuth: supabase.auth.getUser(token)
    SupaAuth-->>AuthMW: Validated User Identity
    AuthMW->>DB: Query users collection where supabase_id == user_id
    DB-->>AuthMW: User Document { _id, shopId, role, name }
    Note over AuthMW: Attaches req.user = userDoc with active shopId
    alt Endpoint has authorize('owner')
        AuthMW->>AuthMW: Check req.user.role == 'owner'
        alt Role is not owner
            AuthMW-->>Client: HTTP 403 Forbidden
        else Role is owner
            AuthMW->>API: next() -> Executes Controller
        end
    else Standard Protected Route
        AuthMW->>API: next() -> Executes Controller
    end
```

### 4.2 Order Creation & Material Consumption Data Flow

```mermaid
sequenceDiagram
    autonumber
    participant UI as Order Creation Wizard
    participant OrderCtrl as orderController.js
    participant OrderSvc as orderService.js
    participant Model as SupabaseModel Adapter
    participant DB as PostgreSQL (app_records)

    UI->>OrderCtrl: POST /api/orders { customerId, apparelType, price, advancePaid, asterRequired, ... }
    Note over OrderCtrl: Validates request schema & bounds
    OrderCtrl->>OrderSvc: createOrder(orderData, shopId)
    OrderSvc->>Model: Query customer measurements
    Model->>DB: Read customer document
    DB-->>Model: Customer measurements
    Note over OrderSvc: Snapshots measurements into order.measurementsSnapshot
    OrderSvc->>Model: Persist Order document
    Model->>DB: Upsert into app_records (collection='orders')
    
    alt Advance Paid > 0
        OrderSvc->>Model: Create Payment document
        OrderSvc->>Model: Create Transaction document (type='Payment', amount=advancePaid)
        OrderSvc->>Model: Create LedgerEntry document (type='income', category='Order Advance')
    end

    alt Order Status in ASTAR_DEDUCT_STATUSES (Stitching/Checking/Ready)
        OrderSvc->>Model: Query active aster/lining inventory
        OrderSvc->>Model: Deduct consumed quantity from inventory
        Model->>DB: Update inventory document
    end

    OrderSvc-->>OrderCtrl: Created Order Record with populated relations
    OrderCtrl-->>UI: HTTP 201 Created { success: true, order }
```

### 4.3 Immutable Payment & Khata Ledger Flow

```mermaid
sequenceDiagram
    autonumber
    actor User as Shop Owner
    participant UI as Payment Modal (Web/Mobile)
    participant Ctrl as orderController.recordOrderPayment
    participant Svc as orderService.syncPaymentFromTransactions
    participant DB as PostgreSQL (app_records)

    User->>UI: Submits Payment { amount: 500, paymentType: 'UPI', notes: 'Trial payment' }
    UI->>Ctrl: POST /api/orders/:id/payments
    Ctrl->>DB: Read existing Order and Payment records
    Ctrl->>DB: Insert immutable Transaction { orderId, amount: 500, type: 'Payment', shopId }
    Ctrl->>Svc: syncPaymentFromTransactions(paymentId, orderId, shopId)
    Svc->>DB: Query ALL Transactions for orderId
    DB-->>Svc: [Tx1: 300 (Advance), Tx2: 500 (Payment)]
    Note over Svc: Computes totalPaid = 800, balance = totalPrice - 800
    Note over Svc: Updates payment status: Pending | Partial | Paid
    Svc->>DB: Update Payment record { paidAmount: 800, balanceAmount: 200, status: 'Partial' }
    Ctrl->>DB: Insert LedgerEntry { type: 'income', amount: 500, category: 'Order Payment' }
    Ctrl-->>UI: HTTP 200 OK { success: true, payment, transaction }
```

### 4.4 Mobile Offline Synchronization Flow

```mermaid
sequenceDiagram
    autonumber
    actor Tailor as Masterji (Offline in Shop)
    participant MobileUI as Flutter UI Screens
    participant LocalDB as Encrypted SQLite (LocalDatabaseService)
    participant Worker as SyncWorker / Workmanager
    participant SyncSvc as SyncService
    participant REST as Express Backend API

    Tailor->>MobileUI: Creates new customer & books order
    MobileUI->>LocalDB: insertRecord('customers', data, sync_status=1)
    MobileUI->>LocalDB: insertRecord('orders', data, sync_status=1)
    Note over LocalDB: Data encrypted with AES key via SQLCipher
    MobileUI-->>Tailor: Immediate UI feedback (No loading spinners)

    Note over Tailor: Internet connection restores
    Worker->>SyncSvc: Periodic 15-minute trigger OR Manual 'Sync Now'
    SyncSvc->>LocalDB: Process mutation_outbox queue
    SyncSvc->>LocalDB: getUnsyncedRecords('customers')
    SyncSvc->>REST: POST /api/customers { idempotencyKey: 'cust_UUID', ... }
    REST-->>SyncSvc: HTTP 201 Created { _id: 'server_id_123' }
    SyncSvc->>LocalDB: updateSyncStatus('customers', id, 0)
    
    SyncSvc->>LocalDB: getUnsyncedRecords('orders')
    SyncSvc->>REST: POST /api/orders { idempotencyKey: 'ord_UUID', ... }
    REST-->>SyncSvc: HTTP 201 Created { _id: 'server_id_456' }
    SyncSvc->>LocalDB: updateSyncStatus('orders', id, 0)

    SyncSvc->>REST: GET /api/orders (Pull remote modifications)
    REST-->>SyncSvc: HTTP 200 OK [ Remote orders list ]
    SyncSvc->>LocalDB: insertRecord('orders', remoteOrder, sync_status=0)
    SyncSvc->>LocalDB: Update lastSyncTime in SharedPreferences
```

### 4.5 Notification & Push Dispatch Architecture

```mermaid
sequenceDiagram
    autonumber
    participant Event as System Trigger (Order Due / Low Stock)
    participant NotifSvc as notificationService.js
    participant DB as PostgreSQL (notifications collection)
    participant FCMAdmin as Firebase Admin SDK
    participant GoogleFCM as Firebase Cloud Messaging
    participant MobileClient as Flutter Device (firebase_messaging)

    Event->>NotifSvc: dispatchNotification(shopId, { title, message, type, recipientRoles })
    NotifSvc->>DB: Persist in-app notification document { read: false, shopId }
    
    alt Notification Type in PUSH_AUTHORIZED_TYPES (Order Due / Low Stock)
        NotifSvc->>DB: Query device tokens for shop users
        DB-->>NotifSvc: [ FCM Registration Tokens ]
        alt Firebase Admin Credentials Configured
            NotifSvc->>FCMAdmin: sendEachForMulticast(payload)
            FCMAdmin->>GoogleFCM: HTTPS Google FCM Gateway
            GoogleFCM-->>MobileClient: System Push Alert on Mobile
        else Credentials Missing
            Note over NotifSvc: Logs graceful warning; in-app notification preserved
        end
    else Routine Event (e.g. Order Status Change)
        Note over NotifSvc: Stored as in-app alert only (Prevents notification fatigue)
    end
```

---

## 5. Technology Stack Matrix

| Layer | Component | Specification | Function |
|---|---|---|---|
| **Frontend** | Framework | React `19.3.1` | Administrative Web SPA |
| | Tooling | Vite `8.3.5` | Fast build & HMR toolchain |
| | Styling | TailwindCSS `v4.3.3` | Utility-first design system |
| | Routing | React Router DOM `v7.18.5` | Client-side page navigation |
| | State Management | React Context API | AuthContext, LanguageContext, ThemeContext |
| **Mobile** | Framework | Flutter SDK (`Dart ^3.10.7`) | Cross-platform mobile runtime |
| | Persistence | `sqflite_sqlcipher 3.0.1` | AES-256 encrypted SQLite engine |
| | Background Work | `workmanager 0.10.10` | 15-minute background sync scheduler |
| | Messaging | `url_launcher 6.3.1` | Native WhatsApp deep-linking |
| | Printing | `pdf 3.11.1` & `printing 5.13.2` | Receipt generation & Bluetooth printing |
| **Backend** | Runtime | Node.js `22.x` (LTS) | Asynchronous backend server |
| | Framework | Express.js `5.2.1` | Modular HTTP API engine |
| | Security | `helmet 8.3.0` | HTTP security response headers |
| | Rate Limiting | `express-rate-limit 8.7.2` | 4-tier request rate bounding |
| | Push Dispatch | `firebase-admin 14.5.0` | Optional mobile push dispatcher |
| **Database** | Database Engine | PostgreSQL 15+ (Supabase) | Primary relational & JSONB database |
| | Identity & Auth | Supabase GoTrue Auth | JWT-based user authentication |
| | Object Storage | Supabase Storage | Encrypted image storage (signed URLs) |
| **Hosting** | Web Deployment | Vercel | Global CDN edge hosting |
| | API Deployment | Render Web Service | Node.js container hosting |

