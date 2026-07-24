import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/cyclecore_palette.dart';
import '../domain/cockpit_field.dart';
import 'cockpit_field_ui.dart';

/// Campos que tiene sentido monitorear como "gauge" -- un subconjunto
/// curado de `CockpitField`. Tiempo y distancia, por ejemplo, no
/// encajan aquí porque no tienen un rango natural que normalizar
/// visualmente (siempre crecen, no hay un "máximo típico").
const List<CockpitField> kLateralGaugeFields = [
  CockpitField.pendiente,
  CockpitField.velocidad,
  CockpitField.frecuenciaCardiaca,
  CockpitField.potencia,
  CockpitField.cadencia,
];

/// Cuál de [kLateralGaugeFields] eligió el usuario para "trackear" de
/// forma visual/dinámica -- se usa en DOS lugares: la barra lateral del
/// mapa (`LateralDataBar`) y, cuando ese mismo campo aparece como tile
/// en el cockpit de pantalla completa, para teñir ese tile con el
/// mismo estilo en vez de duplicar la barra ahí (ver `CockpitGridLayout`).
class _LateralGaugeFieldNotifier extends StateNotifier<CockpitField> {
  static const _prefsKey = 'lateral_gauge_field_v1';

  _LateralGaugeFieldNotifier() : super(CockpitField.pendiente) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return;
    try {
      state = CockpitField.values.byName(raw);
    } catch (_) {
      // Nombre desconocido (versión vieja) -- se ignora, queda el
      // valor por defecto (pendiente).
    }
  }

  Future<void> setField(CockpitField field) async {
    state = field;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, field.name);
  }
}

final lateralGaugeFieldProvider =
    StateNotifierProvider<_LateralGaugeFieldNotifier, CockpitField>(
  (ref) => _LateralGaugeFieldNotifier(),
);

/// Resultado de normalizar el valor actual de un campo: cuánto llenar
/// el gauge (0..1) y con qué color.
class GaugeValue {
  final double fraction;
  final Color color;
  const GaugeValue(this.fraction, this.color);
}

/// Normaliza el valor actual de [field] a 0..1 y decide su color.
///
/// Solo la pendiente usa el gradiente continuo Páramo→Óxido -- ese
/// gradiente comunica "qué tan exigente/peligroso" es el tramo, una
/// semántica que no aplica igual a velocidad o cadencia (más rápido no
/// es "peor"). Los demás campos usan el color propio que ya tienen
/// definido en `CockpitFieldDisplay`, como relleno sólido.
GaugeValue gaugeValueFor(CockpitField field, CockpitLiveData liveData) {
  final display = field.display(liveData);

  switch (field) {
    case CockpitField.pendiente:
      final v = liveData.slopePercent.clamp(-12.0, 12.0);
      return GaugeValue(
        (v + 12) / 24,
        CyclecorePalette.slopeColorFor(liveData.slopePercent),
      );
    case CockpitField.velocidad:
      final v = liveData.currentSpeedKmh.clamp(0.0, 60.0);
      return GaugeValue(v / 60, display.color);
    case CockpitField.frecuenciaCardiaca:
      final bpm = liveData.heartRateBpm;
      if (bpm == null) return GaugeValue(0, display.color);
      final v = bpm.clamp(60, 190);
      return GaugeValue((v - 60) / 130, display.color);
    case CockpitField.potencia:
      final w = liveData.powerWatts;
      if (w == null) return GaugeValue(0, display.color);
      final v = w.clamp(0, 400);
      return GaugeValue(v / 400, display.color);
    case CockpitField.cadencia:
      final rpm = liveData.cadenceRpm;
      if (rpm == null) return GaugeValue(0, display.color);
      final v = rpm.clamp(0, 120);
      return GaugeValue(v / 120, display.color);
    default:
      return GaugeValue(0, display.color);
  }
}
