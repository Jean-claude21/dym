import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_platform/dym_platform.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Ouverture des liens de partage ; remplaçable en test.
@visibleForTesting
ExternalPageOpener shareOpener = const PluginExternalPageOpener();

/// Partage d'un contenu (specs 040, 077) : WhatsApp s'ouvre avec le texte et
/// le lien court ; sans WhatsApp (ou sur le web), le texte est copié, prêt à
/// coller dans un message ou une vidéo.
Future<void> shareContent(
  BuildContext context,
  Future<Uri?> Function(ContentItem content) link,
  ContentItem content,
) async {
  final l10n = DymLocalizations.of(context);
  final messenger = ScaffoldMessenger.maybeOf(context);
  final url = await link(content);
  if (url == null) {
    messenger?.showSnackBar(SnackBar(content: Text(l10n.shareFailed)));
    return;
  }
  final text = l10n.shareText(content.caption ?? '', url.toString()).trim();
  final whatsapp = Uri.https('wa.me', '/', {'text': text});
  final opened = (await shareOpener.open(whatsapp)).valueOrNull ?? false;
  if (opened) return;
  await Clipboard.setData(ClipboardData(text: text));
  messenger?.showSnackBar(SnackBar(content: Text(l10n.shareCopied)));
}
