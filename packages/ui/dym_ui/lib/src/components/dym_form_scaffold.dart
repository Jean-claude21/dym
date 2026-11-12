import 'package:dym_ui/src/layout/dym_content_width.dart';
import 'package:dym_ui/src/layout/dym_layout.dart';
import 'package:dym_ui/src/theme/dym_motion.dart';
import 'package:dym_ui/src/theme/dym_theme.dart';
import 'package:dym_ui/src/tokens/dym_tokens.g.dart';
import 'package:flutter/material.dart';

/// Progression d'un parcours en étapes (« Étape 2 sur 7 »).
@immutable
class DymStepProgress {
  /// Crée la progression ; [label] est le texte affiché et lu.
  const new({required this.current, required this.total, required this.label});

  /// Étape courante (à partir de 1).
  final int current;

  /// Nombre d'étapes.
  final int total;

  /// Texte (« Étape 2 sur 7 »).
  final String label;
}

/// Gabarit d'un écran de formulaire ou d'une étape :
/// - en tête, un retour et une progression facultative ;
/// - puis un titre, un sous-titre et un contenu qui défile, borné à la largeur
///   d'un formulaire ;
/// - en bas, l'action principale.
class DymFormScaffold extends StatelessWidget {
  /// Crée le gabarit. [backLabel] est lu par les lecteurs d'écran.
  const new({
    required this.title,
    required this.children,
    required this.action,
    super.key,
    this.subtitle,
    this.onBack,
    this.backLabel = '',
    this.backgroundColor,
    this.progress,
    this.centerTitle = false,
  });

  final String title;
  final Widget? subtitle;
  final List<Widget> children;
  final Widget action;
  final VoidCallback? onBack;
  final String backLabel;
  final Color? backgroundColor;

  /// Progression du parcours, affichée en tête.
  final DymStepProgress? progress;

  /// Titre et sous-titre centrés (parcours d'onboarding).
  final bool centerTitle;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final align = centerTitle ? TextAlign.center : TextAlign.start;
    final back = onBack == null
        ? const SizedBox(
            width: DymTokenSize.touchMin,
            height: DymTokenSize.touchMin,
          )
        : _BackButton(label: backLabel, onTap: onBack!);
    final step = progress;
    return Scaffold(
      backgroundColor: backgroundColor ?? c.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, box) {
                  final inset = DymLayout.sideInset(
                    box.maxWidth,
                    gutter: DymLayout.gutter(context),
                    maxWidth: DymTokenLayout.formMax,
                  );
                  return ListView(
                    padding: EdgeInsets.fromLTRB(inset, 8, inset, 24),
                    children: [
                      if (step == null)
                        Align(alignment: Alignment.centerLeft, child: back)
                      else
                        Row(
                          children: [
                            back,
                            const SizedBox(width: DymTokenSpace.s2),
                            Expanded(child: _Progress(step: step)),
                            const SizedBox(width: DymTokenSize.touchMin),
                          ],
                        ),
                      const SizedBox(height: DymTokenSpace.s5),
                      Text(
                        title,
                        textAlign: align,
                        style: t.display.copyWith(fontSize: 30, height: 1.15),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: DymTokenSpace.s2),
                        DefaultTextStyle.merge(
                          textAlign: align,
                          style: t.body.copyWith(
                            fontSize: 16,
                            color: c.textSecondary,
                          ),
                          child: subtitle!,
                        ),
                      ],
                      const SizedBox(height: DymTokenSpace.s5),
                      ...children,
                    ],
                  );
                },
              ),
            ),
            DymContentWidth.form(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  DymLayout.gutter(context),
                  4,
                  DymLayout.gutter(context),
                  12,
                ),
                child: action,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const new({required this.step});

  final DymStepProgress step;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    return Semantics(
      label: step.label,
      excludeSemantics: true,
      child: Column(
        children: [
          Text(
            step.label,
            textAlign: TextAlign.center,
            style: context.dym.text.label.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (var i = 0; i < step.total; i++)
                Expanded(
                  child: AnimatedContainer(
                    duration: DymMotion.of(context, DymMotion.fast),
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: i < step.current ? c.brand : c.lineStrong,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const new({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    return Material(
      color: c.card,
      shape: CircleBorder(side: BorderSide(color: c.hairline)),
      child: IconButton(
        tooltip: label,
        onPressed: onTap,
        icon: Icon(Icons.arrow_back_rounded, color: c.textPrimary),
      ),
    );
  }
}
