-- NutriPath Supabase PostgreSQL bootstrap
-- Run this in Supabase SQL Editor before setting NUTRIPATH_DATA_SOURCE=supabase.
--
-- The backend keeps the existing NutriPath API shape by storing the current
-- application state as JSONB. This is the safest first migration step from
-- local JSON/SQL Server to Supabase PostgreSQL without rewriting all routes.

create table if not exists public.nutripath_app_state (
  id text primary key,
  data jsonb not null,
  version integer not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists nutripath_app_state_updated_at_idx
  on public.nutripath_app_state (updated_at desc);

comment on table public.nutripath_app_state is
  'NutriPath backend JSONB state store for Supabase PostgreSQL data source.';
