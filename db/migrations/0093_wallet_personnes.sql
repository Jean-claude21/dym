-- 0093 — Avoir DYM entre personnes (spec 100), simulé : QR personnel, envoyer, demander (« paie ma
-- commande »), recharger pour un proche, argent de poche avec plafond journalier et vue parentale.
-- L'avoir se dépense chez les boutiques DYM ; il ne se retire jamais (seuls les gains et le
-- solde rechargé non reçu d'une personne restent retirables, comme avant).

-- ------------------------------------------------------------------ identifiant et historique

-- Code personnel (QR « DYM-P2P:<code> ») : jamais l'email ni le téléphone.
create table public.wallet_handles (
  user_id uuid primary key references neon_auth."user" (id) on delete cascade,
  handle text not null unique check (handle ~ '^[A-Z0-9]{8}$'),
  created_at timestamptz not null default now()
);
alter table public.wallet_handles enable row level security;

create table public.p2p_transfers (
  id uuid primary key default gen_random_uuid(),
  kind text not null check (kind in ('send', 'request_paid', 'topup_for', 'allowance')),
  from_user uuid references neon_auth."user" (id) on delete set null,
  to_user uuid not null references neon_auth."user" (id) on delete cascade,
  amount_minor bigint not null check (amount_minor > 0),
  currency_code char(3) not null references public.currencies (code),
  note text check (note is null or length(note) <= 140),
  transaction_id uuid references public.ledger_transactions (id),
  created_at timestamptz not null default now()
);
alter table public.p2p_transfers enable row level security;
create index p2p_transfers_to on public.p2p_transfers (to_user, created_at desc);
create index p2p_transfers_from on public.p2p_transfers (from_user, created_at desc);

create table public.p2p_requests (
  id uuid primary key default gen_random_uuid(),
  requester uuid not null references neon_auth."user" (id) on delete cascade,
  payer uuid not null references neon_auth."user" (id) on delete cascade,
  amount_minor bigint not null check (amount_minor > 0),
  currency_code char(3) not null references public.currencies (code),
  note text check (note is null or length(note) <= 140),
  purchase_id uuid references public.purchases (id) on delete set null,
  status text not null default 'pending' check (status in ('pending', 'paid', 'declined', 'cancelled')),
  created_at timestamptz not null default now(),
  answered_at timestamptz
);
alter table public.p2p_requests enable row level security;

-- Famille : un parent, un enfant (invitation acceptée), argent de poche, plafond par jour.
create table public.family_links (
  parent_id uuid not null references neon_auth."user" (id) on delete cascade,
  child_id uuid not null references neon_auth."user" (id) on delete cascade,
  status text not null default 'pending' check (status in ('pending', 'active')),
  allowance_minor bigint check (allowance_minor is null or allowance_minor > 0),
  allowance_every_days smallint not null default 7 check (allowance_every_days in (1, 7, 30)),
  next_allowance_at timestamptz,
  daily_limit_minor bigint check (daily_limit_minor is null or daily_limit_minor > 0),
  created_at timestamptz not null default now(),
  primary key (parent_id, child_id),
  check (parent_id <> child_id)
);
alter table public.family_links enable row level security;

-- ------------------------------------------------------------------ règles

create or replace function app.wallet_handle(p_user uuid)
returns text
language plpgsql security definer set search_path = ''
as $$
declare
  v_handle text := (select handle from public.wallet_handles where user_id = p_user);
begin
  while v_handle is null loop
    v_handle := upper(substr(translate(replace(gen_random_uuid()::text, '-', ''), '01', 'XY'), 1, 8));
    begin
      insert into public.wallet_handles (user_id, handle) values (p_user, v_handle);
    exception when unique_violation then
      v_handle := (select handle from public.wallet_handles where user_id = p_user);
    end;
  end loop;
  return v_handle;
end
$$;
revoke all on function app.wallet_handle(uuid) from public;

create or replace function app.user_by_handle(p_handle text)
returns uuid
language sql stable security definer set search_path = ''
as $$
  select user_id from public.wallet_handles
  where handle = upper(regexp_replace(coalesce(p_handle, ''), '^DYM-P2P:', '', 'i'))
$$;
revoke all on function app.user_by_handle(text) from public;

