import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:dym_vendor/features/store/onboarding/store_onboarding_viewmodel.dart';
import 'package:dym_vendor/features/store/onboarding/store_steps.dart';
import 'package:dym_vendor/features/store/store_service.dart';
import 'package:dym_vendor/features/store/widgets/store_widgets.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Onboarding de la boutique en 7 étapes (écrans 16 à 21), ou réglage d'une
/// étape depuis « Ma boutique » ([editStep]).
class StoreOnboardingView extends StackedView<StoreOnboardingViewModel> {
  const new({
    required this.service,
    required this.onOpened,
    super.key,
    this.editStep,
    this.onSaved,
    this.onCancel,
  });

  final StoreService service;
  final void Function(MyStore store, CountryConfig config) onOpened;
  final StoreStep? editStep;
  final void Function(MyStore store)? onSaved;

  /// Retour depuis un réglage.
  final VoidCallback? onCancel;

  @override
  StoreOnboardingViewModel viewModelBuilder(BuildContext context) =>
      StoreOnboardingViewModel(
        service: service,
        onOpened: onOpened,
        editStep: editStep,
        onSaved: onSaved,
      );

  @override
  void onViewModelReady(StoreOnboardingViewModel viewModel) => viewModel.load();

  @override
  Widget builder(
    BuildContext context,
    StoreOnboardingViewModel viewModel,
    Widget? child,
  ) {
    final c = context.dym.colors;
    final l10n = DymLocalizations.of(context);
    if (!viewModel.ready) {
      return Scaffold(
        backgroundColor: c.background,
        body: SafeArea(
          child: viewModel.loadFailure == null
              ? Center(
                  child: Semantics(
                    label: l10n.startupPreparing,
                    child: CircularProgressIndicator(color: c.brand),
                  ),
                )
              : DymStateView(
                  kind: viewModel.offline
                      ? DymStateKind.offline
                      : DymStateKind.error,
                  title: viewModel.offline
                      ? l10n.errorOffline
                      : l10n.errorGeneric,
                  message: l10n.storeSaveError,
                  actionLabel: l10n.retry,
                  onAction: viewModel.load,
                ),
        ),
      );
    }
    final step = viewModel.step;
    final (title, subtitle) = storeStepTexts(l10n, step);
    final last = step == StoreStep.hours && !viewModel.isEditing;
    return DymFormScaffold(
      // Une étape = un écran : le défilement repart du haut.
      key: ValueKey(step),
      title: title,
      subtitle: Text(subtitle),
      backLabel: l10n.authBack,
      onBack: viewModel.canGoBack
          ? viewModel.back
          : viewModel.isEditing
          ? onCancel
          : null,
      progress: viewModel.isEditing
          ? null
          : DymStepProgress(
              current: step.number,
              total: StoreStep.values.length,
              label: l10n.storeStepLabel(step.number, StoreStep.values.length),
            ),
      action: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StoreErrorBanner(
            failure: viewModel.saveFailure,
            incomplete: viewModel.incomplete,
          ),
          DymButton(
            label: viewModel.isEditing
                ? l10n.storeSave
                : last
                ? l10n.storeOpenAction
                : l10n.storeContinue,
            icon: last ? Icons.storefront_rounded : null,
            variant: last
                ? DymButtonVariant.plantain
                : DymButtonVariant.primary,
            loading: viewModel.isBusy,
            onPressed: viewModel.canContinue ? viewModel.submit : null,
          ),
        ],
      ),
      // Une clé par étape : les champs repartent des valeurs du viewmodel.
      children: [
        KeyedSubtree(
          key: ValueKey(step),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: storeStepBody(context, viewModel),
          ),
        ),
      ],
    );
  }
}
