import 'dart:async';

import 'package:dym_client/features/discovery/discovery_service.dart';
import 'package:dym_client/features/discovery/widgets/discovery_widgets.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';

/// Onglet « Rayons » : tous les rayons du pays.
class AislesView extends StatefulWidget {
  const new({required this.service, required this.onOpenAisle, super.key});

  final DiscoveryService service;
  final ValueChanged<String> onOpenAisle;

  @override
  State<AislesView> createState() => _AislesViewState();
}

class _AislesViewState extends State<AislesView> {
  CountryConfig? _config;
  Failure? _failure;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() => _failure = null);
    final result = await widget.service.countryConfig();
    if (!mounted) return;
    setState(() {
      switch (result) {
        case Ok(:final value):
          _config = value;
        case Err(:final failure):
          _failure = failure;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final config = _config;
    if (config == null) {
      return SafeArea(
        child: DiscoveryState(failure: _failure, onRetry: _load),
      );
    }
    final aisles = config.topCategories;
    final tints = tileTints(c);
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, box) {
          final inset = DymLayout.sideInset(
            box.maxWidth,
            gutter: DymLayout.gutter(context),
          );
          final inner = box.maxWidth - inset * 2;
          const spacing = DymTokenSpace.s3;
          final columns = DymLayout.columns(
            inner,
            minTileWidth: 140 * MediaQuery.textScalerOf(context).scale(1),
            spacing: spacing,
            max: 6,
            itemCount: aisles.length,
          );
          final tile = (inner - spacing * (columns - 1)) / columns;
          return ListView(
            padding: EdgeInsets.fromLTRB(inset, 16, inset, 24),
            children: [
              Semantics(
                header: true,
                child: Text(
                  l10n.navAisles,
                  style: t.display.copyWith(fontSize: 34),
                ),
              ),
              const SizedBox(height: DymTokenSpace.s4),
              Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final (i, aisle) in aisles.indexed)
                    SizedBox(
                      width: tile,
                      height: tile,
                      child: DymAisleTile(
                        image:
                            DymIllustrations.aisle(aisle.icon) ??
                            DymIllustrations.storeOpened,
                        label: aisle.label.resolve(locale),
                        tint: tints[i % tints.length],
                        onTap: () => widget.onOpenAisle(aisle.id),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
