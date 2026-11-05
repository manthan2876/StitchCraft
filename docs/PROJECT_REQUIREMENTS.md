# 📋 StitchCraft: Product Requirements Baseline

**Version:** 1.0.0  
**Target Audience:** Engineering, Product, QA, Workshop Operations  
**Product Concept:** Multi-tenant tailor-shop ERP designed specifically for Indian "Masterji" boutique and custom tailoring workshops.

---

## 1. Product Context & Operational Realities

Small Indian custom-tailoring shops operate under constraints radically different from Western desktop or enterprise SaaS:

1. **User Personas & Operating Dynamic**:
   - **Owner / Masterji (Primary Persona)**: Sole proprietor, master cutter, and financial collector. Constantly interrupted on the shop floor, handles chalk and shears, limited time and patience for typing, manages fabric inventory, calculates customer balances (udhar), assigns jobs to karigars, collects advances and deliveries.
   - **Manager & Counter Staff**: Enters orders, takes customer measurements, receives deliveries, and logs basic expenses. Must be restricted from sensitive business settings, financial margins, and deletion operations.
   - **Karigar (Artisan / Piece-Rate Worker)**: Works on cutting, stitching, or finishing. Only needs to know what garment to cut/stitch, specifications, special instructions, and mark stages complete. Must never see customer phone numbers, wholesale fabric costs, or shop profit margins.
   - **Customer (Guest)**: Never creates an account or logs in. Receives invoice links via WhatsApp, opens them on mobile browsers, checks delivery dates, verifies billing details, and pays via UPI QR.

2. **Operating Conditions & Constraints**:
   - **Unreliable Connectivity**: Workshops are frequently located in dense Indian bazaars, basements, or semi-urban areas with spotty 4G/5G mobile data. Mobile app must be strictly **offline-first** (full local write capability and resilient background synchronization).
   - **Shared Shop Android Devices**: Multiple tailors often share a single low-end Android tablet or counter phone. Switching users or clearing local data must be safe, without leaking client records between shops.
   - **Tri-Lingual Localization**: Workshop owners and staff communicate in English, Hindi (हिंदी), and Gujarati (ગુજરાતી). UI must support full dynamic language switching.
   - **WhatsApp as the Primary Channel**: WhatsApp is the undisputed standard for customer communication in India. Invoices, delivery alerts, trial ready notifications, and payment reminders must format direct WhatsApp links (`wa.me`).
   - **UPI & Cash Financial Model**: Transactions are overwhelmingly cash advances and UPI settlements (Google Pay, PhonePe, Paytm). The system must support Indian currency formatting (₹ Lakh/Crore grouping: `en_IN`) and dynamic UPI QR code generation (`upi://pay?pa=...`).

---

## 2. Requirements Matrix by Domain

Requirements are classified by:
- **Priority**: `Must` (Core MVP / blocker), `Should` (Critical production feature), `Could` (Value-add enhancement).
- **Source**: Explicitly cited from repository code, migrations, tests, wireframes, or marked as **Inferred**.

---

### Domain 1: Authentication & Account Management (AUTH)

| ID | User Role | User Story | Priority | Source & Status |
|---|---|---|---|---|
| **AUTH-01** | Owner / Staff | As an owner or staff member, I need to sign up with my email, password, name, and shop details so that I can create an isolated workshop environment. | Must | Stated: `README.md:18`, `authRoutes.js:33`, `authController.js:14-89` |
| **AUTH-02** | Owner / Staff | As an authenticated user, I need to log in securely with email and password so that I receive an active Supabase JWT session token. | Must | Stated: `authRoutes.js:34`, `authController.js:94-181` |
| **AUTH-03** | Owner | As a new owner, I need email verification (via OTP or email confirmation link) before profile activation so that malicious or unverified accounts cannot spam the platform. | Must | Stated: `authRoutes.js:35-36`, `authController.js:236-357` |
| **AUTH-04** | Owner / Staff | As a user who forgot their password, I need to request a password reset email so that I can regain access to my workshop account. | Must | Stated: `authRoutes.js:37`, `authController.js:388-414` |
| **AUTH-05** | Owner / Staff | As a user with a valid password reset token or recovery session, I need to set a new password of at least 6 characters so that my account remains secure. | Must | Stated: `authRoutes.js:38`, `authController.js:419-436`, `ResetPassword.jsx:1-120` |
| **AUTH-06** | Owner / Staff | As an authenticated user, I need to update my password from within profile settings by providing my current password and new password. | Should | Stated: `authRoutes.js:43`, `authController.js:186-210` |
| **AUTH-07** | Owner / Staff | As a user, I need to stay logged in across app restarts via secure local token storage (hardware-backed `FlutterSecureStorage` on mobile, `localStorage` on web). | Must | Stated: `auth_service.dart:18-20, 85`, `AuthContext.jsx:118` |
| **AUTH-08** | Owner / Staff | As a user on a shared counter phone, logging out must purge all local encrypted SQLite shop data so that subsequent tailors cannot see my business records. | Must | Stated: `auth_service.dart:314-333` |
| **AUTH-09** | Owner | *Inferred Assumption*: As a busy Indian tailor shop owner who rarely checks email, I need phone OTP (SMS/WhatsApp OTP) login so that I can sign up and authenticate using only my mobile number without managing complex passwords. | Should | **Inferred by Auditor (Assumption to confirm)** |

