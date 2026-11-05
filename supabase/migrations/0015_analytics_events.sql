-- 0015_analytics_events.sql — analítica propia, sin depender de un tercero.
--
-- Un evento por acción de producto (torneo creado, inscripción pedida,
-- inscripción confirmada…). Es insert-only para clientes autenticados y no
-- guarda datos personales: sólo el user_id que sale del JWT, el nombre del
-- evento, propiedades no sensibles (deporte, formato, cupo) y metadata de la
-- app. Nadie puede leer la tabla desde el cliente; se consulta desde el
-- dashboard/SQL con service role.
--
-- La app escribe con SupabaseAnalytics (lib/core/observability/analytics.dart)
-- y nunca bloquea una acción si el insert falla.

create table if not exists public.analytics_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  event text not null
    check (char_length(event) between 1 and 64),
  properties jsonb not null default '{}'::jsonb
    check (
      jsonb_typeof(properties) = 'object'
      and pg_column_size(properties) <= 8192
    ),
  app_version text,
  platform text,
  created_at timestamptz not null default now()
);

alter table public.analytics_events enable row level security;

drop policy if exists "Users insert their own analytics events"
  on public.analytics_events;
create policy "Users insert their own analytics events"
  on public.analytics_events for insert
  to authenticated
  with check (user_id = auth.uid());

-- Clients can only insert: no select/update/delete policies exist, and the
-- grants are narrowed on purpose.
revoke all on public.analytics_events from public, anon, authenticated;
grant insert on public.analytics_events to authenticated;

-- Queries are "what happened in the last N days", often per event or user.
create index if not exists analytics_events_created_at_idx
  on public.analytics_events (created_at desc);
create index if not exists analytics_events_event_created_at_idx
  on public.analytics_events (event, created_at desc);
create index if not exists analytics_events_user_created_at_idx
  on public.analytics_events (user_id, created_at desc);

comment on table public.analytics_events is
  'Eventos de producto sin PII. Insert-only para authenticated; lectura sólo '
  'con service role.';

notify pgrst, 'reload schema';
