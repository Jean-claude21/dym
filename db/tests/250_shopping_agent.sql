-- Assistant de courses (spec 029) : listes, habitudes, panier proposé, rappels récurrents.

select plan(19);

create temporary table _t as
select tests.create_user('awa@example.com') as awa,
       tests.create_user('ama@example.com') as ama,
       tests.create_user('kodjo@example.com') as kodjo,
       (select id from public.zones where slug = 'be') as be,
       (select id from public.categories where slug = 'tomates') as tomates,
       '25000000-0000-4000-8000-000000000001'::uuid as tomate,
       '25000000-0000-4000-8000-000000000002'::uuid as tomate_tas,
       null::uuid as kodjo_store, null::uuid as list1, null::uuid as list2, null::date as due;
update _t set kodjo_store = tests.open_store(kodjo, 'Étal de Kodjo', 'be');
grant select, update on _t to authenticated, anonymous;

select tests.login_as((select kodjo from _t));
select public.update_store('{"offers_pickup": true}');
select public.save_product(jsonb_build_object(
  'id', (select tomate from _t), 'name', 'Tomates', 'category_id', (select tomates from _t), 'price_minor', 500,
  'photo_keys', jsonb_build_array('stores/' || (select kodjo_store from _t) || '/products/' || (select tomate from _t) || '.jpg'),
  'variants', jsonb_build_array(jsonb_build_object('id', (select tomate_tas from _t), 'stock_quantity', 50))));
select public.publish_product((select tomate from _t));

select tests.login_as((select ama from _t));
select public.complete_profile('Ama', (select be from _t), 'client');
select tests.login_as((select awa from _t));
select public.complete_profile('Awa', (select be from _t), 'client');

-- Listes : création, nettoyage, refus.
update _t set list1 = (public.save_shopping_list(jsonb_build_object('name', '  Courses   du samedi ',
  'items', jsonb_build_array(jsonb_build_object('label', 'Tomates', 'query', 'tomate', 'quantity', 2),
                             jsonb_build_object('label', 'Licorne', 'query', 'zzzz')))) ->> 'id')::uuid;
select is((public.my_shopping_lists() -> 0 ->> 'name'), 'Courses du samedi', 'liste enregistrée, nom nettoyé');
select is((public.my_shopping_lists() -> 0 -> 'items' -> 1 ->> 'quantity')::int, 1, 'quantité par défaut : 1');
select throws_ok($$select public.save_shopping_list('{"name": "X", "items": [{"label": "Riz", "quantity": 11}]}')$$,
  '22023', 'invalid_quantity', 'quantité bornée à 10');
select throws_ok($$select public.save_shopping_list('{"name": "X", "items": [{"label": "Riz"}], "every_days": 10}')$$,
  '22023', 'invalid_period', 'période inconnue refusée');
select throws_ok(format($$select public.save_shopping_list('{"name": "X", "items": [{"label": "Riz"}],
  "every_days": 7, "starts_on": "%s"}')$$, current_date - 5), '22023', 'invalid_start', 'date de départ passée refusée');
select throws_ok($$select public.save_shopping_list('{"name": "X", "items": []}')$$,
  '22023', 'invalid_items', 'liste vide refusée');

-- Une autre personne ne voit ni ne touche la liste.
select tests.login_as((select ama from _t));
select is(jsonb_array_length(public.my_shopping_lists()), 0, 'Ama ne voit pas les listes d''Awa');
select is((select count(*)::int from public.shopping_lists), 0, 'lecture directe filtrée (RLS)');
select throws_ok(format($$select public.save_shopping_list('{"id": "%s", "name": "Pris", "items": [{"label": "Riz"}]}')$$,
  (select list1 from _t)), 'P0002', null, 'modification refusée');
select throws_ok(format($$select public.delete_shopping_list('%s')$$, (select list1 from _t)), 'P0002', null,
  'suppression refusée');
select throws_ok($$insert into public.shopping_lists (user_id, name, items) values
  (app.current_user_id(), 'X', '[{"label": "Riz"}]')$$, '42501', null, 'écriture directe refusée');
select throws_ok(format($$select public.shopping_list_proposal('%s')$$, (select list1 from _t)), 'P0002', null,
  'proposition d''une liste d''autrui refusée');

-- Panier proposé : composé et chiffré en base, ce qui manque est dit.
select tests.login_as((select awa from _t));
create temporary table _prop as select public.shopping_list_proposal((select list1 from _t)) as p;
select is((select (p -> 'stores' -> 0 -> 'items' -> 0 ->> 'quantity')::int from _prop), 2, 'panier proposé : 2 tas de tomates');
select is((select p -> 'missing' from _prop), '["Licorne"]'::jsonb, 'article introuvable signalé');

-- Habitudes : un produit acheté dans deux commandes, quantité médiane.
select is(jsonb_array_length(public.shopping_habits()), 0, 'aucune habitude sans commandes');
select public.cart_add((select tomate_tas from _t), 2);
select tests.logout();
select app.place_order((select awa from _t), gen_random_uuid(), jsonb_build_object(
  'payment_method_id', (select id from public.payment_methods where country_code = 'TG' and provider_code = 'cash'),
  'modes', jsonb_build_object((select kodjo_store from _t), 'pickup')), date_trunc('week', now()) - interval '14 days' + interval '10 hours');
select tests.login_as((select awa from _t));
select public.cart_add((select tomate_tas from _t), 4);
select tests.logout();
select app.place_order((select awa from _t), gen_random_uuid(), jsonb_build_object(
  'payment_method_id', (select id from public.payment_methods where country_code = 'TG' and provider_code = 'cash'),
  'modes', jsonb_build_object((select kodjo_store from _t), 'pickup')), date_trunc('week', now()) - interval '7 days' + interval '10 hours');
select tests.login_as((select awa from _t));
select is(public.shopping_habits(), '[{"label": "Tomates", "query": "Tomates", "quantity": 3}]'::jsonb,
  'liste habituelle : tomates, quantité médiane 3');

-- Rappels : 8 h locales, une seule fois par échéance, l'échéance avance d'une période.
update _t set list2 = (public.save_shopping_list(jsonb_build_object('name', 'Semaine', 'every_days', 7,
  'items', jsonb_build_array(jsonb_build_object('label', 'Tomates')))) ->> 'id')::uuid;
select tests.logout();
update public.shopping_lists set next_due_on = current_date - 3 where id = (select list2 from _t);
select is(app.create_shopping_reminders(date_trunc('day', now()) - interval '1 day' + interval '7 hours'), 0,
  'avant 8 h : aucun rappel');
select is(app.create_shopping_reminders(date_trunc('day', now()) - interval '1 day' + interval '9 hours')
          + app.create_shopping_reminders(date_trunc('day', now()) - interval '1 day' + interval '10 hours'), 1,
  'un seul rappel par échéance');
select is((select next_due_on from public.shopping_lists where id = (select list2 from _t)), current_date + 4,
  'échéance avancée d''une période');

select * from finish();
