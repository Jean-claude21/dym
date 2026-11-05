import 'dart:async';

import 'package:dym_client/features/content/content_service.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:flutter/material.dart';

/// « Voir en vidéo » sur la fiche produit (C-CAT-12), si une vidéo montre ce
/// produit et que les contenus sont ouverts.
class ProductVideosButton extends StatefulWidget {
  const new({
    required this.service,
    required this.productId,
    required this.onOpen,
    super.key,
  });

  final ContentService service;
  final String productId;
  final VoidCallback onOpen;

  @override
  State<ProductVideosButton> createState() => _ProductVideosButtonState();
}

class _ProductVideosButtonState extends State<ProductVideosButton> {
  int _count = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    if (!await widget.service.enabled()) return;
    final count = (await widget.service.productVideoCount(widget.productId))
        .valueOrNull;
    if (mounted && count != null) setState(() => _count = count);
  }

  @override
  Widget build(BuildContext context) {
    if (_count == 0) return const SizedBox.shrink();
    final l10n = DymLocalizations.of(context);
    return TextButton.icon(
      onPressed: widget.onOpen,
      icon: const Icon(Icons.play_circle_outline_rounded),
      label: Text(l10n.productVideos(_count)),
    );
  }
}