-- Dépenses du jour d'un enfant (paiements wallet, envois, demandes de boutique), heure du pays.
create or replace function app.child_spent_today(p_user uuid)
returns bigint
language sql stable security definer set search_path = ''
as $$
  with tz as (
    select coalesce((select c.timezone from public.profiles p join public.countries c on c.code = p.country_code
                     where p.user_id = p_user), 'UTC') as name
  ), since as (
    select (date_trunc('day', now() at time zone tz.name) at time zone tz.name) as at from tz
  )
  select coalesce(sum(e.amount_minor), 0)::bigint
  from public.ledger_entries e
  join public.ledger_transactions t on t.id = e.transaction_id
  join public.ledger_accounts a on a.id = e.account_id
  cross join since
  where a.kind = 'user_wallet' and a.user_id = p_user and e.amount_minor > 0
    and t.occurred_at >= since.at
    and t.kind not in ('wallet_withdrawal')
$$;
revoke all on function app.child_spent_today(uuid) from public;

-- Plafond parental : refuse une dépense qui dépasserait le plafond du jour.
create or replace function app.check_child_limit(p_user uuid, p_amount bigint)
returns void
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_limit bigint := (select min(daily_limit_minor) from public.family_links
                     where child_id = p_user and status = 'active' and daily_limit_minor is not null);
begin
  if v_limit is not null and app.child_spent_today(p_user) + p_amount > v_limit then
    raise exception 'child_daily_limit' using errcode = 'P0001';
  end if;
end
$$;
revoke all on function app.check_child_limit(uuid, bigint) from public;

-- Transfert entre deux wallets (même devise), journalisé et notifié.
create or replace function app.p2p_move(
  p_kind text, p_from uuid, p_to uuid, p_amount bigint, p_note text, p_key text
) returns uuid
language plpgsql security definer set search_path = ''
as $$
declare
  v_currency char(3) := app.user_currency(p_to);
  v_tx uuid;
  v_id uuid;
  v_from_wallet uuid;
begin
  if v_currency is null then raise exception 'recipient_unknown' using errcode = 'P0002'; end if;
  if p_amount is null or p_amount <= 0 or p_amount > 50000000 then
    raise exception 'wallet_amount_invalid' using errcode = 'P0001';
  end if;
  if exists (select 1 from public.ledger_transactions where idempotency_key = p_key) then
    return (select id from public.p2p_transfers where transaction_id =
              (select id from public.ledger_transactions where idempotency_key = p_key));
  end if;
  if p_from is not null then
    if app.user_currency(p_from) is distinct from v_currency then
      raise exception 'currency_mismatch' using errcode = 'P0001';
    end if;
    perform pg_advisory_xact_lock(hashtext('wallet:' || p_from));
    v_from_wallet := app.ledger_user_account('user_wallet', v_currency, p_from);
    if app.ledger_balance(v_from_wallet) < p_amount then
      raise exception 'wallet_insufficient' using errcode = 'P0001';
    end if;
    perform app.check_child_limit(p_from, p_amount);
  end if;
  v_tx := app.ledger_post('wallet_transfer', p_key, v_currency, jsonb_build_array(
    jsonb_build_object('account', coalesce(v_from_wallet, app.ledger_account('provider_clearing', v_currency)),
                       'amount', p_amount),
    jsonb_build_object('account', app.ledger_user_account('user_wallet', v_currency, p_to), 'amount', -p_amount)),
    p_user => coalesce(p_from, p_to));
  insert into public.p2p_transfers (kind, from_user, to_user, amount_minor, currency_code, note, transaction_id)
  values (p_kind, p_from, p_to, p_amount, v_currency, left(nullif(btrim(p_note), ''), 140), v_tx)
  returning id into v_id;
  perform app.notify(p_to, 'wallet_received', 'payments', null, null, jsonb_build_object(
    'sender_name', coalesce((select first_name from public.profiles where user_id = p_from), ''),
    'amount', app.format_money(p_amount, v_currency)));
  perform app.emit_event('wallet_shared', coalesce(p_from, p_to), 'client', 'server',
    (select country_code from public.profiles where user_id = p_to), null, null,
    jsonb_build_object('kind', p_kind, 'amount_minor', p_amount));
  return v_id;
end
$$;
revoke all on function app.p2p_move(text, uuid, uuid, bigint, text, text) from public;

-- ------------------------------------------------------------------ fonctions publiques

