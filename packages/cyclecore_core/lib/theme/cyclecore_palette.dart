import 'package:flutter/material.dart';

import 'cc_colors.dart';

/// Paleta histórica del cockpit, cinta de pendiente y overlays.
///
/// **Los valores ahora se derivan de [CcColors].** Se mantiene la API
/// (mismos nombres) para no migrar de golpe todos los widgets del mapa;
/// en código nuevo, usa [CcColors] directamente.
///
/// Nota: `paramo` era un naranja aunque el comentario original decía
/// "verde-musgo" -- esa dirección de verde nunca se ejecutó. Ahora es,
/// sin ambigüedad, el naranja de marca ([CcColors.orange]).
class CyclecorePalette {
  CyclecorePalette._();

  /// Fondo base -- carbón azulado.
  static const Color grafito = CcColors.bg;

  /// Superficie de tarjetas/paneles sobre el grafito.
  static const Color panel = CcColors.surfaceHi;

  /// Texto secundario, etiquetas, íconos inactivos.
  static const Color niebla = CcColors.inkDim;

  /// Texto primario, números grandes.
  static const Color hueso = CcColors.ink;

  /// Acento de marca y de pendiente suave/plana.
  static const Color paramo = CcColors.orange;

  /// Color del botón de recentrar el mapa cuando el seguimiento
  /// automático está activo -- azul intenso (contenido blanco encima).
  static const Color ubicacionActiva = CcColors.blueDeep;

  /// Punto intermedio del gradiente de pendiente.
  static const Color _ambarIntermedio = CcColors.slopeMid;

  /// Acento de alerta / pendiente fuerte -- terracota-óxido.
  static const Color oxido = CcColors.slopeHard;

  /// Color continuo de pendiente -- interpola plano → ámbar → óxido
  /// según el % (el signo no importa: lo que se codifica es cuánto
  /// esfuerzo/atención exige el tramo).
  static Color slopeColorFor(double slopePercent) {
    final magnitude = slopePercent.abs().clamp(0.0, 12.0);
    if (magnitude <= 6.0) {
      final t = magnitude / 6.0;
      return Color.lerp(CcColors.slopeFlat, _ambarIntermedio, t)!;
    }
    final t = ((magnitude - 6.0) / 6.0).clamp(0.0, 1.0);
    return Color.lerp(_ambarIntermedio, oxido, t)!;
  }
}
