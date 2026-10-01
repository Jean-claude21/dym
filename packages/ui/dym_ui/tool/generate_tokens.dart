// Génère lib/src/tokens/dym_tokens.g.dart depuis docs/design/tokens/dym.tokens.json
// (format W3C Design Tokens). Lancer depuis packages/ui/dym_ui : `melos run tokens`.
import 'dart:convert';
import 'dart:io';

const _source = '../../../docs/design/tokens/dym.tokens.json';
const _target = 'lib/src/tokens/dym_tokens.g.dart';
const _package = 'dym_ui';

void main() {
  final json = jsonDecode(File(_source).readAsStringSync());
  if (json is! Map<String, dynamic>) {
    throw const FormatException('Racine des tokens invalide');
  }
  final tokens = _flatten(json);
  final out = StringBuffer()
    ..writeln('// GÉNÉRÉ — ne pas modifier.')
    ..writeln('// Source : docs/design/tokens/dym.tokens.json')
    ..writeln('// Commande : melos run tokens')
    ..writeln('// ignore_for_file: public_member_api_docs')
    ..writeln()
    ..writeln("import 'dart:ui' show Color, FontFeature, FontWeight, Offset;")
    ..writeln()
    ..writeln(
      "import 'package:flutter/painting.dart' show BoxShadow, TextStyle;",
    )
    ..writeln();

  _writeColors(out, tokens);
  _writeDimensions(out, tokens, 'space', 'DymTokenSpace', prefix: 's');
  _writeDimensions(out, tokens, 'radius', 'DymTokenRadius');
  _writeDimensions(out, tokens, 'size', 'DymTokenSize');
  _writeDimensions(out, tokens, 'breakpoint', 'DymTokenBreakpoints');
  _writeDimensions(out, tokens, 'layout', 'DymTokenLayout');
  _writeFonts(out, tokens);
  _writeTypography(out, tokens);
  _writeShadows(out, tokens);

  File(_target)
    ..createSync(recursive: true)
    ..writeAsStringSync(out.toString());
  stdout.writeln('Tokens générés : ${tokens.length} → $_target');
}

/// Aplati l'arbre DTCG en `chemin.du.token` → {value, type, description}.
Map<String, _Token> _flatten(
  Map<String, dynamic> node, [
  String path = '',
  String? inheritedType,
]) {
  final result = <String, _Token>{};
  final type = (node[r'$type'] as String?) ?? inheritedType;
  for (final entry in node.entries) {
    if (entry.key.startsWith(r'$')) continue;
    final child = entry.value;
    if (child is! Map<String, dynamic>) continue;
    final childPath = path.isEmpty ? entry.key : '$path.${entry.key}';
    if (child.containsKey(r'$value')) {
      result[childPath] = _Token(
        path: childPath,
        type: (child[r'$type'] as String?) ?? type ?? 'unknown',
        value: child[r'$value'],
        description: child[r'$description'] as String?,
      );
    } else {
      result.addAll(_flatten(child, childPath, type));
    }
  }
  return result;
}

/// Résout les alias `{groupe.token}` récursivement.
Object? _resolve(Map<String, _Token> tokens, Object? value) {
  if (value is String && value.startsWith('{') && value.endsWith('}')) {
    final ref = value.substring(1, value.length - 1);
    final target = tokens[ref];
    if (target == null) throw FormatException('Alias inconnu : $value');
    return _resolve(tokens, target.value);
  }
  return value;
}

String _camel(String path) {
  final parts = path.split(RegExp('[.-]')).where((p) => p.isNotEmpty).toList();
  return parts.first +
      parts.skip(1).map((p) => p[0].toUpperCase() + p.substring(1)).join();
}

String _color(String hex) {
  final h = hex.replaceFirst('#', '').toUpperCase();
  if (h.length == 6) return 'Color(0xFF$h)';
  if (h.length == 8) return 'Color(0x${h.substring(6)}${h.substring(0, 6)})';
  throw FormatException('Couleur invalide : $hex');
}

