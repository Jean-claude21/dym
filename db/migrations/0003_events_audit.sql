-- 0003 — Événements de mesure et audit (spec 004, METRICS.md, constitution IX).
-- Aucune app ne lit ces tables. Les apps n'écrivent des événements que par
-- public.track_event ; le serveur par app.emit_event ; l'audit par app.audit.

create table public.event_names (
  name text primary key check (name ~ '^[a-z]+(_[a-z]+)+$'),
  emitted_by text not null check (emitted_by in ('client', 'server')),
  description text not null
);

create table public.events (
  id bigint generated always as identity primary key,
  occurred_at timestamptz not null default now(),
  actor_id uuid,
  actor_role text not null check (actor_role in ('anonymous', 'authenticated', 'client', 'vendor', 'admin', 'courier', 'system')),
  app text not null check (app in ('client', 'vendor', 'admin', 'delivery', 'server')),
  country_code char(2) references public.countries (code),
  name text not null references public.event_names (name),
  entity_type text check (entity_type ~ '^[a-z_]+$'),
  entity_id text check (length(entity_id) <= 64),
  props jsonb not null default '{}'::jsonb
    check (jsonb_typeof(props) = 'object' and pg_column_size(props) <= 4096),
  client_event_id uuid unique
);

create index events_name_time on public.events (name, occurred_at desc);

create table public.audit_log (
  id bigint generated always as identity primary key,
  occurred_at timestamptz not null default now(),
  actor_id uuid,
  action text not null check (action ~ '^[a-z]+(_[a-z]+)*$'),
  entity_type text not null check (entity_type ~ '^[a-z_]+$'),
  entity_id text not null,
  before jsonb,
  after jsonb,
  reason text
);

create index audit_log_entity on public.audit_log (entity_type, entity_id, occurred_at desc);

-- L'audit est en ajout seul, y compris pour le propriétaire.
create or replace function app.forbid_change() returns trigger
language plpgsql
as $$
begin
  raise exception '% : table en ajout seul', tg_table_name using errcode = '42501';
end
$$;

create trigger audit_log_append_only before update or delete on public.audit_log
  for each row execute function app.forbid_change();

alter table public.event_names enable row level security;
alter table public.events enable row level security;
alter table public.audit_log enable row level security;
-- Aucune politique ni aucun droit pour les rôles de l'API : tables internes.

-- ------------------------------------------------------------------ données personnelles

-- Refuse les propriétés qui contiennent une donnée personnelle : clé interdite
-- ou valeur qui ressemble à un email ou à un numéro de téléphone (récursif).
create or replace function app.assert_no_personal_data(p jsonb) returns void
language plpgsql immutable
as $$
declare
  e record;
