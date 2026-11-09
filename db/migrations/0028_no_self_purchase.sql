-- 0028 — Une personne ne peut pas commander dans sa propre boutique (spec 023, FR-013).
-- Contrôle à l'écriture de la commande : il vaut pour toutes les apps et tous les chemins.

create or replace function app.forbid_own_store_order() returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  if exists (
    select 1
    from public.purchases p
    join public.stores s on s.id = new.store_id
    where p.id = new.purchase_id and p.user_id = s.owner_id
  ) then
    raise exception 'own_store_purchase' using errcode = 'P0001';
  end if;
  return new;
end
$$;

create trigger orders_forbid_own_store before insert on public.orders
  for each row execute function app.forbid_own_store_order();
