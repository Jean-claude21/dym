-- Spec 022 : profil modifiable depuis « Moi » (C-PROF-01, V-PROF-01) et langue
-- de l'app (C-PROF-07). La langue choisie sert aussi aux notifications push :
-- seules les langues qui ont leurs modèles de notification sont acceptées
-- (aucune liste de langues dans le code).

create or replace function public.update_my_profile(
  p_first_name text default null,
  p_locale text default null
) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := app.require_user();
  v_name text := nullif(trim(coalesce(p_first_name, '')), '');
begin
  if not exists (select 1 from public.profiles where user_id = v_user) then
    raise exception 'profil à compléter' using errcode = 'P0002';
  end if;
  if p_first_name is not null and (v_name is null or length(v_name) > 40) then
    raise exception 'prénom : 1 à 40 caractères' using errcode = '22023';
  end if;
  if p_locale is not null and not exists (
    select 1 from public.notification_templates where locale = p_locale) then
    raise exception 'langue non prise en charge' using errcode = '22023';
  end if;
  update public.profiles
  set first_name = coalesce(v_name, first_name),
      locale = coalesce(p_locale, locale)
  where user_id = v_user;
  return public.me();
end
$$;

-- Langues proposées : celles qui ont leurs notifications.
create or replace function public.supported_locales() returns jsonb
language sql stable security definer set search_path = ''
as $$
  select coalesce(jsonb_agg(distinct locale order by locale), '[]'::jsonb)
  from public.notification_templates
$$;

revoke all on function public.update_my_profile(text, text), public.supported_locales() from public;
grant execute on function public.update_my_profile(text, text) to authenticated;
grant execute on function public.supported_locales() to authenticated, anonymous;
