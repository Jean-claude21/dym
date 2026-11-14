import 'package:dym_admin/ui/views/startup/startup_viewmodel.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Démarrage de l'admin le temps de vérifier la session : fond uni, sans
/// splash ; la page voulue s'affiche dès que la session est connue.
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
  ) => Scaffold(backgroundColor: context.dym.colors.background);
}
