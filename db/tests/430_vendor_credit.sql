-- Ardoise et relances (spec 047).

select plan(15);

create temporary table _t as
select tests.create_user('kodjo@example.com') as kodjo,
       tests.create_user('efua@example.com') as efua,
       null::uuid as kodjo_store, null::uuid as credit;
update _t set kodjo_store = tests.open_store(kodjo, 'Étal de Kodjo', 'be');
grant select, update on _t to authenticated, anonymous;

select tests.login_as((select kodjo from _t));
select throws_ok($$select public.save_credit(null, 'Ama', '123')$$, '22023', 'invalid_phone', 'téléphone invalide');
update _t set credit = (public.save_credit(null, 'Ama', '+228 90 00 00 07', 5000) ->> 'id')::uuid;

-- Dettes et remboursements : solde en base, plafond, pas plus que le dû.
select is((public.add_credit_entry((select credit from _t), 'debt', 3000, '43100000-0000-4000-8000-000000000001', 'Tomates')
  ->> 'balance_minor')::bigint, 3000::bigint, 'dette inscrite');
select is((public.add_credit_entry((select credit from _t), 'debt', 3000, '43100000-0000-4000-8000-000000000001')
  ->> 'balance_minor')::bigint, 3000::bigint, 'même clé : une seule fois');
select throws_ok(format($$select public.add_credit_entry('%s', 'debt', 2500, gen_random_uuid())$$, (select credit from _t)),
  'P0001', 'credit_limit', 'plafond dépassé');
select throws_ok(format($$select public.add_credit_entry('%s', 'payment', 4000, gen_random_uuid())$$, (select credit from _t)),
  'P0001', 'payment_too_high', 'remboursement au-delà du dû');
select is((public.add_credit_entry((select credit from _t), 'payment', 1000, gen_random_uuid())
  ->> 'balance_minor')::bigint, 2000::bigint, 'remboursement');
select is(jsonb_array_length(public.credit_detail((select credit from _t)) -> 'entries'), 2, 'historique');
select is((public.my_credits() ->> 'total_minor')::bigint, 2000::bigint, 'total de l''ardoise');

-- Relance : une par jour.
select is(public.remind_credit((select credit from _t)) ->> 'store_name', 'Étal de Kodjo', 'relance préparée');
select throws_ok(format($$select public.remind_credit('%s')$$, (select credit from _t)),
  'P0001', 'already_reminded', 'une relance par jour');
select is(public.credit_detail((select credit from _t)) ->> 'can_remind', 'false', 'relance indisponible aujourd''hui');

-- Archivage seulement soldée.
select throws_ok(format($$select public.archive_credit('%s')$$, (select credit from _t)),
  'P0001', 'balance_not_zero', 'pas d''archivage avec un dû');
select public.add_credit_entry((select credit from _t), 'payment', 2000, gen_random_uuid());
select is(jsonb_array_length(public.archive_credit((select credit from _t)) -> 'credits'), 0, 'ardoise soldée retirée');

-- Une autre vendeuse ne voit rien.
select tests.login_as((select efua from _t));
select tests.logout();
select tests.open_store((select efua from _t), 'Huiles d''Efua', 'be');
select tests.login_as((select efua from _t));
select throws_ok(format($$select public.credit_detail('%s')$$, (select credit from _t)), 'P0002', null, 'ardoise d''autrui');
select is(jsonb_array_length(public.my_credits() -> 'credits'), 0, 'rien chez une autre boutique');
select tests.logout();

select * from finish();
