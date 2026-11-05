import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Base des écrans de l'admin : chargement, échec et devises.
abstract class AdminViewModel extends BaseViewModel {
  Failure? _failure;
  Map<String, Currency> currencies = const {};

  Failure? get failure => _failure;
  bool get failed => _failure != null;

  /// Montant formaté dans sa devise.
  String money(int minor, String? code) {
    final currency = currencies[code];
    return currency == null ? '' : Money(minor, currency).format();
  }

  /// Charge [work] après les devises ; l'échec est gardé pour la vue.
  Future<void> run(
    Future<Result<Map<String, Currency>>> Function() loadCurrencies,
    Future<Failure?> Function() work,
  ) async {
    _failure = null;
    setBusy(true);
    switch (await loadCurrencies()) {
      case Err(:final failure):
        _failure = failure;
      case Ok(:final value):
        currencies = value;
        _failure = await work();
    }
    setBusy(false);
  }
}

/// Page de l'admin : titre, sous-titre, actions, contenu.
class AdminPage extends StatelessWidget {
  const new({
    required this.title,
    required this.child,
    super.key,
    this.subtitle,
    this.actions = const [],
    this.leading,
    this.scrollable = true,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget? leading;
  final Widget child;

  /// Faux : le contenu gère son propre défilement (vue scindée).
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final gutter = DymLayout.gutter(context);
    final header = Padding(
      padding: EdgeInsets.fromLTRB(gutter, gutter, gutter, DymTokenSpace.s3),
      child: Wrap(
        spacing: DymTokenSpace.s3,
        runSpacing: DymTokenSpace.s2,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ?leading,
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: t.display.copyWith(fontSize: 32)),
                    if (subtitle case final s?)
                      Text(s, style: t.body.copyWith(color: c.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          ...actions,
        ],
      ),
    );
    final body = Padding(
      padding: EdgeInsets.fromLTRB(gutter, 0, gutter, gutter),
      child: child,
    );
    return ColoredBox(
      color: c.background,
      child: scrollable
          ? ListView(children: [header, body])
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                Expanded(child: body),
              ],
            ),
    );
  }
}

/// Carte blanche de l'admin.
class AdminCard extends StatelessWidget {
  const new({
    required this.child,
    super.key,
    this.title,
    this.trailing,
    this.color,
    this.borderColor,
    this.padding = const EdgeInsets.all(DymTokenSpace.s4),
  });

  final Widget child;
  final String? title;
  final Widget? trailing;
  final Color? color;
  final Color? borderColor;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    // Material : les tuiles (radio, case, liste) y peignent leurs effets.
    return Material(
      color: color ?? c.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DymTokenRadius.tile),
        side: borderColor == null
            ? BorderSide.none
            : BorderSide(color: borderColor!),
      ),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(title!, style: t.title.copyWith(fontSize: 22)),
                  ),
                  ?trailing,
                ],
              ),
              const SizedBox(height: DymTokenSpace.s2),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

/// Ton d'une pastille.
enum AdminTone { neutral, success, warning, danger }

/// Pastille de statut (texte + fond teinté).
class AdminPill extends StatelessWidget {
  const new(this.label, {super.key, this.tone = AdminTone.neutral, this.icon});