create or replace function public.my_wallet_handle()
returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := app.require_user();
  v_handle text := app.wallet_handle(v_user);
begin
  return jsonb_build_object('handle', v_handle, 'qr', 'DYM-P2P:' || v_handle,
    'first_name', (select first_name from public.profiles where user_id = v_user));
end
$$;
revoke all on function public.my_wallet_handle() from public;
grant execute on function public.my_wallet_handle() to authenticated;

-- Avant d'envoyer : prénom du destinataire (rien d'autre), pour confirmer.
create or replace function public.wallet_recipient(p_handle text)
returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object('handle', h.handle,
    'first_name', coalesce((select first_name from public.profiles where user_id = h.user_id), ''),
    'same_currency', app.user_currency(h.user_id) is not distinct from app.user_currency(app.require_user()))
  from public.wallet_handles h
  where h.user_id = app.user_by_handle(p_handle) and h.user_id <> app.current_user_id()
$$;
revoke all on function public.wallet_recipient(text) from public;
grant execute on function public.wallet_recipient(text) to authenticated;

create or replace function public.wallet_send(p_handle text, p_amount_minor bigint, p_note text, p_key uuid)
returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := app.require_user();
  v_to uuid := app.user_by_handle(p_handle);
begin
  if v_to is null or v_to = v_user then raise exception 'recipient_unknown' using errcode = 'P0002'; end if;
  perform app.p2p_move('send', v_user, v_to, p_amount_minor, p_note, 'p2p:' || p_key);
  return public.my_wallet();
end
$$;
revoke all on function public.wallet_send(text, bigint, text, uuid) from public;
grant execute on function public.wallet_send(text, bigint, text, uuid) to authenticated;

-- Recharger pour un proche (simulé, comme la recharge de son propre wallet).
create or replace function public.wallet_topup_for(p_handle text, p_amount_minor bigint, p_key uuid)
returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := app.require_user();
  v_to uuid := app.user_by_handle(p_handle);
  v_country char(2) := (select country_code from public.profiles where user_id = v_user);
begin
  if not app.feature_enabled('wallet_simulated_topup', v_country) then
    raise exception 'feature_disabled' using errcode = 'P0001';
  end if;
  if v_to is null then raise exception 'recipient_unknown' using errcode = 'P0002'; end if;
  perform app.p2p_move('topup_for', null, v_to, p_amount_minor,
    coalesce((select first_name from public.profiles where user_id = v_user), ''), 'p2ptop:' || p_key);
  update public.p2p_transfers set from_user = v_user
  where transaction_id = (select id from public.ledger_transactions where idempotency_key = 'p2ptop:' || p_key);
  return jsonb_build_object('ok', true);
end
$$;
revoke all on function public.wallet_topup_for(text, bigint, uuid) from public;
grant execute on function public.wallet_topup_for(text, bigint, uuid) to authenticated;

-- Demander de l'argent (« paie ma commande ») à une personne.
create or replace function public.wallet_request(
  p_handle text, p_amount_minor bigint, p_note text, p_purchase uuid default null
) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := app.require_user();
  v_payer uuid := app.user_by_handle(p_handle);
  v_currency char(3) := app.user_currency(v_user);
  v_id uuid;
begin
  if v_payer is null or v_payer = v_user then raise exception 'recipient_unknown' using errcode = 'P0002'; end if;
  if p_amount_minor is null or p_amount_minor <= 0 or p_amount_minor > 50000000 then
    raise exception 'wallet_amount_invalid' using errcode = 'P0001';
  end if;
  if p_purchase is not null and not exists (select 1 from public.purchases where id = p_purchase and user_id = v_user) then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  insert into public.p2p_requests (requester, payer, amount_minor, currency_code, note, purchase_id)
  values (v_user, v_payer, p_amount_minor, v_currency, left(nullif(btrim(p_note), ''), 140), p_purchase)
  returning id into v_id;
  perform app.notify(v_payer, 'wallet_requested', 'payments', null, null, jsonb_build_object(
    'requester_name', coalesce((select first_name from public.profiles where user_id = v_user), ''),
    'amount', app.format_money(p_amount_minor, v_currency), 'request_id', v_id));
  return jsonb_build_object('id', v_id, 'status', 'pending');
