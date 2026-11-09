-- 0032 — Mouvements du wallet lisibles (spec 025) : une ligne par transaction, montant vu du
-- wallet principal, poche concernée indiquée.

-- Mon wallet : un mouvement par transaction (un déplacement interne sur une seule ligne).
create or replace function public.my_wallet() returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
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
          'id', t.id, 'kind', t.kind, 'order_id', t.order_id, 'occurred_at', t.occurred_at,
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
$$;

