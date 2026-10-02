import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';

/// Bloc blanc d'un formulaire de boutique (titre facultatif).
class StoreSection extends StatelessWidget {
  const new({required this.children, super.key, this.title, this.trailing});

  final String? title;
  final Widget? trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    return Container(
      padding: const EdgeInsets.all(DymTokenSpace.s4),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(DymTokenRadius.card),
        boxShadow: const [DymTokenShadows.card],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null || trailing != null) ...[
            Row(
              children: [
                Expanded(
                  child: title == null
                      ? const SizedBox.shrink()
                      : Text(
                          title!,
                          style: context.dym.text.title.copyWith(fontSize: 19),
                        ),
                ),
                if (trailing != null) Flexible(child: trailing!),
              ],
            ),
            const SizedBox(height: DymTokenSpace.s3),
          ],
          ...children,
        ],
      ),
    );
  }
}

/// Note « adresse privée » (cadenas, teinte pêche).
class StorePrivacyNote extends StatelessWidget {
  const new({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    return Container(
      padding: const EdgeInsets.all(DymTokenSpace.s3),
      decoration: BoxDecoration(
        color: c.tintPeche,
        borderRadius: BorderRadius.circular(DymTokenRadius.tile),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_rounded, color: c.originMaisonFg),
          const SizedBox(width: DymTokenSpace.s3),
          Expanded(
            child: Text(
              text,
              style: context.dym.text.label.copyWith(
                color: c.originMaisonFg,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bandeau d'échec (icône + texte), lu par les lecteurs d'écran.
class StoreErrorBanner extends StatelessWidget {
  const new({required this.failure, super.key, this.incomplete = false});

  final Failure? failure;
  final bool incomplete;

  @override
  Widget build(BuildContext context) {
    final current = failure;
    if (current == null) return const SizedBox.shrink();
    final c = context.dym.colors;
    final l10n = DymLocalizations.of(context);
    final offline = current is NetworkFailure;
    final text = offline
        ? l10n.errorOffline
        : incomplete
        ? l10n.storeIncomplete
        : current is ForbiddenFailure
        ? l10n.myStoreSuspended
        : l10n.storeSaveError;
    return Padding(
      padding: const EdgeInsets.only(bottom: DymTokenSpace.s2),
      child: Semantics(
        liveRegion: true,
        child: Container(
          padding: const EdgeInsets.all(DymTokenSpace.s3),
          decoration: BoxDecoration(
            color: c.tintPimentClair,
            borderRadius: BorderRadius.circular(DymTokenRadius.tile),
          ),
          child: Row(
            children: [
              Icon(
                offline ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
                color: c.pimentStrong,
              ),
              const SizedBox(width: DymTokenSpace.s3),
              Expanded(
                child: Text(
                  text,
                  style: context.dym.text.label.copyWith(
                    color: c.pimentStrong,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Champ de saisie qui garde son contrôleur (valeur initiale du viewmodel).
class StoreTextField extends StatefulWidget {
  const new({
    required this.label,
    required this.initialValue,
    required this.onChanged,
    super.key,
    this.hint,
    this.maxLength,
    this.minLines,
    this.maxLines = 1,
    this.autofocus = false,
    this.status = DymFieldStatus.none,
    this.message,
  });

  final String label;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final String? hint;
  final int? maxLength;
  final int? minLines;
  final int? maxLines;
  final bool autofocus;
  final DymFieldStatus status;
  final String? message;

  @override
  State<StoreTextField> createState() => _StoreTextFieldState();
}

class _StoreTextFieldState extends State<StoreTextField> {
  late final _controller = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DymTextField(
    label: widget.label,
    hint: widget.hint ?? widget.label,
    controller: _controller,
    onChanged: widget.onChanged,
    maxLength: widget.maxLength,
    minLines: widget.minLines,
    maxLines: widget.maxLines,
    autofocus: widget.autofocus,
    status: widget.status,
    message: widget.message,
    textCapitalization: TextCapitalization.sentences,
    textInputAction: widget.maxLines == 1
        ? TextInputAction.next
        : TextInputAction.newline,
  );
}

/// Libellé de champ au-dessus d'une saisie.
class StoreFieldLabel extends StatelessWidget {
  const new(this.text, {super.key, this.suffix});

  final String text;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    final t = context.dym.text;
    return Padding(
      padding: const EdgeInsets.only(bottom: DymTokenSpace.s2),
      child: Text.rich(
        TextSpan(
          text: text,
          style: t.title.copyWith(fontSize: 19),
          children: [
            if (suffix != null)
              TextSpan(
                text: ' $suffix',
                style: t.label.copyWith(
                  fontSize: 15,
                  color: context.dym.colors.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
