-- 0097 — Connexion WhatsApp (spec 105) : code à 6 chiffres envoyé par WhatsApp (modèle
-- d'authentification Meta), haché, 10 minutes, 5 essais, 3 envois par 10 minutes. Un numéro vérifié
-- ouvre toujours le même compte (lié à une adresse interne) ; la session reste celle de Neon Auth.

create table public.phone_identities (
  phone text primary key check (phone ~ '^\+[1-9][0-9]{7,14}$'),
  email text not null unique,
  created_at timestamptz not null default now()
);
alter table public.phone_identities enable row level security;

create table public.phone_login_codes (
  phone text primary key check (phone ~ '^\+[1-9][0-9]{7,14}$'),
  code_hash text not null,
  expires_at timestamptz not null,
  attempts integer not null default 0,
  sent_count integer not null default 1,
  window_start timestamptz not null default now()
);
alter table public.phone_login_codes enable row level security;

-- Nouveau code : refusé au-delà de 3 envois par 10 minutes (secondes à attendre).
create or replace function app.phone_code_issue(p_phone text, p_hash text, p_ttl_seconds integer default 600)
returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_row public.phone_login_codes;
begin
  if p_phone !~ '^\+[1-9][0-9]{7,14}$' then
    raise exception 'phone_invalid' using errcode = '22023';
  end if;
  select * into v_row from public.phone_login_codes where phone = p_phone for update;
  if v_row.phone is not null and v_row.window_start > now() - interval '10 minutes' and v_row.sent_count >= 3 then
    return jsonb_build_object('ok', false,
      'retry_after', ceil(extract(epoch from (v_row.window_start + interval '10 minutes' - now())))::int);
  end if;
  insert into public.phone_login_codes (phone, code_hash, expires_at)
  values (p_phone, p_hash, now() + make_interval(secs => p_ttl_seconds))
  on conflict (phone) do update set
    code_hash = excluded.code_hash,
    expires_at = excluded.expires_at,
    attempts = 0,
    sent_count = case when public.phone_login_codes.window_start > now() - interval '10 minutes'
                      then public.phone_login_codes.sent_count + 1 else 1 end,
    window_start = case when public.phone_login_codes.window_start > now() - interval '10 minutes'
                        then public.phone_login_codes.window_start else now() end;
  return jsonb_build_object('ok', true);
end
$$;
revoke all on function app.phone_code_issue(text, text, integer) from public;

-- Vérifie le code : bon → adresse du compte (créée au premier passage), code consommé ;
-- mauvais ou expiré → null, essai compté (5 au plus).
create or replace function app.phone_code_check(p_phone text, p_hash text)
returns text
language plpgsql security definer set search_path = ''
as $$
declare
  v_row public.phone_login_codes;
  v_email text;
begin
  select * into v_row from public.phone_login_codes where phone = p_phone for update;
  if v_row.phone is null or v_row.expires_at < now() or v_row.attempts >= 5 then
    return null;
  end if;
  if v_row.code_hash = '' or v_row.code_hash <> p_hash then
    update public.phone_login_codes set attempts = attempts + 1 where phone = p_phone;
    return null;
  end if;
  -- Code consommé ; la ligne reste pour compter les envois de la fenêtre.
  update public.phone_login_codes set code_hash = '', expires_at = now() where phone = p_phone;
  insert into public.phone_identities (phone, email)
  values (p_phone, 'w' || substr(p_phone, 2) || '@phone.dym.africa')
  on conflict (phone) do nothing;
  select email into v_email from public.phone_identities where phone = p_phone;
  return v_email;
end
$$;
revoke all on function app.phone_code_check(text, text) from public;
