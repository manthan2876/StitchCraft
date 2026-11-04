# StitchCraft Mobile UX Audit

Scope: `stitchcraft-mobile/`, compared with
[`MOBILE_WEB_WIREFRAMES.md`](./MOBILE_WEB_WIREFRAMES.md) and the product
context. This is a read-only review. Findings are based on source inspection;
device-only behavior is marked **Unverified**.

## Summary

| Screen / flow | UX score (1-5) | Worst problem | Severity | Evidence |
|---|---:|---|---|---|
| Startup, splash, language, onboarding | 3 | First-run path is long and splash/session behavior is not device-verified | Major | `lib/main.dart:49-106`; wireframes §2.1 |
| Login and password reset | 3 | Many strings and async feedback are not consistently localized or lifecycle-safe | Major | `features/auth/screens/login_screen.dart:1-80` |
| Role confirmation | 4 | Role choice is removed, but the route still says “Choose Role” and role-specific home is not established | Minor | `features/auth/screens/role_selection_screen.dart:9-57` |
| Shop setup | 3 | Required fields and first-shop completion path need clearer progress and recovery | Major | `features/shop/screens/shop_setup_screen.dart:1-220` |
| Main navigation | 3 | Six bottom actions compete for width; More becomes a catch-all | Major | `features/dashboard/screens/main_navigation_container.dart:80-164` |
| More / Shop Hub | 3 | Important operational destinations are one level deeper and section labels are hardcoded | Major | `features/dashboard/screens/more_hub_screen.dart:10-86` |
| Home dashboard | 3 | Daily priority cards exist, but the screen is still dominated by a cash-flow chart and local heuristic data | Major | `features/dashboard/screens/dashboard_screen.dart:430-680` |
| Orders list | 3 | Ten horizontal status chips plus search create dense scanning and weak empty/error recovery | Major | `features/orders/screens/order_list_screen.dart:134-238` |
| New order: customer | 3 | Returning customers are supported, but the new/existing choice and duplicate dialog add typing and decisions | Major | `features/orders/screens/create_order/step2_customer.dart:25-225` |
| New order: garment | 3 | Garment selection is image-placeholder based and route labels show “2 of 5” while it is the first garment screen | Major | `features/orders/screens/create_order/step1_garment.dart:31-83` |
| New order: measurements | 3 | Fraction support exists, but fields lack garment diagrams, bounds and clear voice affordance guidance | Major | `features/orders/screens/create_order/step3_measurements.dart:70-185` |
| New order: material | 3 | Inventory fallback can show all materials and the step mixes fabric photo, source and astar quantity | Major | `features/orders/screens/create_order/step4_material.dart:65-157` |
| New order: review/payment | 3 | Running total/advance are present, but draft resume, multiple garments and receipt-after-payment are absent or Unverified | Major | `features/orders/screens/create_order/step5_details.dart:178-426` |
| Order details | 3 | Status changes are in a popup rather than one obvious next-stage action; primary action hierarchy is weak | Major | `features/orders/screens/order_details_screen.dart:688-930` |
| Customers list | 3 | Search/add is useful, but loading, empty and offline affordances vary by path | Major | `features/orders/screens/customer_list_screen.dart:39-180` |
| Customer details | 3 | Tabs combine profile/orders/measurements without a prominent repeat-order or reuse-measurements action | Major | `features/orders/screens/customer_details_screen.dart:230-430` |
| Khata/Udhar | 3 | Udhar is the default, but payment collection is not the dominant action and amount formatting is inconsistent | Major | `features/khata/screens/khata_screen.dart:74-116`; `features/khata/widgets/udhar_list.dart:25-190` |
| Deliveries | 2 | The route is a filtered order list, not a delivery-focused queue with clear deliver/partial-payment handling | Critical | `lib/main.dart:180-183`; wireframes §2.4 |
| Payments and invoices | 3 | They have entry points, but are buried under More and invoice actions use dense detail screens | Major | `features/dashboard/screens/more_hub_screen.dart:22-34`; `features/orders/screens/invoice_details_screen.dart:200-442` |
| Inventory | 3 | Material forms are compact but not optimized for rapid stock adjustment or unit clarity | Major | `features/shop/screens/inventory_screen.dart:100-240` |
| Karigars and machines | 2 | There is no simplified karigar “My jobs” experience; staff registry is owner/manager-oriented | Critical | `features/shop/screens/karigars_screen.dart:1-160`; wireframes §2.6 |
| Repairs | 2 | Hardcoded service catalogue and local-only ticket flow look production-ready without clear prototype labeling | Major | `features/repairs/screens/repair_dashboard.dart:17-185` |
| Notifications | 2 | Tapping a notification does not provide an actionable destination | Major | `features/notifications/screens/notifications_screen.dart:24-103`; `core/services/notification_service.dart:185-191` |
| Profile/settings/security | 2 | Four tabs plus shop settings, sync, theme, language and danger actions create a high-risk catch-all | Critical | `features/profile/screens/profile_screen.dart:25-44`; `features/shop/screens/shop_settings_screen.dart:190-359` |
| Sync/offline feedback | 3 | A reusable banner exists but sync is not persistently visible on every screen and record-level pending state is weak | Major | `core/widgets/state_views.dart:92-143`; `core/widgets/custom_app_bar.dart:39-133` |
| Localization | 3 | ARB key coverage is complete, but many screens still hardcode English strings and mixed Gujarati/English labels | Major | `lib/l10n/app_en.arb:1-143`; `step3_measurements.dart:220-241` |
| Themes and visual system | 3 | Shared tokens exist, but screens bypass them with direct colors and fixed dark surfaces | Major | `core/theme/app_theme.dart:1-220`; `repair_dashboard.dart:54-105` |
| Accessibility and performance | 2 | Some semantics and 56dp primary buttons exist, but 200% text scale, focus order and device performance are Unverified | Critical | `core/widgets/primary_button.dart:20-55`; `main_navigation_container.dart:101-135` |

