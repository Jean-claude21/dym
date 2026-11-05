import 'package:dym_ui/src/components/dym_button.dart';
import 'package:dym_ui/src/components/dym_text_field.dart';
import 'package:dym_ui/src/theme/dym_theme.dart';
import 'package:dym_ui/src/tokens/dym_tokens.g.dart';
import 'package:flutter/material.dart';

/// Lieu proposé par [DymPlacePicker] (quartier d'une ville, par exemple).
@immutable
class DymPlace {
  const new({required this.id, required this.name, this.detail});

  final String id;
  final String name;

  /// Précision affichée après le nom (la ville).
  final String? detail;

  String get fullName => detail == null ? name : '$name, $detail';
}

/// Choix d'un lieu sans liste de noms imposée : position de l'appareil
/// ([onLocate]) ou recherche dans [places]. Aucun lieu n'est affiché avant
/// la saisie ; le lieu choisi est rappelé en tête. Recherche insensible à la
/// casse et aux accents.
class DymPlacePicker extends StatefulWidget {
  /// Crée le sélecteur. Les textes viennent de l'app (localisation).
  const new({
    required this.places,
    required this.selectedId,
    required this.onSelected,
    required this.searchLabel,
    required this.noResultLabel,
    super.key,
    this.searchHint,
    this.onLocate,
    this.locateLabel,
    this.locating = false,
    this.message,
    this.maxResults = 6,
  });

  final List<DymPlace> places;
  final String? selectedId;
  final ValueChanged<String> onSelected;
  final String searchLabel;
  final String? searchHint;

  /// Affiché quand la recherche ne trouve rien.
  final String noResultLabel;

  /// Position de l'appareil ; bouton masqué si nul.
  final VoidCallback? onLocate;
  final String? locateLabel;
  final bool locating;

  /// Message sous le bouton de position (position indisponible…).
  final String? message;
  final int maxResults;

  @override
  State<DymPlacePicker> createState() => _DymPlacePickerState();
}

class _DymPlacePickerState extends State<DymPlacePicker> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  List<DymPlace> get _matches {
    final q = foldForSearch(_query.text);
    if (q.isEmpty) return const [];
    return widget.places
        .where((p) => foldForSearch(p.fullName).contains(q))
        .take(widget.maxResults)
        .toList();
  }

  void _pick(DymPlace place) {
    _query.clear();
    FocusScope.of(context).unfocus();
    widget.onSelected(place.id);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final selected = widget.places
        .where((p) => p.id == widget.selectedId)
        .firstOrNull;
    final matches = _matches;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (selected != null) ...[
          Semantics(
            selected: true,
            child: Container(
              padding: const EdgeInsets.all(DymTokenSpace.s4),
              decoration: BoxDecoration(
                color: c.tintPlantainClair,
                borderRadius: BorderRadius.circular(DymTokenRadius.tile),
                border: Border.all(color: c.card, width: 2),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on_rounded, color: c.brand, size: 28),
                  const SizedBox(width: DymTokenSpace.s3),
                  Expanded(
                    child: Text(
                      selected.fullName,
                      style: t.title.copyWith(fontSize: 19),
                    ),
                  ),
                  Icon(Icons.check_circle_rounded, color: c.brand),
                ],
              ),
            ),
          ),
          const SizedBox(height: DymTokenSpace.s3),
        ],
        if (widget.onLocate != null) ...[
          DymButton(
            label: widget.locateLabel ?? '',
            icon: Icons.my_location_rounded,
            variant: DymButtonVariant.secondary,
            loading: widget.locating,
            onPressed: widget.locating ? null : widget.onLocate,
          ),
          if (widget.message case final message?) ...[
            const SizedBox(height: DymTokenSpace.s2),
            Text(
              message,
              style: t.label.copyWith(color: c.textSecondary, fontSize: 14),
            ),
          ],
          const SizedBox(height: DymTokenSpace.s3),
        ],
        DymTextField(
          label: widget.searchLabel,
          hint: widget.searchHint,
          controller: _query,
          icon: Icons.search_rounded,
          textInputAction: TextInputAction.search,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) {
            if (matches.length == 1) _pick(matches.single);
          },
        ),
        if (_query.text.trim().isNotEmpty) ...[
          const SizedBox(height: DymTokenSpace.s2),
          if (matches.isEmpty)
            Padding(
              padding: const EdgeInsets.all(DymTokenSpace.s2),
              child: Text(
                widget.noResultLabel,
                style: t.label.copyWith(color: c.textSecondary, fontSize: 15),
              ),
            )
          else
            for (final place in matches)
              _PlaceRow(place: place, onTap: () => _pick(place)),
        ],
      ],
    );
  }
}

class _PlaceRow extends StatelessWidget {
  const new({required this.place, required this.onTap});

  final DymPlace place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    return Semantics(
      button: true,
      label: place.fullName,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DymTokenRadius.tile),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DymTokenSpace.s2,
              vertical: DymTokenSpace.s2,
            ),
            child: Row(
              children: [
                Icon(Icons.place_outlined, color: c.textSecondary),
                const SizedBox(width: DymTokenSpace.s3),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: place.name,
                      style: t.title.copyWith(fontSize: 17),
                      children: [
                        if (place.detail case final detail?)
                          TextSpan(
                            text: '  $detail',
                            style: t.label.copyWith(
                              color: c.textSecondary,
                              fontSize: 15,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

const _folds = {
  'àáâãäåā': 'a',
  'çćč': 'c',
  'èéêëēė': 'e',
  'ìíîïī': 'i',
  'ñń': 'n',
  'òóôõöøō': 'o',
  'ùúûüū': 'u',
  'ýÿ': 'y',
  'ɛ': 'e',
  'ɔ': 'o',
  'œ': 'oe',
  'æ': 'ae',
};

final Map<String, String> _foldTable = {
  for (final MapEntry(:key, :value) in _folds.entries)
    for (final char in key.split('')) char: value,
};

/// Texte comparable pour la recherche : minuscules, sans accents, espaces
/// réduits.
String foldForSearch(String text) {
  final buffer = StringBuffer();
  for (final char in text.toLowerCase().trim().split('')) {
    buffer.write(_foldTable[char] ?? char);
  }
  return buffer.toString().replaceAll(RegExp(r'\s+'), ' ');
}
