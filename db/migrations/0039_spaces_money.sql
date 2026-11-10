-- 0039 — Argent des espaces (spec 032).
-- Une poche commune par espace, au grand livre (compte `space_pocket`) : chaque membre y verse depuis
-- son wallet ; la personne qui valide peut financer la validation par la poche (le montant des
-- articles passe sur son wallet, elle paie avec le wallet). Tout mouvement est une transaction
-- équilibrée, immuable et idempotente.

-- ------------------------------------------------------------------ grand livre

-- Sans lien bloquant, comme les autres références du grand livre (0033) : les écritures restent.
alter table public.ledger_accounts add column space_id uuid;
alter table public.ledger_accounts drop constraint ledger_accounts_kind_check;
alter table public.ledger_accounts add constraint ledger_accounts_kind_check check (kind in (
  'platform_commission', 'provider_clearing', 'customer_escrow', 'store_balance',
  'user_wallet', 'user_pocket', 'platform_promotions',
  'space_pocket'          -- poche commune d'un espace
));
alter table public.ledger_accounts drop constraint ledger_accounts_owner_check;
alter table public.ledger_accounts add constraint ledger_accounts_owner_check check (
  (kind = 'store_balance') = (store_id is not null)
  and (kind in ('user_wallet', 'user_pocket')) = (user_id is not null)
  and (kind = 'user_pocket') = (pocket_id is not null)
  and (kind = 'space_pocket') = (space_id is not null));
drop index public.ledger_accounts_unique;
create unique index ledger_accounts_unique on public.ledger_accounts (
  kind,
  coalesce(store_id, '00000000-0000-0000-0000-000000000000'),
  coalesce(user_id, '00000000-0000-0000-0000-000000000000'),
  coalesce(pocket_id, '00000000-0000-0000-0000-000000000000'),
  coalesce(space_id, '00000000-0000-0000-0000-000000000000'),
  currency_code);

alter table public.ledger_transactions drop constraint ledger_transactions_kind_check;
alter table public.ledger_transactions add constraint ledger_transactions_kind_check check (kind in (
  'payment_received', 'order_settled', 'cash_commission', 'refund_paid',
  'wallet_topup', 'wallet_transfer', 'cashback',
  'space_contribution',   -- versement d'un membre dans la poche commune
  'space_payout'          -- poche commune vers le wallet de la personne qui valide
));

-- ------------------------------------------------------------------ espaces

alter table public.space_validations add column funded_minor bigint not null default 0
  check (funded_minor >= 0);

create or replace function app.space_pocket_account(p_space uuid) returns uuid
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_currency char(3) := (select currency_code from public.spaces where id = p_space);
  v_id uuid;
begin
  select id into v_id from public.ledger_accounts where kind = 'space_pocket' and space_id = p_space;
  if v_id is null then
    insert into public.ledger_accounts (kind, space_id, currency_code) values ('space_pocket', p_space, v_currency)
    on conflict do nothing returning id into v_id;
    if v_id is null then
      select id into v_id from public.ledger_accounts where kind = 'space_pocket' and space_id = p_space;
    end if;
  end if;
  return v_id;
end
$fn$;

-- Solde de la poche (0 sans compte), sans créer le compte.
create or replace function app.space_pocket_balance(p_space uuid) returns bigint
language sql stable security definer set search_path = ''
as $$
  select coalesce((select app.ledger_balance(a.id) from public.ledger_accounts a
                   where a.kind = 'space_pocket' and a.space_id = p_space), 0)::bigint
$$;

-- Versé par un membre ce mois (fuseau du pays de l'espace).
create or replace function app.space_contributed_month(p_space uuid, p_user uuid, p_at timestamptz default now())
returns bigint
language sql stable security definer set search_path = ''
as $$
  select coalesce(-sum(e.amount_minor), 0)::bigint
  from public.ledger_entries e
  join public.ledger_accounts a on a.id = e.account_id and a.kind = 'space_pocket' and a.space_id = p_space
  join public.ledger_transactions t on t.id = e.transaction_id and t.kind = 'space_contribution'
  join public.spaces s on s.id = p_space
  join public.countries c on c.code = s.country_code
  where t.user_id = p_user
    and date_trunc('month', t.occurred_at at time zone c.timezone)
        = date_trunc('month', p_at at time zone c.timezone)
$$;

-- Versement d'un membre depuis son wallet (clé d'idempotence).
create or replace function public.space_contribute(p_space uuid, p_amount_minor bigint, p_key uuid)
returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_user uuid := app.require_user();
  v_space public.spaces;
  v_wallet uuid;