---

### Domain 2: Shops & Multi-Tenancy (SHOP)

| ID | User Role | User Story | Priority | Source & Status |
|---|---|---|---|---|
| **SHOP-01** | Owner | As an owner, I need every shop entity to be scoped by `shopId` so that no tailor shop can view or mutate another shop's records. | Must | Stated: `ARCHITECTURE.md:58-72`, `supabaseModel.js:179-180`, `shop_isolation.test.js:1-90` |
| **SHOP-02** | Owner | As an owner with multiple branches or boutique locations, I need to view all shops I own and switch active branch context via `PUT /api/auth/switch-shop/:id`. | Should | Stated: `ARCHITECTURE.md:65-66`, `authRoutes.js:42`, `profileController.js:65-115` |
| **SHOP-03** | Owner | As an owner, I need to configure shop branding: Shop Name, Phone, Address, GSTIN, UPI ID (VPA), custom Invoice Prefix (e.g., `SC`, `INV`), and Shop Logo. | Must | Stated: `ARCHITECTURE.md:186-189`, `Shop.js:1-40`, `shopController.js:20-55` |
| **SHOP-04** | Owner | As an owner, I need to update custom WhatsApp message templates (Booking, Ready, Delivery, Balance Reminder) in shop settings. | Should | Stated: `Shop.js:29-30`, `shopController.js:86-98` |
| **SHOP-05** | Owner | As an owner, I need to discover and view registered partner tailor shops (`GET /api/shops/partners`) so that I can outsource overflowing workshop orders. | Should | Stated: `shopRoutes.js:15`, `shopController.js:145-178` |
| **SHOP-06** | Owner | As an owner, I need to safely delete a shop branch, with verification that only the authenticated owner can trigger deletion. | Must | Stated: `shopRoutes.js:24`, `shopController.js:105-140` |

---

### Domain 3: Roles & Permissions (ROLE)

| ID | User Role | User Story | Priority | Source & Status |
|---|---|---|---|---|
| **ROLE-01** | System / Owner | As a shop system, I need 4 distinct roles: `owner`, `manager`, `staff`, and `karigar` with granular permissions enforced on every backend route. | Must | Stated: `ARCHITECTURE.md:73-92`, `User.js:12-16`, `tableValidators.js:130-135` |
| **ROLE-02** | Owner | As an owner, I need sole access to destructive operations (account deletion, database wiping, shop deletion, role changes, and member unlinking). | Must | Stated: `ARCHITECTURE.md:86-90`, `staffRoutes.js:16`, `staff_management.test.js:1-85` |
| **ROLE-03** | Manager | As a shop manager, I need to view staff lists and oversee daily workshop operations (orders, customers, inventory, khata, deliveries) without access to owner settings or role elevation. | Must | Stated: `ARCHITECTURE.md:79-92`, `staffController.js:8-32` |
| **ROLE-04** | Staff | As counter staff, I need to manage customers, enter orders, view inventory, and record payments, but I must be blocked from viewing total shop profits, ledger journal, or deleting entities. | Must | Stated: `ARCHITECTURE.md:77-90`, `MOBILE_WEB_WIREFRAMES.md:745-756` |
| **ROLE-05** | Karigar | As a karigar, I must only see jobs assigned to me, view garment details/measurements, and update production stages; I must never access customer lists, phone numbers, khata, or wholesale costs. | Must | Stated: `ARCHITECTURE.md:77-90`, `MOBILE_WEB_WIREFRAMES.md:745-756`, `my_jobs_screen.dart:53-90` |
| **ROLE-06** | Owner | As an owner, I need to invite team members by name, email, phone, and assign role (`manager`, `karigar`, `staff`), toggle active status, or remove members from my shop. | Must | Stated: `staffRoutes.js:18-24`, `staffController.js:37-146`, `StaffManagement.jsx:58-102` |

