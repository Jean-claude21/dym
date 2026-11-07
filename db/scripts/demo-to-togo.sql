-- Démonstration : bascule des comptes et boutiques de démo de France vers Lomé (Togo),
-- montants convertis d'EUR en F CFA (1 € = 655,957 F, arrondi à 25 F). Staging seulement.
begin;

create function pg_temp.xof(x bigint) returns bigint language sql immutable as $$
  select case when x is null then null when x = 0 then 0
              else greatest(25, round(x * 6.55957 / 25) * 25)::bigint end
$$;

-- Quartier français → quartier de Lomé.
create temp table zmap (fr_city text, fr_zone text, tg_zone text) on commit drop;
insert into zmap values
  ('paris', 'paris-18', 'be'), ('paris', 'paris-11', 'tokoin'), ('paris', 'paris-20', 'adawlato'),
  ('paris', 'paris-10', 'nyekonakpoe'), ('paris', 'paris-13', 'kodjoviakope'),
  ('paris', 'paris-19', 'hedzranawoe'), ('paris', 'paris-17', 'adidogome'),
  ('lyon', 'croix-rousse', 'agoe'), ('lyon', 'guillotiere', 'kegue'),
  ('marseille', 'noailles', 'baguida');
create temp table zid on commit drop as
select fz.id as fr_id, tz.id as tg_id, tz.latitude, tz.longitude, tz.name as tg_name
from zmap m
join public.cities fc on fc.country_code = 'FR' and fc.slug = m.fr_city
join public.zones fz on fz.city_id = fc.id and fz.slug = m.fr_zone
join public.cities tc on tc.country_code = 'TG' and tc.slug = 'lome'
join public.zones tz on tz.city_id = tc.id and tz.slug = m.tg_zone;

create temp table conv_stores on commit drop as
select s.id from public.stores s where s.country_code = 'FR';

-- Profils et boutiques.
update public.profiles p set zone_id = z.tg_id, country_code = 'TG'
from zid z where p.zone_id = z.fr_id;
update public.stores s set zone_id = z.tg_id, country_code = 'TG', currency_code = 'XOF',
  delivery_fee_minor = pg_temp.xof(s.delivery_fee_minor)
from zid z where s.zone_id = z.fr_id;
update public.store_pickup_addresses a set latitude = z.latitude, longitude = z.longitude
from public.stores s join zid z on z.tg_id = s.zone_id
where a.store_id = s.id and s.id in (select id from conv_stores);

-- Livraison dans tout Lomé, paiements du Togo.
delete from public.store_delivery_zones where store_id in (select id from conv_stores);
insert into public.store_delivery_zones (store_id, zone_id)
select s.id, z.id from conv_stores s
cross join public.zones z join public.cities c on c.id = z.city_id
where c.country_code = 'TG' and c.slug = 'lome' and z.is_active;
delete from public.store_payment_methods where store_id in (select id from conv_stores);
insert into public.store_payment_methods (store_id, payment_method_id)
select s.id, m.id from conv_stores s cross join public.payment_methods m
where m.country_code = 'TG' and m.is_active;

-- Catalogue : F CFA et unités du Togo.
create temp table umap (fr text, tg text) on commit drop;
insert into umap values ('kilo', 'kilo'), ('piece', 'piece'), ('litre', 'litre'), ('botte', 'botte'),
  ('sachet', 'sachet'), ('barquette', 'bol'), ('demi_kilo', 'tas'), ('bouteille', 'litre');
update public.products p set currency_code = 'XOF', price_minor = pg_temp.xof(p.price_minor),
  unit_id = coalesce((select tu.id from public.units fu join umap m on m.fr = fu.code
                      join public.units tu on tu.country_code = 'TG' and tu.code = m.tg
                      where fu.id = p.unit_id), p.unit_id)
where p.store_id in (select id from conv_stores);
update public.product_variants v set price_minor = pg_temp.xof(v.price_minor)
from public.products p where p.id = v.product_id and p.store_id in (select id from conv_stores);

-- Adresses des clientes.
update public.customer_addresses a set zone_id = z.tg_id, latitude = z.latitude,
  longitude = z.longitude, phone = '+22890123456'
from zid z where a.zone_id = z.fr_id;

-- Paniers français vidés (un panier par pays).
delete from public.carts where country_code = 'FR';

-- Historique : lignes, commandes, achats, paiements, remboursements (totaux recalculés).
create temp table conv_orders on commit drop as
select id, purchase_id from public.orders where currency_code = 'EUR';
update public.order_items i set unit_price_minor = pg_temp.xof(i.unit_price_minor),
  amount_minor = pg_temp.xof(i.unit_price_minor) * i.quantity
where i.order_id in (select id from conv_orders);
update public.orders o set currency_code = 'XOF',
  subtotal_minor = coalesce((select sum(i.amount_minor) from public.order_items i where i.order_id = o.id), 0),
  delivery_fee_minor = pg_temp.xof(o.delivery_fee_minor),
  total_minor = coalesce((select sum(i.amount_minor) from public.order_items i where i.order_id = o.id), 0)
                + pg_temp.xof(o.delivery_fee_minor),
  commission_minor = pg_temp.xof(o.commission_minor)
where o.id in (select id from conv_orders);
update public.disputes d set refund_minor = pg_temp.xof(d.refund_minor)
where d.order_id in (select id from conv_orders) and d.refund_minor is not null;
update public.purchases p set country_code = 'TG', currency_code = 'XOF',
  subtotal_minor = t.sub, delivery_fee_minor = t.fee, total_minor = t.sub + t.fee,
  address = case when p.address is null then null else p.address || jsonb_build_object(
    'zone_id', z.tg_id, 'zone_name', z.tg_name, 'city_name', 'Lomé',
    'latitude', z.latitude, 'longitude', z.longitude, 'phone', '+22890123456') end
from (select o.purchase_id, sum(o.subtotal_minor) sub, sum(o.delivery_fee_minor) fee
      from public.orders o where o.purchase_id in (select purchase_id from conv_orders) group by 1) t
left join public.purchases p0 on p0.id = t.purchase_id
left join zid z on z.fr_id = (p0.address ->> 'zone_id')::uuid
where p.id = t.purchase_id;
update public.payments y set currency_code = 'XOF', amount_minor = p.total_minor
from public.purchases p where p.id = y.purchase_id and y.currency_code = 'EUR';
update public.refunds set currency_code = 'XOF', amount_minor = pg_temp.xof(amount_minor)
where currency_code = 'EUR';
update public.purchases set country_code = 'TG', currency_code = 'XOF' where country_code = 'FR';
update public.events set country_code = 'TG' where country_code = 'FR';
update public.ai_requests set country_code = 'TG' where country_code = 'FR';

-- La démo se concentre sur le Togo.
update public.countries set is_active = false where code in ('FR', 'GH');

select (select count(*) from conv_stores) boutiques_converties,
       (select count(*) from public.profiles where country_code = 'FR') profils_fr_restants,
       (select count(*) from public.orders where currency_code = 'EUR') commandes_eur_restantes;
commit;