end
$$;
revoke all on function public.wallet_request(text, bigint, text, uuid) from public;
grant execute on function public.wallet_request(text, bigint, text, uuid) to authenticated;

create or replace function public.wallet_answer_request(p_request uuid, p_pay boolean, p_key uuid)
returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := app.require_user();
  v_r public.p2p_requests;
begin
  select * into v_r from public.p2p_requests where id = p_request and payer = v_user for update;
  if v_r.id is null then raise exception 'not_found' using errcode = 'P0002'; end if;
  if v_r.status <> 'pending' then raise exception 'request_closed' using errcode = 'P0001'; end if;
  if p_pay then
    perform app.p2p_move('request_paid', v_user, v_r.requester, v_r.amount_minor, v_r.note, 'p2preq:' || p_key);
  end if;
  update public.p2p_requests set status = case when p_pay then 'paid' else 'declined' end, answered_at = now()
  where id = p_request;
  return jsonb_build_object('id', p_request, 'status', case when p_pay then 'paid' else 'declined' end);
end
$$;
revoke all on function public.wallet_answer_request(uuid, boolean, uuid) from public;
grant execute on function public.wallet_answer_request(uuid, boolean, uuid) to authenticated;

-- Historique entre personnes et demandes en cours (prénoms seulement).
create or replace function public.my_p2p()
returns jsonb
language sql stable security definer set search_path = ''
as $$
  with me as (select app.require_user() as id)
  select jsonb_build_object(
    'handle', app.wallet_handle(me.id),
    'transfers', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', t.id, 'kind', t.kind, 'amount_minor', t.amount_minor, 'currency_code', t.currency_code,
        'note', t.note, 'created_at', t.created_at, 'incoming', t.to_user = me.id,
        'other_name', coalesce((select first_name from public.profiles
                                where user_id = case when t.to_user = me.id then t.from_user else t.to_user end), ''))
        order by t.created_at desc)
      from (select * from public.p2p_transfers x where x.to_user = me.id or x.from_user = me.id
            order by x.created_at desc limit 50) t), '[]'::jsonb),
    'requests', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', r.id, 'amount_minor', r.amount_minor, 'currency_code', r.currency_code, 'note', r.note,
        'status', r.status, 'created_at', r.created_at, 'to_pay', r.payer = me.id,
        'other_name', coalesce((select first_name from public.profiles
                                where user_id = case when r.payer = me.id then r.requester else r.payer end), ''))
        order by r.created_at desc)
      from public.p2p_requests r
      where (r.payer = me.id or r.requester = me.id) and r.status = 'pending'), '[]'::jsonb))
  from me
$$;
revoke all on function public.my_p2p() from public;
grant execute on function public.my_p2p() to authenticated;

-- ------------------------------------------------------------------ famille

-- Le parent invite l'enfant par son code ; l'enfant accepte.
create or replace function public.family_invite(p_handle text)
returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := app.require_user();
  v_child uuid := app.user_by_handle(p_handle);
begin
  if v_child is null or v_child = v_user then raise exception 'recipient_unknown' using errcode = 'P0002'; end if;
  insert into public.family_links (parent_id, child_id) values (v_user, v_child) on conflict do nothing;
  perform app.notify(v_child, 'family_invited', 'payments', null, null, jsonb_build_object(
    'parent_name', coalesce((select first_name from public.profiles where user_id = v_user), '')));
  return public.my_family();
end
$$;
revoke all on function public.family_invite(text) from public;
grant execute on function public.family_invite(text) to authenticated;

create or replace function public.family_accept(p_parent uuid)
returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := app.require_user();
begin
  update public.family_links set status = 'active' where parent_id = p_parent and child_id = v_user;
  if not found then raise exception 'not_found' using errcode = 'P0002'; end if;
  return public.my_family();
end
$$;
revoke all on function public.family_accept(uuid) from public;
grant execute on function public.family_accept(uuid) to authenticated;

