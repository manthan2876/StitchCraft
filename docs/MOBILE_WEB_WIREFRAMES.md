# StitchCraft Mobile and Web Wireframes

This document is the implementation-aligned wireframe reference for the StitchCraft
mobile application and web dashboard. It describes the information hierarchy,
navigation, primary controls, states, and responsive behavior. It is a structural
wireframe, not a pixel-perfect visual specification.

## 1. Product navigation model

### 1.1 Shared domain model

Both clients use the same operational domains:

- Authentication and account recovery
- Dashboard and workshop activity
- Customers and measurements
- Orders and order lifecycle
- Deliveries, payments, invoices, and ledger
- Karigars, machines, inventory, and staff
- Notifications, profile, shop settings, language, and theme

The backend remains the source of truth for authenticated business data. Mobile
also maintains encrypted local data and an offline sync queue.

### 1.2 Responsive principles

| Area | Mobile | Web |
|---|---|---|
| Primary navigation | Home, Orders, Customers, Khata, More, with a centered New Order action | Persistent sidebar plus topbar |
| Dense lists | Cards with progressive disclosure | Tables/cards with filters and bulk actions |
| Forms | Full-screen step forms and bottom sheets | Multi-column forms, panels, and modals |
| Detail pages | App bar, sections, expandable cards | Breadcrumb/title area, tabs, side panels |
| Feedback | Snackbars, dialogs, inline validation | Toasts, inline validation, modal confirmations |
| Offline state | Persistent sync badge, queue count, manual sync, and pending-record chips | API loading/error states; no durable web offline database |
| Small screens | One-column layout, horizontal scrolling only for intentional data strips | Sidebar collapses into an overlay below the large breakpoint |

### 1.3 Shared visual anatomy

```text
+--------------------------------------------------------------+
| Brand / title                 Search     Alerts   Profile   |
+--------------------------------------------------------------+
|                                                              |
| Page heading                 Primary action                 |
| Supporting text / filters                                      |
|                                                              |
| [Summary card] [Summary card] [Summary card]                 |
|                                                              |
| Main content: list / table / form / chart                    |
|                                                              |
+--------------------------------------------------------------+
```

Every screen should define:

1. Loading state
2. Empty state with a useful next action
3. Error state with retry
4. Success feedback
5. Permission/role-restricted state where applicable
6. Destructive-action confirmation where applicable

## 2. Mobile application wireframes

Mobile route definitions are implemented in
[`lib/main.dart`](../stitchcraft-mobile/lib/main.dart).

### 2.1 Startup and onboarding

#### Splash screen — `/`

```text
+---------------------------+
|                           |
|        [scissors]         |
|        StitchCraft        |
|       Made for Bharat     |
|                           |
|       [loading]           |
+---------------------------+
```

- Checks the persisted session and secure auth token.
- Routes authenticated users to Home and others to Language.
- Must remain visually stable while localization, theme, and mobile services
  initialize.

#### Language selection — `/language`

```text
+---------------------------+
| Language settings         |
| Select your language      |
| તમારી ભાષા પસંદ કરો       |
|                           |
| [✓ English           >]   |
| [  ગુજરાતી           >]   |
| [  हिंदी             >]   |
+---------------------------+
```

- Available locales: English, Gujarati, Hindi.
- On first use continues to onboarding.
- When opened from settings, returns to the previous screen after selection.

#### Onboarding carousel — `/onboarding`

```text
+---------------------------+
|                           |
|       [feature art]       |
|   Offline-first tailoring |
|   Orders • Khata • Stock  |
|                           |
|          ● ○ ○            |
| [Skip]             [Next] |
+---------------------------+
```

- Feature introduction carousel.
- Final action continues to Login/Register.

### 2.2 Authentication

#### Login — `/login`

```text
+---------------------------+
| StitchCraft               |
| Welcome back              |
|                           |
| Email                     |
| [____________________]    |
| Password             [◉]  |
| [____________________]    |
| [Forgot password?]        |
|                           |
| [        Login        ]   |
|                           |
| New here? [Register]      |
+---------------------------+
```

- Email/password sign-in.
- Password visibility toggle.
- Validation and authentication error state.
- Successful login provisions local session data and routes according to account
  setup state.

#### Forgot password

```text
+---------------------------+
| Reset password            |
| Registered email          |
| [____________________]    |
| [Send reset link]         |
|                           |
| [Back to login]           |
+---------------------------+
```

