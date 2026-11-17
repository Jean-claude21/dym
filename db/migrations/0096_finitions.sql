-- 0096 — Finitions (spec 104) : rayons autorisés pour un enfant (contrôlés au paiement d'une
-- commande), mouvements « entre proches » nommés dans le wallet (envoyé à / reçu de).

alter table public.family_links
  add column allowed_categories uuid[] check (allowed_categories is null or cardinality(allowed_categories) <= 40);

-- Rayons autorisés : null ou liste vide = tous. Le parent seulement.
create or replace function public.family_set_categories(p_child uuid, p_categories uuid[])
returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := app.require_user();
begin
  if exists (select 1 from unnest(coalesce(p_categories, '{}'::uuid[])) c(id)
             where not exists (select 1 from public.categories k where k.id = c.id)) then
    raise exception 'category_unknown' using errcode = '22023';
  end if;
  update public.family_links set allowed_categories = nullif(p_categories, '{}'::uuid[])
  where parent_id = v_user and child_id = p_child and status = 'active';
  if not found then raise exception 'not_found' using errcode = 'P0002'; end if;
  return public.my_family();
end
$$;
revoke all on function public.family_set_categories(uuid, uuid[]) from public;
grant execute on function public.family_set_categories(uuid, uuid[]) to authenticated;

-- Une commande d'enfant ne contient que des rayons autorisés (le rayon du produit ou son parent).
create or replace function app.check_child_categories(p_user uuid, p_purchase uuid)
returns void
language plpgsql stable security definer set search_path = ''
as $$
begin
  if exists (
    select 1
    from public.family_links f
    join public.orders o on o.purchase_id = p_purchase
    join public.order_items oi on oi.order_id = o.id
    join public.products p on p.id = oi.product_id
    left join public.categories k on k.id = p.category_id
    where f.child_id = p_user and f.status = 'active' and f.allowed_categories is not null
      and not (coalesce(p.category_id = any (f.allowed_categories), false)
               or coalesce(k.parent_id = any (f.allowed_categories), false))) then
    raise exception 'child_category_blocked' using errcode = 'P0001';
  end if;
end
$$;
revoke all on function app.check_child_categories(uuid, uuid) from public;

-- Définitions reprises et étendues.

create or replace function app.wallet_settle_payment()
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
  -- Rayons autorisés par le parent (spec 104).
  perform app.check_child_categories(v_user, new.purchase_id);
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
$function$
;

create or replace function public.my_wallet()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_user uuid := app.current_user_id();
  v_currency char(3);
  v_wallet uuid;
  v_country char(2);
begin
  if v_user is null then
    raise exception 'session requise' using errcode = '42501';
  end if;
  v_currency := app.user_currency(v_user);
  if v_currency is null then
    raise exception 'profil incomplet' using errcode = 'P0002';
  end if;
  select country_code into v_country from public.profiles where user_id = v_user;
  select id into v_wallet from public.ledger_accounts
  where kind = 'user_wallet' and user_id = v_user and currency_code = v_currency;
  return jsonb_build_object(
    'currency_code', v_currency,
    'balance_minor', case when v_wallet is null then 0 else app.ledger_balance(v_wallet) end,
    'simulated_topup', app.feature_enabled('wallet_simulated_topup', v_country),
    'simulated_withdrawal', app.feature_enabled('wallet_simulated_withdrawal', v_country),
    'pockets', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', p.id, 'name', p.name, 'goal_minor', p.goal_minor, 'round_up_minor', p.round_up_minor,
        'reserved_for', p.reserved_for,
        'balance_minor', coalesce((select app.ledger_balance(a.id) from public.ledger_accounts a
                                   where a.kind = 'user_pocket' and a.pocket_id = p.id), 0))
        order by p.created_at)
      from public.wallet_pockets p
      where p.user_id = v_user and p.archived_at is null and p.currency_code = v_currency), '[]'::jsonb),
    'movements', coalesce((
      select jsonb_agg(m order by (m ->> 'occurred_at') desc) from (
        select jsonb_build_object(
          'id', t.id, 'order_id', t.order_id, 'occurred_at', t.occurred_at,
          -- Entre proches (spec 104) : envoyé à / reçu de, avec le prénom.
          'kind', coalesce((select case when p2.from_user = v_user then 'p2p_sent' else 'p2p_received' end
                            from public.p2p_transfers p2 where p2.transaction_id = t.id), t.kind),
          'counterpart', (select coalesce((select first_name from public.profiles
                                           where user_id = case when p2.from_user = v_user
                                                                then p2.to_user else p2.from_user end), '')
                          from public.p2p_transfers p2 where p2.transaction_id = t.id),
          'pocket_id', (select a.pocket_id from public.ledger_entries e
                        join public.ledger_accounts a on a.id = e.account_id
                        where e.transaction_id = t.id and a.kind = 'user_pocket' and a.user_id = v_user
                        limit 1),
          -- Vu du wallet principal ; sinon (poche à poche) vu de la poche d'origine.
          'amount_minor', coalesce(
            (select -sum(e.amount_minor) from public.ledger_entries e
             join public.ledger_accounts a on a.id = e.account_id
             where e.transaction_id = t.id and a.kind = 'user_wallet' and a.user_id = v_user),
            (select -sum(e.amount_minor) from public.ledger_entries e
             join public.ledger_accounts a on a.id = e.account_id
             where e.transaction_id = t.id and a.kind = 'user_pocket' and a.user_id = v_user
               and e.amount_minor > 0))) as m
        from public.ledger_transactions t
        where exists (
          select 1 from public.ledger_entries e
          join public.ledger_accounts a on a.id = e.account_id
          where e.transaction_id = t.id and a.user_id = v_user and a.currency_code = v_currency)
        order by t.occurred_at desc
        limit 30) x), '[]'::jsonb));
end
$function$
;

create or replace function public.my_family()
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  with me as (select app.require_user() as id)
  select jsonb_build_object(
    'children', coalesce((
      select jsonb_agg(jsonb_build_object(
        'user_id', f.child_id, 'status', f.status,
        'first_name', coalesce((select first_name from public.profiles where user_id = f.child_id), ''),
        'allowance_minor', f.allowance_minor, 'allowance_every_days', f.allowance_every_days,
        'next_allowance_at', f.next_allowance_at, 'daily_limit_minor', f.daily_limit_minor,
        'allowed_categories', coalesce(to_jsonb(f.allowed_categories), '[]'::jsonb),
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
        'daily_limit_minor', f.daily_limit_minor, 'allowance_minor', f.allowance_minor,
        'allowed_categories', coalesce(to_jsonb(f.allowed_categories), '[]'::jsonb)))
      from public.family_links f where f.child_id = me.id), '[]'::jsonb))
  from me
$function$
;
