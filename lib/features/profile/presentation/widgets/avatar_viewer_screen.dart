import 'dart:io';

import 'package:flutter/material.dart';

/// Pantalla simple para ver la foto de perfil en grande, con zoom
/// (pellizcar para acercar) sobre fondo negro. Se usa desde el
/// perfil (para poder ver bien la foto actual, algo que antes no se
/// podía) y desde "Editar perfil" como base para la confirmación al
/// elegir una foto nueva.
class AvatarViewerScreen extends StatelessWidget {
  final File imageFile;
  final String? title;

  const AvatarViewerScreen({
    super.key,
    required this.imageFile,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: title == null
            ? null
            : Text(title!, style: const TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 4,
          child: Image.file(imageFile),
        ),
      ),
    );
  }
}