## Per-flow review

### First run and authentication

**User goal:** choose a familiar language, understand the value quickly, sign
in, and reach a usable shop.

**Current experience:** language, carousel, login, role confirmation and shop
setup are separate routes. `main.dart` initializes Supabase, language, theme,
Firebase, notifications and sync before rendering
(`lib/main.dart:49-106`). The wireframe expects this sequence, but it can be
five decisions before the first order.

**Friction and root cause:**

* The carousel adds value only for a new owner; invited staff/karigar users
  should skip it. The route architecture has no evidence of role/account-aware
  shortening.
* The role screen is correctly confirmation-only, but the route title/key
  remains `choose_role` and the copy is hardcoded English
  (`role_selection_screen.dart:9-55`).
* `MainNavigationContainer` performs a second session/shop check
  (`main_navigation_container.dart:23-64`), which can create a visible loading
  hop after splash. Exact behavior is **Unverified** on device.
* Login analyzer findings include `use_build_context_synchronously`
  (`login_screen.dart:44-46`), a reliability issue during fast navigation.

**Right direction:** Supabase is initialized before the app and role
self-selection is not available in the current screen.

**Verdict:** Reduce first-run steps, make them account-aware, and use localized
copy with explicit progress.

### Navigation, Home and More

**User goal:** see what must be done today and reach Orders, Customers and
Udhar with one thumb.

The bottom shell matches the wireframe’s five destinations plus centered New
Order, but visually renders six competing controls in a 70px container
(`main_navigation_container.dart:80-164`). The app bar independently exposes
notifications, sync and profile (`custom_app_bar.dart:89-133`), while More
contains inventory, karigars, machines, repairs, invoices, payments,
deliveries, notifications, profile, shop settings and sync
(`more_hub_screen.dart:10-34`). This is complete but not task-prioritized.

The dashboard does answer “what today?” through Due today, Late and Money to
collect cards (`dashboard_screen.dart:500-544`), which is good. However, the
cash-flow graph and filter consume substantial vertical space before recent
orders, and the cards route Due/Late to the same `/orders_pending` destination
without passing a distinct filter (`dashboard_screen.dart:511-521`).

