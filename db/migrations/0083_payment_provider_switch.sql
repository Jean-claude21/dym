-- 0083 — Moneroo (spec 088) : l'admin bascule un moyen de paiement entre la simulation et Moneroo
-- (même famille de fournisseur), changement journalisé avant / après. Le fournisseur `moneroo`
-- existe depuis 0010 ; il n'est proposé à la commande que si la Function a sa clé.

CREATE OR REPLACE FUNCTION public.admin_save_payment_method(p_method jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_admin uuid := app.require_admin();
  v_id uuid := (p_method ->> 'id')::uuid;
  v_before public.payment_methods;
  v_after public.payment_methods;
  v_provider text := nullif(trim(p_method ->> 'provider_code'), '');
begin
  if v_id is not null then
    select * into v_before from public.payment_methods where id = v_id for update;
    if v_before.id is null then
      raise exception 'moyen introuvable' using errcode = 'P0002';
    end if;
    -- Bascule de fournisseur (spec 088) : même famille seulement (Mobile Money :
    -- simulation ou Moneroo).
    if v_provider is not null and v_provider <> v_before.provider_code
       and (select kind from public.payment_providers where code = v_provider)
           is distinct from (select kind from public.payment_providers where code = v_before.provider_code) then
      raise exception 'provider_kind_mismatch' using errcode = 'P0001';
    end if;
    update public.payment_methods set
      provider_code = coalesce(v_provider, provider_code),
      label = coalesce(p_method -> 'label', label),
      sort = coalesce((p_method ->> 'sort')::smallint, sort),
      is_active = coalesce((p_method ->> 'is_active')::boolean, is_active)
    where id = v_id returning * into v_after;
  else
    insert into public.payment_methods (country_code, provider_code, operator_code, label, sort, is_active)
    values (p_method ->> 'country_code', p_method ->> 'provider_code',
            nullif(trim(p_method ->> 'operator_code'), ''), p_method -> 'label',
            coalesce((p_method ->> 'sort')::smallint, 0), coalesce((p_method ->> 'is_active')::boolean, false))
    returning * into v_after;
  end if;
  if v_after.is_active and not (select is_active from public.payment_providers
                                where code = v_after.provider_code) then
    raise exception 'provider_inactive' using errcode = 'P0001';
  end if;
  perform app.admin_did(v_admin, case when v_id is null then 'payment_method_created'
                                      else 'payment_method_updated' end,
    'payment_method', v_after.id::text,
    case when v_id is null then null else jsonb_build_object('label', v_before.label,
      'sort', v_before.sort, 'is_active', v_before.is_active, 'provider_code', v_before.provider_code) end,
    jsonb_build_object('label', v_after.label, 'sort', v_after.sort, 'is_active', v_after.is_active,
      'provider_code', v_after.provider_code),
    null, v_after.country_code);
  return public.admin_payment_methods(v_after.country_code);
end
$function$;