---

### Domain 4: Customers (CUST)

| ID | User Role | User Story | Priority | Source & Status |
|---|---|---|---|---|
| **CUST-01** | Owner / Staff | As a tailor, I need to register customers with Name, Phone, Email (optional), and Address so that they have a persistent workshop record. | Must | Stated: `Customer.js:1-35`, `customerController.js:17-31`, `customerService.js:27-94` |
| **CUST-02** | Owner / Staff | As a tailor, I need to search customers by Name, 10-digit Phone, or Customer ID (`CUST-XXXXXXXX`) so that I can look up records in under 3 seconds while standing at the counter. | Must | Stated: `customerController.js:38-49`, `CustomerListScreen.dart:1-120`, `Customers.jsx:1-100` |
| **CUST-03** | Owner / Staff | As a tailor, I need to view a customer's full profile: contact details, measurement records, order history, total spent, and outstanding balance. | Must | Stated: `customerController.js:78-87`, `customerService.js:96-148`, `CustomerDetails.jsx:1-150` |
| **CUST-04** | Owner / Staff | As a tailor, I need customer creation to be idempotent via `Idempotency-Key` or phone deduplication so that slow/retried network requests do not create duplicate customer accounts. | Must | Stated: `customerService.js:29-57`, `idempotency_and_inventory.test.js:19-35` |
| **CUST-05** | Owner / Staff | As a mobile user, I need an optional toggle to save new customers directly to the Android device contacts so that I can identify caller ID and WhatsApp them natively. | Could | Stated: `step5_details.dart:222-227`, `device_contacts_service.dart:1-45` |
| **CUST-06** | Owner | As an owner, deleting a customer must be confirmed, scoped by shop, and handle existing orders gracefully without causing orphaned foreign-key violations. | Should | Stated: `customerService.js:192-205` |

---

### Domain 5: Measurements (MEAS)

| ID | User Role | User Story | Priority | Source & Status |
|---|---|---|---|---|
| **MEAS-01** | Owner / Staff | As a masterji, I need to record numeric measurements for standard Indian garments: Shirt (Chest, Waist, Length, Shoulder, Sleeve, Neck, Collar) and Pant (Waist, Hip, Length, Inseam, Thigh, Bottom). | Must | Stated: `Measurement.js:1-45`, `MeasurementForm.jsx:1-180`, `tableValidators.js:52-70` |
| **MEAS-02** | Owner / Staff | As a tailor on mobile, I need an inches vs centimeters toggle and quick fractional keypad (1/4, 1/2, 3/4) so that I can record traditional tailor tape measurements rapidly without keyboard typing. | Must | Stated: `MOBILE_WEB_WIREFRAMES.md:284-286`, `step3_measurements.dart:1-250` |
| **MEAS-03** | Owner / Staff | As a tailor, I need to support "Maap" (sample physical garment provided by customer) by taking a photo of the sample garment and notes instead of body measurements. | Must | Stated: `Order.js:27-28`, `step3_measurements.dart:120-180`, `NewOrder.jsx:31-46` |
| **MEAS-04** | Owner / Staff | As a tailor, I need to record voice notes for custom fitting nuances (e.g., "heavy belly", "sloping shoulder", "deep neck") using speech-to-text. | Should | Stated: `README.md:20`, `voice_text_field.dart:1-120`, `step3_measurements.dart:150-180` |
| **MEAS-05** | Owner / Staff | As a tailor booking a repeat order, I need the customer's last measurements to automatically preload so that I do not have to remeasure a returning customer from scratch. | Must | Stated: `useNewOrder.js:83-100`, `step3_measurements.dart:60-90` |
| **MEAS-06** | System | As an ERP system, every order must snapshot measurements at the time of order creation (`measurementsSnapshot`) so that subsequent updates to customer profile measurements do not alter past orders. | Must | Stated: `ARCHITECTURE.md:190-193`, `orderService.js:238-254`, `order_lifecycle.test.js:1-50` |
| **MEAS-07** | Owner / Staff | *Inferred Assumption*: As an Indian tailor serving women and traditional attire, I need measurement templates for Kurti / Kameez, Salwar / Churidar, Blouse, Lehanga, and Safari Suit beyond basic Western Shirt/Pant. | Should | **Inferred by Auditor (Assumption to confirm)** |

---

### Domain 6: Orders & Workshop Stages (ORD)