**Verdict:** Keep the shell, but promote Today’s queue and make every priority
card land on the matching filtered list.

### Orders list and deliveries

**User goal:** find the next customer/order quickly and complete today’s
deliveries.

The list has search and all backend-aligned stages
(`order_list_screen.dart:39-78`, `order_list_screen.dart:134-238`). The ten
chips are horizontally scrollable, which is efficient for power users but hard
to discover one-handed and difficult in Hindi/Gujarati. Empty/error handling is
not consistently represented by the shared state components.

The deliveries route is only `OrderListScreen(title: 'Deliveries',
statusFilter: 'completed')` (`main.dart:180-183`). That wording does not
communicate “ready to hand over”, and “completed” may not match the backend’s
`Delivered` stage. A delivery queue should show due time, balance, customer
contact and one primary Deliver action.

**Verdict:** The list is serviceable; deliveries need a dedicated task view.

### New order wizard

**User goal:** register a customer, capture a garment and measurements, record
price/advance, and leave the counter with a reliable order.

The current sequence is customer → garment → measurements → material → review,
implemented by navigation between routes
(`step2_customer.dart:184-225`, `step1_garment.dart:54-78`,
`step3_measurements.dart:185-219`, `step4_material.dart:140-157`). This is
logical but places customer selection before garment choice, so the first
screen asks a busy operator for a customer decision before showing the order
type.

Friction:

* The customer screen has separate existing/new modes, search, contact import,
  duplicate detection and phone validation. It is powerful but cognitively
  heavy at the counter (`step2_customer.dart:25-225`).
* Garments use generic `Icons.image` placeholders and the title says
  “2 of 5” (`step1_garment.dart:31-39`), a confidence and progress mismatch.
* Measurements support mixed numbers and fractions
  (`step3_measurements.dart:91-114`, `step3_measurements.dart:302-345`),
  but there is no visible garment diagram or per-field plausible range. The
  voice field has mic support, but Hindi/Gujarati availability and numeric
  recognition are **Unverified**.
* Material selection filters inventory but falls back to all available items
  (`step4_material.dart:109-130`), which can expose irrelevant stock and make
  astar selection ambiguous.
* Draft persistence/resume, multiple garments per order and a receipt immediately
  after advance are not evidenced and are **Unverified**.

**Verdict:** Make the wizard “fast path first”: existing customer + last
measurements + one garment + advance, with optional details after saving.

### Order details and status progression

**User goal:** know the next workshop action, contact the customer, collect
money, or deliver.

The screen has a status popup with all stages, edit/delete actions, a production
stepper and quick action area (`order_details_screen.dart:688-930`). It also
supports call/WhatsApp/invoice actions in the detail body.

Friction:

* The next stage is not the primary action; it is one option among edit, delete
  and a popup menu. A masterji must know the workflow rather than being guided.
* Status is also represented by color-coded badges. A text stage and stepper
  exist, but color is still doing too much work.
* The delivery-with-balance confirmation keys exist in English ARB
  (`app_en.arb:139-140`), but the complete delivery interaction and role
  permissions are **Unverified**.
* A legacy “READY FOR TRIAL” message remains in WhatsApp handling
  (`order_details_screen.dart:650-666`) even though Trial is not a backend
  stage. This can confuse customers and staff.

**Verdict:** Replace the popup-first model with “Move to [next stage]” plus
secondary actions.

### Measurements

**User goal:** record accurate measurements with minimal typing.

The screen provides body/sample toggle, in/cm segmented control, fraction
buttons and a voice-enabled field
(`step3_measurements.dart:220-345`; `core/widgets/voice_text_field.dart:44-98`).
Controllers are disposed correctly.

Friction:

* Mixed-language labels such as `Body Measurement (માપ)` and
  `Sample (નમૂનો / Namuna)` are hardcoded into one string and will not adapt
  to the selected locale.
