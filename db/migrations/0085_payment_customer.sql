-- 0085 — Moneroo exige la cliente (email, prénom, nom) pour ouvrir sa page de paiement (spec 088).
-- Seule la Function la lit, au moment d'initier un paiement en ligne ; DYM ne demande pas de nom
-- de famille : le prénom sert aussi de nom. Aucune autre donnée n'est transmise ; sans prénom,
-- l'initiation échoue (aucune valeur inventée).

create or replace function app.payment_customer(p_payment uuid) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object('email', lower(u.email), 'first_name', nullif(trim(p.first_name), ''))
  from public.payments pay
  join public.purchases pu on pu.id = pay.purchase_id
  join neon_auth."user" u on u.id = pu.user_id
  left join public.profiles p on p.user_id = pu.user_id
  where pay.id = p_payment
$$;

revoke all on function app.payment_customer(uuid) from public;
