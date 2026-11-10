-- 0053 — Ardoise et relances (spec 047, VISION §3 « Vendeuse » : faire crédit sans rien perdre).
-- La vendeuse tient l'ardoise de ses clientes (nom, téléphone) : dettes et remboursements datés,
-- solde calculé en base, plafond facultatif. Relance : message prêt à envoyer sur WhatsApp,
-- une par jour au plus, journalisée. L'argent ne passe pas par DYM : aucun mouvement au grand livre.

create table public.store_credits (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores (id) on delete cascade,
  customer_name text not null check (length(btrim(customer_name)) between 1 and 60),
  phone text check (phone is null or phone ~ '^\+?[0-9 ]{8,20}$'),
  limit_minor bigint check (limit_minor is null or limit_minor > 0),
  currency_code char(3) not null references public.currencies (code),
  last_reminded_at timestamptz,
  created_at timestamptz not null default clock_timestamp(),
  archived_at timestamptz
);
create index store_credits_store on public.store_credits (store_id) where archived_at is null;
alter table public.store_credits enable row level security;
revoke all on public.store_credits from authenticated, anonymous;

create table public.store_credit_entries (
  id uuid primary key default gen_random_uuid(),
  credit_id uuid not null references public.store_credits (id) on delete cascade,
  kind text not null check (kind in ('debt', 'payment')),
  amount_minor bigint not null check (amount_minor > 0 and amount_minor <= 100000000),
  note text check (note is null or length(note) <= 120),
  idempotency_key uuid not null unique,
  created_at timestamptz not null default clock_timestamp()
);
create index store_credit_entries_credit on public.store_credit_entries (credit_id, created_at desc);
alter table public.store_credit_entries enable row level security;
revoke all on public.store_credit_entries from authenticated, anonymous;

-- Dû par la cliente (dettes moins remboursements).
create or replace function app.credit_balance(p_credit uuid) returns bigint
language sql stable security definer set search_path = ''
as $$
  select coalesce(sum(case when kind = 'debt' then amount_minor else -amount_minor end), 0)::bigint
  from public.store_credit_entries where credit_id = p_credit
$$;

create or replace function app.credit_json(p_credit uuid, p_entries boolean) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object('id', c.id, 'customer_name', c.customer_name, 'phone', c.phone,
    'limit_minor', c.limit_minor, 'currency_code', c.currency_code,
    'balance_minor', app.credit_balance(c.id),
    'last_reminded_at', c.last_reminded_at,
    'can_remind', c.phone is not null and app.credit_balance(c.id) > 0
                  and (c.last_reminded_at is null or c.last_reminded_at < now() - interval '1 day'),
    'last_entry_at', (select max(created_at) from public.store_credit_entries where credit_id = c.id))
  || case when p_entries then jsonb_build_object('entries', coalesce((select jsonb_agg(jsonb_build_object(
        'id', e.id, 'kind', e.kind, 'amount_minor', e.amount_minor, 'note', e.note, 'at', e.created_at)
        order by e.created_at desc) from public.store_credit_entries e where e.credit_id = c.id), '[]'::jsonb))
     else '{}'::jsonb end
  from public.store_credits c where c.id = p_credit
$$;

-- Ardoise de la boutique : clientes, du plus dû au moins dû, et total.
create or replace function public.my_credits() returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object(
    'total_minor', coalesce((select sum(app.credit_balance(c.id)) from public.store_credits c
                             where c.store_id = app.own_store_id() and c.archived_at is null), 0),
    'credits', coalesce((select jsonb_agg(app.credit_json(c.id, false) order by app.credit_balance(c.id) desc,
                                          c.customer_name)
                         from public.store_credits c
                         where c.store_id = app.own_store_id() and c.archived_at is null), '[]'::jsonb))
$$;

create or replace function app.own_credit(p_credit uuid) returns uuid
language plpgsql stable security definer set search_path = ''
as $fn$
begin
  if not exists (select 1 from public.store_credits where id = p_credit and store_id = app.own_store_id()) then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  return p_credit;
end
$fn$;

create or replace function public.credit_detail(p_credit uuid) returns jsonb
language sql stable security definer set search_path = ''
as $$ select app.credit_json(app.own_credit(p_credit), true) $$;

-- Nouvelle cliente à l'ardoise (ou mise à jour du nom, du téléphone, du plafond).
create or replace function public.save_credit(p_credit uuid, p_name text, p_phone text default null,
  p_limit_minor bigint default null) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_store public.stores;
  v_id uuid := p_credit;
  v_phone text := nullif(btrim(coalesce(p_phone, '')), '');
