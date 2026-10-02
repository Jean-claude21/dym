import 'package:dym_auth/src/auth_flow_viewmodel.dart';
import 'package:dym_auth/src/widgets/step_scaffold.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';

ImageProvider _asset(String name) =>
    AssetImage('assets/$name', package: 'dym_auth');

/// Bienvenue de l'app cliente : 3 écrans à faire défiler (« Passer »), puis
/// Google ou email (maquette 09).
class WelcomeStep extends StatefulWidget {
  const new({required this.viewModel, super.key});

  final AuthFlowViewModel viewModel;

  @override
  State<WelcomeStep> createState() => _WelcomeStepState();
}

class _WelcomeStepState extends State<WelcomeStep> {
  late final PageController _pages = PageController(
    initialPage: widget.viewModel.welcomePage,
  );

  @override
  void didUpdateWidget(WelcomeStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    final target = widget.viewModel.welcomePage;
    if (_pages.hasClients && _pages.page?.round() != target) {
      _pages.animateToPage(
        target,
        duration: DymMotion.of(context, DymMotion.medium),
        curve: DymMotion.standard,
      );
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final slides = [
      (
        _asset('welcome_market.webp'),
        l10n.welcomeSlide1Title,
        l10n.welcomeSlide1Body,
      ),
      (
        _asset('welcome_basket.webp'),
        l10n.welcomeSlide2Title,
        l10n.welcomeSlide2Body,
      ),
      (
        _asset('welcome_zem.webp'),
        l10n.welcomeSlide3Title,
        l10n.welcomeSlide3Body,
      ),
    ];
    final landscape =
        MediaQuery.sizeOf(context).width > MediaQuery.sizeOf(context).height;

    Widget slide((ImageProvider, String, String) s) {
      final (image, title, body) = s;
      final text = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: t.display.copyWith(
              fontSize: 32,
              height: 1.1,
              color: c.brandDeep,
            ),
          ),
          const SizedBox(height: DymTokenSpace.s2),
          Text(
            body,
            textAlign: TextAlign.center,
            style: t.body.copyWith(fontSize: 17, color: c.textSecondary),
          ),
        ],
      );
      final picture = Image(image: image, fit: BoxFit.contain);
      // Le texte garde sa mise en page et se réduit s'il manque de hauteur
      // (petit téléphone, texte agrandi, paysage).
      return LayoutBuilder(
        builder: (context, box) {
          Widget fitted(double width, double maxHeight) => ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(width: width, child: text),
            ),
          );
          if (landscape) {
            return Row(
              children: [
                Expanded(child: picture),
                const SizedBox(width: DymTokenSpace.s5),
                Expanded(
                  child: Center(
                    child: fitted((box.maxWidth - 24) / 2, box.maxHeight),
                  ),
                ),
              ],
            );
          }
          return Column(
            children: [
              Expanded(child: picture),
              const SizedBox(height: DymTokenSpace.s4),
              fitted(box.maxWidth, box.maxHeight * 0.62),
            ],
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) {
            final inset = DymLayout.sideInset(
              box.maxWidth,
              gutter: DymLayout.gutter(context),
              maxWidth: DymTokenLayout.formMax,
            );
            // Le diaporama prend la place restante sans jamais écraser les
            // boutons : sur petit écran, l'ensemble défile.
            final pageHeight = (box.maxHeight * 0.56).clamp(220.0, 560.0);
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(inset, 0, inset, DymTokenSpace.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: DymTokenSize.touchMin,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: vm.welcomePage < AuthFlowViewModel.welcomePages - 1
                          ? TextButton(
                              onPressed: vm.skipWelcome,
                              child: Text(
                                l10n.welcomeSkip,
                                style: t.title.copyWith(
                                  fontSize: 17,
                                  color: c.brandDeep,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                  SizedBox(
                    height: pageHeight,
                    child: PageView(
                      controller: _pages,
                      onPageChanged: vm.setWelcomePage,
                      children: [for (final s in slides) slide(s)],
                    ),
                  ),
                  const SizedBox(height: DymTokenSpace.s3),
                  Semantics(
                    label: l10n.welcomePage(vm.welcomePage + 1, slides.length),
                    child: ExcludeSemantics(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < slides.length; i++)
                            AnimatedContainer(
                              duration: DymMotion.of(context, DymMotion.fast),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: i == vm.welcomePage ? 28 : 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: i == vm.welcomePage
                                    ? c.brand
                                    : c.textSecondary.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(
                                  DymTokenRadius.chip,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: DymTokenSpace.s4),
                  AuthErrorBanner(error: vm.authError),
                  if (vm.googleAvailable) ...[
                    DymButton(
                      label: l10n.authContinueGoogle,
                      variant: DymButtonVariant.surface,
                      leading: const DymGoogleLogo(),
                      loading: vm.isBusy,
                      onPressed: vm.chooseGoogle,
                    ),
                    const SizedBox(height: DymTokenSpace.s3),
                  ],
                  DymButton(
                    label: l10n.authContinueEmail,
                    onPressed: vm.chooseEmail,
                  ),
                  const SizedBox(height: DymTokenSpace.s3),
                  Text(
                    l10n.authLegal,
                    textAlign: TextAlign.center,
                    style: t.label.copyWith(color: c.textSecondary),
                  ),
                  const SizedBox(height: DymTokenSpace.s2),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Bienvenue de l'app vendeuse (maquette 14) : fond vert profond, photo,
/// promesse, Google ou email.
class VendorWelcomeStep extends StatelessWidget {
  const new({required this.viewModel, super.key});

  final AuthFlowViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final points = [l10n.vendorPoint1, l10n.vendorPoint2, l10n.vendorPoint3];
    return Scaffold(
      backgroundColor: c.brandDeep,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) {
            final inset = DymLayout.sideInset(
              box.maxWidth,
              gutter: DymLayout.gutter(context),
              maxWidth: DymTokenLayout.formMax,
            );
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(inset, 16, inset, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(DymTokenRadius.card),
                    child: AspectRatio(
                      aspectRatio: 1.1,
                      child: Image(
                        image: _asset('vendor_stall.webp'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: DymTokenSpace.s5),
                  Text(
                    l10n.appNameVendor,
                    textAlign: TextAlign.center,
                    style: t.display.copyWith(fontSize: 40, color: c.onBrand),
                  ),
                  const SizedBox(height: DymTokenSpace.s2),
                  Text(
                    l10n.vendorWelcomeBody,
                    textAlign: TextAlign.center,
                    style: t.title.copyWith(fontSize: 18, color: c.onBrand),
                  ),
                  const SizedBox(height: DymTokenSpace.s4),
                  for (final p in points)
                    Padding(
                      padding: const EdgeInsets.only(bottom: DymTokenSpace.s2),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: c.plantain,
                            size: 26,
                          ),
                          const SizedBox(width: DymTokenSpace.s3),
                          Expanded(
                            child: Text(
                              p,
                              style: t.body.copyWith(
                                fontSize: 16,
                                color: c.onBrand,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  AuthErrorBanner(error: vm.authError, onDark: true),
                  const SizedBox(height: DymTokenSpace.s4),
                  if (vm.googleAvailable) ...[
                    DymButton(
                      label: l10n.authContinueGoogle,
                      variant: DymButtonVariant.surface,
                      leading: const DymGoogleLogo(),
                      loading: vm.isBusy,
                      onPressed: vm.chooseGoogle,
                    ),
                    const SizedBox(height: DymTokenSpace.s3),
                  ],
                  DymButton(
                    label: l10n.authContinueEmail,
                    variant: vm.googleAvailable
                        ? DymButtonVariant.onBrand
                        : DymButtonVariant.plantain,
                    onPressed: vm.chooseEmail,
                  ),
                  const SizedBox(height: DymTokenSpace.s3),
                  Text(
                    l10n.authLegal,
                    textAlign: TextAlign.center,
                    style: t.label.copyWith(color: c.onBrand),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
