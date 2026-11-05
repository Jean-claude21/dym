import 'package:dym_ui/src/theme/dym_motion.dart';
import 'package:dym_ui/src/theme/dym_theme.dart';
import 'package:dym_ui/src/tokens/dym_tokens.g.dart';
import 'package:flutter/material.dart';

/// État d'une étape de [DymTimeline].
enum DymStepState {
  /// Étape terminée.
  done,

  /// Étape en cours.
  current,

  /// Étape à venir.
  todo,
}

/// Étape de la frise.
@immutable
class DymStep {
  /// Crée une étape.
  const new(this.label, this.state);

  /// Libellé.
  final String label;

  /// État.
  final DymStepState state;
}

/// Frise d'étapes horizontale (suivi de commande).
class DymTimeline extends StatelessWidget {
  /// Crée la frise.
  const new({required this.steps, super.key});

  /// Étapes, dans l'ordre.
  final List<DymStep> steps;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++)
          Expanded(
            child: Column(
              children: [
                SizedBox(
                  height: 36,
                  child: Row(
                    children: [
                      Expanded(
                        child: i == 0
                            ? const SizedBox()
                            : _Line(done: steps[i].state != DymStepState.todo),
                      ),
                      _Dot(state: steps[i].state),
                      Expanded(
                        child: i == steps.length - 1
                            ? const SizedBox()
                            : _Line(
                                done: steps[i + 1].state != DymStepState.todo,
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: DymTokenSpace.s1),
                Text(
                  steps[i].label,
                  textAlign: TextAlign.center,
                  style: context.dym.text.label.copyWith(
                    fontSize: 12,
                    fontWeight: steps[i].state == DymStepState.current
                        ? FontWeight.w800
                        : FontWeight.w600,
                    color: steps[i].state == DymStepState.todo
                        ? c.textSecondary
                        : c.textPrimary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const new({required this.done});

  final bool done;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    return Container(
      height: 3,
      color: done ? c.brand : c.textSecondary.withValues(alpha: 0.2),
    );
  }
}

class _Dot extends StatelessWidget {
  const new({required this.state});

  final DymStepState state;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    return switch (state) {
      DymStepState.done => Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(color: c.brand, shape: BoxShape.circle),
        child: Icon(Icons.check_rounded, color: c.onBrand, size: 20),
      ),
      DymStepState.current => _Pulse(color: c.plantain),
      DymStepState.todo => Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: c.card,
          shape: BoxShape.circle,
          border: Border.all(
            color: c.textSecondary.withValues(alpha: 0.3),
            width: 3,
          ),
        ),
      ),
    };
  }
}

/// Point « en cours » avec halo qui respire.
class _Pulse extends StatefulWidget {
  const new({required this.color});

  final Color color;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (DymMotion.enabled(context)) {
      _controller.repeat(reverse: true);
    } else {
      _controller.value = 0.5;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.45),
              spreadRadius: 3 + 4 * _controller.value,
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