#### Role confirmation — `/role_selection`

```text
+---------------------------+
| Access is assigned        |
| Your role comes from your |
| account or shop invite.  |
|                           |
| [Continue]                |
+---------------------------+
```

#### Shop setup — `/shop_setup`

```text
+---------------------------+
| Set up your shop          |
| Shop name                 |
| [____________________]    |
| Address                   |
| [____________________]    |
|                           |
| [Create shop]             |
+---------------------------+
```

### 2.3 Main shell and dashboard

#### Main navigation — `/home`

```text
+---------------------------+
| StitchCraft       [🔔]    |
+---------------------------+
|                           |
|       Current module      |
|                           |
+---------------------------+
| Home | Orders | Customers |
| Khata | More       [+] |
+---------------------------+
```

The shell hosts the dashboard and exposes Customers and Khata directly. More is
the single destination for Shop Hub, Repairs, Notifications, Profile, staff,
and settings. The cloud badge is available from every app bar and shows pending
offline records.

#### Dashboard

```text
+---------------------------+
| Good morning, Masterji    |
| [Sync: Up to date]        |
|                           |
| [Due today] 3 orders      |
| [Late] 2 orders           |
| [Money to collect] ₹12,500|
|                           |
| Order pipeline             |
| [Incoming] [Stitching]    |
| [Checking] [Ready]        |
|                           |
| Recent orders              |
+---------------------------+
```

- Action cards for Due today, Late, and Money to collect.
- Backend-aligned stages: Incoming, Measuring, Cutting, Stitching, Checking,
  Ready, Delivered, and Cancelled. Trial is not shown.
- Recent activity and notification entry point.
- Loading, offline, and empty dashboard states.

### 2.4 Orders

#### Order list — `/orders_pending`, `/deliveries`

```text
+---------------------------+
| Orders                    |
| [Search orders... ] [≡]   |
| [Today] [Late] [Ready]    |
| [Unpaid]                  |
|                           |
| [Order card]              |
| Customer • garment        |
| Due date • amount         |
| Status badge        [>]   |
|                           |
|                         [+]|
+---------------------------+
```

- Search/filter by status and delivery state.
- Cards expose customer, garment, due date, amount, urgency, and status.
- Empty state links to New Order.

#### Five-step create-order wizard

Routes: Launched via bottom bar `+` action to `/create_order_customer`, with step routing across `/create_order_customer`, `/create_order_step1`, `/create_order_step3`, `/create_order_step4`, and `/create_order_step5`.

Common frame:

```text
+---------------------------+
| < Back     New order  2/5 |
| [●][●][○][○][○]           |
|                           |
| Step content              |
|                           |
| [Save draft] [Continue]   |
+---------------------------+
```

1. **Customer selection (`/create_order_customer`)**: search existing customer or create a new customer record.
2. **Garment selection (`/create_order_step1`)**: add one or more garment categories and item types.
3. **Measurements (`/create_order_step3`)**: measurement fields, voice input, notes, and photo attachment.
4. **Optional details (`/create_order_step4`)**: fabric, lining/astar, inventory, and karigar assignment.
5. **Pricing and confirmation (`/create_order_step5`)**: price, advance, delivery date, running total,
   rush flag, and final review.

Each step preserves entered values when navigating backward, supports “use last
measurements”, and validates before continuing. Measurement entry includes an
in/cm toggle, fraction keypad, and sensible bounds. After an advance is saved,
the confirmation state offers WhatsApp receipt sharing.

#### Order details — `/order_details`

```text
+---------------------------+
| < Orders     Order #123   |
| Customer / phone          |
| Due date • balance        |
| Status: Stitching         |
|                           |
| Garment and measurements  |
| Material and karigar      |
| Payment summary           |
| Notes                     |
|                           |
| [Mark next stage]         |
| [⋮ Invoice • Edit • Delete]|
+---------------------------+
```

- Status transition control.
- Measurement/material summary.
- Payment and notes.
- Invoice, edit, WhatsApp, and delivery actions where permitted.

### 2.5 Customers and measurements

#### Customer list — `/customers`

```text
+---------------------------+
| Customers          [+]    |
| [Search by name/phone]    |
|                           |
| [Avatar] Name             |
| Phone • Last order        |
| Balance              [>]  |
|                           |
+---------------------------+
```

