import 'dart:async';

import 'package:dym_auth/src/auth_service.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:stacked/stacked.dart';

/// Étapes du parcours de connexion.
enum AuthStep { welcome, email, code, profile }

/// Erreur affichable du parcours (traduite par la vue).
enum AuthError {
  offline,
  generic,
  codeWrong,
  sessionExpired,
  emailInvalid,
  firstNameInvalid,
  zoneRequired,
  googleUnavailable,
  passwordWrong,
}

/// Résultat d'une demande de position.
enum ZoneLocation {
  /// Quartier trouvé et choisi.
  found,

  /// Quartier trouvé dans un pays non proposé.
  outside,

  /// Position refusée ou impossible à obtenir.
  unavailable,
}

/// Parcours bienvenue → email → code → profil, ou Google. Toute la logique est
/// ici ; les vues ne font qu'afficher et transmettre les gestes.
class AuthFlowViewModel extends BaseViewModel {
  new({
    required this._service,
    required this.onReady,
    this.locale = 'fr',
    this.resendDelay = const Duration(seconds: 60),
    AuthStep initialStep = AuthStep.welcome,
    String initialEmail = '',
  }) : _step = initialStep,
       _email = initialEmail;

  final AuthService _service;

  /// Appelé quand le profil est complet : la personne entre dans l'app.
  final void Function(Me me) onReady;

  /// Langue de l'appareil (profil).
  final String locale;

  /// Délai avant de pouvoir renvoyer un code.
  final Duration resendDelay;

  static const welcomePages = 3;
  static const codeLength = 6;
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[a-zA-Z]{2,}$');

  AuthStep _step;
  int _welcomePage = 0;
  String _email;
  String _code = '';
  int _resendSeconds = 0;
  Timer? _resendTimer;
  String _firstName = '';
  List<Country> _countries = const [];
  String? _countryCode;
  CountryConfig? _config;
  String? _zoneId;
  bool _locating = false;
  ZoneLocation? _location;
  AuthError? _error;
  bool _codeRejected = false;

  AuthStep get step => _step;
  int get welcomePage => _welcomePage;
  bool get googleAvailable => _service.googleAvailable;
  String get email => _email;
  bool get emailValid => _emailPattern.hasMatch(_email.trim());
  bool get emailTouched => _email.trim().isNotEmpty;
  String get code => _code;
  bool get codeRejected => _codeRejected;
  int get resendSeconds => _resendSeconds;
  bool get canResend => _resendSeconds == 0 && !isBusy;
  String get firstName => _firstName;
  bool get firstNameValid {
    final n = _firstName.trim().length;
    return n >= 1 && n <= 40;
  }

  List<Country> get countries => _countries;
  String? get countryCode => _countryCode;
  CountryConfig? get config => _config;

  /// Quartiers proposés (toutes les villes actives du pays).
  List<Zone> get zones => _config?.zones ?? const [];
  String? get zoneId => _zoneId;
  Zone? get selectedZone => zones.where((z) => z.id == _zoneId).firstOrNull;

  /// Recherche de la position en cours.
  bool get locating => _locating;

  /// Résultat de la dernière demande de position (rien avant la demande).
  ZoneLocation? get location => _location;

  /// Nom de la ville d'un quartier.
  String? cityNameOf(Zone zone) =>
      _config?.cities.where((c) => c.id == zone.cityId).firstOrNull?.name;

  AuthError? get authError => _error;
  bool get canSubmitProfile => firstNameValid && _zoneId != null && !isBusy;

  // --- bienvenue

  void setWelcomePage(int page) {
    _welcomePage = page.clamp(0, welcomePages - 1);
    notifyListeners();
  }

  /// « Passer » : dernier écran de bienvenue.
  void skipWelcome() => setWelcomePage(welcomePages - 1);

  void chooseEmail() => _goTo(AuthStep.email);

