import 'package:dym_auth/dym_auth.dart';
import 'package:dym_core/dym_core.dart';
import 'package:stacked/stacked.dart';

/// Écran « Moi » : profil (prénom, langue), déconnexion, suppression du
/// compte.
class AccountViewModel extends BaseViewModel {
  new({required this._service, required this.onSignedOut});

  final AuthService _service;

  /// Appelé après déconnexion ou suppression : retour à la bienvenue.
  final void Function() onSignedOut;

  AuthError? _authError;

  String get firstName => _service.me?.profile?.firstName ?? '';

  /// Langue du profil (nulle : celle de l'appareil).
  String? get localeCode => _service.me?.profile?.locale;

  /// Langues proposées : celles du serveur que l'app sait afficher.
  Future<List<String>> languages(List<String> appLanguages) async {
    final server = (await _service.supportedLocales()).valueOrNull;
    return [
      for (final code in server ?? appLanguages)
        if (appLanguages.contains(code)) code,
    ];
  }

  /// Nouveau prénom ; `false` : refusé (vide, trop long) ou hors ligne.
  Future<bool> rename(String value) => _update(firstName: value.trim());

  Future<bool> setLanguage(String code) => _update(locale: code);

  Future<bool> _update({String? firstName, String? locale}) async {
    _authError = null;
    final result = await runBusyFuture(
      _service.updateProfile(firstName: firstName, locale: locale),
    );
    switch (result) {
      case Ok():
        notifyListeners();
        return true;
      case Err(:final failure):
        _authError = switch (failure) {
          NetworkFailure() => AuthError.offline,
          ValidationFailure() when firstName != null =>
            AuthError.firstNameInvalid,
          _ => AuthError.generic,
        };
        notifyListeners();
        return false;
    }
  }

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