| ID | User Role | User Story | Priority | Source & Status |
|---|---|---|---|---|
| **ORD-01** | Owner / Staff | As a tailor, I need to create multi-item custom orders specifying customer, garment items, fabrics, delivery date, stitching price, and advance payment. | Must | Stated: `orderService.js:196-397`, `NewOrder.jsx:1-470`, `step5_details.dart:210-460` |
| **ORD-02** | Owner / Staff | As a tailor, I need sequential, strict order production status progression: `Incoming` -> `Measuring` -> `Cutting` -> `Stitching` -> `Checking` -> `Ready` -> `Delivered` (or `Cancelled`). | Must | Stated: `ARCHITECTURE.md:231-232`, `Order.js:12-16`, `order_lifecycle.test.js:50-80` |
| **ORD-03** | Owner / Staff | As a tailor, I need order creation to be strictly idempotent using `idempotencyKey` so that mobile retries over unstable network never create duplicate orders. | Must | Stated: `orderService.js:219-230`, `idempotency_and_inventory.test.js:1-18` |
| **ORD-04** | Owner / Staff | As a tailor, I need to attach fabric swatches or style reference photos via camera or file upload, stored securely in private cloud storage. | Should | Stated: `uploadController.js:1-74`, `step5_details.dart:367-384`, `Order.js:29-30` |
| **ORD-05** | Owner / Staff | As an owner or manager, I need to assign a karigar and sewing machine to an order for workshop production tracking. | Should | Stated: `Order.js:31-34`, `orderService.js:210-212`, `NewOrder.jsx:39-40` |
| **ORD-06** | Owner / Staff | As a tailor, I need to add timestamped audit notes to an order (e.g., "Customer called for sleeve shortening") without mutating past notes. | Should | Stated: `orderRoutes.js:47`, `orderController.js:508-529`, `order_lifecycle.test.js:80-95` |
| **ORD-07** | Owner | As an owner with workshop overload, I need to outsource/delegate an order to a partner tailor with agreed cost and an earlier due date (1 day before customer delivery date). | Should | Stated: `orderService.js:515-600`, `outsource_order_sheet.dart:1-150` |
| **ORD-08** | Owner / Staff | As an owner, deleting an order must be a soft-delete (`isDeleted: true`, `status: 'Cancelled'`) that restores inventory, updates customer stats, and preserves financial audit records. | Must | Stated: `orderService.js:681-730`, `idempotency_and_inventory.test.js:40-60` |

---

### Domain 7: Inventory & Astar (Lining) Stock (INV)

| ID | User Role | User Story | Priority | Source & Status |
|---|---|---|---|---|
| **INV-01** | Owner / Manager | As a masterji, I need to track workshop inventory items: Name, Item Type (`Lining`, `Fabric`, `Thread`, `Accessories`), Quantity, Unit (`meters`, `pieces`, `rolls`), Unit Cost, and Low Stock Threshold. | Must | Stated: `Inventory.js:1-40`, `inventoryController.js:1-120`, `inventory_screen.dart:1-200` |
| **INV-02** | System | As an automated workshop system, when an order requiring astar transitions to an active workshop stage (`Stitching`, `Checking`, `Ready`, `Delivered`), the required quantity must be deducted from inventory exactly once. | Must | Stated: `orderService.js:14-16, 123-193`, `idempotency_and_inventory.test.js:36-55` |
| **INV-03** | System | As an automated workshop system, if an order with deducted astar is cancelled, moved backward before stitching, or soft-deleted, the consumed stock must be automatically restored to inventory. | Must | Stated: `orderService.js:157-165, 692-715`, `idempotency_and_inventory.test.js:56-70` |
| **INV-04** | Owner / Manager | As an owner, when an inventory item drops to or below its minimum threshold, the system must trigger an immediate low-stock alert and device push notification. | Must | Stated: `orderService.js:145-155`, `notificationService.js:69-74`, `Inventory.jsx:1-120` |
| **INV-05** | Owner / Manager | As a masterji, I need to record stock adjustments, purchase restocks, and scrap wastage (damaged/cut pieces) so that ledger and physical inventory stay reconciled. | Should | Stated: `inventoryController.js:65-115`, `idempotency_and_inventory.test.js:80-110` |

---

### Domain 8: Payments & Financial Transactions (PAY)

