-- Development/current cutover: allow server and authenticated clients to
-- read and write application documents. Supabase RLS is intentionally disabled
-- for this deployment until tenant-level policies are configured.
alter table if exists public.app_records disable row level security;

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'users', 'shops', 'customers', 'measurements', 'orders', 'payments',
    'transactions', 'ledger_entries', 'inventory', 'karigars', 'machines',
    'deliveries', 'notifications', 'action_logs', 'inventory_movements',
    'sync_mutations', 'shop_memberships'
  ]
  loop
    if to_regclass(format('public.%I', table_name)) is not null then
      execute format('alter table public.%I disable row level security', table_name);
    end if;
  end loop;
end;
$$;
