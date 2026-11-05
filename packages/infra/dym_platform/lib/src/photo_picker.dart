import 'dart:typed_data';

import 'package:dym_core/dym_core.dart';
import 'package:image_picker/image_picker.dart';
import 'package:meta/meta.dart';

/// Source d'une photo.
enum PhotoSource { camera, gallery }

/// Photo prête à l'envoi : compressée sur l'appareil.
@immutable
class PickedPhoto {
  const new({required this.bytes, required this.contentType});

  final Uint8List bytes;

  /// `image/jpeg` ou `image/webp`.
  final String contentType;
}

/// Prise ou choix d'une photo. `null` : annulé par l'utilisatrice.
abstract interface class PhotoPicker {
  Future<Result<PickedPhoto?>> pick(PhotoSource source);
}

/// Implémentation `image_picker` : 1 600 px au plus, qualité 80 (réseau 3G,
/// architecture « images compressées sur l'appareil »).
class PluginPhotoPicker implements PhotoPicker {
  new([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  static const maxSide = 1600.0;
  static const quality = 80;

  @override
  Future<Result<PickedPhoto?>> pick(PhotoSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source == PhotoSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: maxSide,
        maxHeight: maxSide,
        imageQuality: quality,
        requestFullMetadata: false,
      );
      if (file == null) return const Ok(null);
      final bytes = await file.readAsBytes();
      final type = file.mimeType ?? _typeOf(file.name);
      return Ok(PickedPhoto(bytes: bytes, contentType: type));
    } on Object catch (error) {
      return Err(UnknownFailure('photo indisponible : ${error.runtimeType}'));
    }
  }

  static String _typeOf(String name) =>
      name.toLowerCase().endsWith('.webp') ? 'image/webp' : 'image/jpeg';
}
