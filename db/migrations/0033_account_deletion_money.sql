-- 0033 — Suppression de compte et argent (correctif).
-- 1. Le grand livre (0030, 0031) garde ses références (achat, commande, paiement, remboursement,
--    boutique, personne, poche) sans lien bloquant : les écritures sont immuables et restent après
--    la suppression des données personnelles. Avant, une cliente payée en ligne ne pouvait plus
--    supprimer son compte.
-- 2. Horodatage à l'heure réelle d'écriture : deux mouvements d'une même transaction SQL
--    restent ordonnés.
-- 3. Motifs de refus explicites, au lieu d'une erreur technique : argent restant, commande en
--    cours, boutique avec un historique de commandes (traitée par le support).

alter table public.ledger_transactions
  drop constraint ledger_transactions_purchase_id_fkey,
  drop constraint ledger_transactions_order_id_fkey,
  drop constraint ledger_transactions_payment_id_fkey,
  drop constraint ledger_transactions_refund_id_fkey,
  drop constraint ledger_transactions_user_id_fkey;
alter table public.ledger_accounts
  drop constraint ledger_accounts_store_id_fkey,
  drop constraint ledger_accounts_user_id_fkey,
  drop constraint ledger_accounts_pocket_id_fkey;

alter table public.ledger_transactions alter column occurred_at set default clock_timestamp();

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
      where s.owner_id = p_user) then 'store_history' end
  ], null)
$$;
