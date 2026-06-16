-- NutriPath Supabase PostgreSQL normalized bootstrap
-- Run this in Supabase SQL Editor when using:
--   NUTRIPATH_DATA_SOURCE=supabase
--   NUTRIPATH_SUPABASE_STORAGE=normalized
--
-- The backend also creates these tables automatically on startup when the
-- database user has DDL permission. This file is provided for team review,
-- production setup, and visible Supabase table structure.

create table if not exists public.nutripath_members (
  id text primary key,
  email text unique not null,
  name text not null,
  tier text,
  role text,
  data jsonb not null,
  updated_at timestamptz not null default now()
);

create table if not exists public.nutripath_foods (
  id text primary key,
  name text not null,
  category text not null,
  calories numeric,
  data jsonb not null,
  updated_at timestamptz not null default now()
);

create table if not exists public.nutripath_plans (
  id text primary key,
  name text not null,
  monthly_price integer,
  data jsonb not null,
  updated_at timestamptz not null default now()
);

create table if not exists public.nutripath_meal_logs (
  id text primary key,
  member_id text not null,
  log_date date not null,
  data jsonb not null,
  updated_at timestamptz not null default now(),
  unique (member_id, log_date)
);

create table if not exists public.nutripath_recipes (
  id text primary key,
  name text not null,
  calories integer,
  data jsonb not null,
  updated_at timestamptz not null default now()
);

create table if not exists public.nutripath_personalized_recipes (
  id text primary key,
  member_id text not null,
  name text not null,
  generated_at timestamptz,
  saved_at timestamptz,
  data jsonb not null,
  updated_at timestamptz not null default now()
);

create table if not exists public.nutripath_payments (
  id text primary key,
  member_id text not null,
  invoice text unique,
  status text,
  paid_at timestamptz,
  data jsonb not null,
  updated_at timestamptz not null default now()
);

create table if not exists public.nutripath_auth_credentials (
  id text primary key,
  member_id text not null,
  email text unique not null,
  data jsonb not null,
  updated_at timestamptz not null default now()
);

create table if not exists public.nutripath_oauth_identities (
  id text primary key,
  member_id text not null,
  provider text,
  provider_user_id text,
  email text,
  data jsonb not null,
  updated_at timestamptz not null default now()
);

create table if not exists public.nutripath_chat_messages (
  id text primary key,
  member_id text not null,
  sender text,
  message_time timestamptz,
  data jsonb not null,
  updated_at timestamptz not null default now()
);

create table if not exists public.nutripath_notifications (
  id text primary key,
  member_id text not null,
  notification_key text,
  read_at timestamptz,
  created_at timestamptz,
  data jsonb not null,
  updated_at timestamptz not null default now()
);

create table if not exists public.nutripath_personal_foods (
  id text primary key,
  member_id text not null,
  name text not null,
  data jsonb not null,
  updated_at timestamptz not null default now()
);

create table if not exists public.nutripath_coach_plans (
  id text primary key,
  member_id text not null,
  created_at timestamptz,
  data jsonb not null,
  updated_at timestamptz not null default now()
);

create table if not exists public.nutripath_ai_safety_logs (
  id text primary key,
  created_at timestamptz,
  data jsonb not null
);

create table if not exists public.nutripath_reference_items (
  collection text not null,
  item_id text not null,
  sort_order integer not null default 0,
  data jsonb not null,
  updated_at timestamptz not null default now(),
  primary key (collection, item_id)
);

create table if not exists public.nutripath_settings (
  setting_key text primary key,
  data jsonb not null,
  updated_at timestamptz not null default now()
);

create index if not exists nutripath_foods_category_idx
  on public.nutripath_foods (category);

create index if not exists nutripath_meal_logs_member_date_idx
  on public.nutripath_meal_logs (member_id, log_date desc);

create index if not exists nutripath_payments_member_paid_idx
  on public.nutripath_payments (member_id, paid_at desc);

create index if not exists nutripath_chat_messages_member_time_idx
  on public.nutripath_chat_messages (member_id, message_time desc);

create index if not exists nutripath_notifications_member_read_idx
  on public.nutripath_notifications (member_id, read_at);