| ID | User Role | User Story | Priority | Source & Status |
|---|---|---|---|---|
| **PAY-01** | Owner / Staff | As a tailor, I need to record customer advance payments at order booking and subsequent interim payments (`Cash`, `UPI`, `Card`, `Credit`, `Bank`). | Must | Stated: `orderController.js:320-401`, `orderService.js:358-376`, `Payments.jsx:1-150` |
| **PAY-02** | System | As an immutable financial ledger, payment updates must never overwrite past payment records; each payment must create an immutable `Transaction` row and recalculate `paidAmount` and `balanceAmount`. | Must | Stated: `ARCHITECTURE.md:177-181`, `orderService.js:31-58`, `financial_integrity.test.js:1-25` |
| **PAY-03** | Owner / Manager | As an owner, when issuing a refund or customer return, I need to record an immutable `Refund` transaction with a mandatory audit reason without mutating existing payment history. | Must | Stated: `orderController.js:406-489`, `financial_integrity.test.js:26-50` |
| **PAY-04** | System | As an accounting system, payment status must compute strictly: `Paid` (balance = 0), `Partial` (paid > 0 and balance > 0), `Pending` (paid = 0). | Must | Stated: `orderService.js:54`, `order_lifecycle.test.js:30-45` |
| **PAY-05** | Owner / Staff | As a user recording a payment, the request must be idempotent via `idempotencyKey` so that double-tapping "Record Payment" does not double-charge the customer. | Must | Stated: `orderController.js:325-358`, `financial_integrity.test.js:10-25` |

---

### Domain 9: Invoices & Public Share Links (INVOICE)

| ID | User Role | User Story | Priority | Source & Status |
|---|---|---|---|---|
| **INVOICE-01** | Customer | As a customer receiving a shared link on WhatsApp, I need to open the invoice on my mobile browser without logging in so that I can see my order items, delivery date, and balance due. | Must | Stated: `orderRoutes.js:31`, `orderController.js:164-260`, `PublicInvoice.jsx:1-364` |
| **INVOICE-02** | System / Security | As a secure privacy engine, public invoice endpoints (`/api/orders/public/:token`) must strictly look up orders by opaque 48-character hex `shareToken` or `shareTokenHash`, with zero fallback to sequential IDs or MongoDB `_id`. | Must | Stated: `orderController.js:172-180`, `public_invoice_hardening.test.js:1-60` |
| **INVOICE-03** | System / Security | As a privacy safeguard, the public invoice payload must strictly strip sensitive data: customer phone, address, measurements, internal profit margins, wholesale fabric costs, and assigned karigar IDs. | Must | Stated: `orderController.js:205-260`, `public_invoice_hardening.test.js:18-35` |
| **INVOICE-04** | Owner | As an owner, I need shared invoice links to expire automatically after 30 days and have the ability to manually revoke a token, returning HTTP 410 Gone. | Must | Stated: `orderController.js:186-198`, `orderRoutes.js:48-50`, `public_invoice_hardening.test.js:36-50` |
| **INVOICE-05** | Customer | As a customer viewing a public invoice with an unpaid balance, I need to see a dynamic UPI QR code and an "Open UPI App" deep link pre-filled with the shop's UPI VPA and exact balance amount. | Must | Stated: `PublicInvoice.jsx:309-327`, `invoice_details_screen.dart:246-250` |
| **INVOICE-06** | Owner / Staff | As a tailor on mobile or web, I need to generate printable PDF receipts with shop logo, GSTIN, and itemized billing for physical counter handover. | Must | Stated: `pdf_service.dart:1-250`, `InvoiceDetails.jsx:150-220` |

---

### Domain 10: Khata & Udhar (Credit Book) (KHATA)

| ID | User Role | User Story | Priority | Source & Status |
|---|---|---|---|---|
| **KHATA-01** | Owner / Manager | As a masterji, I need an aggregated Udhar (credit) view showing all customers who owe money, their total outstanding balance, and oldest unpaid order date. | Must | Stated: `customerRoutes.js:17`, `customerController.js:118-208`, `udhar_balances.test.js:1-40` |
| **KHATA-02** | Owner / Manager | As a masterji chasing payments, I need a one-tap WhatsApp button for each debtor that opens a pre-composed polite Hindi/Gujarati/English payment reminder containing shop name, amount due, and UPI details. | Must | Stated: `customerController.js:160-185`, `udhar_balances.test.js:25-45`, `udhar_list.dart:200-240` |
| **KHATA-03** | Owner / Manager | As a tailor, I need to log routine shop operational expenses (e.g., electricity, tea/chai, thread, needle repairs, rent) with amount, category, and description. | Must | Stated: `ledgerRoutes.js:21-23`, `expenseController.js:1-80`, `add_expense_bottom_sheet.dart:1-120` |
| **KHATA-04** | Owner / Manager | As an owner, I need a cash journal displaying a chronological running cash balance reconciling incoming customer payments, refunds, and outgoing shop expenses. | Must | Stated: `ledgerService.js:53-154`, `ledger_and_expenses.test.js:1-45`, `Ledger.jsx:1-250` |
| **KHATA-05** | Owner / Manager | As an owner on mobile, I need Udhar to be the first and primary default tab when opening Khata so that outstanding debt is front and center. | Must | Stated: `MOBILE_WEB_WIREFRAMES.md:368`, `KhataScreen.dart:1-50` |

