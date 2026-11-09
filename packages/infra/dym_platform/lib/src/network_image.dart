import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';

/// Photo distante mise en cache sur l'appareil (spec 026) : une photo déjà vue
/// s'affiche sans nouveau téléchargement, même en 3G. Sur le web, le cache est
/// celui du navigateur.
ImageProvider dymNetworkImage(String url) => CachedNetworkImageProvider(url);
