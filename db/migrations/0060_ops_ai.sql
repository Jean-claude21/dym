-- 0060 — Antifraude, modération et support assistés (spec 054, phase 13 « ops-center »).
-- L'IA propose, l'équipe décide (VISION §4) :
-- 1. Signaux de fraude : des règles SQL (seuils par règle, données de référence) repèrent les
--    comportements anormaux des dernières 24 h ; un job les écrit une fois par jour et par sujet ;
--    l'équipe les écarte ou les confirme (audité). Rien n'est suspendu automatiquement.
-- 2. Tri des signalements : un job demande au modèle configuré (`moderation_triage`) un avis
--    « garder », « retirer » ou « incertain » avec une raison ; la file de modération l'affiche.
-- 3. Agent support : brouillon de réponse à un ticket, généré à la demande de l'équipe
--    (`support_agent`) ; l'humain relit, modifie et envoie. Sans modèle actif : rien n'est généré.

create table public.fraud_rules (
  kind text primary key check (kind ~ '^[a-z][a-z_]*$'),
  threshold integer not null check (threshold between 1 and 1000),
  is_active boolean not null default true,
  description text not null
);
alter table public.fraud_rules enable row level security;
revoke all on public.fraud_rules from authenticated, anonymous;
insert into public.fraud_rules (kind, threshold, description) values
  ('client_cancel_burst', 3, 'Commandes annulées par une même cliente en 24 h'),
  ('store_refusal_burst', 3, 'Commandes refusées par une même boutique en 24 h'),
  ('shared_device', 3, 'Comptes différents sur un même appareil'),
  ('handover_code_failures', 5, 'Codes de remise faux saisis par un même livreur en 24 h'),
  ('haggle_burst', 9, 'Propositions de marchandage d''une même cliente en 24 h sans achat')
on conflict do nothing;

create table public.fraud_signals (
  id uuid primary key default gen_random_uuid(),
  kind text not null references public.fraud_rules (kind),
  country_code char(2) references public.countries (code),
  subject_type text not null check (subject_type in ('user', 'store')),
  subject_id uuid not null,
  signal_day date not null default current_date,
  detail jsonb not null default '{}'::jsonb,
  status text not null default 'open' check (status in ('open', 'dismissed', 'confirmed')),
  created_at timestamptz not null default clock_timestamp(),
  decided_by uuid references neon_auth."user" (id) on delete set null,
  decided_at timestamptz,
  decision_note text check (decision_note is null or length(decision_note) <= 500),
  unique (kind, subject_id, signal_day)
);
create index fraud_signals_open on public.fraud_signals (country_code, created_at desc) where status = 'open';
alter table public.fraud_signals enable row level security;
revoke all on public.fraud_signals from authenticated, anonymous;

-- Essais de code de remise faux (0049 garde un compteur par commande, remis à zéro à chaque code).
create table public.handover_failures (
  id bigint generated always as identity primary key,
  order_id uuid not null references public.orders (id) on delete cascade,
  courier_id uuid references neon_auth."user" (id) on delete set null,
  occurred_at timestamptz not null default clock_timestamp()
);
create index handover_failures_courier on public.handover_failures (courier_id, occurred_at);
alter table public.handover_failures enable row level security;
revoke all on public.handover_failures from authenticated, anonymous;

create or replace function app.handover_failed() returns trigger
language plpgsql security definer set search_path = ''
as $fn$
begin
  if new.handover_attempts > old.handover_attempts then
    insert into public.handover_failures (order_id, courier_id)
    values (new.id, (select courier_id from public.order_couriers where order_id = new.id));
  end if;
  return null;
end
$fn$;
create trigger orders_handover_failed after update of handover_attempts on public.orders
for each row execute function app.handover_failed();

-- Règles des dernières 24 h ; un signal par règle, sujet et jour. Renvoie le nombre de nouveaux signaux.
create or replace function app.detect_fraud_signals() returns integer
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_count integer := 0;
  v_n integer;
  v_t integer;
