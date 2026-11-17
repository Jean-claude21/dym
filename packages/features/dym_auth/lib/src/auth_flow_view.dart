import 'dart:async';

import 'package:dym_auth/src/auth_flow_viewmodel.dart';
import 'package:dym_auth/src/auth_service.dart';
import 'package:dym_auth/src/steps/code_step.dart';
import 'package:dym_auth/src/steps/email_step.dart';
import 'package:dym_auth/src/steps/phone_step.dart';
import 'package:dym_auth/src/steps/profile_step.dart';
import 'package:dym_auth/src/steps/welcome_step.dart';
import 'package:dym_auth/src/whatsapp_sign_in.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Apparence de la bienvenue selon l'app.
enum AuthVariant { client, vendor, delivery }

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
    this.onBrowse,
    this.whatsApp,
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

  /// Découvrir sans compte (cliente seulement, spec 093).
  final void Function(String zoneId, String countryCode)? onBrowse;

  /// Connexion WhatsApp (spec 105) ; nulle : pas proposée.
  final WhatsAppSignIn? whatsApp;

  @override
  AuthFlowViewModel viewModelBuilder(BuildContext context) => AuthFlowViewModel(
    service: service,
    onReady: onReady,
    onBrowse: onBrowse,
    whatsApp: whatsApp,
    locale: Localizations.localeOf(context).languageCode,
    supportedLocales: [
      for (final l in DymLocalizations.supportedLocales) l.languageCode,
    ],
    initialStep: startWithProfile ? AuthStep.profile : initialStep,
    initialEmail: initialEmail,
  );

  @override
  void onViewModelReady(AuthFlowViewModel viewModel) {
    if (startWithProfile) unawaited(viewModel.startProfile());
    unawaited(viewModel.loadWhatsApp());
  }

  @override
  Widget builder(
    BuildContext context,
    AuthFlowViewModel viewModel,
    Widget? child,
  ) {
    final step = switch (viewModel.step) {
      AuthStep.welcome => switch (variant) {
        AuthVariant.vendor => VendorWelcomeStep(viewModel: viewModel),
        AuthVariant.delivery => VendorWelcomeStep(
          viewModel: viewModel,
          delivery: true,
        ),
        AuthVariant.client => WelcomeStep(viewModel: viewModel),
      },
      AuthStep.email => EmailStep(viewModel: viewModel),
      AuthStep.phone => PhoneStep(viewModel: viewModel),
      AuthStep.code => CodeStep(viewModel: viewModel),
      AuthStep.profile => ProfileStep(viewModel: viewModel),
    };
    return PopScope(
      // Ouverte par-dessus l'app (visiteuse, spec 093) : retour possible
      // depuis la bienvenue.
      canPop:
          viewModel.step == AuthStep.welcome &&
          (ModalRoute.of(context)?.canPop ?? false),
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