* There is no garment illustration, saved-measurement shortcut or clear
  “repeat last measurement” action.
* `parseMeasurement` accepts any positive value, with no garment-specific
  bounds (`step3_measurements.dart:91-114`).
* The mic is a decorative `GestureDetector` rather than a clearly labeled
  48dp semantic button (`voice_text_field.dart:107-139`). Speech locale and
  numeric recognition are **Unverified**.

**Verdict:** Prioritize numeric accuracy and reuse over visual polish.

### Khata/Udhar and WhatsApp reminders

**User goal:** immediately see who owes money, collect it, and record expenses.

Udhar is the first tab (`khata_screen.dart:80-111`) and shows total outstanding,
per-order due and WhatsApp reminder (`udhar_list.dart:25-190`). This matches the
business need.

Friction:

* The primary action in each card is “Send WhatsApp Reminder”; “Record payment”
  is not equally prominent, although collecting money is usually the next
  counter action.
* The floating action button always says “Add Expense”, even when the user is
  viewing Udhar or Income (`khata_screen.dart:99-108`). Its meaning changes by
  context only through a label that is not localized.
* Amounts use `toStringAsFixed(0)` rather than a shared Indian grouping formatter
  (`udhar_list.dart:74-159`).
* Empty Udhar is reassuring but has no next action to review paid orders or
  create a new order (`udhar_list.dart:39-59`).

**Verdict:** Keep Udhar first; make payment collection the primary card action
and expense creation contextual.

### Customers and customer details

**User goal:** find a person, see history and measurements, and start a repeat
order quickly.

The customer list supports search, add, device contacts and duplicate-phone
checking (`customer_list_screen.dart:39-180`; `step2_customer.dart:145-225`).
Customer details merge remote/local orders and measurements and expose two tabs
(`customer_details_screen.dart:20-210`).

Friction:

* The high-value “New order with these measurements” action is not established
  as the primary action on the details screen; exact placement is
  **Unverified** in the truncated lower section.
* Local/remote merge by phone/name can make records appear unexpectedly; the
  UI needs a clear “local/offline” marker.
* Contact import asks for device permission as part of the add flow; the reason
  and fallback are not consistently explained.

**Verdict:** Make repeat ordering the primary customer-detail action.

### Profile, settings, security and shop management

**User goal:** change shop/account settings safely without accidentally touching
  destructive actions.

Profile has four tabs (`profile_screen.dart:25-44`) and separate Shop Settings
now exists at `/shop_settings` (`main.dart:186-187`). Shop deletion has a
confirmation dialog and owner check (`shop_settings_screen.dart:135-203`).

Friction:

* Four tabs are too many for a shared shop phone; language/theme/sync/logout
  should be a compact Settings list, while identity and shop administration
  should be separate.
* Destructive operations are still close to routine account settings in the
  profile surface. Account deletion/wipe behavior and owner-only visibility are
  **Unverified** from the visible profile lower section.
* The fixed dark dialog/list surfaces in profile/shop screens bypass the active
  theme and can be illegible in light mode (`profile_screen.dart:91-105`,
  `shop_settings_screen.dart:190-220`).

**Verdict:** Separate “My account”, “Shop”, “Preferences”, “Sync” and
“Danger zone”.

### Karigar, inventory, repairs and notifications

Karigar management is a registry form intended for managers/owners, not a
karigar work queue (`karigars_screen.dart:1-160`). A simplified “My jobs” view
is not present and is a critical role UX gap.

Inventory forms use bottom sheets with name/category/quantity/unit price
(`inventory_screen.dart:100-240`), but fast stock adjustments, low-stock
priorities and unit-specific input are not prominent.

Repairs present a hardcoded catalogue and create tickets locally
(`repair_dashboard.dart:17-185`). The production status/prototype boundary is
not communicated.

Notifications list and read actions exist, but notification taps and push taps
do not open the related order/customer (`notification_service.dart:185-191`).

### Offline, states, accessibility and visual language

