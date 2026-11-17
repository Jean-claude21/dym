-- 0099 — La position décide du pays (spec 110) : une cliente inscrite à Lomé qui ouvre l'app à Rouen
-- voit Rouen. Son quartier et son pays suivent son choix ; un panier d'un autre pays est signalé,
-- gardé ou vidé à sa demande (un panier ne mélange jamais deux pays).

-- Changer de lieu : quartier actif d'une ville visible, n'importe quel pays ouvert.
create or replace function public.set_my_place(p_zone uuid)
returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := app.require_user();
  v_country char(2);
  v_before char(2);
  v_cart public.carts;
  v_items integer;
begin
  select c.country_code into v_country
  from public.zones z join public.cities c on c.id = z.city_id
  where z.id = p_zone and z.is_active and app.city_is_visible(c.id);
  if v_country is null then
    raise exception 'zone_unavailable' using errcode = 'P0002';
  end if;
  select country_code into v_before from public.profiles where user_id = v_user;
  if not found then
    raise exception 'profile_required' using errcode = 'P0001';
  end if;
  update public.profiles set zone_id = p_zone, country_code = v_country, updated_at = now()
  where user_id = v_user;
  if v_before is distinct from v_country then
    perform app.emit_event('place_changed', v_user, 'client', 'server', v_country, 'zone', p_zone::text,
      jsonb_build_object('from_country', v_before, 'to_country', v_country));
  end if;
  select * into v_cart from public.carts where user_id = v_user;
  select count(*) into v_items from public.cart_items where cart_id = v_cart.id;
  return jsonb_build_object(
    'zone_id', p_zone, 'country_code', v_country,
    'country_changed', v_before is distinct from v_country,
    -- Panier d'un autre pays : la cliente choisit de le garder ou de le vider.
    'cart_country', case when coalesce(v_items, 0) > 0 then v_cart.country_code end,
    'cart_items', coalesce(v_items, 0));
end
$$;
revoke all on function public.set_my_place(uuid) from public;
grant execute on function public.set_my_place(uuid) to authenticated;

-- Vider son panier (avant de commander dans un autre pays, par exemple).
create or replace function public.cart_clear()
returns void
language sql security definer set search_path = ''
as $$
  delete from public.cart_items
  where cart_id in (select id from public.carts where user_id = app.require_user())
$$;
revoke all on function public.cart_clear() from public;
grant execute on function public.cart_clear() to authenticated;

insert into public.event_names (name, emitted_by, description) values
  ('place_changed', 'server', 'Lieu de la cliente changé vers un autre pays (spec 110)')
on conflict do nothing;
