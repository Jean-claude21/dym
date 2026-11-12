import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:neon_kit/neon_kit.dart';

/// App émettrice d'un événement.
enum EventApp { client, vendor, admin, delivery }

/// Envoi des événements de parcours (`METRICS.md`) par la fonction SQL
/// `track_event`. Le serveur impose l'auteur, refuse les noms non prévus et
/// les données personnelles ; l'identifiant client rend le rejeu sans effet.
///
/// L'échec d'un envoi n'interrompt jamais un parcours : le résultat est
/// renvoyé, l'appelant peut l'ignorer.
class EventsRepository {
  new(this._data, {required this.app, String Function()? newId})
    : _newId = newId ?? Uuid.v4;

  final NeonDataClient _data;
  final EventApp app;
  final String Function() _newId;

  /// Envoie l'événement [name] (ex. `search_performed`).
  Future<Result<void>> track(
    String name, {
    String? countryCode,
    String? entityType,
    String? entityId,
    Map<String, Object?> props = const {},
    String? clientEventId,
  }) => _data.rpc<void>(
    'track_event',
    params: {
      'p_name': name,
      'p_app': app.name,
      'p_client_event_id': clientEventId ?? _newId(),
      'p_country_code': countryCode,
      'p_entity_type': entityType,
      'p_entity_id': entityId,
      'p_props': props,
    },
  );
}

/// Position hors des zones desservies (spec 065) : pays du quartier le plus
/// proche et distance au kilomètre, jamais la position elle-même.
Future<Result<void>> trackOutsideCoverage(
  EventsRepository events,
  ZoneMatch match,
) => events.track(
  'location_outside_coverage',
  countryCode: match.countryCode,
  props: {'distance_km': match.distanceKm, 'app': events.app.name},
);