begin
  -- Annulations d'une même cliente.
  select threshold into v_t from public.fraud_rules where kind = 'client_cancel_burst' and is_active;
  if v_t is not null then
    insert into public.fraud_signals (kind, country_code, subject_type, subject_id, detail)
    select 'client_cancel_burst', pu.country_code, 'user', pu.user_id, jsonb_build_object('count', count(*))
    from public.order_status_events e
    join public.orders o on o.id = e.order_id
    join public.purchases pu on pu.id = o.purchase_id
    where e.to_status = 'cancelled' and e.actor_role = 'client' and e.occurred_at > now() - interval '24 hours'
    group by pu.user_id, pu.country_code having count(*) >= v_t
    on conflict do nothing;
    get diagnostics v_n = row_count; v_count := v_count + v_n;
  end if;
  -- Refus d'une même boutique.
  select threshold into v_t from public.fraud_rules where kind = 'store_refusal_burst' and is_active;
  if v_t is not null then
    insert into public.fraud_signals (kind, country_code, subject_type, subject_id, detail)
    select 'store_refusal_burst', s.country_code, 'store', s.id, jsonb_build_object('count', count(*))
    from public.order_status_events e
    join public.orders o on o.id = e.order_id
    join public.stores s on s.id = o.store_id
    where e.to_status = 'refused' and e.occurred_at > now() - interval '24 hours'
    group by s.id, s.country_code having count(*) >= v_t
    on conflict do nothing;
    get diagnostics v_n = row_count; v_count := v_count + v_n;
  end if;
  -- Appareil partagé par plusieurs comptes (vu ces dernières 24 h).
  select threshold into v_t from public.fraud_rules where kind = 'shared_device' and is_active;
  if v_t is not null then
    insert into public.fraud_signals (kind, country_code, subject_type, subject_id, detail)
    select 'shared_device', p.country_code, 'user', d.user_id,
           jsonb_build_object('accounts', x.n)
    from (select install_id, count(distinct user_id) as n from public.user_devices
          group by install_id having count(distinct user_id) >= v_t) x
    join public.user_devices d on d.install_id = x.install_id
    left join public.profiles p on p.user_id = d.user_id
    where d.seen_at > now() - interval '24 hours'
    on conflict do nothing;
    get diagnostics v_n = row_count; v_count := v_count + v_n;
  end if;
  -- Codes de remise faux d'un même livreur.
  select threshold into v_t from public.fraud_rules where kind = 'handover_code_failures' and is_active;
  if v_t is not null then
    insert into public.fraud_signals (kind, country_code, subject_type, subject_id, detail)
    select 'handover_code_failures', cp.country_code, 'user', f.courier_id, jsonb_build_object('count', count(*))
    from public.handover_failures f
    left join public.courier_profiles cp on cp.user_id = f.courier_id
    where f.courier_id is not null and f.occurred_at > now() - interval '24 hours'
    group by f.courier_id, cp.country_code having count(*) >= v_t
    on conflict do nothing;
    get diagnostics v_n = row_count; v_count := v_count + v_n;
  end if;
  -- Marchandage en rafale sans achat.
  select threshold into v_t from public.fraud_rules where kind = 'haggle_burst' and is_active;
  if v_t is not null then
    insert into public.fraud_signals (kind, country_code, subject_type, subject_id, detail)
    select 'haggle_burst', s.country_code, 'user', h.user_id, jsonb_build_object('count', count(*))
    from public.haggles h join public.stores s on s.id = h.store_id
    where h.created_at > now() - interval '24 hours'
    group by h.user_id, s.country_code
    having count(*) >= v_t and count(*) filter (where h.status = 'used') = 0
    on conflict do nothing;
    get diagnostics v_n = row_count; v_count := v_count + v_n;
  end if;
  if v_count > 0 then
    perform app.emit_event('fraud_signals_detected', null, 'admin', 'server', null, null, null,
      jsonb_build_object('count', v_count));
  end if;
  return v_count;
end
$fn$;

-- Signaux d'un pays du périmètre, avec un libellé du sujet.
create or replace function public.admin_fraud_signals(p_country char(2), p_status text default 'open')
returns jsonb
language plpgsql stable security definer set search_path = ''
as $fn$
begin
  perform app.require_ops(p_country);
  if p_status not in ('open', 'decided') then raise exception 'invalid_status' using errcode = '22023'; end if;
  return coalesce((select jsonb_agg(jsonb_build_object(
      'id', f.id, 'kind', f.kind, 'subject_type', f.subject_type, 'subject_id', f.subject_id,
      'subject', case f.subject_type
        when 'store' then (select name from public.stores where id = f.subject_id)
        else coalesce((select display_name from public.courier_profiles where user_id = f.subject_id),
                      (select first_name from public.profiles where user_id = f.subject_id),
                      (select email from neon_auth."user" where id = f.subject_id)) end,
      'detail', f.detail, 'status', f.status, 'created_at', f.created_at, 'decision_note', f.decision_note)
      order by f.created_at desc)
    from public.fraud_signals f
    where f.country_code = p_country and (p_status = 'open') = (f.status = 'open')
      and f.created_at > now() - interval '30 days'), '[]'::jsonb);
