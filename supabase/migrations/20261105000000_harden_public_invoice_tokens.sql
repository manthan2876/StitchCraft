-- Migration: 20261105000000_harden_public_invoice_tokens.sql
-- Description: Indexes for opaque public invoice share tokens and hashes (P0-01)

create index if not exists app_records_order_share_token_hash_idx
  on public.app_records (((document->>'shareTokenHash')))
  where collection = 'orders';

create index if not exists app_records_order_share_token_idx
  on public.app_records (((document->>'shareToken')))
  where collection = 'orders';

create index if not exists orders_share_token_hash_idx
  on public.orders (((document->>'shareTokenHash')));

create index if not exists orders_share_token_idx
  on public.orders (((document->>'shareToken')));

