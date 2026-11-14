import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:dym_vendor/ui/views/startup/startup_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Démarrage : splash animé de la marque le temps de restaurer la session.
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
    final l10n = DymLocalizations.of(context);
    return Scaffold(
      backgroundColor: c.background,
      // Le splash couvre tout l'écran (légumes jusque sous la barre d'état) ;
      // seul l'écran de reprise reste dans la zone sûre.
      body: viewModel.failed
          ? SafeArea(
              child: DymStateView(
                kind: viewModel.offline
                    ? DymStateKind.offline
                    : DymStateKind.error,
                title: viewModel.offline
                    ? l10n.errorOffline
                    : l10n.errorGeneric,
                message: l10n.vendorTagline,
                actionLabel: l10n.retry,
                onAction: viewModel.runStartupLogic,
              ),
            )
          : !viewModel.showSplash
          ? const SizedBox.shrink()
          : DymSplash(
              onIntroComplete: viewModel.introFinished,
              tagline: l10n.vendorTagline,
            ),
    );
  }
}