---

### Domain 11: Deliveries & Dispatch (DELIV)

| ID | User Role | User Story | Priority | Source & Status |
|---|---|---|---|---|
| **DELIV-01** | Owner / Staff | As a tailor at the counter, I need a delivery dispatch dashboard grouped by tabs: `Today`, `Late / Overdue`, `Upcoming`, and `Delivered`. | Must | Stated: `deliveryRoutes.js:8`, `deliveryController.js:9-62`, `Delivery.jsx:1-150` |
| **DELIV-02** | Owner / Staff | As an owner, marking an order as Delivered when there is an unpaid balance must trigger a prominent credit warning and require an explicit confirmation reason for audit logging. | Must | Stated: `deliveryController.js:79-101`, `financial_integrity.test.js:45-70` |
| **DELIV-03** | Customer | As a customer, when my order status changes to Ready or Delivered, I should receive an automated WhatsApp notification or SMS alerting me to pick up the garment. | Should | Stated: `whatsapp_service.dart:1-100`, `orderService.js:481-504` |
| **DELIV-04** | System | As an integrity guard, an order that is already marked `Delivered` cannot be delivered a second time. | Must | Stated: `deliveryController.js:74-77`, `financial_integrity.test.js:60-65` |

---

### Domain 12: Karigars (Artisans) (KAR)

| ID | User Role | User Story | Priority | Source & Status |
|---|---|---|---|---|
| **KAR-01** | Owner / Manager | As an owner, I need a karigar registry with Name, Phone, Specialization (`Coat / Suit`, `Shirt`, `Pant`, `Kurta`), and Employment Type (`In-House`, `Piece-Rate`, `Contractor`). | Must | Stated: `Karigar.js:1-45`, `karigarController.js:1-120`, `Karigars.jsx:1-150` |
| **KAR-02** | Owner / Manager | As an owner, I need to track active orders assigned to each karigar and calculate completed volume and value for piece-rate wage settlement. | Should | Stated: `dashboardController.js:93-108`, `KarigarDetails.jsx:1-180` |
| **KAR-03** | Karigar | As a karigar logging in on a workshop phone, I must see a simplified "My Jobs" view listing only my assigned cutting/stitching tasks and a single-tap button to advance the job stage. | Must | Stated: `my_jobs_screen.dart:1-150`, `MOBILE_WEB_WIREFRAMES.md:414-418` |

---

### Domain 13: Machines & Workshop Maintenance (MACH)

| ID | User Role | User Story | Priority | Source & Status |
|---|---|---|---|---|
| **MACH-01** | Owner / Manager | As a masterji, I need a registry of workshop sewing machines: Name/Number, Type (`Lockstitch`, `Overlock / Interlock`, `Buttonhole`, `Embroidery`, `Iron / Press`), Status (`Active`, `Maintenance`, `Broken`), and Serial Number. | Should | Stated: `Machine.js:1-45`, `machineController.js:1-90`, `Machines.jsx:1-150` |
| **MACH-02** | Owner / Manager | As a masterji, I need to record machine service and oiling maintenance dates to prevent costly machine breakdowns during festive wedding seasons. | Could | Stated: `Machine.js:26-30`, `machineController.js:45-85`, `Machines.jsx:80-140` |

---

### Domain 14: Notifications & Alerts (NOTIF)

