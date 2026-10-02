import 'package:dym_ui/src/theme/dym_motion.dart';
import 'package:dym_ui/src/theme/dym_theme.dart';
import 'package:dym_ui/src/tokens/dym_tokens.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Saisie d'un code à usage unique : des cases visibles au-dessus d'un champ
/// numérique unique (collage, remplissage automatique et clavier natifs).
class DymCodeInput extends StatefulWidget {
  /// Crée la saisie. [label] est lu par les lecteurs d'écran.
  const new({
    required this.label,
    required this.onChanged,
    super.key,
    this.length = 6,
    this.onCompleted,
    this.error = false,
    this.enabled = true,
    this.autofocus = true,
    this.controller,
  });

  final String label;
  final ValueChanged<String> onChanged;

  /// Appelé quand toutes les cases sont remplies.
  final ValueChanged<String>? onCompleted;
  final int length;

  /// Cases encadrées de rouge (code refusé).
  final bool error;
  final bool enabled;
  final bool autofocus;
  final TextEditingController? controller;

  @override
  State<DymCodeInput> createState() => _DymCodeInputState();
}

class _DymCodeInputState extends State<DymCodeInput> {
  late final TextEditingController _controller =
      widget.controller ?? TextEditingController();
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_rebuild);
    _focus.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    _controller.removeListener(_rebuild);
    if (widget.controller == null) _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final value = _controller.text;
    return Semantics(
      label: widget.label,
      textField: true,
      child: GestureDetector(
        onTap: _focus.requestFocus,
        child: Stack(
          children: [
            // Champ réel, transparent : reçoit le clavier et le collage.
            Positioned.fill(
              child: Opacity(
                opacity: 0,
                child: TextField(
                  controller: _controller,
                  focusNode: _focus,
                  enabled: widget.enabled,
                  autofocus: widget.autofocus,
                  keyboardType: TextInputType.number,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  maxLength: widget.length,
                  showCursor: false,
                  enableInteractiveSelection: false,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(counterText: ''),
                  onChanged: (v) {
                    widget.onChanged(v);
                    if (v.length == widget.length) widget.onCompleted?.call(v);
                  },
                ),
              ),
            ),
            ExcludeSemantics(
              child: Row(
                children: [
                  for (var i = 0; i < widget.length; i++) ...[
                    if (i > 0) const SizedBox(width: DymTokenSpace.s2),
                    Expanded(
                      child: _Box(
                        digit: i < value.length ? value[i] : null,
                        active:
                            _focus.hasFocus &&
                            i == value.length.clamp(0, widget.length - 1),
                        error: widget.error,
                        textStyle: t.display.copyWith(
                          fontSize: 26,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Box extends StatelessWidget {
  const new({
    required this.digit,
    required this.active,
    required this.error,
    required this.textStyle,
  });

  final String? digit;
  final bool active;
  final bool error;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final borderColor = error
        ? c.pimentStrong
        : active
        ? c.brand
        : c.textSecondary.withValues(alpha: 0.15);
    return AspectRatio(
      aspectRatio: 0.82,
      child: AnimatedContainer(
        duration: DymMotion.of(context, DymMotion.fast),
        constraints: const BoxConstraints(minHeight: DymTokenSize.touchMin),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(DymTokenRadius.button),
          border: Border.all(
            color: borderColor,
            width: active || error ? 2 : 1,
          ),
        ),
        child: FittedBox(child: Text(digit ?? '', style: textStyle)),
      ),
    );
  }
}
