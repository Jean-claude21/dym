-- Côte d'Ivoire ouverte par configuration (spec 090) : pays complet et actif, Abidjan, paiements.

select plan(4);

select ok((select is_active from public.countries where code = 'CI') and cardinality(app.country_missing('CI')) = 0,
  'Côte d''Ivoire complète et active');
select is((select count(*)::int from public.zones z join public.cities c on c.id = z.city_id
           where c.country_code = 'CI' and c.slug = 'abidjan'), 10, 'dix communes d''Abidjan');
select ok(exists (select 1 from public.payment_methods where country_code = 'CI' and provider_code = 'wallet' and is_active),
  'wallet ouvert');
select is((select count(*)::int from public.payment_methods
           where country_code = 'CI' and provider_code = 'moneroo' and is_active), 0,
  'Moneroo désactivé tant que la passerelle XOF manque');

select * from finish();
