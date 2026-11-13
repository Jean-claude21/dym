-- Bascule simulation ↔ Moneroo d'un moyen de paiement par l'admin (spec 088).

select plan(5);

create temporary table _t as
select tests.create_user('chef@example.com') as chef, null::uuid as method;
insert into public.user_roles (user_id, role) select chef, 'admin' from _t;
grant select, update on _t to authenticated, anonymous;

insert into public.payment_methods (country_code, provider_code, operator_code, label, sort, is_active)
values ('TG', 'simulator', 'essai_sept', '{"fr": "Mobile Money (essai)"}', 90, true);
update _t set method = (select id from public.payment_methods where operator_code = 'essai_sept');

select tests.login_as((select chef from _t));
select is((select m ->> 'provider_code' from jsonb_array_elements(
  public.admin_save_payment_method(jsonb_build_object('id', (select method from _t), 'provider_code', 'moneroo'))
  -> 'methods') m where m ->> 'id' = (select method from _t)::text), 'moneroo', 'bascule vers Moneroo');
select is((select m ->> 'provider_code' from jsonb_array_elements(
  public.admin_save_payment_method(jsonb_build_object('id', (select method from _t), 'provider_code', 'simulator'))
  -> 'methods') m where m ->> 'id' = (select method from _t)::text), 'simulator', 'retour à la simulation');
select throws_ok($$select public.admin_save_payment_method(
  jsonb_build_object('id', (select method from _t), 'provider_code', 'cash'))$$, 'P0001', 'provider_kind_mismatch',
  'pas vers une autre famille');
select lives_ok($$select public.admin_save_payment_method(
  jsonb_build_object('id', (select method from _t), 'sort', 91))$$, 'sans fournisseur : inchangé');
select tests.logout();
select is((select count(*)::int from public.audit_log
           where action = 'payment_method_updated' and after ->> 'provider_code' = 'moneroo'), 1,
  'bascule journalisée avec le fournisseur');

select * from finish();
