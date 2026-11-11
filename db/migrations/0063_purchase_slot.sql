-- Spec 056 (client-navigation) : la confirmation de commande rappelle le créneau choisi.
-- `app.purchase_json` expose, pour chaque commande, le début et la fin du créneau
-- (nuls : dès que possible). Lecture seule ; aucune règle ne change.

create or replace function app.purchase_json(p_purchase uuid) returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object(
    'id', pu.id, 'created_at', pu.created_at,
    'country_code', pu.country_code, 'currency_code', pu.currency_code,
    'payment_method', jsonb_build_object('id', pm.id, 'country_code', pm.country_code,
                                         'provider_code', pm.provider_code,
                                         'operator_code', pm.operator_code, 'label', pm.label),
    'address', pu.address, 'substitution_allowed', pu.substitution_allowed,
    'payment_status', pu.payment_status,
    'payment', (
      select jsonb_build_object(
        'id', pa.id, 'status', pa.status, 'provider_code', pa.provider_code,
        'checkout_url', pa.checkout_url, 'amount_minor', pa.amount_minor,
        'reference', app.payment_reference(pa.id), 'completed_at', pa.completed_at)
      from public.payments pa where pa.purchase_id = pu.id
      order by pa.created_at desc, pa.id limit 1),
    'subtotal_minor', pu.subtotal_minor, 'delivery_fee_minor', pu.delivery_fee_minor,
    'total_minor', pu.total_minor,
    'orders', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'id', o.id, 'status', o.status, 'fulfillment', o.fulfillment,
        'store', jsonb_build_object('id', s.id, 'name', s.name, 'origin', s.origin),
        'subtotal_minor', o.subtotal_minor, 'delivery_fee_minor', o.delivery_fee_minor,
        'total_minor', o.total_minor,
        'scheduled_start', o.scheduled_start, 'scheduled_end', o.scheduled_end,
        'item_count', (select coalesce(sum(i.quantity), 0) from public.order_items i where i.order_id = o.id),
        'items', (select coalesce(jsonb_agg(jsonb_build_object(
                    'product_id', i.product_id, 'variant_id', i.variant_id, 'name', i.product_name,
                    'variant_label', i.variant_label, 'unit_label', i.unit_label,
                    'unit_price_minor', i.unit_price_minor, 'quantity', i.quantity,
                    'amount_minor', i.amount_minor) order by i.product_name), '[]'::jsonb)
                  from public.order_items i where i.order_id = o.id))
        order by o.total_minor desc, o.id), '[]'::jsonb)
      from public.orders o join public.stores s on s.id = o.store_id
      where o.purchase_id = pu.id))
  from public.purchases pu
  join public.payment_methods pm on pm.id = pu.payment_method_id
  where pu.id = p_purchase
$$;