-- Le parent règle l'argent de poche (montant, rythme) et le plafond journalier.
create or replace function public.family_set_rules(
  p_child uuid, p_allowance_minor bigint, p_every_days integer, p_daily_limit_minor bigint
) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := app.require_user();
begin
  update public.family_links set
    allowance_minor = nullif(p_allowance_minor, 0),
    allowance_every_days = coalesce(p_every_days, 7),
    next_allowance_at = case when coalesce(p_allowance_minor, 0) > 0
                             then coalesce(next_allowance_at, now()) end,
    daily_limit_minor = nullif(p_daily_limit_minor, 0)
  where parent_id = v_user and child_id = p_child and status = 'active';
  if not found then raise exception 'not_found' using errcode = 'P0002'; end if;
  return public.my_family();
end
$$;
revoke all on function public.family_set_rules(uuid, bigint, integer, bigint) from public;
grant execute on function public.family_set_rules(uuid, bigint, integer, bigint) to authenticated;

-- Vue des parents : solde, dépenses du jour et derniers mouvements de chaque enfant.
create or replace function public.my_family()
returns jsonb
language sql stable security definer set search_path = ''
as $$
  with me as (select app.require_user() as id)
  select jsonb_build_object(
    'children', coalesce((
      select jsonb_agg(jsonb_build_object(
        'user_id', f.child_id, 'status', f.status,
        'first_name', coalesce((select first_name from public.profiles where user_id = f.child_id), ''),
        'allowance_minor', f.allowance_minor, 'allowance_every_days', f.allowance_every_days,
        'next_allowance_at', f.next_allowance_at, 'daily_limit_minor', f.daily_limit_minor,
        'currency_code', app.user_currency(f.child_id),
        'balance_minor', case when f.status = 'active' then coalesce((
          select app.ledger_balance(a.id) from public.ledger_accounts a
          where a.kind = 'user_wallet' and a.user_id = f.child_id
            and a.currency_code = app.user_currency(f.child_id)), 0) end,
        'spent_today_minor', case when f.status = 'active' then app.child_spent_today(f.child_id) end,
        'recent', case when f.status = 'active' then coalesce((
          select jsonb_agg(jsonb_build_object('kind', t.kind, 'occurred_at', t.occurred_at,
                                              'amount_minor', -e.amount_minor) order by t.occurred_at desc)
          from (select e2.* from public.ledger_entries e2
                join public.ledger_accounts a2 on a2.id = e2.account_id
                join public.ledger_transactions t2 on t2.id = e2.transaction_id
                where a2.kind = 'user_wallet' and a2.user_id = f.child_id
                order by t2.occurred_at desc limit 10) e
          join public.ledger_transactions t on t.id = e.transaction_id), '[]'::jsonb) end)
        order by f.created_at)
      from public.family_links f where f.parent_id = me.id), '[]'::jsonb),
    'parents', coalesce((
      select jsonb_agg(jsonb_build_object('user_id', f.parent_id, 'status', f.status,
        'first_name', coalesce((select first_name from public.profiles where user_id = f.parent_id), ''),
        'daily_limit_minor', f.daily_limit_minor, 'allowance_minor', f.allowance_minor))
      from public.family_links f where f.child_id = me.id), '[]'::jsonb))
  from me
$$;
revoke all on function public.my_family() from public;
grant execute on function public.my_family() to authenticated;

-- Cron : argent de poche dû, payé depuis le wallet du parent (rien si le solde manque).
create or replace function app.pay_allowances(p_at timestamptz default now())
returns integer
language plpgsql security definer set search_path = ''
as $$
declare
  v_link record;
  v_paid integer := 0;
begin
  for v_link in select * from public.family_links
                where status = 'active' and allowance_minor is not null and next_allowance_at <= p_at
                for update skip locked loop
    begin
      perform app.p2p_move('allowance', v_link.parent_id, v_link.child_id, v_link.allowance_minor, null,
        'allowance:' || v_link.parent_id || ':' || v_link.child_id || ':' || to_char(v_link.next_allowance_at, 'YYYYMMDDHH24MI'));
      v_paid := v_paid + 1;
    exception when others then
      perform app.notify(v_link.parent_id, 'allowance_failed', 'payments', null, null, jsonb_build_object(
        'child_name', coalesce((select first_name from public.profiles where user_id = v_link.child_id), '')));
    end;
    update public.family_links set next_allowance_at = next_allowance_at + make_interval(days => allowance_every_days)
    where parent_id = v_link.parent_id and child_id = v_link.child_id;
  end loop;
  return v_paid;
end
$$;
revoke all on function app.pay_allowances(timestamptz) from public;

-- ------------------------------------------------------------------ textes et événements

