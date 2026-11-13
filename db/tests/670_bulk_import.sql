-- Import en masse du catalogue (spec 081).

select plan(8);

create temporary table _t as
select tests.create_user('kodjo@example.com') as kodjo,
       tests.create_user('ama@example.com') as ama,
       null::uuid as kodjo_store;
update _t set kodjo_store = tests.open_store(kodjo, 'Super Frais', 'be');
grant select, update on _t to authenticated, anonymous;

select is(app.parse_price_minor('1 500', 0), 1500::bigint, 'prix avec espace');
select is(app.parse_price_minor('12,50', 2), 1250::bigint, 'prix décimal à virgule');
select is(app.parse_price_minor('abc', 0), null::bigint, 'prix illisible');

select tests.login_as((select kodjo from _t));
create temporary table _rows as select '[
  {"name": "Tomates", "price": "500", "unit": "tas", "category": "Légumes", "stock": "40"},
  {"name": "Huile rouge", "price": "1 200", "unit": "", "category": "huiles-condiments", "stock": ""},
  {"name": "X", "price": "100", "unit": "", "category": "Légumes", "stock": ""},
  {"name": "Gombo", "price": "deux cents", "unit": "", "category": "Légumes", "stock": ""},
  {"name": "Mangues", "price": "300", "unit": "", "category": "Inconnu", "stock": ""}
]'::jsonb as rows;
grant select on _rows to authenticated;

select is((public.import_products((select rows from _rows)) ->> 'valid')::int, 2, 'aperçu : deux lignes valides');
select tests.logout();
select is((select count(*)::int from public.products where store_id = (select kodjo_store from _t)), 0,
  'aperçu : rien de créé');
select tests.login_as((select kodjo from _t));
select is(public.import_products((select rows from _rows)) -> 'errors',
  '[{"line": 3, "reason": "name_invalid"}, {"line": 4, "reason": "price_invalid"},
    {"line": 5, "reason": "category_unknown"}]'::jsonb, 'erreurs par ligne');
select is((public.import_products((select rows from _rows), false) ->> 'valid')::int, 2, 'import : deux créés');
select tests.logout();
select is((select count(*)::int from public.products
           where store_id = (select kodjo_store from _t) and status = 'draft'), 2, 'créés en brouillon');

select * from finish();
