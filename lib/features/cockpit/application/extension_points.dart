import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/cockpit_field.dart';

/// Punto de extensión del cockpit para features ajenas: vacío por
/// defecto, se completa una sola vez desde la raíz de composición de la
/// app (ver `main.dart`). El cockpit nunca importa esas features.

/// Campos que el coach acaba de nombrar en voz alta. El cockpit resalta
/// su recuadro unos segundos para que el oído y la vista apunten al
/// mismo dato (ADR-6). Vacío mientras nadie los registre.
final mentionedFieldsProvider = Provider<Set<CockpitField>>((ref) => const {});
