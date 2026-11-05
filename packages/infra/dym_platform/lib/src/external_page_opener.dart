import 'package:dym_core/dym_core.dart';
import 'package:url_launcher/url_launcher.dart';

/// Ouvre une page hors de l'app (page de paiement du fournisseur). L'app ne
/// connaît pas le fournisseur : elle ouvre l'URL reçue (décision 0004).
abstract interface class ExternalPageOpener {
  /// `Ok(false)` : aucune app ne peut ouvrir la page.
  Future<Result<bool>> open(Uri url);
}

/// Implémentation `url_launcher` : navigateur externe (onglet sur le web).
class PluginExternalPageOpener implements ExternalPageOpener {
  const new();

  @override
  Future<Result<bool>> open(Uri url) async {
    try {
      return Ok(await launchUrl(url, mode: LaunchMode.externalApplication));
    } on Object catch (error) {
      return Err(UnknownFailure('ouverture impossible : $error'));
    }
  }
}