begin
  case jsonb_typeof(p)
    when 'object' then
      for e in select key, value from jsonb_each(p) loop
        if lower(e.key) ~ '(^|_)(email|mail|phone|telephone|tel|mobile|address|adresse)($|_)'
          or lower(e.key) ~ '^(name|nom|prenom|first_?name|last_?name|full_?name|surname)$' then
          raise exception 'propriété personnelle interdite : %', e.key using errcode = '22023';
        end if;
        perform app.assert_no_personal_data(e.value);
      end loop;
    when 'array' then
      for e in select value from jsonb_array_elements(p) loop
        perform app.assert_no_personal_data(e.value);
      end loop;
    when 'string' then
      if (p #>> '{}') ~* '[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}'
        or regexp_replace(p #>> '{}', '[\s().-]', '', 'g') ~ '^\+?[0-9]{8,15}$' then
        raise exception 'valeur personnelle interdite dans les propriétés' using errcode = '22023';
      end if;
    else
      null;
  end case;
end
$$;

-- ------------------------------------------------------------------ émission

-- Événement serveur (appelé par les fonctions métier, jamais exposé).
create or replace function app.emit_event(
  p_name text,
  p_actor_id uuid,
  p_actor_role text,
  p_app text,
  p_country_code char(2) default null,
  p_entity_type text default null,
  p_entity_id text default null,
  p_props jsonb default '{}'::jsonb
) returns void
language plpgsql security definer set search_path = ''
as $$
begin
  perform app.assert_no_personal_data(p_props);
  insert into public.events (actor_id, actor_role, app, country_code, name, entity_type, entity_id, props)
  values (p_actor_id, p_actor_role, p_app, p_country_code, p_name, p_entity_type, p_entity_id, coalesce(p_props, '{}'::jsonb));
end
$$;

-- Événement client (Data API, RPC). L'auteur et son rôle viennent du jeton,
-- jamais de l'app ; seuls les noms prévus pour les clients sont acceptés ; un
-- rejeu (même identifiant client) est ignoré.
create or replace function public.track_event(
  p_name text,
  p_app text,
  p_client_event_id uuid,
  p_country_code char(2) default null,
  p_entity_type text default null,
  p_entity_id text default null,
  p_props jsonb default '{}'::jsonb
) returns void
language plpgsql security definer set search_path = ''
as $$
declare
  v_actor uuid := app.current_user_id();
begin
  if not exists (select 1 from public.event_names where name = p_name and emitted_by = 'client') then
    raise exception 'événement inconnu ou réservé au serveur : %', p_name using errcode = '22023';
  end if;
  if p_app not in ('client', 'vendor', 'admin', 'delivery') then
    raise exception 'app inconnue : %', p_app using errcode = '22023';
  end if;
  if p_client_event_id is null then
    raise exception 'identifiant client obligatoire' using errcode = '22023';
  end if;
  if pg_column_size(coalesce(p_props, '{}'::jsonb)) > 4096 then
    raise exception 'propriétés trop volumineuses' using errcode = '22023';
  end if;
  perform app.assert_no_personal_data(coalesce(p_props, '{}'::jsonb));

  insert into public.events (
    actor_id, actor_role, app, country_code, name, entity_type, entity_id, props, client_event_id
  ) values (
    v_actor,
    case when v_actor is null then 'anonymous' else 'authenticated' end,
    p_app, p_country_code, p_name, p_entity_type, p_entity_id,
    coalesce(p_props, '{}'::jsonb), p_client_event_id
  )
  on conflict (client_event_id) do nothing;
end
$$;

revoke all on function public.track_event(text, text, uuid, char, text, text, jsonb) from public;
grant execute on function public.track_event(text, text, uuid, char, text, text, jsonb)
  to authenticated, anonymous;

-- Entrée d'audit (actions admin, transitions forcées).
create or replace function app.audit(
  p_actor_id uuid,
  p_action text,
  p_entity_type text,
  p_entity_id text,
  p_before jsonb,
  p_after jsonb,
  p_reason text default null
) returns void
language sql security definer set search_path = ''
as $$
  insert into public.audit_log (actor_id, action, entity_type, entity_id, before, after, reason)
  values (p_actor_id, p_action, p_entity_type, p_entity_id, p_before, p_after, p_reason)
$$;

-- ------------------------------------------------------------------ noms d'événements

insert into public.event_names (name, emitted_by, description) values
  ('user_signed_up', 'server', 'Compte créé'),
  ('user_signed_in', 'server', 'Connexion'),
  ('store_created', 'server', 'Boutique créée (porte store_origin)'),
  ('store_opened', 'server', 'Boutique ouverte'),
  ('store_closed', 'server', 'Boutique fermée'),
  ('product_published', 'server', 'Produit publié'),
  ('product_stock_changed', 'server', 'Stock modifié'),
  ('ai_product_suggestion_shown', 'client', 'Suggestion IA affichée'),
  ('ai_product_suggestion_accepted', 'server', 'Suggestion IA acceptée'),
  ('search_performed', 'client', 'Recherche effectuée'),
  ('product_viewed', 'client', 'Fiche produit vue'),
  ('cart_item_added', 'client', 'Article ajouté au panier'),
  ('checkout_started', 'client', 'Commande commencée'),
  ('order_created', 'server', 'Commande créée (porte stores_count)'),
  ('payment_initiated', 'server', 'Paiement initié'),
  ('payment_succeeded', 'server', 'Paiement réussi'),
  ('payment_failed', 'server', 'Paiement échoué'),
  ('order_accepted', 'server', 'Commande acceptée'),
  ('order_rejected', 'server', 'Commande refusée'),
  ('order_status_changed', 'server', 'Statut de commande modifié'),
  ('order_delivered', 'server', 'Commande livrée'),
  ('order_cancelled', 'server', 'Commande annulée'),
  ('dispute_opened', 'server', 'Litige ouvert'),
  ('dispute_resolved', 'server', 'Litige résolu'),
  ('admin_action_performed', 'server', 'Action admin');
