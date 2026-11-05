import 'package:dym_gallery/demo/demo_assets.dart';
import 'package:dym_gallery/demo/demo_country.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Écran 01 — Splash « Le marché de Lomé, livré chez toi ».
class SplashScreen extends StatelessWidget {
  const new({required this.country, super.key});

  final DemoCountry country;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final animate = DymMotion.enabled(context);
    final city = country.code == 'GH' ? 'Accra' : 'Lomé';

    Widget basin = Image(image: DemoImages.splashBasin, fit: BoxFit.contain);
    Widget logo = Text(
      'DYM',
      style: context.dym.text.display.copyWith(
        fontSize: 112,
        fontWeight: FontWeight.w900,
        height: 1,
        letterSpacing: -2,
        color: c.brand,
      ),
    );
    Widget tagline = Text(
      'Le marché de $city, livré chez toi',
      textAlign: TextAlign.center,
      style: context.dym.text.title.copyWith(fontSize: 22, color: c.brand),
    );
    Widget kente = SizedBox(
      height: 64,
      width: double.infinity,
      child: Image(
        image: DemoImages.kente,
        repeat: ImageRepeat.repeatX,
        fit: BoxFit.fitHeight,
        alignment: Alignment.centerLeft,
      ),
    );

    if (animate) {
      basin = basin
          .animate()
          .scale(
            begin: const Offset(0.82, 0.82),
            duration: 650.ms,
            curve: Curves.easeOutBack,
          )
          .fadeIn(duration: 400.ms);
      logo = logo
          .animate(delay: 350.ms)
          .fadeIn(duration: 400.ms)
          .slideY(begin: 0.25, duration: 450.ms, curve: DymMotion.standard);
      tagline = tagline.animate(delay: 600.ms).fadeIn(duration: 450.ms);
      kente = kente
          .animate(delay: 750.ms)
          .slideY(begin: 1, duration: 450.ms, curve: DymMotion.standard);
    }

    // Paysage : bassine à gauche, logo et accroche à droite (spec 002).
    final size = MediaQuery.sizeOf(context);
    if (size.width > size.height) {
      return Scaffold(
        backgroundColor: c.background,
        body: Column(
          children: [
            Expanded(
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(DymTokenSpace.s5),
                        child: Center(child: basin),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(DymTokenSpace.s4),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                logo,
                                const SizedBox(height: DymTokenSpace.s2),
                                tagline,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            kente,
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: c.background,
      body: Column(
        children: [
          const Spacer(flex: 3),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DymTokenSpace.s4),
            // Bornée sur tablette ; identique sur téléphone.
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: AspectRatio(aspectRatio: 1, child: basin),
            ),
          ),
          const Spacer(),
          logo,
          const SizedBox(height: DymTokenSpace.s2),
          tagline,
          const Spacer(flex: 3),
          kente,
        ],
      ),
    );
  }
}