| ID | User Role | User Story | Priority | Source & Status |
|---|---|---|---|---|
| **NOTIF-01** | Owner / Staff | As a user, I need an in-app notification center that logs workshop events (new orders, stage progress, delivery dispatch, payments) with read/unread status. | Must | Stated: `notificationRoutes.js:1-25`, `notificationController.js:1-90`, `Notifications.jsx:1-120` |
| **NOTIF-02** | Owner / Staff | As an owner, routine events (new orders, routine payments) must remain in-app only, while high-priority events (`order_due_reminder`, `low_stock`, `partner_job_completed`) trigger native device push notifications via FCM. | Must | Stated: `notificationService.js:69-75, 120-128`, `security_and_scoping.test.js:140-165` |
| **NOTIF-03** | Owner / Staff | As a mobile user, tapping a push or in-app notification must deep-link directly to the specific order or customer screen. | Should | Stated: `notification_service.dart:342-364`, `MOBILE_WEB_WIREFRAMES.md:462-464` |
| **NOTIF-04** | Owner / Staff | As a mobile user, the app must schedule local notifications for order deliveries due tomorrow morning and due today morning even when completely offline. | Should | Stated: `notification_service.dart:247-286`, `step5_details.dart:296-320` |

---

### Domain 15: Dashboard & Analytics (DASH)

| ID | User Role | User Story | Priority | Source & Status |
|---|---|---|---|---|
| **DASH-01** | Owner / Manager | As a masterji starting my morning, I need an instant dashboard summary: Orders Due Today, Late / Overdue Orders, Money to Collect (Pending Udhar), and Incoming Uncut Orders. | Must | Stated: `dashboardController.js:12-46`, `DashboardScreen.dart:1-150`, `Dashboard.jsx:1-180` |
| **DASH-02** | Owner / Manager | As a masterji, I need a weekly stitching production chart and recent order activity feed to monitor workshop output. | Should | Stated: `dashboardController.js:67-91`, `Dashboard.jsx:100-160`, `line_chart_painter.dart:1-80` |
| **DASH-03** | Owner / Manager | As an owner, the dashboard must exclude cancelled orders from revenue and output metrics. | Must | Stated: `order_lifecycle.test.js:115-130`, `dashboardController.js:83-87` |

---

### Domain 16: Mobile Offline Sync & Durability (SYNC)

| ID | User Role | User Story | Priority | Source & Status |
|---|---|---|---|---|
| **SYNC-01** | Owner / Staff | As a tailor with unreliable internet, I must be able to create customers, book orders, and record payments completely offline into local encrypted SQLite. | Must | Stated: `LocalDatabaseService.dart:86-155`, `step5_details.dart:233-264` |
| **SYNC-02** | System | As an offline engine, mutations created while offline must synchronize automatically in the background via periodic worker (`workmanager` every 15 minutes) or upon reconnecting. | Must | Stated: `sync_worker.dart:1-50`, `sync_service.dart:227-295` |
| **SYNC-03** | Owner / Staff | As a user, I need a Sync Status screen showing pending records by entity, last sync timestamp, and a manual "Sync Now" trigger with retry logic. | Must | Stated: `sync_status_screen.dart:1-180`, `sync_service.dart:65-134` |
| **SYNC-04** | System | As a data sync engine, when an offline local record is synced and the server issues a permanent database ID, the local database must update local IDs and cascade foreign keys without duplicating records. | Must | Stated: `local_db_service.dart:825-894`, `sync_service.dart:475-502` |
| **SYNC-05** | System | As an offline data protection guarantee, local records must NEVER be purged on sync failure; records must remain marked as pending or conflict and visible in the Sync Status queue. | Must | Stated: `MOBILE_WEB_WIREFRAMES.md:456, 735-736`, `sync_service.dart:77-104` |

---

### Domain 17: Localization (LOC)

| ID | User Role | User Story | Priority | Source & Status |
|---|---|---|---|---|
| **LOC-01** | All Users | As a tailor or staff member, I need the entire web dashboard and mobile app available in English (`en`), Hindi (`hi`), and Gujarati (`gu`). | Must | Stated: `README.md:118`, `translations.js:1-40`, `app_en.arb`, `app_gu.arb`, `app_hi.arb` |
| **LOC-02** | All Users | As a user switching language from the top bar or settings, the change must apply instantly across all active views without requiring an app reload. | Must | Stated: `LanguageContext.jsx:1-40`, `localization_service.dart:1-60` |
| **LOC-03** | All Users | Currency must always format according to the Indian numbering system (`₹1,25,000` instead of Western `₹125,000`). | Must | Stated: `currency_utils.dart:1-35`, `formatters.js:1-25`, `formatters.test.js:1-35` |

---

### Domain 18: Data Export, Import, & Purging (DATA)

