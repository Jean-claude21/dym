-- 0034 — Fil personnel de l'accueil (spec 027) : dernière commande livrée de la personne, produits
-- les plus demandés du quartier (30 jours) et nouveautés (14 jours). Seulement des produits
-- publiés, disponibles, de boutiques actives qui livrent le quartier.

create or replace function public.home_feed(p_zone uuid, p_at timestamptz default now())
returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object(
    'last_order', (
      select jsonb_build_object(
        'order_id', o.id, 'store_name', s.name, 'delivered_at', o.delivered_at,
        'item_count', (select coalesce(sum(oi.quantity), 0) from public.order_items oi where oi.order_id = o.id))
      from public.orders o
      join public.purchases pu on pu.id = o.purchase_id
      join public.stores s on s.id = o.store_id
      where app.current_user_id() is not null and pu.user_id = app.current_user_id()
        and o.status = 'delivered'
      order by o.delivered_at desc nulls last, o.created_at desc
      limit 1),
    'popular', coalesce((
      select jsonb_agg(app.catalog_item(x.id) order by x.n desc, x.id)
      from (
        select p.id, sum(oi.quantity) as n
        from public.order_items oi
        join public.orders o on o.id = oi.order_id
        join public.products p on p.id = oi.product_id
        join public.stores s on s.id = p.store_id
        where o.created_at > p_at - interval '30 days'
          and p.status = 'published' and s.status = 'active'
          and app.store_serves(s.id, p_zone) and app.product_available(p.id)
        group by p.id
        order by n desc, p.id
        limit 10) x), '[]'::jsonb),
    'fresh', coalesce((
      select jsonb_agg(app.catalog_item(x.id) order by x.published_at desc, x.id)
      from (
        select p.id, p.published_at
        from public.products p
        join public.stores s on s.id = p.store_id
        where p.status = 'published' and s.status = 'active'
          and p.published_at > p_at - interval '14 days'
          and app.store_serves(s.id, p_zone) and app.product_available(p.id)
        order by p.published_at desc, p.id
        limit 10) x), '[]'::jsonb))
$$;

revoke all on function public.home_feed(uuid, timestamptz) from public;
grant execute on function public.home_feed(uuid, timestamptz) to authenticated, anonymous;