  Future<void> chooseGoogle() async {
    if (!_service.googleAvailable) {
      _setError(AuthError.googleUnavailable);
      return;
    }
    _clearError();
    final result = await runBusyFuture(_service.signInWithGoogle());
    switch (result) {
      case Ok(value: null):
        break; // annulé : on reste sur la bienvenue, sans message
      case Ok(:final value?):
        await _handleState(value);
      case Err(:final failure):
        _setError(_errorFor(failure));
    }
  }

  // --- email

  void setEmail(String value) {
    _email = value;
    _clearError(notify: false);
    notifyListeners();
  }

  Future<void> submitEmail() async {
    if (!emailValid) {
      _setError(AuthError.emailInvalid);
      return;
    }
    _clearError();
    final result = await runBusyFuture(
      _service.sendEmailCode(_email.trim().toLowerCase()),
    );
    switch (result) {
      case Ok():
        _code = '';
        _codeRejected = false;
        _startResendTimer();
        _goTo(AuthStep.code);
      case Err(:final failure):
        _setError(_errorFor(failure));
    }
  }

  // --- mot de passe (comptes de test)

  bool _usePassword = false;
  String _password = '';

  bool get usePassword => _usePassword;
  bool get canSubmitPassword => emailValid && _password.isNotEmpty;

  void toggleUsePassword() {
    _usePassword = !_usePassword;
    _clearError(notify: false);
    notifyListeners();
  }

  void setPassword(String value) {
    _password = value;
    _clearError(notify: false);
    notifyListeners();
  }

  Future<void> submitPassword() async {
    if (!canSubmitPassword || isBusy) return;
    _clearError();
    final result = await runBusyFuture(
      _service.signInWithPassword(_email.trim().toLowerCase(), _password),
    );
    switch (result) {
      case Ok(:final value):
        await _handleState(value);
      case Err(:final failure):
        if (failure is ValidationFailure || failure is UnauthenticatedFailure) {
          _setError(AuthError.passwordWrong);
        } else {
          _setError(_errorFor(failure));
        }
    }
  }

  // --- code

  void setCode(String value) {
    _code = value;
    _codeRejected = false;
    _clearError(notify: false);
    notifyListeners();
    if (value.length == codeLength) unawaited(verifyCode());
  }

  Future<void> verifyCode() async {
    if (_code.length != codeLength || isBusy) return;
    _clearError();
    final result = await runBusyFuture(
      _service.verifyEmailCode(_email.trim().toLowerCase(), _code),
    );
    switch (result) {
      case Ok(:final value):
        await _handleState(value);
      case Err(:final failure):
        if (failure is ValidationFailure || failure is UnauthenticatedFailure) {
          _codeRejected = true;
          _setError(AuthError.codeWrong);
        } else {
          _setError(_errorFor(failure));
        }
    }
  }

