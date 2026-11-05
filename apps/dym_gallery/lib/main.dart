import 'package:dym_gallery/shell/gallery_home.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';

void main() => runApp(const GalleryApp());

/// Galerie de validation du design system DYM (outil interne, non publié).
class GalleryApp extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Galerie DYM',
      debugShowCheckedModeBanner: false,
      theme: DymTheme.light(),
      home: const GalleryHome(),
    );
  }
}
