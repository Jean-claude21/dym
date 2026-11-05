import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

/// Bouton « Se connecter avec Google » rendu par le SDK Google (exigé sur le
/// web). L'`idToken` reçu est échangé contre une session Neon Auth.
Widget? googleWebButton({
  required String clientId,
  required void Function(String idToken) onIdToken,
}) {
  if (clientId.isEmpty) return null;
  return _GoogleWebButton(clientId: clientId, onIdToken: onIdToken);
}

class _GoogleWebButton extends StatefulWidget {
  const new({required this.clientId, required this.onIdToken});

  final String clientId;
  final void Function(String idToken) onIdToken;

  @override
  State<_GoogleWebButton> createState() => _GoogleWebButtonState();
}

class _GoogleWebButtonState extends State<_GoogleWebButton> {
  StreamSubscription<GoogleSignInAuthenticationEvent>? _events;
  late final Future<void> _ready = GoogleSignIn.instance
      .initialize(clientId: widget.clientId)
      .then((_) {
        _events = GoogleSignIn.instance.authenticationEvents.listen((event) {
          if (event case GoogleSignInAuthenticationEventSignIn(:final user)) {
            final token = user.authentication.idToken;
            if (token != null) widget.onIdToken(token);
          }
        });
      });

  @override
  void dispose() {
    unawaited(_events?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: _ready,
    builder: (context, snapshot) =>
        snapshot.connectionState == ConnectionState.done
        ? web.renderButton(
            configuration: web.GSIButtonConfiguration(
              text: web.GSIButtonText.continueWith,
              shape: web.GSIButtonShape.pill,
              size: web.GSIButtonSize.large,
              locale: Localizations.localeOf(context).languageCode,
            ),
          )
        : const SizedBox(height: 48),
  );
}
