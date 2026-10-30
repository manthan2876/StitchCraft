-- StitchCraft Database Table Level Validations & Constraints
-- Enforces integrity on all domain tables

-- 1. Ensure Orders prices cannot be negative
alter table if exists public.orders
  drop constraint if exists check_order_price_non_negative;
alter table if exists public.orders
  add constraint check_order_price_non_negative
  check (
    (document->>'price') is null or
    (document->>'price')::numeric >= 0
  );

-- 2. Ensure Payments amounts are non-negative
alter table if exists public.payments
  drop constraint if exists check_payment_amounts_non_negative;
alter table if exists public.payments
  add constraint check_payment_amounts_non_negative
  check (
    ((document->>'totalAmount') is null or (document->>'totalAmount')::numeric >= 0) and
    ((document->>'paidAmount') is null or (document->>'paidAmount')::numeric >= 0) and
    ((document->>'balanceAmount') is null or (document->>'balanceAmount')::numeric >= 0)
  );

-- 3. Ensure Transactions amounts are strictly positive
alter table if exists public.transactions
  drop constraint if exists check_transaction_amount_positive;
alter table if exists public.transactions
  add constraint check_transaction_amount_positive
  check (
    (document->>'amount') is null or
    (document->>'amount')::numeric > 0
  );

-- 4. Ensure Ledger entries amounts are strictly positive
alter table if exists public.ledger_entries
  drop constraint if exists check_ledger_amount_positive;
alter table if exists public.ledger_entries
  add constraint check_ledger_amount_positive
  check (
    (document->>'amount') is null or
    (document->>'amount')::numeric > 0
  );

-- 5. Ensure Inventory counts and costs are non-negative
alter table if exists public.inventory
  drop constraint if exists check_inventory_non_negative;
alter table if exists public.inventory
  add constraint check_inventory_non_negative
  check (
    ((document->>'quantity') is null or (document->>'quantity')::numeric >= 0) and
    ((document->>'costPerUnit') is null or (document->>'costPerUnit')::numeric >= 0) and
    ((document->>'minQuantity') is null or (document->>'minQuantity')::numeric >= 0)
  );

-- 6. Ensure Users role is in allowed set
alter table if exists public.users
  drop constraint if exists check_user_role_valid;
alter table if exists public.users
  add constraint check_user_role_valid
  check (
    (document->>'role') is null or
    (document->>'role') in ('owner', 'manager', 'karigar', 'staff')
  );

-- 7. Ensure Customers have valid names and phones
alter table if exists public.customers
  drop constraint if exists check_customer_name_not_empty;
alter table if exists public.customers
  add constraint check_customer_name_not_empty
  check (
    (document->>'name') is null or
    length(trim(document->>'name')) >= 2
  );

