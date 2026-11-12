import 'package:dym_auth/src/auth_flow_viewmodel.dart';
import 'package:dym_auth/src/widgets/step_scaffold.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';

ImageProvider _asset(String name) =>
    AssetImage('assets/$name', package: 'dym_auth');

/// Bienvenue de l'app cliente (design « Épuré ») : trois photos du quotidien
/// en pleine largeur, un message par écran, « Passer », puis email ou
/// Google. Le texte n'est jamais posé sur la photo.
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
    final l10n = DymLocalizations.of(context);
    final slides = [
      (
        _asset('onb_market.webp'),
        l10n.welcomeSlide1Title,
        l10n.welcomeSlide1Body,
      ),
      (
        _asset('onb_cook.webp'),
        l10n.welcomeSlide2Title,
        l10n.welcomeSlide2Body,
      ),
      (
        _asset('onb_delivery.webp'),
        l10n.welcomeSlide3Title,
        l10n.welcomeSlide3Body,
      ),
    ];
    final last = vm.welcomePage >= AuthFlowViewModel.welcomePages - 1;
    final skip = last
        ? null
        : _PhotoChip(label: l10n.welcomeSkip, onTap: vm.skipWelcome);
    final dots = Semantics(
      label: l10n.welcomePage(vm.welcomePage + 1, slides.length),
      child: ExcludeSemantics(
        child: Row(
          children: [
            for (var i = 0; i < slides.length; i++)
              AnimatedContainer(
                duration: DymMotion.of(context, DymMotion.fast),
                margin: const EdgeInsets.only(right: 6),
                width: i == vm.welcomePage ? 24 : 8,
                height: 4,
                decoration: BoxDecoration(
                  color: i == vm.welcomePage ? c.brand : c.lineStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      ),
    );
    final actions = _Actions(viewModel: vm);

    return Scaffold(
      backgroundColor: c.background,
      body: LayoutBuilder(
        builder: (context, box) {
          final landscape = box.maxWidth > box.maxHeight;
          final pages = PageView(
            controller: _pages,
            onPageChanged: vm.setWelcomePage,
            children: [
              for (final (image, title, body) in slides)
                _Slide(
                  image: image,
                  title: title,
                  body: body,
                  landscape: landscape,
                ),
            ],
          );
          if (landscape) {
            // Paysage : la photo à gauche, texte et boutons à droite.
            return Stack(
              children: [
                pages,
                if (skip != null)
                  Positioned(
                    top: MediaQuery.paddingOf(context).top + 12,
                    left: 16,
                    child: skip,
                  ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  width: box.maxWidth / 2,
                  child: SafeArea(
                    left: false,
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(32, 0, 32, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [dots, const SizedBox(height: 16), actions],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
          final inset = DymLayout.sideInset(
            box.maxWidth,
            gutter: DymLayout.gutter(context),
            maxWidth: DymTokenLayout.formMax,
          );
          return Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    pages,
                    if (skip != null)
                      Positioned(
                        top: MediaQuery.paddingOf(context).top + 12,
                        right: 16,
                        child: skip,
                      ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(inset, 4, inset, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [dots, const SizedBox(height: 20), actions],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Un écran du diaporama : photo en pleine largeur, puis titre et texte.
class _Slide extends StatelessWidget {
  const new({
    required this.image,
    required this.title,
    required this.body,
    required this.landscape,
  });

  final ImageProvider image;
  final String title;
  final String body;
  final bool landscape;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final photo = Image(
      image: image,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      errorBuilder: (_, _, _) => ColoredBox(color: c.tintVertTendre),
    );
    final text = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: t.display.copyWith(fontSize: 30, height: 1.15)),
        const SizedBox(height: DymTokenSpace.s2),
        Text(
          body,
          style: t.body.copyWith(fontSize: 16, color: c.textSecondary),
        ),
      ],
    );
    return LayoutBuilder(
      builder: (context, box) {
        if (landscape) {
          return Row(
            children: [
              Expanded(child: SizedBox.expand(child: photo)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(32, 24, 32, 180),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: box.maxWidth / 2 - 64,
                        child: text,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }
        final inset = DymLayout.sideInset(
          box.maxWidth,
          gutter: DymLayout.gutter(context),
          maxWidth: DymTokenLayout.formMax,
        );
        // La photo prend ce que le texte laisse ; le texte se réduit plutôt
        // que de déborder (petit téléphone, texte agrandi).
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: photo),
            Padding(
              padding: EdgeInsets.fromLTRB(inset, 24, inset, 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: box.maxHeight * 0.4),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.topLeft,
                  child: SizedBox(width: box.maxWidth - 2 * inset, child: text),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// « Passer » posé sur la photo : pastille blanche, lisible sur toute image.
class _PhotoChip extends StatelessWidget {
  const new({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    return Semantics(
      button: true,
      container: true,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: c.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DymTokenRadius.chip),
          side: BorderSide(color: c.hairline),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DymTokenRadius.chip),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40, minWidth: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Center(
                widthFactor: 1,
                child: Text(
                  label,
                  style: context.dym.text.label.copyWith(
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Email (action principale), Google, mentions légales.
class _Actions extends StatelessWidget {
  const new({required this.viewModel});

  final AuthFlowViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;
    final c = context.dym.colors;
    final l10n = DymLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AuthErrorBanner(error: vm.authError),
        if (vm.authError != null) const SizedBox(height: DymTokenSpace.s3),
        DymButton(
          label: l10n.authContinueEmail,
          icon: Icons.mail_outline_rounded,
          onPressed: vm.chooseEmail,
        ),
        if (vm.googleAvailable) ...[
          const SizedBox(height: DymTokenSpace.s2 + 2),
          DymButton(
            label: l10n.authContinueGoogle,
            variant: DymButtonVariant.surface,
            leading: const DymGoogleLogo(),
            loading: vm.isBusy,
            onPressed: vm.chooseGoogle,
          ),
        ],
        const SizedBox(height: DymTokenSpace.s3),
        Text(
          l10n.authLegal,
          textAlign: TextAlign.center,
          style: context.dym.text.label.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: c.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Bienvenue des apps vendeuse et livreur (design « Épuré ») : une photo du
/// métier, le nom de l'app, trois promesses, puis email ou Google.
class VendorWelcomeStep extends StatelessWidget {
  const new({required this.viewModel, super.key, this.delivery = false});

  final AuthFlowViewModel viewModel;

  /// Accueil de l'app livreur (mêmes gestes, autre photo et autres textes).
  final bool delivery;

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final points = delivery
        ? [
            (Icons.near_me_outlined, l10n.deliveryPoint1),
            (Icons.phone_in_talk_outlined, l10n.deliveryPoint2),
            (Icons.verified_user_outlined, l10n.deliveryPoint3),
          ]
        : [
            (Icons.add_a_photo_outlined, l10n.vendorPoint1),
            (Icons.receipt_long_outlined, l10n.vendorPoint2),
            (Icons.payments_outlined, l10n.vendorPoint3),
          ];
    final photo = Image(
      image: _asset(delivery ? 'courier_hero.webp' : 'vendor_hero.webp'),
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      errorBuilder: (_, _, _) => ColoredBox(color: c.tintVertTendre),
    );
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          delivery ? l10n.appNameDelivery : l10n.appNameVendor,
          style: t.display.copyWith(fontSize: 30),
        ),
        const SizedBox(height: DymTokenSpace.s2),
        Text(
          delivery ? l10n.deliveryWelcomeBody : l10n.vendorWelcomeBody,
          style: t.body.copyWith(fontSize: 16, color: c.textSecondary),
        ),
        const SizedBox(height: DymTokenSpace.s4),
        for (final (icon, text) in points)
          Padding(
            padding: const EdgeInsets.only(bottom: DymTokenSpace.s3),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: c.tintVertTendre,
                    borderRadius: BorderRadius.circular(DymTokenRadius.field),
                  ),
                  child: Icon(icon, color: c.brandDeep, size: 20),
                ),
                const SizedBox(width: DymTokenSpace.s3),
                Expanded(child: Text(text, style: t.body)),
              ],
            ),
          ),
        const SizedBox(height: DymTokenSpace.s2),
        _Actions(viewModel: vm),
      ],
    );
    return Scaffold(
      backgroundColor: c.background,
      body: LayoutBuilder(
        builder: (context, box) {
          if (box.maxWidth > box.maxHeight) {
            return Row(
              children: [
                Expanded(child: SizedBox.expand(child: photo)),
                Expanded(
                  child: SafeArea(
                    left: false,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(32, 24, 32, 16),
                      child: content,
                    ),
                  ),
                ),
              ],
            );
          }
          final inset = DymLayout.sideInset(
            box.maxWidth,
            gutter: DymLayout.gutter(context),
            maxWidth: DymTokenLayout.formMax,
          );
          // Petit écran : la photo garde un tiers de la hauteur, le reste
          // défile sans jamais masquer les boutons.
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: box.maxHeight * 0.42, child: photo),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(inset, 24, inset, 12),
                    child: content,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
