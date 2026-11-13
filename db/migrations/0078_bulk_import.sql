-- Import en masse du catalogue (spec 081, supermarchés) : lignes collées
-- depuis un tableur (nom, prix, unité, rayon, stock), vérifiées une à une en
-- SQL, créées en brouillon (photos ajoutées ensuite). `p_dry` : contrôle sans
-- rien créer (aperçu).

create or replace function app.parse_price_minor(p_text text, p_minor_units int) returns bigint
language plpgsql immutable set search_path = ''
as $$
declare
  v_clean text := regexp_replace(coalesce(p_text, ''), '[\s  ]', '', 'g');
  v_num numeric;
begin
  v_clean := replace(v_clean, ',', '.');
  if v_clean !~ '^[0-9]+(\.[0-9]+)?$' then
    return null;
  end if;
  v_num := v_clean::numeric * (10 ^ p_minor_units);
  if v_num <> trunc(v_num) or v_num <= 0 then
    return null;
  end if;
  return v_num::bigint;
end
$$;

create or replace function public.import_products(p_rows jsonb, p_dry boolean default true) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_store uuid := app.own_editable_store();
  v_country char(2);
  v_units int;
  v_row jsonb;
  v_line int := 0;
  v_name text;
  v_price bigint;
  v_category uuid;
  v_unit uuid;
  v_stock int;
  v_reason text;
  v_ok int := 0;
  v_errors jsonb := '[]'::jsonb;
begin
  if p_rows is null or jsonb_typeof(p_rows) <> 'array' or jsonb_array_length(p_rows) = 0 then
    raise exception 'aucune ligne' using errcode = '22023';
  end if;
  if jsonb_array_length(p_rows) > 500 then
    raise exception 'too_many_rows' using errcode = '22023';
  end if;
  select s.country_code, c.minor_units into v_country, v_units
  from public.stores s join public.currencies c on c.code = s.currency_code where s.id = v_store;

  for v_row in select value from jsonb_array_elements(p_rows) loop
    v_line := v_line + 1;
    v_reason := null;
    v_name := btrim(coalesce(v_row ->> 'name', ''));
    v_price := app.parse_price_minor(v_row ->> 'price', coalesce(v_units, 0));
    select id into v_category from public.categories
    where is_active
      and (app.normalize(label ->> 'fr') = app.normalize(btrim(coalesce(v_row ->> 'category', '')))
           or app.normalize(label ->> 'en') = app.normalize(btrim(coalesce(v_row ->> 'category', '')))
           or slug = app.normalize(btrim(coalesce(v_row ->> 'category', ''))))
    order by parent_id nulls last
    limit 1;
    v_unit := null;
    if btrim(coalesce(v_row ->> 'unit', '')) <> '' then
      select id into v_unit from public.units
      where country_code = v_country and is_active
        and (code = app.normalize(btrim(v_row ->> 'unit'))
             or app.normalize(label ->> 'fr') = app.normalize(btrim(v_row ->> 'unit'))
             or app.normalize(label ->> 'en') = app.normalize(btrim(v_row ->> 'unit')))
      limit 1;
    end if;
    v_stock := case when coalesce(v_row ->> 'stock', '') ~ '^\s*[0-9]{1,5}\s*$'
                    then btrim(v_row ->> 'stock')::int end;
    v_reason := case
      when length(v_name) < 2 or length(v_name) > 120 then 'name_invalid'
      when v_price is null then 'price_invalid'
      when v_category is null then 'category_unknown'
      when btrim(coalesce(v_row ->> 'unit', '')) <> '' and v_unit is null then 'unit_unknown'
      when btrim(coalesce(v_row ->> 'stock', '')) <> '' and v_stock is null then 'stock_invalid'
    end;
    if v_reason is null and not p_dry then
      begin
        perform public.save_product(jsonb_build_object(
          'id', gen_random_uuid(), 'name', v_name, 'category_id', v_category,
          'unit_id', v_unit, 'price_minor', v_price,
          'variants', jsonb_build_array(jsonb_build_object(
            'id', gen_random_uuid(), 'stock_quantity', v_stock))));
      exception when others then
        v_reason := 'error';
      end;
    end if;
    if v_reason is null then
      v_ok := v_ok + 1;
    else
      v_errors := v_errors || jsonb_build_object('line', v_line, 'reason', v_reason);
    end if;
  end loop;
  if not p_dry and v_ok > 0 then
    perform app.emit_event('products_imported', auth.uid(), 'vendor', 'server', v_country,
      'store', v_store::text, jsonb_build_object('created', v_ok, 'errors', jsonb_array_length(v_errors)));
  end if;
  return jsonb_build_object('valid', v_ok, 'errors', v_errors, 'dry', p_dry);
end
$$;

insert into public.event_names (name, emitted_by, description) values
  ('products_imported', 'server', 'Produits importés en masse (créés, lignes en erreur)')
on conflict do nothing;

revoke all on function app.parse_price_minor(text, int) from public;
revoke all on function public.import_products(jsonb, boolean) from public, anonymous;
grant execute on function public.import_products(jsonb, boolean) to authenticated;
