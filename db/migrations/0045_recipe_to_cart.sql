-- 0045 — Tout pour la faire (spec 038).
-- 1. Ingrédients génériques d'une recette (libellé, mot de recherche, quantité), fixés par
--    l'autrice : jamais un produit précis.
-- 2. « Tout pour la faire » : produits tagués + chaque ingrédient chez la meilleure vendeuse qui
--    livre le quartier (règles de la spec 028), chiffré en base, manquants nommés.
-- 3. Rayon « Ustensiles » ; rayons hors grocery retirés du référentiel (décision 0015).

alter table public.contents add column ingredients jsonb not null default '[]'::jsonb
  check (jsonb_typeof(ingredients) = 'array' and jsonb_array_length(ingredients) <= 15);

insert into public.categories (slug, label, icon, sort)
values ('ustensiles', '{"fr": "Ustensiles de cuisine", "en": "Kitchenware"}', 'ustensiles', 13)
on conflict (slug) do update set is_active = true;
-- Hors périmètre grocery : plus proposés (les produits existants restent en base).
update public.categories set is_active = false
where slug in ('pagnes-textile', 'beaute', 'hygiene')
   or parent_id in (select id from public.categories where slug in ('pagnes-textile', 'beaute', 'hygiene'));

-- Ingrédients d'un post : autrice (ou boutique propriétaire) seulement ; liste vide : retirés.
create or replace function public.set_content_ingredients(p_content uuid, p_items jsonb) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_user uuid := app.require_user();
  v_items jsonb;
begin
  if not exists (select 1 from public.contents c where c.id = p_content
                 and (c.author_id = v_user
                      or exists (select 1 from public.stores s where s.id = c.store_id and s.owner_id = v_user))) then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  if p_items is null or jsonb_array_length(coalesce(p_items, '[]'::jsonb)) = 0 then
    v_items := '[]'::jsonb;
  else
    if jsonb_array_length(p_items) > 15 then raise exception 'invalid_items' using errcode = '22023'; end if;
    v_items := app.clean_shopping_items(p_items);
  end if;
  update public.contents set ingredients = v_items where id = p_content;
  return v_items;
end
$fn$;

-- Panier de la recette pour le quartier : produits tagués (1 de chaque) + ingrédients.
create or replace function public.recipe_basket(p_content uuid, p_zone uuid default null) returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_user uuid := app.current_user_id();
  v_content public.contents;
  v_zone uuid;
  v_pick jsonb;
  v_items jsonb := '[]'::jsonb;
  v_out jsonb;
begin
  select * into v_content from public.contents where id = p_content;
  if v_content.id is null or not app.content_visible(v_content, now()) then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  v_zone := coalesce(p_zone, (select zone_id from public.profiles where user_id = v_user));
  -- Produits tagués encore en vente et livrables dans le quartier.
  select coalesce(jsonb_agg(jsonb_build_object('variant_id', v.id, 'quantity', 1, 'need', p.name,
           'reason', 'tagged') order by cp.sort), '[]'::jsonb)
  into v_items
  from public.content_products cp
  join public.products p on p.id = cp.product_id and p.status = 'published'
  join public.stores s on s.id = p.store_id and s.status = 'active'
  join lateral (select pv.id from public.product_variants pv
                where pv.product_id = p.id and coalesce(pv.stock_quantity, 1) > 0
                order by app.variant_price(pv.id), pv.sort limit 1) v on true
  where cp.content_id = p_content and app.store_serves(s.id, v_zone) and app.product_available(p.id);
  v_pick := app.copilot_pick(v_zone, v_content.ingredients, 15);
  select v_items || coalesce(jsonb_agg(jsonb_build_object('variant_id', i ->> 'variant_id',
           'quantity', (i ->> 'quantity')::int, 'need', i ->> 'need', 'reason', i ->> 'reason')), '[]'::jsonb)
  into v_items
  from jsonb_array_elements(coalesce(v_pick -> 'stores', '[]'::jsonb)) st,
       jsonb_array_elements(st -> 'items') i
  where not exists (select 1 from jsonb_array_elements(v_items) t where t ->> 'variant_id' = i ->> 'variant_id');
  v_out := app.copilot_quote(v_items) || jsonb_build_object('missing', coalesce(v_pick -> 'missing', '[]'::jsonb));
  perform app.emit_event('recipe_basket_built', v_user, 'client', 'server',
    (select country_code from public.profiles where user_id = v_user), 'content', p_content::text,
    jsonb_build_object('items_count', coalesce((v_out ->> 'item_count')::int, 0),
      'missing_count', jsonb_array_length(coalesce(v_out -> 'missing', '[]'::jsonb))));
  return v_out;
end
$fn$;

insert into public.event_names (name, emitted_by, description) values
  ('recipe_basket_built', 'server', '« Tout pour la faire » : panier composé (articles, manquants)')
on conflict do nothing;

-- Contenu (0043) : ingrédients.
create or replace function app.content_json(p_content uuid, p_user uuid) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object(
    'id', c.id, 'kind', c.kind, 'media_key', c.media_key, 'media_type', c.media_type,
    'background', c.background,
    'caption', c.caption, 'status', c.status, 'created_at', c.created_at, 'expires_at', c.expires_at,
    'store', case when s.id is not null then jsonb_build_object('id', s.id, 'name', s.name, 'origin', s.origin,
      'cover_key', (select f.object_key from public.products p
                                join public.product_photos f on f.product_id = p.id
                                where p.store_id = s.id and p.status = 'published'
                                order by p.published_at, f.sort limit 1)) end,
    'author', case when cp0.user_id is not null then jsonb_build_object('id', cp0.user_id,
      'display_name', cp0.display_name, 'bio', cp0.bio) end,
    'category', (select jsonb_build_object('id', cc.id, 'slug', cc.slug, 'label', cc.label)
                 from public.content_categories cc where cc.id = c.category_id),
    'category_source', c.category_source,
    'ingredients', c.ingredients,
    'like_count', (select count(*) from public.content_likes l where l.content_id = c.id),
    'liked', p_user is not null and exists (select 1 from public.content_likes l
                                            where l.content_id = c.id and l.user_id = p_user),
    'products', coalesce((
      select jsonb_agg(app.catalog_item(cp.product_id) order by cp.sort)
      from public.content_products cp
      join public.products p on p.id = cp.product_id and p.status = 'published'
      where cp.content_id = c.id), '[]'::jsonb))
  from public.contents c left join public.stores s on s.id = c.store_id
  left join public.creator_profiles cp0 on cp0.user_id = c.author_id
  where c.id = p_content
$$;

revoke all on function public.set_content_ingredients(uuid, jsonb), public.recipe_basket(uuid, uuid) from public;
grant execute on function public.set_content_ingredients(uuid, jsonb), public.recipe_basket(uuid, uuid)
  to authenticated;
