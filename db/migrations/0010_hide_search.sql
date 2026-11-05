-- La colonne générée `search` (0008) ne sort pas des fonctions de lecture de
-- la propriétaire (`my_store`, `my_products` via `app.product_json`).

create or replace function public.my_store() returns jsonb
language sql stable security definer set search_path = ''
as $$
  select case when s.id is null then null else
    to_jsonb(s) - 'owner_id' - 'search'
    || jsonb_build_object(
      'pickup_address', (select to_jsonb(a) - 'store_id' from public.store_pickup_addresses a where a.store_id = s.id),
      'delivery_zone_ids', coalesce((select jsonb_agg(z.zone_id) from public.store_delivery_zones z where z.store_id = s.id), '[]'::jsonb),
      'payment_method_ids', coalesce((select jsonb_agg(p.payment_method_id) from public.store_payment_methods p where p.store_id = s.id), '[]'::jsonb),
      'hours', coalesce((select jsonb_agg(jsonb_build_object('weekday', h.weekday, 'opens_at', to_char(h.opens_at, 'HH24:MI'), 'closes_at', to_char(h.closes_at, 'HH24:MI')) order by h.weekday) from public.store_hours h where h.store_id = s.id), '[]'::jsonb),
      'missing', to_jsonb(app.store_missing(s.id))
    )
  end
  from (select 1) one
  left join public.stores s on s.owner_id = app.current_user_id()
$$;

create or replace function app.product_json(p_product uuid) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select to_jsonb(p) - 'store_id' - 'search'
    || jsonb_build_object(
      'variants', coalesce((
        select jsonb_agg(jsonb_build_object(
          'id', v.id, 'label', v.label, 'price_minor', v.price_minor,
          'stock_quantity', v.stock_quantity, 'sort', v.sort) order by v.sort, v.created_at)
        from public.product_variants v where v.product_id = p.id), '[]'::jsonb),
      'photo_keys', coalesce((
        select jsonb_agg(f.object_key order by f.sort)
        from public.product_photos f where f.product_id = p.id), '[]'::jsonb),
      'store_category_ids', coalesce((
        select jsonb_agg(c.store_category_id)
        from public.product_store_categories c where c.product_id = p.id), '[]'::jsonb),
      'missing', to_jsonb(app.product_missing(p.id))
    )
  from public.products p where p.id = p_product
$$;
