import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/coaching/coaching.dart';
import '../features/cockpit/cockpit.dart';

/// Une lo que el coach dice con lo que el cockpit muestra: cada número
/// hablado apunta al recuadro que lo tiene en pantalla (ADR-6).
///
/// Vive en la raíz de composición a propósito: el cockpit no conoce al
/// coach y el coach no conoce al cockpit; solo la app sabe que el
/// «objetivo de potencia» que se dice en voz alta y el recuadro de
/// potencia son el mismo dato. `main.dart` registra este proveedor en el
/// punto de extensión del cockpit.

/// Recuadro que le toca a cada número que el coach puede decir. Los que
/// no tienen recuadro (los metros que faltan, la ventaja al récord) no
/// resaltan nada.
CockpitField? cockpitFieldOf(MessageValue value) => switch (value) {
  MessageValue.potencia ||
  MessageValue.deltaPotencia ||
  MessageValue.potenciaActual ||
  MessageValue.piso => CockpitField.potencia,
  MessageValue.cadencia || MessageValue.cadenciaActual => CockpitField.cadencia,
  MessageValue.pulso ||
  MessageValue.pulsoObjetivo => CockpitField.frecuenciaCardiaca,
  MessageValue.pendiente || MessageValue.rampa => CockpitField.pendiente,
  MessageValue.desnivel => CockpitField.desnivel,
  MessageValue.metrosRampa ||
  MessageValue.metrosRestantes ||
  MessageValue.kmRestantes ||
  MessageValue.ventaja => null,
};

/// Campos del cockpit que el coach acaba de nombrar.
final coachMentionedFieldsProvider = Provider<Set<CockpitField>>((ref) {
  final mentioned = ref.watch(coachMentionedValuesProvider);
  return {for (final value in mentioned) ?cockpitFieldOf(value)};
});