#### Customer details — `/customer_details`

```text
+---------------------------+
| < Customers   Customer    |
| [avatar] Name             |
| Phone / WhatsApp          |
|                           |
| [Orders] [Measurements]   |
| [Ledger] [Notes]          |
|                           |
| Measurement history       |
| Order history             |
| [New order for customer]  |
+---------------------------+
```

- Customer profile, measurements, order history, balance, and contact actions.
- Confirm destructive customer actions.

### 2.6 Khata, payments, and invoices

#### Khata — `/khata`

```text
+---------------------------+
| Khata                     |
| [Income] [Expenses] [Udhar]|
|                           |
| This month                |
| ₹ income   ₹ expenses     |
|                           |
| Ledger rows               |
| Date • description • ₹    |
|                           |
|                      [+]  |
+---------------------------+
```

- Udhar is the default tab and shows total outstanding above the customer list.
- Income and Expenses have separate labeled add actions; no ambiguous global plus.
- Add expense bottom sheet.
- WhatsApp reminder action for pending customer balances.

#### Payments — `/payments`

- Payment history and balance summary.
- Payment capture form: amount, method, note, and order/customer.
- Validation prevents invalid or over-limit amounts.

#### Invoice list/detail — `/invoices`, `/invoice_details`

```text
+---------------------------+
| Invoices                  |
| [Search / filter]         |
| [Invoice row] [View]      |
|                           |
| Invoice details           |
| Shop/customer             |
| Items • totals • advance  |
| [Print] [Share] [PDF]     |
+---------------------------+
```

### 2.7 Shop operations

#### Shop Hub — `/shop_hub`

```text
+---------------------------+
| Shop management           |
| [Inventory] [Karigars]    |
| [Machines]  [Repairs]     |
| [Shop setup/settings]     |
+---------------------------+
```

#### Inventory — `/inventory`, `/inventory_details`

- Inventory summary with low-stock indicators.
- Item detail/edit view with item type, quantity, unit cost, and threshold.
- Add/edit form and delete confirmation.

#### Karigars — `/karigars`, `/karigar_details`

- Karigar cards/list with specialty and status.
- Detail view with contact, assignment, performance, and order history.
- Add/edit/delete actions according to role.

#### Machines (Web Dashboard only — `/machines`)

- *Note*: Machine registry and maintenance tracking is currently implemented on the Web Dashboard (`/machines`). It is omitted from the mobile application navigation.
- Web feature includes machine registry with type, serial number, and maintenance state (`Working`, `Under Maintenance`, `Broken`).

#### Repairs — `/repairs`

- Repair dashboard with pending, active, and completed repair jobs.
- Customer, service type, complexity, photos, price, notes, and completion state.

### 2.8 Profile, sync, notifications, and settings

#### Profile — `/profile`

```text
+---------------------------+
| Profile                   |
| [Profile] [Shops]         |
| [Shop manage] [Settings]  |
| [Security]                |
|                           |
| Account/shop content      |
| [Sync status]             |
| [Language] [Theme]        |
| [Logout]                  |
+---------------------------+
```

Profile tabs cover account information, shops, shop management, settings, and
security. Owner-only actions must be visibly restricted.

#### Sync status

- Pending count by entity.
- Last successful sync time.
- Failed record list.
- Manual Sync Now action.
- Error state must explain that local data is retained.

#### Notifications — `/notifications`

- Notification list with read/unread state.
- Mark-one-read and mark-all-read controls.
- Notification tap should route to the relevant order/customer when payload data
  is available.

## 3. Web application wireframes

Web routes are implemented in
[`src/App.jsx`](../stitchcraft-frontend/src/App.jsx), inside the authenticated
[`AppLayout`](../stitchcraft-frontend/src/components/layout/AppLayout.jsx).

### 3.1 Web shell

```text
+------------------+---------------------------------------------+
| StitchCraft      | Page title        Search  Alerts  User     |
| ERP Platform     +---------------------------------------------+
| Dashboard        |                                             |
| Orders           | Page content                                |
| Customers        |                                             |
| Deliveries       |                                             |
| Invoices         |                                             |
| Payments         |                                             |
| Karigars         |                                             |
| Machines         |                                             |
| Inventory        |                                             |
| Ledger           |                                             |
| Staff*           |                                             |
|                  |                                             |
| [Logout]         |                                             |
+------------------+---------------------------------------------+
```