| ID | User Role | User Story | Priority | Source & Status |
|---|---|---|---|---|
| **DATA-01** | Owner | As an owner, I need to export all my shop's data (customers, orders, measurements, inventory, transactions, ledger) as a JSON backup protected by my account password. | Must | Stated: `authRoutes.js:45`, `accountController.js:28-43`, `accountService.js:34-76` |
| **DATA-02** | Owner | As an owner migrating devices or restoring from a backup, I need to check for ID and record conflicts before importing data, with options to keep existing database records or overwrite from backup. | Should | Stated: `authRoutes.js:48-49`, `accountController.js:80-99`, `accountService.js:102-211` |
| **DATA-03** | Owner | As an owner closing a workshop branch, I need to purge all shop data or schedule account deletion after verifying my password and entering an audit reason. | Must | Stated: `authRoutes.js:46-47`, `accountController.js:45-77`, `accountService.js:78-100` |
| **DATA-04** | Owner | *Inferred Assumption*: As a tailor working with a local Chartered Accountant / tax consultant for GST and income tax, I need to export monthly ledger, expense, and order transactions as an Excel / CSV spreadsheet formatted for Indian accounting. | Should | **Inferred by Auditor (Assumption to confirm)** |

---

### Domain 19: Security, Privacy, & Infrastructure (SEC)

| ID | User Role | User Story | Priority | Source & Status |
|---|---|---|---|---|
| **SEC-01** | System | The Supabase service-role key must strictly remain on the backend server; client web and mobile apps must only possess the anonymous/publishable key. | Must | Stated: `SECURITY.md:1-50`, `ARCHITECTURE.md:49-51`, `supabase.js:1-20` |
| **SEC-02** | System | Cross-tenant data isolation must be enforced: no database read, write, or delete can succeed without scoping to `req.user.shopId`. | Must | Stated: `ARCHITECTURE.md:58-72`, `shop_isolation.test.js:1-90` |
| **SEC-03** | System | Multi-tier rate limiting must protect sensitive endpoints: Authentication (10/15m), File Uploads (30/15m), Destructive Operations/DELETE (10/15m), Public Invoices (60/15m), and General API (300/15m). | Must | Stated: `securityMiddleware.js:12-40`, `security_and_scoping.test.js:35-65` |
| **SEC-04** | System | Client mobile SQLite databases must be encrypted at rest using AES via `sqflite_sqlcipher` with hardware-backed encryption keys generated via `FlutterSecureStorage`. | Must | Stated: `local_db_service.dart:70-155`, `ARCHITECTURE.md:169-172` |
| **SEC-05** | System | All regular expressions used in input validation must have bounded lengths and linear-time execution to prevent Regular Expression Denial of Service (ReDoS). | Must | Stated: `validationMiddleware.js:1-120`, `SECURITY.md:30-45` |
| **SEC-06** | System | Cloud file uploads must validate file types, bound file size, and store photos in private buckets accessible only via time-limited signed URLs (TTL 1 hour). | Must | Stated: `uploadController.js:16-73`, `supabase.js:28-42` |

---

## 3. Assumptions & Inferred Requirements Requiring Product Owner Confirmation

The following requirements were not formally documented in the repository and have been inferred based on deep analysis of the Indian tailor-shop domain. These require explicit sign-off from the Product Owner:

1. **[INFER-01] Phone-First Authentication**: Indian masterjis rarely use email. Is email/password sufficient for the pilot, or is Phone OTP (Firebase Auth / Twilio / MSG91) a hard requirement for workshop adoption?
2. **[INFER-02] Female & Traditional Garment Templates**: The current database models only define `shirt` and `pant` measurement objects. Indian tailor shops survive on Salwar-Kameez, Blouse, Kurta-Pajama, and Lehangas. Should generic dynamic JSON measurement templates be prioritized over hardcoded shirt/pant fields?
3. **[INFER-03] P2P UPI Reconciliation**: The current public invoice generates a standard P2P UPI QR code (`upi://pay?pa=...`). P2P UPI provides no webhook callback. Does the product owner require a payment gateway (Razorpay / Cashfree) with automated webhooks, or does the masterji manually verify and record payments upon checking bank SMS?
4. **[INFER-04] Karigar Wage Calculation**: Karigars in India are almost universally paid piece-rates (e.g., ₹250 per pant stitched, ₹180 per shirt). The current codebase has fields for `labor_cost` but no piece-rate wage calculation ledger or payout tracking for karigars. Is karigar piece-rate payroll planned for MVP?
5. **[INFER-05] Role Model Simplification vs Multi-Role**: Currently, `authMiddleware.js` hard-blocks any user who is not an `owner` with HTTP 403. Did the product owner intend for StitchCraft v1 to be strictly single-user (Owner-only), or was the multi-role matrix (Owner, Manager, Staff, Karigar) temporarily disabled?