  final String label;
  final AdminTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final (bg, fg) = switch (tone) {
      AdminTone.success => (c.tintVertTendre, c.brandDeep),
      AdminTone.warning => (c.tintPlantainClair, c.textPrimary),
      AdminTone.danger => (c.tintPimentClair, c.pimentStrong),
      AdminTone.neutral => (c.background, c.textSecondary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DymTokenSpace.s2,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(DymTokenRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              style: context.dym.text.label.copyWith(
                color: fg,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Chargement, échec ou hors ligne (avec « Réessayer »).
class AdminState extends StatelessWidget {
  const new({required this.failure, required this.onRetry, super.key});

  final Failure? failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final l10n = DymLocalizations.of(context);
    final current = failure;
    if (current == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(DymTokenSpace.s5),
          child: Semantics(
            label: l10n.startupPreparing,
            child: CircularProgressIndicator(color: c.brand),
          ),
        ),
      );
    }
    final offline = current is NetworkFailure;
    return DymStateView(
      kind: offline ? DymStateKind.offline : DymStateKind.error,
      title: offline ? l10n.errorOffline : l10n.errorGeneric,
      message: current is ForbiddenFailure ? l10n.adminAccessDenied : '',
      actionLabel: l10n.retry,
      onAction: onRetry,
    );
  }
}

/// Aucun élément.
class AdminEmpty extends StatelessWidget {
  const new(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(DymTokenSpace.s4),
    child: Text(
      message,
      textAlign: TextAlign.center,
      style: context.dym.text.body.copyWith(
        color: context.dym.colors.textSecondary,
      ),
    ),
  );
}

/// Liste et détail côte à côte en fenêtre large ; l'un ou l'autre sinon.
class AdminSplit extends StatelessWidget {
  const new({
    required this.list,
    required this.detail,
    required this.onCloseDetail,
    super.key,
    this.listFlex = 2,
    this.detailFlex = 3,
  });

  final Widget list;

  /// Nul : rien de sélectionné.
  final Widget? detail;
  final VoidCallback onCloseDetail;
  final int listFlex;
  final int detailFlex;

  @override
  Widget build(BuildContext context) {
    final l10n = DymLocalizations.of(context);
    final wide = DymWindowClass.of(context) >= DymWindowClass.expanded;
    if (wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: listFlex, child: list),
          const SizedBox(width: DymTokenSpace.s3),
          Expanded(
            flex: detailFlex,
            child: detail ?? AdminEmpty(l10n.adminSelectItem),
          ),
        ],
      );
    }
    final d = detail;
    if (d == null) return list;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: onCloseDetail,
          icon: const Icon(Icons.arrow_back_rounded),
          label: Text(l10n.authBack),
        ),
        Expanded(child: d),
      ],
    );
  }
}

/// Ligne étiquette / valeur.
class AdminField extends StatelessWidget {
  const new(this.label, this.value, {super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: t.label.copyWith(color: c.textSecondary)),
          ),
          const SizedBox(width: DymTokenSpace.s2),
          Flexible(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: t.title.copyWith(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}

/// Message d'échec d'un geste.
class AdminAlert extends StatelessWidget {
  const new(this.text, {super.key, this.tone = AdminTone.danger});

  final String text;
  final AdminTone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final (bg, fg) = tone == AdminTone.danger
        ? (c.tintPimentClair, c.pimentStrong)
        : (c.tintPlantainClair, c.textPrimary);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: DymTokenSpace.s2),
      padding: const EdgeInsets.all(DymTokenSpace.s2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(DymTokenRadius.chip),
      ),
      child: Text(
        text,
        style: context.dym.text.label.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Demande une raison (3 caractères au moins) avant un geste.
Future<String?> showReasonDialog(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  bool destructive = false,
}) => showDialog<String>(
  context: context,
  builder: (_) => _ReasonDialog(
    title: title,
    confirmLabel: confirmLabel,
    destructive: destructive,
  ),
);

class _ReasonDialog extends StatefulWidget {
  const new({
    required this.title,
    required this.confirmLabel,
    required this.destructive,
  });

  final String title;
  final String confirmLabel;
  final bool destructive;

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = DymLocalizations.of(context);
    return AlertDialog(
      backgroundColor: context.dym.colors.card,
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        child: DymTextField(
          label: l10n.adminReasonLabel,
          controller: _text,
          autofocus: true,
          maxLength: 200,
          textCapitalization: TextCapitalization.sentences,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        ListenableBuilder(
          listenable: _text,
          builder: (context, _) => DymButton(
            label: widget.confirmLabel,
            expanded: false,
            variant: widget.destructive
                ? DymButtonVariant.destructive
                : DymButtonVariant.primary,
            onPressed: _text.text.trim().length < 3
                ? null
                : () => Navigator.pop(context, _text.text.trim()),
          ),
        ),
      ],
    );
  }
}
