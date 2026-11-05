import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

part 'account_models.g.dart';

/// Rôle d'un utilisateur (`user_roles.role`).
enum UserRole {
  client,
  vendor,
  admin,
  courier;

  /// Rôle depuis la base ; inconnu → `null` (rôle futur ignoré).
  static UserRole? tryParse(Object? value) => values.asNameMap()['$value'];
}

/// Profil de l'utilisateur connecté (`profiles`).
@immutable
@JsonSerializable()
class Profile {
  const new({
    required this.userId,
    required this.firstName,
    required this.countryCode,
    required this.locale,
    this.zoneId,
    this.avatarKey,
  });

  factory fromJson(Map<String, dynamic> json) => _$ProfileFromJson(json);

  final String userId;
  final String firstName;
  final String countryCode;
  final String? zoneId;
  final String locale;
  final String? avatarKey;
}

/// L'utilisateur connecté : profil (absent = à compléter) et rôles.
@immutable
class Me {
  const new({required this.userId, required this.roles, this.profile});

  /// Lit la réponse de `public.me()`.
  factory fromJson(Map<String, dynamic> json) {
    final profile = json['profile'];
    final roles = json['roles'];
    return Me(
      userId: json['user_id']! as String,
      profile: profile is Map<String, dynamic>
          ? Profile.fromJson(profile)
          : null,
      roles: {
        if (roles is List)
          for (final r in roles) ?UserRole.tryParse(r),
      },
    );
  }

  final String userId;
  final Profile? profile;
  final Set<UserRole> roles;

  /// Vrai si le profil doit encore être complété (prénom, quartier).
  bool get needsProfile => profile == null;

  bool hasRole(UserRole role) => roles.contains(role);
}
