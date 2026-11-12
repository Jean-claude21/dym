-- Spec 057 (cuisine-video-feed) : « Tout pour la recette » pour N personnes, sans quitter la vidéo.
-- 1. Une recette a un nombre de portions de référence (4 par défaut).
-- 2. `recipe_basket` accepte un nombre de portions : les quantités des ingrédients sont recalculées
--    en base (arrondi au-dessus, au moins 1) ; les produits tagués (ustensiles, plats) restent à 1.
--    La réponse rappelle les portions demandées et celles de référence.

alter table public.contents add column servings smallint not null default 4
  check (servings between 1 and 50);

drop function public.recipe_basket(uuid, uuid);

create function public.recipe_basket(p_content uuid, p_zone uuid default null, p_servings int default null)
returns jsonb
language plpgsql security definer set search_path = ''
as $fn$
declare
  v_user uuid := app.current_user_id();
  v_content public.contents;
  v_zone uuid;
  v_servings int;
  v_needs jsonb;
  v_pick jsonb;
  v_items jsonb := '[]'::jsonb;
  v_out jsonb;
begin
  select * into v_content from public.contents where id = p_content;
  if v_content.id is null or not app.content_visible(v_content, now()) then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  v_servings := coalesce(p_servings, v_content.servings);
  if v_servings < 1 or v_servings > 50 then
    raise exception 'invalid_servings' using errcode = '22023';
  end if;
  v_zone := coalesce(p_zone, (select zone_id from public.profiles where user_id = v_user));
  -- Produits tagués encore en vente et livrables dans le quartier (toujours 1).
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
  -- Ingrédients mis à l'échelle des portions demandées.
  select coalesce(jsonb_agg(i || jsonb_build_object('quantity',
           greatest(1, ceil(coalesce((i ->> 'quantity')::numeric, 1) * v_servings / v_content.servings))::int)
         order by o), '[]'::jsonb)
  into v_needs
  from jsonb_array_elements(v_content.ingredients) with ordinality as t(i, o);
  v_pick := app.copilot_pick(v_zone, v_needs, 15);
  select v_items || coalesce(jsonb_agg(jsonb_build_object('variant_id', i ->> 'variant_id',
           'quantity', (i ->> 'quantity')::int, 'need', i ->> 'need', 'reason', i ->> 'reason')), '[]'::jsonb)
  into v_items
  from jsonb_array_elements(coalesce(v_pick -> 'stores', '[]'::jsonb)) st,
       jsonb_array_elements(st -> 'items') i
  where not exists (select 1 from jsonb_array_elements(v_items) t where t ->> 'variant_id' = i ->> 'variant_id');
  v_out := app.copilot_quote(v_items) || jsonb_build_object(
    'missing', coalesce(v_pick -> 'missing', '[]'::jsonb),
    'servings', v_servings, 'base_servings', v_content.servings);
  perform app.emit_event('recipe_basket_built', v_user, 'client', 'server',
    (select country_code from public.profiles where user_id = v_user), 'content', p_content::text,
    jsonb_build_object('items_count', coalesce((v_out ->> 'item_count')::int, 0),
      'missing_count', jsonb_array_length(coalesce(v_out -> 'missing', '[]'::jsonb)),
      'servings', v_servings));
  return v_out;
end
$fn$;

revoke all on function public.recipe_basket(uuid, uuid, int) from public;
grant execute on function public.recipe_basket(uuid, uuid, int) to authenticated;
