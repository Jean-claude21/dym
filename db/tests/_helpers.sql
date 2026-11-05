-- Aides de test, chargées par `dym-db test` au début de chaque transaction de
-- test (annulée ensuite) : rien ne persiste, y compris sur une branche Neon.

create schema tests;

-- Crée un utilisateur Neon Auth et renvoie son identifiant.
create function tests.create_user(p_email text) returns uuid
language sql
as $$
  insert into neon_auth."user" (name, email, "emailVerified")
  values (split_part(p_email, '@', 1), p_email, true)
  returning id
$$;

-- Agit comme la Data API pour un utilisateur connecté.
create function tests.login_as(p_user uuid) returns void
language plpgsql
as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', p_user, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';
end
$$;

-- Agit comme la Data API sans jeton.
create function tests.login_anonymous() returns void
language plpgsql
as $$
begin
  perform set_config('request.jwt.claims', '', true);
  execute 'set local role anonymous';
end
$$;

-- Revient au rôle propriétaire (préparation des données).
create function tests.logout() returns void
language plpgsql
as $$
begin
  execute 'reset role';
  perform set_config('request.jwt.claims', '', true);
end
$$;

-- Ouvre une boutique complète pour une vendeuse (quartier `p_zone`), puis
-- revient au rôle propriétaire. Renvoie l'identifiant de la boutique.
create function tests.open_store(p_user uuid, p_name text, p_zone text default 'tokoin')
returns uuid
language plpgsql
as $$
declare
  v_zone uuid := (select id from public.zones where slug = p_zone);
  v_country char(2) := (select c.country_code from public.zones z join public.cities c on c.id = z.city_id
                        where z.id = v_zone);
  v_store jsonb;
begin
  perform tests.login_as(p_user);
  perform public.complete_profile(p_name, v_zone, 'vendor');
  perform public.start_store(p_name);
  perform public.update_store(jsonb_build_object(
    'origin', 'maison', 'zone_id', v_zone,
    'main_category_id', (select id from public.categories where slug = 'fait-maison')));
  perform public.set_store_pickup_address('Rue des Hibiscus');
  perform public.set_store_delivery_zones(array[v_zone]);
  perform public.set_store_hours('[{"weekday": 1, "opens_at": "07:00", "closes_at": "19:00"}]');
  perform tests.logout();
  -- Moyen de paiement : actif dans le pays de la boutique (le Ghana est inactif en base).
  perform tests.login_as(p_user);
  perform public.set_store_payment_methods(array(
    select id from public.payment_methods where country_code = v_country and provider_code = 'cash'));
  v_store := public.publish_store();
  perform tests.logout();
  return (v_store ->> 'id')::uuid;
end
$$;

grant usage on schema tests to authenticated, anonymous;
grant execute on all functions in schema tests to authenticated, anonymous;
