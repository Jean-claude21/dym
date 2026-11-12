import 'dart:async';

import 'package:dym_client/features/discovery/search_ai_service.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// État de l'écoute (écran 71).
enum VoiceStep { listening, transcribing, heard, nothing, failed }

/// Recherche à la voix : écoute (15 s au plus), transcription par la
/// Function, puis « Tu as dit : … » à confirmer.
class VoiceSearchViewModel extends BaseViewModel {
  new({required this.service, this.maxDuration = const Duration(seconds: 15)});

  final SearchAiService service;
  final Duration maxDuration;

  VoiceStep step = VoiceStep.listening;
  String? heard;
  Failure? failure;
  List<SearchHistoryEntry> history = const [];

  /// Derniers niveaux sonores (onde), du plus ancien au plus récent.
  final levels = List<double>.filled(24, 0.08, growable: true);

  StreamSubscription<double>? _levels;
  Timer? _limit;

  Future<void> init() async {
    _levels = service.recorder.level.listen((v) {
      levels
        ..removeAt(0)
        ..add(v.clamp(0.08, 1));
      notifyListeners();
    });
    if (await service.history() case Ok(:final value)) history = value;
    await listen();
  }

  Future<void> listen() async {
    heard = null;
    failure = null;
    step = VoiceStep.listening;
    notifyListeners();
    final started = await service.recorder.start();
    if (started case Err(failure: final f)) {
      failure = f;
      step = VoiceStep.failed;
      notifyListeners();
      return;
    }
    _limit = Timer(maxDuration, finish);
  }

  /// Fin de l'écoute : transcription.
  Future<void> finish() async {
    _limit?.cancel();
    if (step != VoiceStep.listening) return;
    step = VoiceStep.transcribing;
    notifyListeners();
    final audio = await service.recorder.stop();
    switch (audio) {
      case Err(failure: final f):
        failure = f;
        step = VoiceStep.failed;
      case Ok(value: null):
        step = VoiceStep.nothing;
      case Ok(value: final a?):
        final text = await service.transcribe(a);
        switch (text) {
          case Err(failure: final f):
            failure = f;
            step = VoiceStep.failed;
          case Ok(value: null):
            step = VoiceStep.nothing;
          case Ok(value: final t?):
            heard = t;
            step = VoiceStep.heard;
        }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _limit?.cancel();
    unawaited(_levels?.cancel());
    unawaited(service.recorder.cancel());
    super.dispose();
  }
}

/// Écran 71.
class VoiceSearchView extends StackedView<VoiceSearchViewModel> {
  const new({
    required this.service,
    required this.onBack,
    required this.onSearch,
    super.key,
    this.listenFor = const Duration(seconds: 15),
  });

  final SearchAiService service;

  /// Durée maximale de l'écoute.
  final Duration listenFor;
  final VoidCallback onBack;

  /// Texte à chercher et son origine (voix ou historique).
  final void Function(String text, SearchSource source) onSearch;

  @override
  VoiceSearchViewModel viewModelBuilder(BuildContext context) =>
      VoiceSearchViewModel(service: service, maxDuration: listenFor);

  @override
  void onViewModelReady(VoiceSearchViewModel viewModel) =>
      unawaited(viewModel.init());

