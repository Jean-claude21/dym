import 'dart:async';

import 'package:dym_client/features/discovery/copilot/copilot_service.dart';
import 'package:dym_client/features/discovery/search/voice_search_view.dart';
import 'package:dym_client/features/discovery/search_ai_service.dart';
import 'package:dym_client/features/discovery/widgets/discovery_widgets.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_platform/dym_platform.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Copilote d'intention (écran 73) : intention → panier proposé, chiffré
/// par la base ; retrait d'une ligne (rechiffrage), tout ajouter, ou retour
/// à la recherche classique.
class CopilotViewModel extends BaseViewModel {
  new({required this.service, this.ai});

  final CopilotService service;

  /// Voix et photo (spec 018) ; absent ou coupé : texte seul.
  final SearchAiService? ai;

  CountryConfig? config;
  bool aiEnabled = false;
  String? asked;
  CopilotProposal? proposal;
  Failure? failure;
  bool thinking = false;
  String? removing;
  bool adding = false;

  /// Lignes refusées par le panier (rupture entre-temps).
  List<CopilotLine> refused = const [];

  Future<void> init({String? initialText}) async {
    config = (await service.countryConfig()).valueOrNull;
    aiEnabled = await ai?.aiEnabled() ?? false;
    notifyListeners();
    if (initialText != null && initialText.trim().length >= 2) {
      await ask(initialText);
    }
  }

  Future<void> ask(String text) async {
    final value = text.trim();
    if (value.length < 2 || thinking) return;
    asked = value;
    proposal = null;
    failure = null;
    refused = const [];
    thinking = true;
    notifyListeners();
    switch (await service.propose(value)) {
      case Ok(:final value):
        proposal = value;
      case Err(failure: final f):
        failure = f;
    }
    thinking = false;
    notifyListeners();
  }

  Future<void> remove(CopilotLine line) async {
    final current = proposal;
    if (current == null || removing != null) return;
    removing = line.variantId;
    notifyListeners();
    switch (await service.remove(current, line.variantId)) {
      case Ok(:final value):
        proposal = value;
      case Err(failure: final f):
        failure = f;
    }
    removing = null;
    notifyListeners();
  }

  /// `true` : tout est au panier.
  Future<bool> addAll() async {
    final current = proposal;
    if (current == null || current.isEmpty || adding) return false;
    adding = true;
    notifyListeners();
    refused = await service.addAll(current);
    adding = false;
    notifyListeners();
    return refused.isEmpty;
  }

  /// Photo d'un plat ou d'un produit : décrite, puis demandée au copilote.
  Future<void> askPhoto(PhotoSource source) async {
    final ai = this.ai;
    if (ai == null) return;
    final picked = await ai.pickPhoto(source);
    if (picked case Ok(value: final p?)) {
      thinking = true;
      notifyListeners();
      final described = await ai.describePhoto(p);
      thinking = false;
      switch (described) {
        case Ok(value: final text?):
          await ask(text);
        case Ok(value: null):
          failure = const ValidationFailure('photo_unrecognized');
          notifyListeners();
        case Err(failure: final f):
          failure = f;
          notifyListeners();
      }
    }
  }
}

/// Écran 73. Avec [title] (liste de courses, spec 029) : proposition lancée
/// à l'ouverture, sans zone de saisie.
class CopilotView extends StackedView<CopilotViewModel> {
  const new({
    required this.service,
    required this.onBack,
    required this.onAdded,
    super.key,
    this.onSearchMyself,
    this.ai,
    this.initialText,
    this.title,
  });

  final CopilotService service;
  final SearchAiService? ai;
  final VoidCallback onBack;

  /// Recherche classique avec le texte de l'intention ; absente : masquée.
  final ValueChanged<String>? onSearchMyself;

  /// Tout est au panier : ouvrir le panier.
  final VoidCallback onAdded;
  final String? initialText;

  /// Titre fixe (liste de courses) : ni bulle d'intention ni saisie.
  final String? title;

  @override
  CopilotViewModel viewModelBuilder(BuildContext context) =>
      CopilotViewModel(service: service, ai: ai);

  @override
  void onViewModelReady(CopilotViewModel viewModel) =>
      unawaited(viewModel.init(initialText: initialText));