`Staff` is visible to owners and managers. The sidebar collapses into a mobile
overlay below the large breakpoint. The topbar supplies the current page title,
notifications, theme/language/account controls, and menu toggle.

### 3.2 Public authentication pages

#### `/login`

- Centered authentication card.
- Email, password, visibility toggle, submit, forgot-password link, and signup
  link.
- Loading, invalid credentials, and session restoration states.

#### `/signup`

- Owner/shop registration form.
- Account credentials, owner identity, shop details, validation, and confirmation.

#### `/forgot-password`

- Email field, submit action, success confirmation, and return-to-login link.

#### `/reset-password`

- Recovery-token state.
- New password and confirmation fields.
- Expired/invalid token state and successful reset confirmation.

### 3.3 Public invoice

#### `/invoice/share/:id`

```text
+--------------------------------------------------------------+
| StitchCraft / Invoice                                        |
| Shop logo and contact                                        |
| Customer                                                     |
| Items              Qty       Price                           |
| Subtotal / advance / balance                                 |
| UPI QR or payment instruction                                |
| [Print] [Download/share]                                     |
+--------------------------------------------------------------+
```

Only customer-safe invoice data is shown. Internal workshop data, margins,
wholesale costs, and staff identifiers must not appear.

### 3.4 Dashboard

#### `/dashboard`

```text
+--------------------------------------------------------------+
| Dashboard                             [New order]            |
| [Orders] [Revenue] [Pending] [Customers]                    |
|                                                              |
| Weekly stitching chart       Calendar / reminders            |
|                                                              |
| Performance tracker          Recent orders                   |
|                                                              |
| Low stock / payment / delivery alerts                        |
+--------------------------------------------------------------+
```

Components include calendar, weekly chart, performance tracker, reminders,
recent orders, stat cards, and actionable alerts.

### 3.5 Orders

#### `/orders`

- Registry table with search, status filters, date filters, customer, amount,
  delivery date, and row actions.
- Primary action: New Order.
- Empty, loading, API error, and pagination states.

#### `/new-order`

```text
+--------------------------------------------------------------+
| New order                                      Step 1 of 3   |
| [Customer and garment] [Measurements] [Pricing and review]  |
|                                                              |
| Form fields / customer search / measurement form             |
|                                                              |
| [Save draft]                                  [Continue]     |
+--------------------------------------------------------------+
```

The web wizard is three steps: customer/order information, measurements, and
pricing/review. It is separate from the five-step mobile wizard but writes the
same order domain.

#### `/orders/:id`

- Order header with status and customer.
- Garment/material/measurement summary.
- Timeline/status controls.
- Notes, payment ledger, invoice link, edit, delete confirmation, and share.

#### `/orders/:id/edit`

- Pre-filled order form.
- Editable customer, measurements, material, price, delivery date, and status.
- Unsaved-change warning and validation summary.

### 3.6 Customers

#### `/customers`

- Searchable customer registry table/list.
- Add customer action.
- Name, phone, email, last order, balance, and open-detail action.

#### `/customers/:id`

- Customer profile header.
- Contact and WhatsApp actions.
- Measurement history.
- Order history.
- Ledger/balance summary.
- New-order action for the customer.

### 3.7 Financial operations

#### `/payments`

- Payment tracking table across orders.
- Filters by date, method, customer, and status.
- Payment modal with amount, method, note, and order.
- Success/error feedback and balance recalculation.

#### `/ledger`

```text
+--------------------------------------------------------------+
| Ledger                         [Add expense]                 |
| [Journal] [Income] [Expenses] [Pending balances / Udhar]    |
|                                                              |
| Total income     Total expenses     Outstanding              |
|                                                              |
| Ledger rows / pending balance cards                         |
+--------------------------------------------------------------+
```

- Journal, income, expenses, and pending balances tabs.
- Udhar rows include customer, amount due, age, and WhatsApp reminder.

#### `/invoices`, `/invoices/:id`

- Invoice registry with search/filter.
- Invoice detail with printable layout, totals, payment status, and share/print
  actions.

#### `/deliveries`

- Delivery queue grouped or filtered by due date and status.
- Customer/order details, delivery confirmation, balance check, and completion
  action.

### 3.8 Workshop operations