end
$fn$;

-- Décision humaine : écarter ou confirmer (l'équipe agit ensuite avec ses outils habituels).
create or replace function public.admin_decide_fraud_signal(p_id uuid, p_confirm boolean, p_note text default null)
returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_signal public.fraud_signals;
  v_admin uuid;
begin
  select * into v_signal from public.fraud_signals where id = p_id for update;
  if v_signal.id is null then raise exception 'not_found' using errcode = 'P0002'; end if;
  v_admin := app.require_ops(v_signal.country_code);
  if v_signal.status <> 'open' then raise exception 'already_decided' using errcode = 'P0001'; end if;
  update public.fraud_signals set status = case when p_confirm then 'confirmed' else 'dismissed' end,
    decided_by = v_admin, decided_at = clock_timestamp(), decision_note = nullif(left(btrim(coalesce(p_note, '')), 500), '')
  where id = p_id;
  perform app.admin_did(v_admin, case when p_confirm then 'fraud_confirmed' else 'fraud_dismissed' end,
    'fraud_signal', p_id::text, jsonb_build_object('status', 'open'),
    jsonb_build_object('status', case when p_confirm then 'confirmed' else 'dismissed' end), p_note,
    v_signal.country_code);
  return public.admin_fraud_signals(v_signal.country_code);
end
$fn$;

-- ------------------------------------------------------------------ tri des signalements

create table public.report_triage (
  target_type text not null,
  target_id uuid not null,
  verdict text not null check (verdict in ('keep', 'remove', 'unsure')),
  reason text check (reason is null or length(reason) <= 300),
  model text,
  triaged_at timestamptz not null default clock_timestamp(),
  primary key (target_type, target_id)
);
alter table public.report_triage enable row level security;
revoke all on public.report_triage from authenticated, anonymous;

insert into public.ai_models (usage, provider, model, params, is_active) values
  ('moderation_triage', 'openai', 'gpt-5.4-mini', '{"temperature": 0}', true),
  ('support_agent', 'openai', 'gpt-5.4-mini', '{"temperature": 0.3}', true)
on conflict (usage) do nothing;

-- Signalements ouverts sans avis (texte à juger, motifs), et modèle actif. Pour la Function.
create or replace function app.reports_to_triage(p_limit integer default 20) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object(
    'model', (select jsonb_build_object('provider', provider, 'model', model, 'params', params)
              from public.ai_models where usage = 'moderation_triage' and is_active),
    'items', coalesce((select jsonb_agg(x) from (
      select jsonb_build_object('target_type', r.target_type, 'target_id', r.target_id,
        'reasons', jsonb_agg(distinct r.reason),
        'notes', coalesce(jsonb_agg(r.note) filter (where r.note is not null), '[]'::jsonb),
        'text', case r.target_type
          when 'content' then (select coalesce(c.caption, '') from public.contents c where c.id = r.target_id)
          when 'product' then (select p.name || coalesce(' — ' || p.description, '') from public.products p
                               where p.id = r.target_id)
          when 'comment' then (select k.body from public.content_comments k where k.id = r.target_id)
          else (select coalesce(v.comment, '') from public.reviews v where v.id = r.target_id) end) as x
      from public.reports r
      where r.status = 'open'
        and not exists (select 1 from public.report_triage t where t.target_type = r.target_type
                        and t.target_id = r.target_id)
      group by r.target_type, r.target_id
      order by min(r.created_at)
      limit greatest(1, least(p_limit, 50))) t), '[]'::jsonb))
$$;

create or replace function app.record_report_triage(p_target_type text, p_target_id uuid, p_verdict text,
  p_reason text, p_model text) returns void
language plpgsql security definer set search_path = ''
as $fn$
begin
  insert into public.report_triage (target_type, target_id, verdict, reason, model)
  values (p_target_type, p_target_id, p_verdict, left(p_reason, 300), p_model)
  on conflict (target_type, target_id) do update
    set verdict = excluded.verdict, reason = excluded.reason, model = excluded.model, triaged_at = clock_timestamp();
  perform app.emit_event('report_triaged', null, 'admin', 'server', null, p_target_type, p_target_id::text,
    jsonb_build_object('verdict', p_verdict));
end
$fn$;

-- ------------------------------------------------------------------ agent support

-- Fil d'un ticket et modèle actif, pour un admin (la Function rédige le brouillon).
create or replace function app.support_draft_context(p_admin uuid, p_ticket uuid) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_ticket public.support_tickets;
begin
  perform app.assert_admin(p_admin);
  select * into v_ticket from public.support_tickets where id = p_ticket;
  if v_ticket.id is null then raise exception 'not_found' using errcode = 'P0002'; end if;
  perform app.emit_event('support_draft_requested', p_admin, 'admin', 'server',
    (select country_code from public.profiles where user_id = v_ticket.user_id), 'ticket', p_ticket::text, '{}'::jsonb);
  return jsonb_build_object(
    'model', (select jsonb_build_object('provider', provider, 'model', model, 'params', params)
              from public.ai_models where usage = 'support_agent' and is_active),
    'subject', v_ticket.subject, 'app', v_ticket.app,
    'locale', coalesce((select locale from public.profiles where user_id = v_ticket.user_id), 'fr'),
    'order_status', (select status from public.orders where id = v_ticket.order_id),
    'messages', coalesce((select jsonb_agg(jsonb_build_object('role', m.author_role, 'body', m.body)
                          order by m.created_at)
                          from public.support_messages m where m.ticket_id = p_ticket), '[]'::jsonb));
end
$fn$;

insert into public.event_names (name, emitted_by, description) values
  ('fraud_signals_detected', 'server', 'Nouveaux signaux de fraude écrits par le job (nombre)'),
  ('report_triaged', 'server', 'Avis de l''IA sur un signalement (garder, retirer, incertain)'),
  ('support_draft_requested', 'server', 'Brouillon de réponse demandé à l''agent support')
on conflict do nothing;

-- Copies : file de modération (0044) avec l'avis de l'IA ; vue en direct (0059) avec les signaux.
create or replace function public.admin_reports(p_status text default 'open') returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
begin
  perform app.require_admin();
  if p_status not in ('open', 'decided') then
    raise exception 'statut inconnu' using errcode = '22023';
  end if;
  return coalesce((
    select jsonb_agg(row order by (row ->> 'first_at') desc)
    from (
      select jsonb_build_object(
        'target_type', r.target_type, 'target_id', r.target_id,
        'count', count(*), 'first_at', min(r.created_at),
        'reasons', jsonb_agg(distinct r.reason),
        'notes', coalesce(jsonb_agg(r.note) filter (where r.note is not null), '[]'::jsonb),
        'status', max(r.status), 'decision_reason', max(r.decision_reason),
        -- Avis de l'IA (spec 054) : une suggestion, l'équipe décide.
        'ai', (select jsonb_build_object('verdict', t.verdict, 'reason', t.reason) from public.report_triage t
               where t.target_type = r.target_type and t.target_id = r.target_id),
        'preview', case r.target_type
          when 'content' then (select jsonb_build_object('title', coalesce(c.caption, ''), 'kind', c.kind,
                                 'media_key', c.media_key, 'media_type', c.media_type,
                                 'store_name', coalesce(s.name, (select cr.display_name from public.creator_profiles cr
                                                                 where cr.user_id = c.author_id)),
                                 'tags', coalesce((select jsonb_agg(p.name) from public.content_products cp
                                                   join public.products p on p.id = cp.product_id
                                                   where cp.content_id = c.id), '[]'::jsonb))
                               from public.contents c left join public.stores s on s.id = c.store_id
                               where c.id = r.target_id)
          when 'product' then (select jsonb_build_object('title', p.name, 'store_name', s.name,
                                 'media_key', (select f.object_key from public.product_photos f
                                               where f.product_id = p.id order by f.sort limit 1),
                                 'media_type', 'image')
                               from public.products p join public.stores s on s.id = p.store_id
                               where p.id = r.target_id)
          when 'comment' then (select jsonb_build_object('title', k.body, 'kind', 'comment',
                                 'store_name', coalesce((select cr.display_name from public.creator_profiles cr
                                                         where cr.user_id = k.author_id),
                                                        (select p.first_name from public.profiles p
                                                         where p.user_id = k.author_id)))
                               from public.content_comments k where k.id = r.target_id)
          else (select jsonb_build_object('title', coalesce(v.comment, ''), 'store_name', s.name,
                  'rating', v.rating)
                from public.reviews v join public.stores s on s.id = v.store_id
                where v.id = r.target_id) end) as row
      from public.reports r
      where (p_status = 'open') = (r.status = 'open')
      group by r.target_type, r.target_id) g), '[]'::jsonb);
end
$$;

create or replace function public.ops_live(p_country char(2)) returns jsonb
language plpgsql stable security definer set search_path = ''
as $fn$
declare
  v_country public.countries;
begin
  perform app.require_ops(p_country);
  select * into v_country from public.countries where code = p_country;
  return jsonb_build_object(
    'country_code', p_country,
    'currency_code', v_country.currency_code,
    'countries', to_jsonb(app.admin_countries()),
    'orders_by_status', coalesce((
      select jsonb_object_agg(status, n) from (
        select o.status, count(*) as n from public.orders o join public.stores s on s.id = o.store_id
        where s.country_code = p_country and o.created_at > now() - interval '24 hours'
        group by o.status) t), '{}'::jsonb),
    'delivered_minor', coalesce((
      select sum(o.total_minor) from public.orders o join public.stores s on s.id = o.store_id
      where s.country_code = p_country and o.status = 'delivered' and o.created_at > now() - interval '24 hours'), 0),
    'alerts', coalesce((
      select jsonb_agg(a order by (a ->> 'minutes')::int desc) from (
        select jsonb_build_object('order_id', o.id, 'store_name', s.name, 'status', o.status,
                 'fulfillment', o.fulfillment, 'minutes', w.minutes,
                 'has_courier', exists (select 1 from public.order_couriers oc where oc.order_id = o.id)) as a
        from public.orders o
        join public.stores s on s.id = o.store_id
        cross join lateral (
          select floor(extract(epoch from now() - coalesce(
            (select max(e.occurred_at) from public.order_status_events e where e.order_id = o.id),
            o.created_at)) / 60)::int as minutes) w
        where s.country_code = p_country
          and o.status in ('pending', 'accepted', 'preparing', 'ready', 'out_for_delivery')
          and w.minutes > case o.status
            when 'pending' then v_country.ops_pending_alert_minutes
            when 'ready' then v_country.ops_ready_alert_minutes
            when 'out_for_delivery' then v_country.ops_transit_alert_minutes
            else s.prep_time_minutes + v_country.ops_ready_alert_minutes end
        order by w.minutes desc
        limit 50) t), '[]'::jsonb),
    'couriers_online', (select count(*) from public.courier_profiles
                        where country_code = p_country and is_online and status = 'active'),
    'missions_waiting', (select count(*) from public.orders o join public.stores s on s.id = o.store_id
      where s.country_code = p_country and o.fulfillment = 'delivery'
        and o.status in ('accepted', 'preparing', 'ready')
        and not exists (select 1 from public.order_couriers oc where oc.order_id = o.id)),
    'open_disputes', (select count(*) from public.disputes d join public.orders o on o.id = d.order_id
      join public.stores s on s.id = o.store_id where s.country_code = p_country and d.status = 'open'),
    'open_tickets', (select count(*) from public.support_tickets t join public.profiles p on p.user_id = t.user_id
      where p.country_code = p_country and t.status in ('open', 'pending')),
    'open_reports', (select count(*) from public.reports where status = 'open'),
    'fraud_open', (select count(*) from public.fraud_signals where country_code = p_country and status = 'open'),
    'courier_cash', app.ops_courier_cash(p_country));
end
$fn$;

revoke all on function app.handover_failed(), app.detect_fraud_signals(), public.admin_fraud_signals(char, text),
  public.admin_decide_fraud_signal(uuid, boolean, text), app.reports_to_triage(integer),
  app.record_report_triage(text, uuid, text, text, text), app.support_draft_context(uuid, uuid) from public;
grant execute on function public.admin_fraud_signals(char, text), public.admin_decide_fraud_signal(uuid, boolean, text)
  to authenticated;