  @override
  Widget builder(
    BuildContext context,
    CopilotViewModel viewModel,
    Widget? child,
  ) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final vm = viewModel;
    final p = vm.proposal;
    final gutter = DymLayout.gutter(context);
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: DymContentWidth(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(gutter, 4, gutter, gutter),
                  children: [
                    Row(
                      children: [
                        IconButton(
                          tooltip: l10n.authBack,
                          onPressed: onBack,
                          icon: Icon(
                            Icons.arrow_back_rounded,
                            color: c.textPrimary,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            title ?? l10n.copilotTitle,
                            style: t.display.copyWith(fontSize: 26),
                          ),
                        ),
                      ],
                    ),
                    if (title != null)
                      const SizedBox.shrink()
                    else if (vm.asked case final asked?)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          margin: const EdgeInsets.only(
                            top: DymTokenSpace.s2,
                            left: DymTokenSpace.s5,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: DymTokenSpace.s3,
                            vertical: DymTokenSpace.s2,
                          ),
                          decoration: BoxDecoration(
                            color: c.brand,
                            borderRadius: BorderRadius.circular(
                              DymTokenRadius.tile,
                            ),
                          ),
                          child: Text(
                            asked,
                            style: t.body.copyWith(color: c.card),
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(top: DymTokenSpace.s3),
                        child: Text(
                          l10n.copilotExample,
                          style: t.body.copyWith(color: c.textSecondary),
                        ),
                      ),
                    const SizedBox(height: DymTokenSpace.s3),
                    if (vm.thinking)
                      _Note(
                        icon: Icons.auto_awesome_rounded,
                        text: l10n.copilotThinking,
                        busy: true,
                      )
                    else if (vm.failure case final f?) ...[
                      _Note(
                        icon: Icons.info_rounded,
                        text: f.message == 'photo_unrecognized'
                            ? l10n.photoSearchNothing
                            : (f is NetworkFailure
                                  ? l10n.errorOffline
                                  : l10n.copilotUnavailable),
                      ),
                      const SizedBox(height: DymTokenSpace.s3),
                      if ((onSearchMyself, vm.asked) case (
                        final search?,
                        final asked?,
                      ))
                        DymButton(
                          label: l10n.copilotSearchMyself,
                          icon: Icons.search_rounded,
                          variant: DymButtonVariant.secondary,
                          onPressed: () => search(asked),
                        ),
                    ] else if (p != null)
                      _Proposal(vm: vm, proposal: p),
                    if (p != null && !p.isEmpty) ...[
                      const SizedBox(height: DymTokenSpace.s3),
                      if (vm.refused.isNotEmpty)
                        _Note(
                          icon: Icons.warning_amber_rounded,
                          text: l10n.copilotRefused(
                            vm.refused.map((l) => l.name).join(', '),
                          ),
                        ),
                      DymButton(
                        label: l10n.copilotAddAll,
                        icon: Icons.add_shopping_cart_rounded,
                        loading: vm.adding,
                        onPressed: vm.adding
                            ? null
                            : () async {
                                if (await vm.addAll()) onAdded();
                              },
                      ),
                      if (onSearchMyself case final search?) ...[
                        const SizedBox(height: DymTokenSpace.s2),
                        DymButton(
                          label: l10n.copilotSearchMyself,
                          icon: Icons.search_rounded,
                          variant: DymButtonVariant.secondary,
                          onPressed: () => search(vm.asked ?? ''),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              if (title == null) _InputBar(vm: vm),
            ],
          ),
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const new({required this.icon, required this.text, this.busy = false});

  final IconData icon;
  final String text;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    return Container(
      margin: const EdgeInsets.only(bottom: DymTokenSpace.s2),
      padding: const EdgeInsets.all(DymTokenSpace.s3),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(DymTokenRadius.tile),
      ),
      child: Row(
        children: [
          if (busy)
            const SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 3),
            )
          else
            Icon(icon, color: c.textSecondary),
          const SizedBox(width: DymTokenSpace.s2),
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: Text(text, style: t.body),
            ),
          ),
        ],
      ),
    );
  }
}

class _Proposal extends StatelessWidget {
  const new({required this.vm, required this.proposal});

