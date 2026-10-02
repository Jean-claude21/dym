import 'package:dym_models/src/json.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

part 'store_models.g.dart';

/// Statut d'administration d'une boutique.
enum StoreStatus { draft, active, suspended }

/// Adresse de ramassage (privée : propriétaire, équipe, livreur de la
/// commande).
@immutable
@JsonSerializable()
class PickupAddress {
  const new({
    required this.address,
    this.landmark,
    this.latitude,
    this.longitude,
    this.contactPhone,
  });

  factory fromJson(Map<String, dynamic> json) => _$PickupAddressFromJson(json);

  final String address;
  final String? landmark;
  final double? latitude;
  final double? longitude;
  final String? contactPhone;
}

/// Horaires d'un jour (1 = lundi, ISO), heures locales `HH:MM`.
@immutable
@JsonSerializable(createToJson: true)
class StoreHours {
  const new({
    required this.weekday,
    required this.opensAt,
    required this.closesAt,
  });

  factory fromJson(Map<String, dynamic> json) => _$StoreHoursFromJson(json);

  final int weekday;
  final String opensAt;
  final String closesAt;

  Map<String, dynamic> toJson() => _$StoreHoursToJson(this);

  StoreHours copyWith({String? opensAt, String? closesAt}) => StoreHours(
    weekday: weekday,
    opensAt: opensAt ?? this.opensAt,
    closesAt: closesAt ?? this.closesAt,
  );
}

/// La boutique de la vendeuse connectée (`public.my_store()`), adresse
/// comprise, avec ce qui manque pour l'ouvrir.
@immutable
@JsonSerializable()
class MyStore {
  const new({
    required this.id,
    required this.name,
    required this.status,
    required this.isOpen,
    required this.onboardingStep,
    required this.prepTimeMinutes,
    required this.offersPickup,
    this.description,
    this.origin,
    this.zoneId,
    this.countryCode,
    this.currencyCode,
    this.mainCategoryId,
    this.deliveryFeeMinor,
    this.pickupAddress,
    this.deliveryZoneIds = const [],
    this.paymentMethodIds = const [],
    this.hours = const [],
    this.missing = const [],
  });

  factory fromJson(Map<String, dynamic> json) => _$MyStoreFromJson(json);

  final String id;
  final String name;
  final String? description;
  final String? origin;
  final String? zoneId;
  final String? countryCode;
  final String? currencyCode;
  final String? mainCategoryId;
  final int prepTimeMinutes;
  final bool offersPickup;
  @JsonKey(fromJson: nullableMinorFromJson)
  final int? deliveryFeeMinor;
  final StoreStatus status;
  final bool isOpen;
  final int onboardingStep;
  final PickupAddress? pickupAddress;
  final List<String> deliveryZoneIds;
  final List<String> paymentMethodIds;
  final List<StoreHours> hours;

  /// Éléments manquants pour ouvrir (`origin`, `zone`, `category`,
  /// `pickup_address`, `delivery_zones`, `payment_methods`, `hours`).
  final List<String> missing;

  bool get isActive => status == StoreStatus.active;
  bool get isComplete => missing.isEmpty;
}
