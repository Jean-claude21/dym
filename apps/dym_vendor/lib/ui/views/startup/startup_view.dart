import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:dym_vendor/ui/views/startup/startup_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Premier écran technique (spec 003) : marque, accroche, environnement.
/// Remplacé par le parcours de connexion de la spec `auth`.
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
    return Scaffold(
      backgroundColor: context.dym.colors.brandDeep,
      body: _Welcome(viewModel: viewModel),
    );
  }
}

class _Welcome extends StatelessWidget {
  const new({required this.viewModel});

  final StartupViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final environment = viewModel.environmentName;
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(DymLayout.gutter(context)),
          child: DymContentWidth.form(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.appNameVendor,
                  textAlign: TextAlign.center,
                  style: t.display.copyWith(fontSize: 56, color: c.onBrand),
                ),
                const SizedBox(height: DymTokenSpace.s2),
                Text(
                  l10n.vendorTagline,
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
    );
  }
}
