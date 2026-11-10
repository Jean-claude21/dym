import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Partage d'un contenu (spec 040) : le texte et le lien court sont copiés,
/// prêts à coller dans une vidéo TikTok ou un message.
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
  await Clipboard.setData(ClipboardData(text: text));
  messenger?.showSnackBar(SnackBar(content: Text(l10n.shareCopied)));
}