insert into public.notification_templates (kind, locale, title, body) values
  ('wallet_received', 'fr', 'Avoir reçu', '{sender_name} t''a envoyé {amount}.'),
  ('wallet_received', 'en', 'Credit received', '{sender_name} sent you {amount}.'),
  ('wallet_requested', 'fr', 'Demande d''avoir', '{requester_name} te demande {amount}.'),
  ('wallet_requested', 'en', 'Credit request', '{requester_name} asks you for {amount}.'),
  ('family_invited', 'fr', 'Invitation familiale', '{parent_name} veut suivre ton argent de poche.'),
  ('family_invited', 'en', 'Family invitation', '{parent_name} wants to follow your pocket money.'),
  ('allowance_failed', 'fr', 'Argent de poche non versé', 'Solde insuffisant pour l''argent de poche de {child_name}.'),
  ('allowance_failed', 'en', 'Pocket money not paid', 'Not enough balance for {child_name}''s pocket money.');

insert into public.event_names (name, emitted_by, description) values
  ('wallet_shared', 'server', 'Avoir entre personnes : envoi, demande payée, recharge, argent de poche (spec 100)')
on conflict do nothing;

-- ------------------------------------------------------------------ fonctions existantes modifiées

CREATE OR REPLACE FUNCTION app.wallet_settle_payment()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_user uuid;
  v_country char(2);
  v_wallet uuid;
  v_pocket record;
  v_round bigint;
begin
  if new.provider_code <> 'wallet' or new.status <> 'pending' then
    return null;
  end if;
  select user_id, country_code into v_user, v_country from public.purchases where id = new.purchase_id;
  perform pg_advisory_xact_lock(hashtext('wallet:' || v_user));
  v_wallet := app.ledger_user_account('user_wallet', new.currency_code, v_user);
  if app.ledger_balance(v_wallet) < new.amount_minor then
    raise exception 'wallet_insufficient' using errcode = 'P0001';
  end if;
  -- Plafond parental du jour (spec 100).
  perform app.check_child_limit(v_user, new.amount_minor);
  perform app.apply_payment_event('wallet', 'wallet:' || new.id, '{}'::jsonb, true, new.id, 'succeeded',
                                  new.amount_minor, new.currency_code);
  perform app.emit_event('wallet_payment_succeeded', v_user, 'client', 'server', v_country,
                         'payment', new.id::text, jsonb_build_object('amount_minor', new.amount_minor));
  for v_pocket in
    select id, round_up_minor from public.wallet_pockets
    where user_id = v_user and currency_code = new.currency_code
      and archived_at is null and round_up_minor is not null
    order by created_at
  loop
    v_round := (v_pocket.round_up_minor - new.amount_minor % v_pocket.round_up_minor) % v_pocket.round_up_minor;
    if v_round > 0 and app.ledger_balance(v_wallet) >= v_round then
      perform app.ledger_post('wallet_transfer', 'roundup:' || new.id || ':' || v_pocket.id, new.currency_code,
        jsonb_build_array(
          jsonb_build_object('account', v_wallet, 'amount', v_round),
          jsonb_build_object('account', app.ledger_user_account('user_pocket', new.currency_code, v_user, v_pocket.id),
                             'amount', -v_round)),
        p_payment => new.id);
    end if;
  end loop;
  return null;
end
$function$;