double _px(Object? value) {
  final s = value.toString().replaceAll('px', '');
  return double.parse(s);
}

void _doc(StringBuffer out, _Token t) {
  if (t.description != null) out.writeln('  /// ${t.description}');
}

void _writeColors(StringBuffer out, Map<String, _Token> tokens) {
  out.writeln('abstract final class DymTokenColors {');
  for (final t in tokens.values.where((t) => t.path.startsWith('color.'))) {
    final value = _resolve(tokens, t.value)! as String;
    _doc(out, t);
    out.writeln(
      '  static const ${_camel(t.path.substring(6))} = ${_color(value)};',
    );
  }
  out
    ..writeln('}')
    ..writeln();
}

void _writeDimensions(
  StringBuffer out,
  Map<String, _Token> tokens,
  String group,
  String className, {
  String prefix = '',
}) {
  out.writeln('abstract final class $className {');
  for (final t in tokens.values.where((t) => t.path.startsWith('$group.'))) {
    final name = prefix + _camel(t.path.substring(group.length + 1));
    _doc(out, t);
    final value = _px(_resolve(tokens, t.value));
    out.writeln('  static const double $name = $value;');
  }
  out
    ..writeln('}')
    ..writeln();
}

String _family(Object? value) {
  final list = value is List ? value : [value];
  return list.first.toString().replaceAll(' ', '');
}

void _writeFonts(StringBuffer out, Map<String, _Token> tokens) {
  out
    ..writeln('abstract final class DymTokenFonts {')
    ..writeln("  static const package = '$_package';");
  for (final t in tokens.values.where(
    (t) => t.path.startsWith('font.family.'),
  )) {
    _doc(out, t);
    out.writeln(
      "  static const ${_camel(t.path.substring(12))} = '${_family(t.value)}';",
    );
  }
  out
    ..writeln('}')
    ..writeln();
}

void _writeTypography(StringBuffer out, Map<String, _Token> tokens) {
  out.writeln('abstract final class DymTokenTypography {');
  for (final t in tokens.values.where(
    (t) => t.path.startsWith('typography.'),
  )) {
    final v = t.value! as Map<String, dynamic>;
    final family = _family(_resolve(tokens, v['fontFamily']));
    final weight = v['fontWeight'] as int;
    final size = _px(v['fontSize']);
    final height = (v['lineHeight'] as num).toDouble();
    final tabular = v['fontFeatureSettings'] == 'tnum';
    _doc(out, t);
    out
      ..writeln('  static const ${_camel(t.path.substring(11))} = TextStyle(')
      ..writeln("    fontFamily: '$family',")
      ..writeln("    package: '$_package',")
      ..writeln('    fontWeight: FontWeight.w$weight,')
      ..writeln('    fontSize: $size,')
      ..writeln('    height: $height,');
    if (tabular) {
      out.writeln('    fontFeatures: [FontFeature.tabularFigures()],');
    }
    out.writeln('  );');
  }
  out
    ..writeln('}')
    ..writeln();
}

void _writeShadows(StringBuffer out, Map<String, _Token> tokens) {
  out.writeln('abstract final class DymTokenShadows {');
  for (final t in tokens.values.where((t) => t.path.startsWith('shadow.'))) {
    final v = t.value! as Map<String, dynamic>;
    _doc(out, t);
    out
      ..writeln('  static const ${_camel(t.path.substring(7))} = BoxShadow(')
      ..writeln('    color: ${_color(v['color'] as String)},')
      ..writeln(
        '    offset: Offset(${_px(v['offsetX'])}, ${_px(v['offsetY'])}),',
      )
      ..writeln('    blurRadius: ${_px(v['blur'])},')
      ..writeln('    spreadRadius: ${_px(v['spread'])},')
      ..writeln('  );');
  }
  out.writeln('}');
}

class _Token {
  new({
    required this.path,
    required this.type,
    required this.value,
    this.description,
  });

  final String path;
  final String type;
  final Object? value;
  final String? description;
}