begin
  select * into v_space from public.spaces where id = p_space;
  if v_space.id is null or app.space_role(p_space, v_user) is null then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  if p_amount_minor is null or p_amount_minor <= 0 or p_key is null then
    raise exception 'wallet_amount_invalid' using errcode = 'P0001';
  end if;
  if app.user_currency(v_user) is distinct from v_space.currency_code then
    raise exception 'other_country' using errcode = '22023';
  end if;
  perform pg_advisory_xact_lock(hashtext('wallet:' || v_user));
  if not exists (select 1 from public.ledger_transactions where idempotency_key = 'space-contribution:' || p_key) then
    v_wallet := app.ledger_user_account('user_wallet', v_space.currency_code, v_user);
    if app.ledger_balance(v_wallet) < p_amount_minor then
      raise exception 'wallet_insufficient' using errcode = 'P0001';
    end if;
    perform app.ledger_post('space_contribution', 'space-contribution:' || p_key, v_space.currency_code,
      jsonb_build_array(
        jsonb_build_object('account', v_wallet, 'amount', p_amount_minor),
        jsonb_build_object('account', app.space_pocket_account(p_space), 'amount', -p_amount_minor)),
      p_user => v_user);
    perform app.emit_event('space_contributed', v_user, 'client', 'server', v_space.country_code, 'space',
      p_space::text, jsonb_build_object('amount_minor', p_amount_minor));
  end if;
  return app.space_json(p_space, v_user);
end
$fn$;

-- Suppression : refusée tant que la poche n'est pas vide (le grand livre garde l'historique).
create or replace function public.delete_space(p_space uuid) returns void
language plpgsql security definer set search_path = ''
as $fn$
begin
  if not exists (select 1 from public.spaces where id = p_space and owner_id = app.require_user()) then
    raise exception 'not_allowed' using errcode = '42501';
  end if;
  if app.space_pocket_balance(p_space) <> 0 then
    raise exception 'space_balance' using errcode = '22023';
  end if;
  delete from public.spaces where id = p_space;
end
$fn$;

-- Suppression de compte (0033) : aussi refusée si un espace de la personne garde de l'argent.
create or replace function app.account_deletion_blockers(p_user uuid) returns text[]
language sql stable security definer set search_path = ''
as $$
  select array_remove(array[
    case when exists (
      select 1 from public.ledger_accounts a
      where a.user_id = p_user and a.kind in ('user_wallet', 'user_pocket')
        and app.ledger_balance(a.id) <> 0) then 'wallet_balance' end,
    case when exists (
      select 1 from public.stores s
      join public.ledger_accounts a on a.store_id = s.id and a.kind = 'store_balance'
      where s.owner_id = p_user and app.ledger_balance(a.id) <> 0) then 'store_balance' end,
    case when exists (
      select 1 from public.orders o
      join public.purchases pu on pu.id = o.purchase_id
      left join public.stores s on s.id = o.store_id
      where (pu.user_id = p_user or s.owner_id = p_user)
        and o.status in ('pending', 'accepted', 'preparing', 'ready', 'out_for_delivery'))
      then 'orders_in_progress' end,
    case when exists (
      select 1 from public.stores s join public.orders o on o.store_id = s.id
      where s.owner_id = p_user) then 'store_history' end,
    case when exists (
      select 1 from public.spaces sp where sp.owner_id = p_user and app.space_pocket_balance(sp.id) <> 0)
      then 'space_balance' end
  ], null)
$$;

-- Espace ouvert (0038) : poche commune et versements du mois par membre.
create or replace function app.space_json(p_space uuid, p_user uuid) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object(
    'id', s.id, 'name', s.name, 'currency_code', s.currency_code,
    'monthly_budget_minor', s.monthly_budget_minor,
    'spent_month_minor', app.space_spent_month(s.id),
    'join_code', s.join_code,
    'pocket_balance_minor', app.space_pocket_balance(s.id),
    'my_role', app.space_role(s.id, p_user),
    'is_owner', s.owner_id = p_user,
    'members', coalesce((
      select jsonb_agg(jsonb_build_object(
          'user_id', m.user_id, 'first_name', coalesce(pr.first_name, '?'), 'role', m.role,
          'is_owner', m.user_id = s.owner_id, 'is_me', m.user_id = p_user,
          'contributed_month_minor', app.space_contributed_month(s.id, m.user_id))
        order by m.user_id <> s.owner_id, m.joined_at)
      from public.space_members m left join public.profiles pr on pr.user_id = m.user_id
      where m.space_id = s.id), '[]'::jsonb),
    'items', app.space_items_json(s.id),
    'total_minor', coalesce((
      select sum(app.variant_price(i.variant_id) * i.quantity) from public.space_items i
      where i.space_id = s.id), 0))
  from public.spaces s where s.id = p_space
