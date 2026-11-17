import 'dart:async';

import 'package:dym_client/app/app.locator.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_platform/dym_platform.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';

/// Économie de données active (spec 103) ; non configurée (tests) : non.
bool dataSaverOn() =>
    locator.isRegistered<DataSaverPreference>() &&
    locator<DataSaverPreference>().value;

/// Réglage « Économie de données » (menu Moi).
Future<void> showDataSaverSheet(
  BuildContext context,
  DataSaverPreference preference,
) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  builder: (context) {
    final l10n = DymLocalizations.of(context);
    final t = context.dym.text;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          DymTokenSpace.s4,
          0,
          DymTokenSpace.s4,
          DymTokenSpace.s4,
        ),
        child: ValueListenableBuilder<bool>(
          valueListenable: preference,
          builder: (context, on, _) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.dataSaverTitle, style: t.title),
              const SizedBox(height: DymTokenSpace.s2),
              Text(l10n.dataSaverBody, style: t.body),
              const SizedBox(height: DymTokenSpace.s3),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.dataSaverSwitch),
                value: on,
                onChanged: (v) => unawaited(preference.set(on: v)),
              ),
            ],
          ),
        ),
      ),
    );
  },
);
