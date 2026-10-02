import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:neon_kit/neon_kit.dart';

/// App qui ouvre la session : décide du rôle donné à la complétion du profil
/// (cliente ou vendeuse) et trace la connexion.
enum AccountApp { client, vendor, admin }

/// Compte de l'utilisateur connecté : lecture, complétion du profil, trace de
/// connexion, suppression. Toutes les décisions sont prises en SQL.
class AccountRepository {
  new(this._data);

  final NeonDataClient _data;

  /// Profil et rôles (`public.me`).
  Future<Result<Me>> me() => _me(_data.rpc<Object?>('me'));

  /// Complète ou met à jour le profil ; le pays découle du quartier, le rôle
  /// de l'app (`public.complete_profile`).
  Future<Result<Me>> completeProfile({
    required String firstName,
    required String zoneId,
    required AccountApp app,
    String locale = 'fr',
  }) => _me(
    _data.rpc<Object?>(
      'complete_profile',
      params: {
        'p_first_name': firstName.trim(),
        'p_zone_id': zoneId,
        'p_app': app.name,
        'p_locale': locale,
      },
    ),
  );

  /// Trace une connexion réussie ; refusée (403) pour l'admin sans rôle admin.
  Future<Result<Me>> recordSignIn(AccountApp app) => _me(
    _data.rpc<Object?>('record_sign_in', params: {'p_app': app.name}),
  );

  /// Supprime définitivement le compte (`public.delete_my_account`).
  Future<Result<void>> deleteMyAccount() =>
      _data.rpc<void>('delete_my_account');

  Future<Result<Me>> _me(Future<Result<Object?>> call) async =>
      switch (await call) {
        Ok(:final value) when value is Map<String, dynamic> => _decode(value),
        Ok() => const Err(UnauthenticatedFailure('aucune session')),
        Err(:final failure) => Err(failure),
      };

  Result<Me> _decode(Map<String, dynamic> json) {
    try {
      return Ok(Me.fromJson(json));
    } on Object catch (error) {
      return Err(ServerFailure('profil illisible : ${error.runtimeType}'));
    }
  }
}
