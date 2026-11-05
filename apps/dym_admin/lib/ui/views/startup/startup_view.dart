import 'package:dym_admin/ui/views/startup/startup_viewmodel.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Démarrage de l'admin le temps de vérifier la session.
class StartupView extends StackedView<StartupViewModel> {
  const new({super.key, this.viewModelFactory});

  /// Fabrique du viewmodel (tests).
  final StartupViewModel Function()? viewModelFactory;

  @override
  StartupViewModel viewModelBuilder(BuildContext context) =>
      viewModelFactory?.call() ?? StartupViewModel();

  @override
  void onViewModelReady(StartupViewModel viewModel) =>
      viewModel.runStartupLogic();

  @override
  Widget builder(
    BuildContext context,
    StartupViewModel viewModel,
    Widget? child,
  ) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final environment = viewModel.environmentName;
    return Scaffold(
      backgroundColor: c.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.appNameAdmin,
              style: t.display.copyWith(fontSize: 40, color: c.brandDeep),
            ),
            const SizedBox(height: DymTokenSpace.s4),
            Semantics(
              label: l10n.startupPreparing,
              child: CircularProgressIndicator(color: c.brand),
            ),
            if (environment != null) ...[
              const SizedBox(height: DymTokenSpace.s4),
              Text(
                l10n.environmentLabel(environment),
                style: t.label.copyWith(color: c.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