$$;

-- Validation (0038) avec financement facultatif par la poche commune.
drop function public.validate_space(uuid);
create function public.validate_space(p_space uuid, p_use_pocket boolean default false) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_user uuid := app.require_user();
  v_space public.spaces;
  v_item record;
  v_added int := 0;
  v_total bigint := 0;
  v_skipped jsonb := '[]'::jsonb;
  v_cart jsonb;
  v_price bigint;
  v_name text := (select first_name from public.profiles where user_id = v_user);
  v_validation uuid;
begin
  select * into v_space from public.spaces where id = p_space for update;
  if v_space.id is null or app.space_role(p_space, v_user) is null then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  if app.space_role(p_space, v_user) <> 'payer' then raise exception 'not_payer' using errcode = '42501'; end if;
  if not exists (select 1 from public.space_items where space_id = p_space) then
    raise exception 'space_empty' using errcode = '22023';
  end if;
  if v_space.monthly_budget_minor is not null and app.space_spent_month(p_space) + (
       select coalesce(sum(app.variant_price(i.variant_id) * i.quantity), 0) from public.space_items i
       where i.space_id = p_space) > v_space.monthly_budget_minor then
    raise exception 'budget_exceeded' using errcode = '22023';
  end if;
  if p_use_pocket and app.space_pocket_balance(p_space) < (
       select coalesce(sum(app.variant_price(i.variant_id) * i.quantity), 0) from public.space_items i
       where i.space_id = p_space) then
    raise exception 'space_pocket_insufficient' using errcode = '22023';
  end if;
  for v_item in
    select i.variant_id, i.quantity, p.name
    from public.space_items i
    join public.product_variants v on v.id = i.variant_id
    join public.products p on p.id = v.product_id
    where i.space_id = p_space order by i.added_at
  loop
    begin
      v_price := app.variant_price(v_item.variant_id);
      v_cart := public.cart_add(v_item.variant_id, v_item.quantity);
      delete from public.space_items where space_id = p_space and variant_id = v_item.variant_id;
      v_added := v_added + 1;
      v_total := v_total + v_price * v_item.quantity;
    exception when others then
      v_skipped := v_skipped || to_jsonb(v_item.name);
    end;
  end loop;
  if v_added > 0 then
    insert into public.space_validations (space_id, validated_by, items_count, total_minor, funded_minor)
    values (p_space, v_user, v_added, v_total, case when p_use_pocket then v_total else 0 end)
    returning id into v_validation;
    -- Financement : la poche commune verse le montant des articles sur le wallet de la personne qui
    -- valide, qui paie ensuite avec le wallet (spec 025).
    if p_use_pocket and v_total > 0 then
      perform app.ledger_post('space_payout', 'space-payout:' || v_validation, v_space.currency_code,
        jsonb_build_array(
          jsonb_build_object('account', app.space_pocket_account(p_space), 'amount', v_total),
          jsonb_build_object('account', app.ledger_user_account('user_wallet', v_space.currency_code, v_user),
                             'amount', -v_total)),
        p_user => v_user);
      perform app.emit_event('space_funded', v_user, 'client', 'server', v_space.country_code, 'space',
        p_space::text, jsonb_build_object('amount_minor', v_total));
    end if;
    perform app.notify(m.user_id, 'space_validated', 'orders', null, null,
      jsonb_build_object('space_id', p_space, 'space_name', v_space.name, 'by_name', coalesce(v_name, '')))
    from public.space_members m where m.space_id = p_space and m.user_id <> v_user;
  end if;
  perform app.emit_event('space_validated', v_user, 'client', 'server', v_space.country_code, 'space',
    p_space::text, jsonb_build_object('added', v_added, 'skipped', jsonb_array_length(v_skipped),
      'amount_minor', v_total));
  return jsonb_build_object('added', v_added, 'skipped', v_skipped, 'funded_minor',
    case when p_use_pocket then v_total else 0 end, 'cart', coalesce(v_cart, public.my_cart()));
end
$fn$;

insert into public.event_names (name, emitted_by, description) values
  ('space_contributed', 'server', 'Versement dans la poche commune d''un espace (montant)'),
  ('space_funded', 'server', 'Validation financée par la poche commune (montant)')
on conflict do nothing;

-- ------------------------------------------------------------------ droits

revoke all on function app.space_pocket_account(uuid), app.space_pocket_balance(uuid),
  app.space_contributed_month(uuid, uuid, timestamptz), public.space_contribute(uuid, bigint, uuid),
  public.validate_space(uuid, boolean) from public;
grant execute on function public.space_contribute(uuid, bigint, uuid), public.validate_space(uuid, boolean)
  to authenticated;
