-- Connexion WhatsApp (spec 105) : codes hachés, essais, envois limités, même compte à chaque fois.

select plan(9);

select is(app.phone_code_issue('+22890112233', 'h1') ->> 'ok', 'true', 'premier code');
select is(app.phone_code_check('+22890112233', 'faux'), null, 'mauvais code refusé');
select is(app.phone_code_check('+22890112233', 'h1'), 'w22890112233@phone.dym.africa', 'bon code : adresse du compte');
select is(app.phone_code_check('+22890112233', 'h1'), null, 'code consommé');

select app.phone_code_issue('+22890112233', 'h2');
select is(app.phone_code_check('+22890112233', 'h2'), 'w22890112233@phone.dym.africa', 'même compte ensuite');

select app.phone_code_issue('+22890112233', 'h3');
select is((app.phone_code_issue('+22890112233', 'h4') ->> 'ok')::boolean, false, 'trois envois par 10 minutes');

-- Cinq essais au plus.
select app.phone_code_issue('+33612345678', 'h5');
select app.phone_code_check('+33612345678', 'x') from generate_series(1, 5);
select is(app.phone_code_check('+33612345678', 'h5'), null, 'bloqué après cinq essais');

select throws_ok($$select app.phone_code_issue('0612345678', 'h')$$, '22023', null, 'numéro international exigé');
select is((select count(*)::int from public.phone_identities), 1, 'une seule identité créée');

select * from finish();