  @override
  Widget builder(
    BuildContext context,
    VoiceSearchViewModel viewModel,
    Widget? child,
  ) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final vm = viewModel;
    final listening = vm.step == VoiceStep.listening;
    final status = switch (vm.step) {
      VoiceStep.listening => l10n.voiceListening,
      VoiceStep.transcribing => l10n.voiceTranscribing,
      VoiceStep.heard => l10n.voiceDone,
      VoiceStep.nothing => l10n.voiceNothing,
      VoiceStep.failed => voiceFailureLabel(l10n, vm.failure),
    };
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: DymContentWidth(
          child: ListView(
            padding: EdgeInsets.symmetric(
              horizontal: DymLayout.gutter(context),
              vertical: DymTokenSpace.s3,
            ),
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: l10n.authBack,
                    onPressed: onBack,
                    icon: Icon(Icons.arrow_back_rounded, color: c.textPrimary),
                  ),
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 64),
                      padding: const EdgeInsets.only(left: DymTokenSpace.s3),
                      decoration: BoxDecoration(
                        color: c.card,
                        borderRadius: BorderRadius.circular(
                          DymTokenRadius.chip,
                        ),
                        border: Border.all(color: c.hairline),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search_rounded, color: c.textSecondary),
                          const SizedBox(width: DymTokenSpace.s2),
                          Expanded(
                            child: Semantics(
                              liveRegion: true,
                              child: Text(
                                status,
                                style: t.body.copyWith(color: c.textSecondary),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(DymTokenSpace.s1),
                            child: Material(
                              color: listening ? c.brand : c.tintVertTendre,
                              shape: const CircleBorder(),
                              child: IconButton(
                                iconSize: 28,
                                tooltip: listening
                                    ? l10n.voiceStop
                                    : l10n.voiceRestart,
                                onPressed: vm.step == VoiceStep.transcribing
                                    ? null
                                    : (listening ? vm.finish : vm.listen),
                                icon: Icon(
                                  listening
                                      ? Icons.stop_rounded
                                      : Icons.mic_rounded,
                                  color: listening ? c.card : c.brandDeep,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DymTokenSpace.s5),
              SizedBox(
                height: 140,
                child: ExcludeSemantics(
                  child: _Wave(levels: vm.levels, active: listening),
                ),
              ),
              const SizedBox(height: DymTokenSpace.s3),
              Text(
                l10n.voiceHint,
                textAlign: TextAlign.center,
                style: t.title.copyWith(fontSize: 18),
              ),
              const SizedBox(height: DymTokenSpace.s4),
              if (vm.step == VoiceStep.transcribing)
                const Center(child: CircularProgressIndicator()),
              if (vm.heard case final heard?)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(DymTokenRadius.card),
                    border: Border.all(color: c.hairline),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(DymTokenSpace.s4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text.rich(
                          TextSpan(
                            text: l10n.voiceYouSaid,
                            style: t.title.copyWith(fontSize: 20),
                            children: [
                              TextSpan(
                                text: heard,
                                style: TextStyle(color: c.brandDeep),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: DymTokenSpace.s3),
                        Wrap(
                          spacing: DymTokenSpace.s2,
                          runSpacing: DymTokenSpace.s3,
                          children: [
                            DymButton(
                              label: l10n.voiceSearch,
                              icon: Icons.search_rounded,
                              expanded: false,
                              onPressed: () =>
                                  onSearch(heard, SearchSource.voice),
                            ),
                            DymButton(
                              label: l10n.voiceRestart,
                              icon: Icons.mic_rounded,
                              variant: DymButtonVariant.secondary,
                              expanded: false,
                              onPressed: vm.listen,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              if (vm.step == VoiceStep.nothing || vm.step == VoiceStep.failed)
                Center(
                  child: DymButton(
                    label: l10n.voiceRestart,
                    icon: Icons.mic_rounded,
                    expanded: false,
                    onPressed: vm.listen,
                  ),
                ),
              if (vm.history.isNotEmpty) ...[
                const SizedBox(height: DymTokenSpace.s5),
                Text(l10n.searchHistory, style: t.title),
                const SizedBox(height: DymTokenSpace.s2),
                Wrap(
                  spacing: DymTokenSpace.s2,
                  runSpacing: DymTokenSpace.s2,
                  children: [
                    for (final h in vm.history)
                      ActionChip(
                        avatar: Icon(Icons.history_rounded, color: c.brandDeep),
                        label: Text(h.query),
                        onPressed: () => onSearch(h.query, SearchSource.text),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Message d'un échec de la voix ou de la photo.
String voiceFailureLabel(DymLocalizations l10n, Failure? failure) =>
    switch (failure) {
      ForbiddenFailure() => l10n.voiceMicDenied,
      NetworkFailure() => l10n.errorOffline,
      _ => l10n.aiSearchFailed,
    };

/// Onde : barres jaunes aux bords, vertes au centre (maquette 71).
class _Wave extends StatelessWidget {
  const new({required this.levels, required this.active});

  final List<double> levels;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final n = levels.length;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < n; i++)
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: AnimatedContainer(
                duration: reduce
                    ? Duration.zero
                    : const Duration(milliseconds: 90),
                width: 8,
                height: 140 * levels[i] * (1 - (i - n / 2).abs() / n),
                decoration: BoxDecoration(
                  color: (i - n / 2).abs() < n / 5 ? c.brand : c.tintVertTendre,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
