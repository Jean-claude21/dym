import 'package:dym_auth/dym_auth.dart';
import 'package:dym_core/dym_core.dart';
import 'package:stacked/stacked.dart';

/// Écran « Moi » : profil, déconnexion, suppression du compte.
class AccountViewModel extends BaseViewModel {
  new({required this._service, required this.onSignedOut});

  final AuthService _service;

  /// Appelé après déconnexion ou suppression : retour à la bienvenue.
  final void Function() onSignedOut;

  AuthError? _authError;

  String get firstName => _service.me?.profile?.firstName ?? '';
  String? get email => _service.email;
  AuthError? get authError => _authError;

  /// Initiale affichée tant que la photo n'existe pas.
  String get initial =>
      firstName.isEmpty ? '?' : firstName.characters.first.toUpperCase();

  Future<void> signOut() async {
    _authError = null;
    await runBusyFuture(_service.signOut());
    onSignedOut();
  }

  /// Supprime le compte (après confirmation de la personne).
  Future<bool> deleteAccount() async {
    _authError = null;
    final result = await runBusyFuture(_service.deleteAccount());
    switch (result) {
      case Ok():
        onSignedOut();
        return true;
      case Err(:final failure):
        _authError = failure is NetworkFailure
            ? AuthError.offline
            : AuthError.generic;
        notifyListeners();
        return false;
    }
  }
}

extension on String {
  Iterable<String> get characters => runes.map(String.fromCharCode);
}