CREATE OR REPLACE FUNCTION public.pay_payment_request(p_code text, p_key uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_user uuid := app.require_user();
  v_request public.payment_requests;
  v_store public.stores;
  v_wallet uuid;
  v_commission bigint;
begin
  select * into v_request from public.payment_requests where pay_key = p_key and paid_by = v_user;
  if v_request.id is not null then return app.payment_request_json(v_request.id) - 'code' - 'qr'; end if;
  select * into v_request from public.payment_requests where id = app.open_request_id(p_code) for update;
  if v_request.id is null or v_request.status <> 'open' then raise exception 'invalid_code' using errcode = 'P0001'; end if;
  select * into v_store from public.stores where id = v_request.store_id;
  if v_store.owner_id = v_user then raise exception 'own_store' using errcode = 'P0001'; end if;
  if app.user_currency(v_user) is distinct from v_request.currency_code then
    raise exception 'currency_mismatch' using errcode = 'P0001';
  end if;
  v_wallet := app.ledger_user_account('user_wallet', v_request.currency_code, v_user);
  perform 1 from public.ledger_accounts where id = v_wallet for update;
  if app.ledger_balance(v_wallet) < v_request.amount_minor then
    raise exception 'wallet_insufficient' using errcode = 'P0001';
  end if;
  perform app.check_child_limit(v_user, v_request.amount_minor);
  v_commission := (v_request.amount_minor *
    (select qr_commission_bps from public.countries where code = v_store.country_code)) / 10000;
  perform app.ledger_post('qr_payment', 'qr:' || p_key, v_request.currency_code, jsonb_build_array(
    jsonb_build_object('account', v_wallet, 'amount', v_request.amount_minor),
    jsonb_build_object('account', app.ledger_account('store_balance', v_request.currency_code, v_store.id),
                       'amount', -(v_request.amount_minor - v_commission)),
    jsonb_build_object('account', app.ledger_account('platform_commission', v_request.currency_code),
                       'amount', -v_commission)),
    p_user => v_user);
  update public.payment_requests set status = 'paid', paid_by = v_user, paid_at = clock_timestamp(), pay_key = p_key
  where id = v_request.id;
  insert into public.store_sales (store_id, label, amount_minor, currency_code, method, idempotency_key)
  values (v_store.id, coalesce(v_request.label, 'QR ' || v_request.code), v_request.amount_minor,
          v_request.currency_code, 'dym', v_request.id);
  perform app.notify(v_store.owner_id, 'qr_paid', 'payments', null, null,
    jsonb_build_object('amount_minor', v_request.amount_minor, 'currency_code', v_request.currency_code));
  perform app.emit_event('qr_paid', v_user, 'client', 'server', v_store.country_code, 'store', v_store.id::text,
    jsonb_build_object('amount_minor', v_request.amount_minor));
  return app.payment_request_json(v_request.id) - 'code' - 'qr';
end
$function$;

CREATE OR REPLACE FUNCTION public.wallet_withdraw_simulated(p_amount_minor bigint, p_key uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_user uuid := app.require_user();
  v_country char(2) := (select country_code from public.profiles where user_id = v_user);
  v_currency char(3) := app.user_currency(v_user);
  v_wallet uuid;
begin
  if v_currency is null then raise exception 'profil incomplet' using errcode = 'P0002'; end if;
  if not app.feature_enabled('wallet_simulated_withdrawal', v_country) then
    raise exception 'feature_disabled' using errcode = 'P0001';
  end if;
  if exists (select 1 from public.ledger_transactions where idempotency_key = 'withdraw:' || p_key) then
    return public.my_wallet();
  end if;
  if p_amount_minor is null or p_amount_minor <= 0 then
    raise exception 'wallet_amount_invalid' using errcode = 'P0001';
  end if;
  v_wallet := app.ledger_user_account('user_wallet', v_currency, v_user);
  -- Verrou sur le compte : deux retraits simultanés ne dépassent pas le solde.
  perform 1 from public.ledger_accounts where id = v_wallet for update;
  if app.ledger_balance(v_wallet) < p_amount_minor then
    raise exception 'wallet_insufficient' using errcode = 'P0001';
  end if;
  -- Spec 100 : l'avoir reçu d'une personne se dépense, il ne se retire jamais.
  if app.ledger_balance(v_wallet) - greatest(0, coalesce((
       select sum(case when t.to_user = v_user then t.amount_minor else -t.amount_minor end)
       from public.p2p_transfers t
       where (t.to_user = v_user or t.from_user = v_user) and t.currency_code = v_currency), 0))
     < p_amount_minor then
    raise exception 'p2p_not_withdrawable' using errcode = 'P0001';
  end if;
  perform app.ledger_post('wallet_withdrawal', 'withdraw:' || p_key, v_currency, jsonb_build_array(
    jsonb_build_object('account', v_wallet, 'amount', p_amount_minor),
    jsonb_build_object('account', app.ledger_account('provider_clearing', v_currency), 'amount', -p_amount_minor)),
    p_user => v_user);
  perform app.emit_event('wallet_withdrawn', v_user, 'client', 'server', v_country, null, null,
    jsonb_build_object('amount_minor', p_amount_minor, 'provider', 'simulator'));
  return public.my_wallet();
end
$function$;
