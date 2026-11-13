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
    this.role = AdminAccess.superAdmin,
  });

  factory fromJson(Map<String, Object?> json) => AdminMember(
    email: json['email']! as String,
    userId: json['user_id'] as String?,
    firstName: json['first_name'] as String?,
    isDefault: json['source'] == 'env',
    isActive: json['status'] == 'active',
    isMe: json['is_me'] == true,
    role: json['role'] as String? ?? AdminAccess.superAdmin,
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

  /// Rôle (spec 085) : `super_admin`, `operations`, `support`, `finance`,
  /// `content`, `analyst`.
  final String role;
}

/// Ce que l'admin connecté peut faire (spec 085), décidé en SQL : rôle et
/// permissions « domaine.read » ou « domaine.write ».
class AdminAccess {
  const new({
    required this.role,
    required this.permissions,
    this.roles = const [],
  });

  factory fromJson(Map<String, Object?> json) => AdminAccess(
    role: json['role'] as String? ?? superAdmin,
    permissions: {
      for (final p in json['permissions'] as List? ?? const []) p as String,
    },
    roles: [for (final r in json['roles'] as List? ?? const []) r as String],
  );

  static const superAdmin = 'super_admin';

  final String role;
  final Set<String> permissions;

  /// Rôles proposés à l'invitation, du plus large au plus restreint.
  final List<String> roles;

  bool can(String permission) => permissions.contains(permission);

  /// Lecture d'un domaine (`orders`, `finance`…).
  bool reads(String area) => can('$area.read');

  bool writes(String area) => can('$area.write');
}

/// Clé MCP personnelle d'un admin (spec 086) ; la clé n'est jamais relue,
/// seuls ses quatre derniers caractères sont montrés.
class AdminMcpKey {
  const new({
    required this.id,
    required this.name,
    required this.hint,
    this.createdAt,
    this.lastUsedAt,
    this.revoked = false,
  });

  factory fromJson(Map<String, Object?> json) => AdminMcpKey(
    id: json['id']! as String,
    name: json['name'] as String? ?? '',
    hint: json['hint'] as String? ?? '',
    createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    lastUsedAt: DateTime.tryParse(json['last_used_at'] as String? ?? ''),
    revoked: json['revoked'] == true,
  );

  final String id;
  final String name;
  final String hint;
  final DateTime? createdAt;
  final DateTime? lastUsedAt;
  final bool revoked;
}
