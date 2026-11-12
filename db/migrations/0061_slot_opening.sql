-- Commande programmée (spec 033) : l'ouverture d'une boutique se vérifie au début du créneau
-- choisi, pas à l'heure où la cliente commande. Une boutique fermée maintenant accepte donc une
-- commande pour demain matin si elle est ouverte à ce moment-là ; « dès que possible » reste refusé.

-- Début d'un créneau dans le fuseau du pays ; nul si le créneau est absent ou inconnu
-- (app.schedule_purchase refuse ensuite le créneau invalide).
create or replace function app.slot_start(p_country text, p_slot jsonb) returns timestamptz
language plpgsql stable security definer set search_path = ''
as $fn$
declare
  v_start timestamptz;
begin
  if p_slot is null or jsonb_typeof(p_slot) <> 'object' then
    return null;
  end if;
  begin
    select ((p_slot ->> 'date')::date + w.starts_at) at time zone c.timezone into v_start
    from public.delivery_windows w
    join public.countries c on c.code = w.country_code
    where w.id = (p_slot ->> 'window_id')::uuid and w.country_code = p_country and w.is_active;
  exception when others then
    return null;
  end;
  return v_start;
end
$fn$;

-- Copie (0011) avec le créneau choisi : le devis vérifie l'ouverture à son début.
drop function public.my_cart(uuid, jsonb, uuid, timestamptz);

create function public.my_cart(
  p_address uuid default null,
  p_modes jsonb default '{}'::jsonb,
  p_payment_method uuid default null,
  p_at timestamptz default now(),
  p_slot jsonb default null
) returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_user uuid := app.require_user();
  v_cart public.carts;
  v_address public.customer_addresses;
  v_zone uuid;
  v_country char(2);
begin
  select * into v_cart from public.carts where user_id = v_user;
  if v_cart.id is null or not exists (select 1 from public.cart_items where cart_id = v_cart.id) then
    v_country := coalesce(v_cart.country_code, (select country_code from public.profiles where user_id = v_user));
    return app.empty_cart(v_country);
  end if;
  v_address := app.delivery_address(v_user, p_address, v_cart.country_code);
  v_zone := coalesce(v_address.zone_id,
    (select p.zone_id from public.profiles p
     join public.zones z on z.id = p.zone_id join public.cities c on c.id = z.city_id
     where p.user_id = v_user and c.country_code = v_cart.country_code));
  return app.cart_quote(v_cart.id, v_zone, coalesce(p_modes, '{}'::jsonb), p_payment_method,
                        coalesce(app.slot_start(v_cart.country_code, p_slot), p_at))
    || jsonb_build_object('address_id', v_address.id, 'zone_id', v_zone);
end
$$;

-- Copie (0040) : le devis de la commande se fait au début du créneau ; la programmation
-- (délai de préparation, horizon, ouverture au créneau) se vérifie toujours à l'heure réelle.
create or replace function app.place_order_scheduled(
  p_user uuid, p_key uuid, p_request jsonb, p_at timestamptz, p_providers text[]
) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_quote_at timestamptz := coalesce(
    app.slot_start((select country_code from public.carts where user_id = p_user), p_request -> 'slot'),
    p_at);
  v_result jsonb := app.place_order(p_user, p_key, p_request, v_quote_at, p_providers);
  v_purchase uuid := (v_result -> 'purchase' ->> 'id')::uuid;
begin
  if not (v_result ->> 'replayed')::boolean then
    perform app.schedule_purchase(v_purchase, p_request -> 'slot', p_at);
    if p_request -> 'slot' is not null and jsonb_typeof(p_request -> 'slot') = 'object' then
      v_result := jsonb_set(v_result, '{purchase}', app.purchase_json(v_purchase));
    end if;
  end if;
  return v_result;
end
$fn$;

-- ------------------------------------------------------------------ droits

revoke all on function app.slot_start(text, jsonb),
  public.my_cart(uuid, jsonb, uuid, timestamptz, jsonb) from public;
grant execute on function public.my_cart(uuid, jsonb, uuid, timestamptz, jsonb) to authenticated;
