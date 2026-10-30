create table if not exists public.app_records (
  collection text not null,
  source_id text not null,
  document jsonb not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (collection, source_id)
);

create or replace function public.touch_app_record()
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
for each row execute function public.touch_app_record();

create index if not exists app_records_collection_idx
  on public.app_records (collection);

alter table public.app_records enable row level security;

comment on table public.app_records is
  'Runtime application documents during the Supabase cutover. Access is server-role only.';

insert into storage.buckets (id, name, public)
values
  ('profile-images', 'profile-images', false),
  ('maap-images', 'maap-images', false)
on conflict (id) do update set public = excluded.public;
