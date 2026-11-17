import 'dart:typed_data';

import 'package:dym_core/dym_core.dart';
import 'package:file_picker/file_picker.dart';
import 'package:meta/meta.dart';

/// Document prêt à l'envoi dans une conversation (spec 111).
@immutable
class PickedDocument {
  const new({
    required this.bytes,
    required this.name,
    required this.contentType,
  });

  final Uint8List bytes;

  /// Nom du fichier, montré dans la bulle.
  final String name;

  /// Type MIME accepté par le serveur (PDF, Word, Excel, PowerPoint, texte…).
  final String contentType;

  int get size => bytes.length;
}

/// Choix d'un document. `Ok(null)` : annulé ; [ValidationFailure] `too_large`
/// au-delà de [maxDocumentBytes], `unsupported` pour un type refusé.
abstract interface class DocumentPicker {
  Future<Result<PickedDocument?>> pick();
}

/// Types acceptés, par extension (la base vérifie aussi la clé).
const documentTypes = <String, String>{
  'pdf': 'application/pdf',
  'doc': 'application/msword',
  'docx':
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'xls': 'application/vnd.ms-excel',
  'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  'ppt': 'application/vnd.ms-powerpoint',
  'pptx':
      'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  'odt': 'application/vnd.oasis.opendocument.text',
  'ods': 'application/vnd.oasis.opendocument.spreadsheet',
  'txt': 'text/plain',
  'csv': 'text/csv',
};

/// 10 Mo au plus (même limite que la base).
const int maxDocumentBytes = 10 * 1024 * 1024;

/// Implémentation `file_picker` : sélecteur du système, fichier lu en mémoire.
class PluginDocumentPicker implements DocumentPicker {
  const new();

  @override
  Future<Result<PickedDocument?>> pick() async {
    try {
      final picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: documentTypes.keys.toList(),
      );
      final file = picked.firstOrNull;
      if (file == null) return const Ok(null);
      // Taille connue avant lecture : rien n'est chargé au-delà de 10 Mo.
      final size = file.lengthSync() ?? await file.length() ?? 0;
      if (size > maxDocumentBytes) return documentFrom(file.name, null, size);
      return documentFrom(file.name, await file.readAsBytes());
    } on Object catch (error) {
      return Err(
        UnknownFailure('document indisponible : ${error.runtimeType}'),
      );
    }
  }
}

/// Vérifie nom, taille et type d'un fichier choisi.
Result<PickedDocument?> documentFrom(
  String name,
  Uint8List? bytes, [
  int? knownSize,
]) {
  final extension = name.contains('.')
      ? name.split('.').last.toLowerCase()
      : '';
  final type = documentTypes[extension];
  if (type == null) {
    return const Err(
      ValidationFailure('unsupported', fields: {'file': 'unsupported'}),
    );
  }
  if ((bytes?.length ?? knownSize ?? 0) > maxDocumentBytes) {
    return const Err(
      ValidationFailure('too_large', fields: {'file': 'too_large'}),
    );
  }
  if (bytes == null) return const Ok(null);
  final short = name.length > 120 ? name.substring(name.length - 120) : name;
  return Ok(PickedDocument(bytes: bytes, name: short, contentType: type));
}
