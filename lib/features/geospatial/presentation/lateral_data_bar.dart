import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/cyclecore_palette.dart';
import '../domain/cockpit_field.dart';
import 'cockpit_field_ui.dart';
import 'gps_status_widgets.dart';

/// Campos que tiene sentido monitorear como "gauge" lateral -- un
/// subconjunto curado de `CockpitField`. Tiempo y distancia, por
/// ejemplo, no encajan aquí porque no tienen un rango natural que
/// normalizar visualmente (siempre crecen, no hay un "máximo típico").
const List<CockpitField> kLateralGaugeFields = [
  CockpitField.pendiente,
  CockpitField.velocidad,
  CockpitField.frecuenciaCardiaca,
  CockpitField.potencia,
  CockpitField.cadencia,
];

/// Persiste qué campo eligió el usuario para la barra lateral --
/// SharedPreferences directo (no hace falta el mismo mecanismo de
/// migración que el cockpit, es un solo valor).
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

/// Normaliza el valor actual de [field] a 0..1 (cuánto llenar la
/// barra) y decide su color.
///
/// Solo la pendiente usa el gradiente continuo Páramo→Óxido -- ese
/// gradiente comunica "qué tan exigente/peligroso" es el tramo, una
/// semántica que no aplica igual a velocidad o cadencia (más rápido no
/// es "peor"). Los demás campos usan el color propio que ya tienen
/// definido en `CockpitFieldDisplay`, como relleno sólido.
class _GaugeValue {
  final double fraction;
  final Color color;
  const _GaugeValue(this.fraction, this.color);
}

_GaugeValue _gaugeValueFor(CockpitField field, CockpitLiveData liveData) {
  final display = field.display(liveData);

  switch (field) {
    case CockpitField.pendiente:
      final v = liveData.slopePercent.clamp(-12.0, 12.0);
      return _GaugeValue(
        (v + 12) / 24,
        CyclecorePalette.slopeColorFor(liveData.slopePercent),
      );
    case CockpitField.velocidad:
      final v = liveData.currentSpeedKmh.clamp(0.0, 60.0);
      return _GaugeValue(v / 60, display.color);
    case CockpitField.frecuenciaCardiaca:
      final bpm = liveData.heartRateBpm;
      if (bpm == null) return _GaugeValue(0, display.color);
      final v = bpm.clamp(60, 190);
      return _GaugeValue((v - 60) / 130, display.color);
    case CockpitField.potencia:
      final w = liveData.powerWatts;
      if (w == null) return _GaugeValue(0, display.color);
      final v = w.clamp(0, 400);
      return _GaugeValue(v / 400, display.color);
    case CockpitField.cadencia:
      final rpm = liveData.cadenceRpm;
      if (rpm == null) return _GaugeValue(0, display.color);
      final v = rpm.clamp(0, 120);
      return _GaugeValue(v / 120, display.color);
    default:
      return _GaugeValue(0, display.color);
  }
}

/// Barra lateral tipo "indicador de tráfico" de Waze/Google Maps: un
/// gauge vertical fijo al costado del mapa, siempre visible mientras se
/// graba, sin importar si el cockpit está compacto o en pantalla
/// completa -- es independiente de ese panel, igual que el indicador de
/// tráfico no depende de si tienes abierta la vista de direcciones.
///
/// El ícono de arriba es tocable: abre un selector para elegir qué
/// dato mostrar aquí (por defecto, pendiente). La elección se recuerda
/// entre sesiones.
class LateralDataBar extends ConsumerWidget {
  final CockpitLiveData liveData;
  final bool isApproximate;

  const LateralDataBar({
    super.key,
    required this.liveData,
    required this.isApproximate,
  });

  Future<void> _pickField(BuildContext context, WidgetRef ref) async {
    final current = ref.read(lateralGaugeFieldProvider);
    final picked = await showModalBottomSheet<CockpitField>(
      context: context,
      backgroundColor: CyclecorePalette.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Text(
                'Mostrar en la barra lateral',
                style: TextStyle(
                  color: AppColors.textPrimaryOnPanel,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            ...kLateralGaugeFields.map((f) {
              final selected = f == current;
              return ListTile(
                leading: Icon(f.icon, color: f.color),
                title: Text(
                  f.label,
                  style: const TextStyle(color: AppColors.textPrimaryOnPanel),
                ),
                trailing: selected
                    ? const Icon(Icons.check, color: CyclecorePalette.paramo)
                    : null,
                onTap: () => Navigator.of(context).pop(f),
              );
            }),
          ],
        ),
      ),
    );
    if (picked != null) {
      await ref.read(lateralGaugeFieldProvider.notifier).setField(picked);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final field = ref.watch(lateralGaugeFieldProvider);
    final display = field.display(liveData);
    final gauge = _gaugeValueFor(field, liveData);
    final isSlope = field == CockpitField.pendiente;

    return Container(
      width: 46,
      decoration: BoxDecoration(
        color: CyclecorePalette.panel.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 10),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // El relleno tipo gauge -- crece desde abajo, con animación
          // suave para no saltar con cada muestra nueva. En modo
          // aproximado (sin DEM confiable / posible puente) se atenúa
          // en vez de mostrarse a toda intensidad, comunicando "esto es
          // menos certero" sin necesitar texto.
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedFractionallySizedBox(
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOut,
              heightFactor: gauge.fraction.clamp(0.03, 1.0),
              widthFactor: 1,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 450),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      gauge.color.withValues(
                        alpha: (isSlope && isApproximate) ? 0.45 : 0.85,
                      ),
                      gauge.color.withValues(
                        alpha: (isSlope && isApproximate) ? 0.2 : 0.4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Ícono arriba -- tocable, abre el selector de campo.
          Positioned(
            top: 10,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () => _pickField(context, ref),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    display.icon,
                    size: 18,
                    color: AppColors.textPrimaryOnPanel,
                  ),
                ),
              ),
            ),
          ),

          // Badge de "modo aproximado" -- solo aplica cuando el campo
          // mostrado es pendiente. Reutiliza el mismo bottom sheet
          // explicativo que ya existe en el mapa.
          if (isSlope && isApproximate)
            const Positioned(
              top: 4,
              right: 4,
              child: ApproximateElevationBadge(),
            ),

          // Valor + unidad -- siempre abajo, fijo (no se mueve con el
          // relleno, para que sea legible sin perseguir el gauge).
          Positioned(
            bottom: 10,
            left: 2,
            right: 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    display.value,
                    style: const TextStyle(
                      color: AppColors.textPrimaryOnPanel,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (display.unit.isNotEmpty)
                  Text(
                    display.unit,
                    style: const TextStyle(
                      color: AppColors.textSecondaryOnPanel,
                      fontSize: 9,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
