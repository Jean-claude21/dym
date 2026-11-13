-- Cliente transmise au fournisseur de paiement (spec 088) : email et prénom, lisibles par la
-- Function seulement.

select plan(2);

select is(app.payment_customer(gen_random_uuid()), null, 'paiement inconnu : rien');
select ok(not has_function_privilege('authenticated', 'app.payment_customer(uuid)', 'execute'),
  'illisible depuis les apps');

select * from finish();
