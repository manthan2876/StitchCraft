-- StitchCraft Supabase schema.
-- The backend currently writes through config/supabaseModel.js, which stores
-- complete documents in app_records. The domain tables below provide stable
-- Supabase tables for reporting and the next relational migration while
-- preserving the existing document-shaped API.

create extension if not exists pgcrypto;

create table if not exists public.app_records (
  collection text not null,
  source_id text not null,
  document jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (collection, source_id)
);

create index if not exists app_records_collection_idx
  on public.app_records (collection);

create index if not exists app_records_document_gin_idx
  on public.app_records using gin (document);

create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists app_records_updated_at on public.app_records;
create trigger app_records_updated_at
before update on public.app_records
for each row execute function public.touch_updated_at();

comment on table public.app_records is
  'Compatibility document store used by the StitchCraft backend model adapters.';

-- Domain tables retain the original document shape while exposing one table
-- per application entity for SQL reporting and future typed-column migration.
create table if not exists public.users (
  id text primary key,
  supabase_id uuid unique,
  email text,
  shop_id text,
  document jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.shops (
  id text primary key,
  owner_id text,
  document jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.customers (
  id text primary key,
  shop_id text,
  document jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.measurements (
  id text primary key,
  shop_id text,
  customer_id text,
  document jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.orders (
  id text primary key,
  shop_id text,
  customer_id text,
  karigar_id text,
  machine_id text,
  document jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.payments (
  id text primary key,
  shop_id text,
  order_id text,
  document jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.transactions (
  id text primary key,
  shop_id text,
  order_id text,
  payment_id text,
  document jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.ledger_entries (
  id text primary key,
  shop_id text,
  document jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.inventory (
  id text primary key,
  shop_id text,
  document jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.karigars (
  id text primary key,
  shop_id text,
  document jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.machines (
  id text primary key,
  shop_id text,
  document jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.deliveries (
  id text primary key,
  shop_id text,
  order_id text,
  document jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.notifications (
  id text primary key,
  shop_id text,
  user_id text,
  document jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.action_logs (
  id text primary key,
  shop_id text,
  user_id text,
  order_id text,
  document jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'users', 'customers', 'measurements', 'orders', 'payments',
    'transactions', 'ledger_entries', 'inventory', 'karigars', 'machines',
    'deliveries', 'notifications', 'action_logs'
  ]
  loop
    execute format(
      'drop trigger if exists %I on public.%I',
      table_name || '_updated_at',
      table_name
    );
    execute format(
      'create trigger %I before update on public.%I for each row execute function public.touch_updated_at()',
      table_name || '_updated_at',
      table_name
    );
    execute format(
      'create index if not exists %I on public.%I (shop_id)',
      table_name || '_shop_id_idx',
      table_name
    );
  end loop;
end;
$$;

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'users', 'customers', 'measurements', 'orders', 'payments',
    'transactions', 'ledger_entries', 'inventory', 'karigars', 'machines',
    'deliveries', 'notifications', 'action_logs'
  ]
  loop
    execute format(
      'create index if not exists %I on public.%I using gin (document)',
      table_name || '_document_gin_idx',
      table_name
    );
  end loop;
end;
$$;

-- Backend service-role access bypasses RLS. Direct client access remains
-- blocked until explicit per-user policies are added.
alter table public.app_records enable row level security;

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'users', 'shops', 'customers', 'measurements', 'orders', 'payments',
    'transactions', 'ledger_entries', 'inventory', 'karigars', 'machines',
    'deliveries', 'notifications', 'action_logs'
  ]
  loop
    execute format('alter table public.%I enable row level security', table_name);
  end loop;
end;
$$;

insert into storage.buckets (id, name, public)
values
  ('profile-images', 'profile-images', false),
  ('maap-images', 'maap-images', false)
on conflict (id) do update set public = excluded.public;
