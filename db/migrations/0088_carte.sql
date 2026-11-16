-- Carte DYM (spec 095) : boutiques visibles dans un cadre de carte, filtres « ouvertes » et
-- catégorie. Lecture publique (visiteuse sans compte comprise), comme la découverte.

-- Catégorie et ses sous-catégories.
create or replace function app.category_tree(p_category uuid)
returns setof uuid
language sql stable security definer set search_path = ''
as $$
  with recursive tree as (
    select c.id from public.categories c where c.id = p_category
    union
    select c.id from public.categories c join tree t on c.parent_id = t.id
  )
  select id from tree
$$;

create or replace function public.map_stores(
  p_south numeric,
  p_west numeric,
  p_north numeric,
  p_east numeric,
  p_category uuid default null,
  p_open_only boolean default false,
  p_limit integer default 200,
  p_at timestamptz default now()
) returns jsonb
language sql stable security definer set search_path = ''
as $$
  with box as (
    select p_south as s, p_west as w, p_north as n, p_east as e
    where p_south between -90 and 90 and p_north between -90 and 90 and p_south <= p_north
      and p_west between -180 and 180 and p_east between -180 and 180 and p_west <= p_east
  ),
  candidates as (
    select s.id, s.name, app.store_open_at(s.id, p_at) as open_now
    from public.stores s
    join public.zones z on z.id = s.zone_id
    cross join box b
    cross join lateral app.store_point(s.id) sp
    where s.status = 'active'
      and app.city_is_visible(z.city_id)
      and sp.lat between b.s and b.n and sp.lng between b.w and b.e
      and (p_category is null
           or s.main_category_id in (select app.category_tree(p_category))
           or exists (select 1 from public.products p
                      where p.store_id = s.id and p.status = 'published'
                        and p.category_id in (select app.category_tree(p_category))))
  )
  select coalesce(jsonb_agg(app.store_summary(id, p_at) order by open_now desc, name), '[]'::jsonb)
  from (select * from candidates
        where open_now or not p_open_only
        order by open_now desc, name
        limit greatest(1, least(p_limit, 300))) t
$$;

revoke all on function public.map_stores(numeric, numeric, numeric, numeric, uuid, boolean, integer, timestamptz)
  from public;
grant execute on function public.map_stores(numeric, numeric, numeric, numeric, uuid, boolean, integer, timestamptz)
  to anonymous, authenticated;
revoke all on function app.category_tree(uuid) from public;
