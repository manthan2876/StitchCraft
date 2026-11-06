-- ============================================================================
-- StitchCraft Phase 6: Relational Scalability, Indexes & Verification Migration
-- ============================================================================
-- Adds high-volume relational tables (sync_mutations, inventory_movements),
-- typed columns, performance composite indexes, and integrity check constraints.

-- 1. Sync Mutations Table (Offline-first idempotent sync ledger)
create table if not exists public.sync_mutations (
  id text primary key,
  shop_id text not null,
  mutation_id text not null,
  entity text not null,
  action text not null,
  version integer not null default 1,
  payload jsonb not null default '{}'::jsonb,
  status text not null default 'applied',
  applied_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  constraint uq_sync_mutations_shop_mutation unique (shop_id, mutation_id)
);

-- 2. Inventory Movements Table (Stock movement audit trail)
create table if not exists public.inventory_movements (
  id text primary key,
  shop_id text not null,
  item_id text not null,
  order_id text,
  type text not null, -- consumption, return, adjustment, purchase, wastage
  quantity numeric not null,
  unit text not null default 'meters',
  notes text,
  created_at timestamptz not null default now()
);

-- 3. Shop Memberships Table (Multi-user shop access & role assignments)
create table if not exists public.shop_memberships (
  id text primary key,
  shop_id text not null,
  user_id text not null,
  role text not null default 'staff',
  permissions jsonb not null default '[]'::jsonb,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint uq_shop_membership unique (shop_id, user_id)
);

-- 4. Add Typed Columns to Relational Tables if not already present
do $$
begin
  -- orders
  alter table public.orders add column if not exists status text;
  alter table public.orders add column if not exists price numeric check (price >= 0);
  alter table public.orders add column if not exists delivery_date timestamptz;
  alter table public.orders add column if not exists is_deleted boolean default false;
  alter table public.orders add column if not exists delegated_to_shop_id text;

  -- customers
  alter table public.customers add column if not exists phone text;
  alter table public.customers add column if not exists name text;
  alter table public.customers add column if not exists is_deleted boolean default false;

  -- payments
  alter table public.payments add column if not exists amount numeric check (amount >= 0);
  alter table public.payments add column if not exists balance_amount numeric;
  alter table public.payments add column if not exists payment_status text;

  -- ledger_entries
  alter table public.ledger_entries add column if not exists amount numeric;
  alter table public.ledger_entries add column if not exists type text;
  alter table public.ledger_entries add column if not exists category text;
  alter table public.ledger_entries add column if not exists entry_date date;

  -- inventory
  alter table public.inventory add column if not exists item_name text;
  alter table public.inventory add column if not exists stock_quantity numeric check (stock_quantity >= 0);
  alter table public.inventory add column if not exists unit text;
exception
  when others then null;
end;
$$;

-- 5. Required Performance Composite Indexes (Phase 10.4)
-- Orders
create index if not exists idx_orders_shop_created
  on public.orders (shop_id, created_at desc);

create index if not exists idx_orders_shop_status
  on public.orders (shop_id, status);

create index if not exists idx_orders_shop_delivery
  on public.orders (shop_id, delivery_date asc);

create index if not exists idx_orders_delegated_shop
  on public.orders (delegated_to_shop_id)
  where delegated_to_shop_id is not null;

-- Customers
create index if not exists idx_customers_shop_phone
  on public.customers (shop_id, phone);

create index if not exists idx_customers_shop_created
  on public.customers (shop_id, created_at desc);

-- Payments
create index if not exists idx_payments_shop_order
  on public.payments (shop_id, order_id);

create index if not exists idx_payments_shop_created
  on public.payments (shop_id, created_at desc);

-- Transactions
create index if not exists idx_transactions_shop_order
  on public.transactions (shop_id, order_id);

create index if not exists idx_transactions_shop_payment
  on public.transactions (shop_id, payment_id);

-- Ledger Entries
create index if not exists idx_ledger_entries_shop_date
  on public.ledger_entries (shop_id, entry_date desc, id desc);

-- Sync Mutations
create index if not exists idx_sync_mutations_shop_applied
  on public.sync_mutations (shop_id, applied_at desc);

-- Inventory Movements
create index if not exists idx_inventory_movements_shop_item
  on public.inventory_movements (shop_id, item_id, created_at desc);

-- Enable RLS on new tables
alter table public.sync_mutations enable row level security;
alter table public.inventory_movements enable row level security;
alter table public.shop_memberships enable row level security;