  final CopilotViewModel vm;
  final CopilotProposal proposal;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final p = proposal;
    if (p.isEmpty) {
      return _Note(
        icon: Icons.search_off_rounded,
        text: [
          l10n.copilotNothing,
          if (p.missing.isNotEmpty) l10n.copilotMissing(p.missing.join(', ')),
        ].join(' '),
      );
    }
    final total = moneyOf(vm.config, p.totalMinor);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(DymTokenRadius.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DymTokenSpace.s3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: c.tintVertTendre,
                  child: Icon(Icons.auto_awesome_rounded, color: c.brandDeep),
                ),
                const SizedBox(width: DymTokenSpace.s2),
                Expanded(
                  child: Text(
                    l10n.copilotProposal,
                    style: t.title.copyWith(fontSize: 20),
                  ),
                ),
              ],
            ),
            for (final store in p.stores) ...[
              const Divider(height: DymTokenSpace.s4),
              Text(store.name, style: t.title.copyWith(fontSize: 18)),
              for (final line in store.lines)
                _Line(
                  vm: vm,
                  line: line,
                  removing: vm.removing == line.variantId,
                ),
            ],
            if (p.missing.isNotEmpty) ...[
              const SizedBox(height: DymTokenSpace.s2),
              _Note(
                icon: Icons.info_rounded,
                text: l10n.copilotMissing(p.missing.join(', ')),
              ),
            ],
            const Divider(height: DymTokenSpace.s4),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: DymTokenSpace.s1,
              children: [
                if (total != null)
                  MoneyText(total, size: 26, color: c.brandDeep),
                Text(
                  l10n.copilotPlusDelivery,
                  style: t.title.copyWith(color: c.brandDeep),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const new({required this.vm, required this.line, required this.removing});

  final CopilotViewModel vm;
  final CopilotLine line;
  final bool removing;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final price = moneyOf(vm.config, line.lineMinor);
    final locale = Localizations.localeOf(context).languageCode;
    final unit = line.variantLabel ?? line.unitLabel?.resolve(locale);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DymTokenSpace.s1),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(DymTokenRadius.tile / 2),
            child: SizedBox.square(
              dimension: 56,
              child: line.photoKey == null
                  ? ColoredBox(color: c.tintVertTendre)
                  : Image(
                      image: vm.service.photo(line.photoKey!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          ColoredBox(color: c.tintVertTendre),
                    ),
            ),
          ),
          const SizedBox(width: DymTokenSpace.s2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(line.name, style: t.title.copyWith(fontSize: 16)),
                Text(
                  [
                    '${line.quantity}${unit == null ? '' : ' $unit'}',
                    ?price?.format(),
                  ].join(' · '),
                  style: t.body.copyWith(color: c.brandDeep),
                ),
                if (line.reason case final reason?)
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 16,
                        color: c.textSecondary,
                      ),
                      const SizedBox(width: DymTokenSpace.s1),
                      Flexible(
                        child: Text(
                          copilotReasonLabel(l10n, reason),
                          style: t.label.copyWith(color: c.textSecondary),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: l10n.copilotRemove(line.name),
            onPressed: vm.removing == null ? () => vm.remove(line) : null,
            icon: removing
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.close_rounded, color: c.pimentStrong),
            style: IconButton.styleFrom(backgroundColor: c.tintPimentClair),
          ),
        ],
      ),
    );
  }
}

/// Saisie de l'intention : texte, voix et photo (si `ai_search` est actif).
class _InputBar extends StatefulWidget {
  const new({required this.vm});

  final CopilotViewModel vm;

  @override
  State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _voice() async {
    final ai = widget.vm.ai;
    if (ai == null) return;
    final chosen = await Navigator.of(context).push<(String, SearchSource)>(
      MaterialPageRoute(
        builder: (route) => VoiceSearchView(
          service: ai,
          onBack: () => Navigator.of(route).pop(),
          onSearch: (text, source) => Navigator.of(route).pop((text, source)),
        ),
      ),
    );
    if (chosen case (final text, _)) await widget.vm.ask(text);
  }

  Future<void> _photo() async {
    final l10n = DymLocalizations.of(context);
    final source = await showModalBottomSheet<PhotoSource>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              minTileHeight: 56,
              leading: const Icon(Icons.photo_camera_rounded),
              title: Text(l10n.photoTake),
              onTap: () => Navigator.of(sheet).pop(PhotoSource.camera),
            ),
            ListTile(
              minTileHeight: 56,
              leading: const Icon(Icons.photo_library_rounded),
              title: Text(l10n.photoFromGallery),
              onTap: () => Navigator.of(sheet).pop(PhotoSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source != null) await widget.vm.askPhoto(source);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final l10n = DymLocalizations.of(context);
    final vm = widget.vm;
    void send() {
      final text = _text.text;
      _text.clear();
      unawaited(vm.ask(text));
    }

    return Padding(
      padding: EdgeInsets.all(DymLayout.gutter(context) / 2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: DymTokenSpace.s1),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(DymTokenRadius.tile),
        ),
        child: Row(
          children: [
            if (vm.aiEnabled) ...[
              IconButton(
                tooltip: l10n.voiceSearchAction,
                onPressed: vm.thinking ? null : _voice,
                icon: Icon(Icons.mic_rounded, color: c.brandDeep),
              ),
              IconButton(
                tooltip: l10n.photoSearchAction,
                onPressed: vm.thinking ? null : _photo,
                icon: Icon(Icons.photo_camera_rounded, color: c.brandDeep),
              ),
            ],
            Expanded(
              child: TextField(
                controller: _text,
                minLines: 1,
                maxLines: 3,
                maxLength: 300,
                textInputAction: TextInputAction.send,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => send(),
                decoration: InputDecoration(
                  hintText: l10n.copilotHint,
                  counterText: '',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: DymTokenSpace.s2,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: l10n.copilotSend,
              onPressed: vm.thinking ? null : send,
              icon: Icon(Icons.send_rounded, color: c.brand),
            ),
          ],
        ),
      ),
    );
  }
}

/// Raison du choix, en clair (spec 028).
String copilotReasonLabel(DymLocalizations l10n, CopilotReason reason) =>
    switch (reason) {
      CopilotReason.sameStore => l10n.copilotReasonSameStore,
      CopilotReason.openNow => l10n.copilotReasonOpenNow,
      CopilotReason.topRated => l10n.copilotReasonTopRated,
      CopilotReason.bestPrice => l10n.copilotReasonBestPrice,
      CopilotReason.nearby => l10n.copilotReasonNearby,
      CopilotReason.bestMatch => l10n.copilotReasonBestMatch,
    };