  Future<void> resendCode() async {
    if (!canResend) return;
    _clearError();
    final result = await runBusyFuture(
      _service.sendEmailCode(_email.trim().toLowerCase()),
    );
    switch (result) {
      case Ok():
        _code = '';
        _codeRejected = false;
        _startResendTimer();
        notifyListeners();
      case Err(:final failure):
        _setError(_errorFor(failure));
    }
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    _resendSeconds = resendDelay.inSeconds;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _resendSeconds = (_resendSeconds - 1).clamp(0, resendDelay.inSeconds);
      if (_resendSeconds == 0) timer.cancel();
      notifyListeners();
    });
  }

  // --- profil

  /// Ouvre l'étape profil (après connexion ou au démarrage).
  Future<void> startProfile() async {
    _goTo(AuthStep.profile);
    await loadZones();
    // Pays et quartier détectés d'emblée depuis la position (aucun pays figé) ;
    // sans position, la personne choisit dans la liste.
    if (_countries.isNotEmpty) await locate();
  }

  Future<void> loadZones() async {
    _clearError();
    final countries = await runBusyFuture(_service.countries());
    switch (countries) {
      case Err(:final failure):
        _setError(_errorFor(failure));
        return;
      case Ok(:final value):
        _countries = value;
    }
    if (_countries.isEmpty) {
      _setError(AuthError.generic);
      return;
    }
    await selectCountry(_countryCode ?? _countries.first.code);
  }

  Future<void> selectCountry(String code) async {
    _countryCode = code;
    _zoneId = null;
    notifyListeners();
    final result = await runBusyFuture(_service.countryConfig(code));
    switch (result) {
      case Ok(:final value):
        _config = value;
        notifyListeners();
      case Err(:final failure):
        _setError(_errorFor(failure));
    }
  }

  void setFirstName(String value) {
    _firstName = value;
    _clearError(notify: false);
    notifyListeners();
  }

  /// Quartier le plus proche de la position ; le pays suit le quartier
  /// trouvé.
  Future<void> locate() async {
    if (_locating) return;
    _locating = true;
    _location = null;
    _clearError(notify: false);
    notifyListeners();
    final result = await _service.locateZone();
    _locating = false;
    switch (result) {
      case Ok(value: final match?):
        if (match.countryCode != _countryCode &&
            _countries.any((c) => c.code == match.countryCode)) {
          await selectCountry(match.countryCode);
        }
        if (zones.any((z) => z.id == match.zoneId)) {
          _location = ZoneLocation.found;
          _zoneId = match.zoneId;
        } else {
          _location = ZoneLocation.outside;
        }
      case Ok() || Err():
        _location = ZoneLocation.unavailable;
    }
    notifyListeners();
  }

  void selectZone(String zoneId) {
    _zoneId = zoneId;
    _clearError(notify: false);
    notifyListeners();
  }

  Future<void> submitProfile() async {
    if (!firstNameValid) {
      _setError(AuthError.firstNameInvalid);
      return;
    }
    final zone = _zoneId;
    if (zone == null) {
      _setError(AuthError.zoneRequired);
      return;
    }
    _clearError();
    final result = await runBusyFuture(
      _service.completeProfile(
        firstName: _firstName.trim(),
        zoneId: zone,
        locale: locale,
      ),
    );
    switch (result) {
      case Ok(:final value):
        await _handleState(value);
      case Err(:final failure):
        _setError(_errorFor(failure));
    }
  }

  // --- navigation

  /// Retour à l'étape précédente ; `false` si on est déjà au début.
  bool back() {
    switch (_step) {
      case AuthStep.welcome:
        return false;
      case AuthStep.email:
        _goTo(AuthStep.welcome);
      case AuthStep.code:
        _resendTimer?.cancel();
        _goTo(AuthStep.email);
      case AuthStep.profile:
        return false; // session ouverte : le profil est obligatoire
    }
    return true;
  }

  void changeEmail() {
    _resendTimer?.cancel();
    _goTo(AuthStep.email);
  }

  Future<void> _handleState(AuthState state) async {
    switch (state.status) {
      case AuthStatus.ready:
        onReady(state.me!);
      case AuthStatus.needsProfile:
        await startProfile();
      case AuthStatus.signedOut:
        _goTo(AuthStep.welcome);
    }
  }

  void _goTo(AuthStep step) {
    _step = step;
    _error = null;
    notifyListeners();
  }

  void _setError(AuthError error) {
    _error = error;
    if (error == AuthError.sessionExpired) _step = AuthStep.email;
    notifyListeners();
  }

  void _clearError({bool notify = true}) {
    if (_error == null) return;
    _error = null;
    if (notify) notifyListeners();
  }

  AuthError _errorFor(Failure failure) => switch (failure) {
    NetworkFailure() || RateLimitedFailure() => AuthError.offline,
    UnauthenticatedFailure() => AuthError.sessionExpired,
    ValidationFailure() when _step == AuthStep.email => AuthError.emailInvalid,
    _ => AuthError.generic,
  };

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }
}
