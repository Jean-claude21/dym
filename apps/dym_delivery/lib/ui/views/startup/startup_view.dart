import 'package:dym_delivery/ui/views/startup/startup_viewmodel.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Démarrage : marque et accroche le temps de restaurer la session.
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
      backgroundColor: c.brandDeep,
      body: SafeArea(
        child: viewModel.failed
            ? DymStateView(
                kind: viewModel.offline
                    ? DymStateKind.offline
                    : DymStateKind.error,
                title: viewModel.offline
                    ? l10n.errorOffline
                    : l10n.errorGeneric,
                message: l10n.deliveryTagline,
                actionLabel: l10n.retry,
                onAction: viewModel.runStartupLogic,
              )
            : Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(DymLayout.gutter(context)),
                  child: DymContentWidth.form(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.appNameDelivery,
                          textAlign: TextAlign.center,
                          style: t.display.copyWith(
                            fontSize: 48,
                            letterSpacing: -1.5,
                            color: c.onBrand,
                          ),
                        ),
                        const SizedBox(height: DymTokenSpace.s2),
                        Text(
                          l10n.deliveryTagline,
                          textAlign: TextAlign.center,
                          style: t.title.copyWith(color: c.onBrand),
                        ),
                        const SizedBox(height: DymTokenSpace.s5),
                        if (viewModel.isBusy)
                          Semantics(
                            label: l10n.startupPreparing,
                            child: CircularProgressIndicator(color: c.onBrand),
                          ),
                        if (environment != null) ...[
                          const SizedBox(height: DymTokenSpace.s4),
                          Text(
                            l10n.environmentLabel(environment),
                            style: t.label.copyWith(color: c.onBrand),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
