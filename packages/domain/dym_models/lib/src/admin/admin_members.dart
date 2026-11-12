import 'package:meta/meta.dart';

/// Admin actif ou invitation en attente (`admin_admins()`).
@immutable
class AdminMember {
  const new({
    required this.email,
    required this.isDefault,
    required this.isActive,
    this.userId,
    this.firstName,
    this.since,
    this.isMe = false,
  });

  factory fromJson(Map<String, Object?> json) => AdminMember(
    email: json['email']! as String,
    userId: json['user_id'] as String?,
    firstName: json['first_name'] as String?,
    isDefault: json['source'] == 'env',
    isActive: json['status'] == 'active',
    isMe: json['is_me'] == true,
    since: switch (json['since']) {
      final String s => DateTime.tryParse(s),
      _ => null,
    },
  );

  final String email;
  final String? userId;
  final String? firstName;

  /// Admin par défaut (variable ADMIN_EMAILS) : non retirable depuis l'app.
  final bool isDefault;

  /// Faux : invitation en attente de la première connexion.
  final bool isActive;
  final DateTime? since;

  /// Admin connecté : il ne peut pas retirer son propre accès.
  final bool isMe;
}
