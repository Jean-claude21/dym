import 'dart:async';

import 'package:dym_auth/src/auth_flow_viewmodel.dart';
import 'package:dym_auth/src/auth_service.dart';
import 'package:dym_auth/src/steps/code_step.dart';
import 'package:dym_auth/src/steps/email_step.dart';
import 'package:dym_auth/src/steps/profile_step.dart';
import 'package:dym_auth/src/steps/welcome_step.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Apparence de la bienvenue selon l'app.
enum AuthVariant { client, vendor }

/// Parcours de connexion complet, partagé par les apps cliente et vendeuse.
/// [onReady] reçoit l'utilisateur prêt (profil complet, rôle de l'app).
class AuthFlowView extends StackedView<AuthFlowViewModel> {
  const new({
    required this.service,
    required this.onReady,
    super.key,
    this.variant = AuthVariant.client,
    this.startWithProfile = false,
    this.initialStep = AuthStep.welcome,
    this.initialEmail = '',
  });

  final AuthService service;
  final void Function(Me me) onReady;
  final AuthVariant variant;

  /// Session déjà ouverte mais profil à compléter (au démarrage de l'app).
  final bool startWithProfile;

  /// Étape de départ (prévisualisation dans la galerie de validation).
  final AuthStep initialStep;

  /// Email déjà saisi (prévisualisation).
  final String initialEmail;

  @override
  AuthFlowViewModel viewModelBuilder(BuildContext context) => AuthFlowViewModel(
    service: service,
    onReady: onReady,
    locale: Localizations.localeOf(context).languageCode,
    initialStep: startWithProfile ? AuthStep.profile : initialStep,
    initialEmail: initialEmail,
  );

  @override
  void onViewModelReady(AuthFlowViewModel viewModel) {
    if (startWithProfile) unawaited(viewModel.startProfile());
  }

  @override
  Widget builder(
    BuildContext context,
    AuthFlowViewModel viewModel,
    Widget? child,
  ) {
    final step = switch (viewModel.step) {
      AuthStep.welcome =>
        variant == AuthVariant.vendor
            ? VendorWelcomeStep(viewModel: viewModel)
            : WelcomeStep(viewModel: viewModel),
      AuthStep.email => EmailStep(viewModel: viewModel),
      AuthStep.code => CodeStep(viewModel: viewModel),
      AuthStep.profile => ProfileStep(viewModel: viewModel),
    };
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) viewModel.back();
      },
      child: AnimatedSwitcher(
        duration: DymMotion.of(context, DymMotion.medium),
        switchInCurve: DymMotion.standard,
        child: KeyedSubtree(key: ValueKey(viewModel.step), child: step),
      ),
    );
  }
}