#### `/karigars`, `/karigars/:id`

- Registry cards/table with specialty, active assignments, and performance.
- Detail page with profile, order history, assignment/status information, and
  edit actions.

#### `/machines`

- Machine registry with type, serial number, status, and maintenance information.
- Add/edit modal and status/maintenance action.

#### `/inventory`

- Inventory table with item type, quantity, cost, low-stock threshold, and status.
- Add/edit modal.
- Delete modal with explicit confirmation.
- Low-stock visual emphasis and filtering.

#### `/staff`

- Owner/manager-visible staff registry.
- Invite member, role assignment, active/inactive toggle, and unlink action.
- Role restrictions and forbidden state.

### 3.9 Profile and notifications

#### `/profile`

```text
+--------------------------------------------------------------+
| Profile                                                     |
| [Profile] [Shop info] [Settings] [Security]                |
|                                                              |
| Tab content                                                  |
|                                                              |
| Shops: switch/add/delete shop                               |
| Settings: language/theme/UPI/GST/logo/prefix                |
| Security: password and privacy actions                      |
| Data: export/import with conflict confirmation               |
+--------------------------------------------------------------+
```

Profile components include shop switching, shop modal, UPI/GST/logo settings,
password change, data conflict resolution, privacy confirmation, deletion
reason, and delete-shop confirmation.

#### `/notifications`

- Alert feed with unread styling.
- Mark read and mark all read.
- Order, inventory, payment, and delivery notification categories.

#### `*` — Not Found

- Friendly 404 message.
- Return to dashboard action.

## 4. Cross-platform state and interaction rules

### Loading

Use skeletons or progress indicators inside the relevant content region. Do not
replace the entire application shell for a page-level request.

### Empty states

Every empty list must state what is empty and provide the primary action:

- No orders → Create new order
- No customers → Add customer
- No inventory → Add inventory item
- No ledger entries → Add income/expense
- No notifications → Continue working

### Errors

- Preserve unsaved form input.
- Explain whether the failure is network, authentication, validation, or server
  rejection.
- Provide Retry where safe.
- For mobile sync failures, keep the local record queued and expose it in Sync
  Status.

### Destructive actions

Delete order, customer, inventory, shop, staff unlink, data wipe, and account
actions require a confirmation modal/dialog. The confirmation must identify the
target and explain irreversible effects.

### Role visibility

| Area | Owner | Manager | Staff | Karigar |
|---|---:|---:|---:|---:|
| Dashboard/analytics | Full | Full | Limited | Limited |
| Orders | Full | Full | Assigned | Status/assigned |
| Customers/measurements | Full | Full | Full | None |
| Ledger/expenses | Full | Read/create as permitted | None | None |
| Inventory | Full | Full | Read | None |
| Karigars/machines | Full | Full | None | None |
| Staff management | Full | None | None | None |
| Shop settings/data deletion | Full | None | None | None |

The UI should hide unavailable actions and the backend must still enforce every
permission.

## 5. Accessibility and responsive acceptance checklist

- All fields have visible labels and validation messages.
- Touch targets are at least 44 logical pixels on mobile.
- Keyboard focus is visible on web.
- Dialogs and bottom sheets can be dismissed without losing form data.
- Text remains readable at larger font scales.
- Color is not the only status indicator.
- Tables have a card or horizontal-scroll fallback on narrow screens.
- Charts include a textual summary.
- Hindi and Gujarati strings fit without clipping.
- Offline/sync state is visible without relying only on color.

## 6. Implementation references

- Mobile routes and startup: [`stitchcraft-mobile/lib/main.dart`](../stitchcraft-mobile/lib/main.dart)
- Mobile services and sync: [`stitchcraft-mobile/lib/core/services/`](../stitchcraft-mobile/lib/core/services/)
- Web route hierarchy: [`stitchcraft-frontend/src/App.jsx`](../stitchcraft-frontend/src/App.jsx)
- Web shell: [`stitchcraft-frontend/src/components/layout/AppLayout.jsx`](../stitchcraft-frontend/src/components/layout/AppLayout.jsx)
- Web navigation: [`stitchcraft-frontend/src/components/layout/Sidebar.jsx`](../stitchcraft-frontend/src/components/layout/Sidebar.jsx)
- Web page components: [`stitchcraft-frontend/src/pages/`](../stitchcraft-frontend/src/pages/)