Reusable `LoadingView`, `EmptyStateView`, `ErrorStateView` and `OfflineBanner`
exist (`core/widgets/state_views.dart:4-143`). The app bar shows a sync badge and
manual sync (`core/widgets/custom_app_bar.dart:39-133`). These are good
foundations, but adoption is inconsistent: many screens use raw
`CircularProgressIndicator`, `debugPrint`, or snackbars instead of the shared
states.

`PrimaryButton` is 56dp high (`core/widgets/primary_button.dart:20-55`), but
many list/filter controls use compact padding and `GestureDetector`; exact
48dp compliance across the app is **Unverified**. The bottom navigation labels
use 10.5px text and ellipsis (`main_navigation_container.dart:101-135`), risky
for Gujarati/Hindi and 200% text scale.

Theme tokens exist, but direct `Colors.white`, `Colors.white10`, fixed dark
surfaces and hardcoded colors occur throughout feature screens. Contrast,
200% text scale and all three themes on physical devices are **Unverified**.

ARB key counts match across English, Hindi and Gujarati (143 keys), but that
does not mean all visible strings are localized. Direct strings include
“Everything else for your shop”, “Due today”, “Money to collect”, field labels,
status names, repair copy and mixed-language measurement labels.

## Top 10 problems for real shop owners

1. New order takes too many decisions before the first save; no proven draft
   resume or repeat-measurement fast path.
2. The next order-stage action is hidden in a status popup instead of being the
   obvious primary button.
3. Deliveries are a generic filtered order list, not a focused “hand over today”
   queue.
4. Sync status is available, but not persistently clear at record level; users
   cannot easily distinguish local-pending from server-confirmed data.
5. More is overloaded with workshop, money, account and diagnostics.
6. Udhar cards emphasize reminders more than recording a payment.
7. Karigars lack a “My jobs” screen and therefore see an owner-oriented registry.
8. Hindi/Gujarati strings are incomplete in practice despite matching ARB keys;
   mixed-language labels and narrow nav text will increase hesitation.
9. Fixed dark surfaces and direct colors weaken theme consistency and may harm
   contrast.
10. Build-breaking analyzer errors reduce confidence in shipping UI changes and
    can block fast fixes.

## Analyzer result

`flutter analyze` currently reports **26 issues**, including build errors:

* undefined `getAllCustomers` and `getAllInventory` repository methods;
* duplicate `dispose` in `device_contacts_service.dart:316`;
* undefined `_authService` in `dashboard_screen.dart:280`;
* async `BuildContext` warnings in login, contacts, order details and profile;
* dead/null-aware code in customer, invoice and order details;
* deprecated speech `localeId` and dropdown `value` APIs;
* unused dashboard/Khata members and imports.

These are not all visual defects, but they directly affect UX reliability and
must be resolved before UI acceptance testing.

## Unverified items and how to verify

1. First-run route count and splash visual stability: fresh-install Android
   test for owner, invited staff and karigar accounts.
2. 200% text scale, Hindi/Gujarati overflow, screen-reader focus and 48dp hit
   targets: Flutter integration test plus TalkBack on a mid-range Android.
3. Contrast ratio across light, dark and Masterji themes: capture key screens
   and run automated contrast checks plus manual low-brightness review.
4. Voice input accuracy and permission recovery: physical device tests in
   English, Hindi and Gujarati, including numeric fractions.
5. Draft persistence/resume, multiple garments, last-measurement reuse and
   receipt-after-advance: interrupt the wizard at every step, kill/reopen app.
6. Delivery with unpaid balance: test each role and confirm copy, confirmation
   and resulting queue state.
7. Karigar restrictions and assigned-job experience: sign in as each backend
   role and inspect reachable routes/actions.
8. Push notification tap behavior, notification permission prompts and
   terminated-app routing: real FCM Android/iOS test.
9. Offline banners and pending chips on every route: disable network during
   create/edit/payment and verify recovery messaging.
10. Jank, image loading and rotation/background state: profile/orders with
    1,000 records and several photos on a mid-range Android.
