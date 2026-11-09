-- 0029 — État réel de sa boutique pour la vendeuse (spec 023, FR-012) : ouverte maintenant,
-- selon l'interrupteur et les horaires. Toujours calculé par le serveur.

create or replace function public.my_store_open_now() returns boolean
language sql stable security definer set search_path = ''
as $$
  select coalesce(
    (select app.store_open_at(s.id, now())
     from public.stores s where s.owner_id = app.current_user_id()),
    false)
$$;

revoke all on function public.my_store_open_now() from public;
grant execute on function public.my_store_open_now() to authenticated;
