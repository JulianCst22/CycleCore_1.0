import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Revisa si un sistema de desbloqueos AJENO a profile (ej. las voces de
/// guía) tiene algo nuevo que festejar, y si hay, muestra su propio
/// flujo. Devuelve `true` si mostró algo.
///
/// `ClimbScreen` encadena su propio festejo (el vestidor, que sí es de
/// profile) con uno de estos por cada elemento registrado en
/// `unlockCelebrationSourcesProvider` (ver
/// `presentation/extension_points.dart`) -- así no necesita conocer de
/// qué feature concreta viene cada uno.
typedef UnlockCelebrationCheck = Future<bool> Function(
  BuildContext context,
  WidgetRef ref,
);
