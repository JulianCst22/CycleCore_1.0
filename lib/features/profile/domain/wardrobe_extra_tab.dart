import 'package:flutter/widgets.dart';

/// Una pestaña que otro feature quiere agregar al Vestidor (ej. "Voz",
/// del feature `voice`) -- así `WardrobeScreen` no necesita conocer qué
/// feature concreta la provee.
class WardrobeExtraTab {
  final String label;
  final WidgetBuilder builder;

  const WardrobeExtraTab({required this.label, required this.builder});
}
