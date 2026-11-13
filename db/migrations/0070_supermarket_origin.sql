-- Supermarchés (spec 071) : nouvelle origine de boutique, donnée de référence
-- comme les autres (aucune liste dans le code des apps).
insert into public.store_origins (code, label, description, sort) values
  ('supermarche', '{"fr": "Supermarché", "en": "Supermarket"}',
   '{"fr": "Tu gères un supermarché ou une supérette : rayons, caisses, produits frais emballés.", "en": "You run a supermarket or a mini-market: aisles, checkouts, packed fresh produce."}', 4)
on conflict (code) do nothing;