begin
  select * into v_store from public.stores where id = app.own_store_id();
  if v_store.id is null then raise exception 'not_found' using errcode = 'P0002'; end if;
  if length(btrim(coalesce(p_name, ''))) not between 1 and 60 then raise exception 'invalid_name' using errcode = '22023'; end if;
  if v_phone is not null and v_phone !~ '^\+?[0-9 ]{8,20}$' then raise exception 'invalid_phone' using errcode = '22023'; end if;
  if p_limit_minor is not null and p_limit_minor <= 0 then raise exception 'invalid_amount' using errcode = '22023'; end if;
  if v_id is null then
    insert into public.store_credits (store_id, customer_name, phone, limit_minor, currency_code)
    values (v_store.id, btrim(p_name), v_phone, p_limit_minor, v_store.currency_code)
    returning id into v_id;
  else
    perform app.own_credit(v_id);
    update public.store_credits set customer_name = btrim(p_name), phone = v_phone, limit_minor = p_limit_minor
    where id = v_id;
  end if;
  return app.credit_json(v_id, true);
end
$fn$;

-- Dette ou remboursement (une fois par clé). Plafond dépassé : refusé. Remboursement : jamais
-- plus que le dû.
create or replace function public.add_credit_entry(p_credit uuid, p_kind text, p_amount_minor bigint, p_key uuid,
  p_note text default null) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_credit public.store_credits;
  v_balance bigint;
begin
  perform app.own_credit(p_credit);
  if exists (select 1 from public.store_credit_entries where idempotency_key = p_key) then
    return app.credit_json(p_credit, true);
  end if;
  select * into v_credit from public.store_credits where id = p_credit for update;
  if p_kind is null or p_kind not in ('debt', 'payment') then raise exception 'invalid_kind' using errcode = '22023'; end if;
  if p_amount_minor is null or p_amount_minor <= 0 or p_amount_minor > 100000000 then
    raise exception 'invalid_amount' using errcode = '22023';
  end if;
  v_balance := app.credit_balance(p_credit);
  if p_kind = 'debt' and v_credit.limit_minor is not null and v_balance + p_amount_minor > v_credit.limit_minor then
    raise exception 'credit_limit' using errcode = 'P0001';
  end if;
  if p_kind = 'payment' and p_amount_minor > v_balance then
    raise exception 'payment_too_high' using errcode = 'P0001';
  end if;
  insert into public.store_credit_entries (credit_id, kind, amount_minor, note, idempotency_key)
  values (p_credit, p_kind, p_amount_minor, nullif(left(btrim(coalesce(p_note, '')), 120), ''), p_key);
  perform app.emit_event(case when p_kind = 'debt' then 'credit_given' else 'credit_repaid' end,
    app.current_user_id(), 'vendor', 'server',
    (select country_code from public.stores where id = v_credit.store_id), 'store', v_credit.store_id::text,
    jsonb_build_object('amount_minor', p_amount_minor));
  return app.credit_json(p_credit, true);
end
$fn$;

-- Relance (une par jour) : l'app ouvre WhatsApp avec le message ; la base trace la relance.
create or replace function public.remind_credit(p_credit uuid) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_credit public.store_credits;
begin
  perform app.own_credit(p_credit);
  select * into v_credit from public.store_credits where id = p_credit for update;
  if v_credit.phone is null or app.credit_balance(p_credit) <= 0 then
    raise exception 'nothing_to_remind' using errcode = 'P0001';
  end if;
  if v_credit.last_reminded_at is not null and v_credit.last_reminded_at > now() - interval '1 day' then
    raise exception 'already_reminded' using errcode = 'P0001';
  end if;
  update public.store_credits set last_reminded_at = clock_timestamp() where id = p_credit;
  perform app.emit_event('credit_reminded', app.current_user_id(), 'vendor', 'server',
    (select country_code from public.stores where id = v_credit.store_id), 'store', v_credit.store_id::text,
    jsonb_build_object('balance_minor', app.credit_balance(p_credit)));
  return app.credit_json(p_credit, true) || jsonb_build_object('store_name',
    (select name from public.stores where id = v_credit.store_id));
end
$fn$;

-- Ardoise soldée : retirée de la liste (gardée en base).
create or replace function public.archive_credit(p_credit uuid) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
begin
  perform app.own_credit(p_credit);
  if app.credit_balance(p_credit) <> 0 then raise exception 'balance_not_zero' using errcode = 'P0001'; end if;
  update public.store_credits set archived_at = clock_timestamp() where id = p_credit;
  return public.my_credits();
end
$fn$;

insert into public.event_names (name, emitted_by, description) values
  ('credit_given', 'server', 'Dette inscrite à l''ardoise (montant)'),
  ('credit_repaid', 'server', 'Remboursement à l''ardoise (montant)'),
  ('credit_reminded', 'server', 'Relance d''une cliente (dû)')
on conflict do nothing;

revoke all on function app.credit_balance(uuid), app.credit_json(uuid, boolean), public.my_credits(),
  app.own_credit(uuid), public.credit_detail(uuid), public.save_credit(uuid, text, text, bigint),
  public.add_credit_entry(uuid, text, bigint, uuid, text), public.remind_credit(uuid),
  public.archive_credit(uuid) from public;
grant execute on function public.my_credits(), public.credit_detail(uuid), public.save_credit(uuid, text, text, bigint),
  public.add_credit_entry(uuid, text, bigint, uuid, text), public.remind_credit(uuid), public.archive_credit(uuid)
  to authenticated;
