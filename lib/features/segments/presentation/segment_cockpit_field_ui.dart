import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format_utils.dart';
import '../domain/segment_cockpit_field.dart';

/// Valor ya formateado (ícono, color, etiqueta, valor, unidad) de un
/// `SegmentCockpitField`, listo para pintar en un tile -- mismo shape
/// que `CockpitFieldDisplay` del mapa.
class SegmentFieldDisplay {
  final String label;
  final IconData icon;
  final Color color;
  final String value;
  final String unit;

  const SegmentFieldDisplay({
    required this.label,
    required this.icon,
    required this.color,
    required this.value,
    required this.unit,
  });
}

extension SegmentCockpitFieldX on SegmentCockpitField {
  String get label {
    switch (this) {
      case SegmentCockpitField.mapaSegmento:
        return 'MAPA';
      case SegmentCockpitField.perfilAltimetria:
        return 'PERFIL';
      case SegmentCockpitField.barraProgreso:
        return 'PROGRESO';
      case SegmentCockpitField.tiempoEnSegmento:
        return 'TIEMPO';
      case SegmentCockpitField.deltaPr:
        return 'Δ vs PR';
      case SegmentCockpitField.proyeccionMeta:
        return 'META EST.';
      case SegmentCockpitField.mejorTiempo:
        return 'MEJOR TIEMPO';
      case SegmentCockpitField.distanciaRecorrida:
        return 'RECORRIDO';
      case SegmentCockpitField.distanciaRestante:
        return 'RESTANTE';
      case SegmentCockpitField.progreso:
        return 'PROGRESO';
      case SegmentCockpitField.desnivelRestante:
        return 'DESNIVEL REST.';
      case SegmentCockpitField.pendienteActual:
        return 'PENDIENTE';
      case SegmentCockpitField.pendienteMediaSegmento:
        return 'PEND. MEDIA';
      case SegmentCockpitField.velocidad:
        return 'VELOCIDAD';
      case SegmentCockpitField.velocidadMediaSegmento:
        return 'VEL. MEDIA SEG.';
      case SegmentCockpitField.frecuenciaCardiaca:
        return 'FRECUENCIA CARDÍACA';
      case SegmentCockpitField.potencia:
        return 'POTENCIA';
      case SegmentCockpitField.cadencia:
        return 'CADENCIA';
      case SegmentCockpitField.altitud:
        return 'ALTITUD';
    }
  }

  IconData get icon {
    switch (this) {
      case SegmentCockpitField.mapaSegmento:
        return Icons.map_outlined;
      case SegmentCockpitField.perfilAltimetria:
        return Icons.show_chart;
      case SegmentCockpitField.barraProgreso:
        return Icons.linear_scale;
      case SegmentCockpitField.tiempoEnSegmento:
      case SegmentCockpitField.mejorTiempo:
        return Icons.timer_outlined;
      case SegmentCockpitField.deltaPr:
        return Icons.compare_arrows;
      case SegmentCockpitField.proyeccionMeta:
        return Icons.flag_outlined;
      case SegmentCockpitField.distanciaRecorrida:
        return Icons.straighten;
      case SegmentCockpitField.distanciaRestante:
        return Icons.trending_flat;
      case SegmentCockpitField.progreso:
        return Icons.donut_large;
      case SegmentCockpitField.desnivelRestante:
        return Icons.terrain;
      case SegmentCockpitField.pendienteActual:
      case SegmentCockpitField.pendienteMediaSegmento:
        return Icons.trending_up;
      case SegmentCockpitField.velocidad:
      case SegmentCockpitField.velocidadMediaSegmento:
        return Icons.speed;
      case SegmentCockpitField.frecuenciaCardiaca:
        return Icons.favorite;
      case SegmentCockpitField.potencia:
        return Icons.electric_bolt;
      case SegmentCockpitField.cadencia:
        return Icons.autorenew;
      case SegmentCockpitField.altitud:
        return Icons.height;
    }
  }

  Color get color {
    switch (this) {
      case SegmentCockpitField.mapaSegmento:
      case SegmentCockpitField.perfilAltimetria:
      case SegmentCockpitField.barraProgreso:
        return AppColors.segmentActiveTrack;
      case SegmentCockpitField.tiempoEnSegmento:
      case SegmentCockpitField.mejorTiempo:
      case SegmentCockpitField.proyeccionMeta:
        return AppColors.accentTime;
      case SegmentCockpitField.deltaPr:
        return AppColors.segmentActiveTrack;
      case SegmentCockpitField.distanciaRecorrida:
      case SegmentCockpitField.distanciaRestante:
      case SegmentCockpitField.progreso:
        return AppColors.accentDistance;
      case SegmentCockpitField.desnivelRestante:
      case SegmentCockpitField.altitud:
        return AppColors.accentElevation;
      case SegmentCockpitField.pendienteActual:
      case SegmentCockpitField.pendienteMediaSegmento:
        return AppColors.accentSlope;
      case SegmentCockpitField.velocidad:
      case SegmentCockpitField.velocidadMediaSegmento:
        return AppColors.accentSpeed;
      case SegmentCockpitField.frecuenciaCardiaca:
        return AppColors.accentHeartRate;
      case SegmentCockpitField.potencia:
        return AppColors.accentPower;
      case SegmentCockpitField.cadencia:
        return AppColors.accentCadence;
    }
  }

  /// Descripción corta para la pantalla de ajustes -- explica qué es
  /// cada campo, ya que varios son nuevos (Δ vs PR, meta estimada...).
  String get helpText {
    switch (this) {
      case SegmentCockpitField.mapaSegmento:
        return 'Mini-mapa con el trazado del segmento y tu posición.';
      case SegmentCockpitField.perfilAltimetria:
        return 'Perfil de la subida con un marcador de dónde vas.';
      case SegmentCockpitField.barraProgreso:
        return 'Barra de avance + cuánto falta en distancia y desnivel.';
      case SegmentCockpitField.tiempoEnSegmento:
        return 'Tu tiempo desde que entraste al segmento.';
      case SegmentCockpitField.deltaPr:
        return 'Cuánto vas por delante o por detrás de tu mejor marca '
            'en este punto.';
      case SegmentCockpitField.proyeccionMeta:
        return 'Tiempo final estimado si mantenés el ritmo actual.';
      case SegmentCockpitField.mejorTiempo:
        return 'Tu mejor tiempo registrado en este segmento.';
      case SegmentCockpitField.distanciaRecorrida:
        return 'Metros que llevas dentro del segmento.';
      case SegmentCockpitField.distanciaRestante:
        return 'Metros que faltan para la meta.';
      case SegmentCockpitField.progreso:
        return 'Porcentaje del segmento completado.';
      case SegmentCockpitField.desnivelRestante:
        return 'Metros de subida que faltan, según el perfil del segmento.';
      case SegmentCockpitField.pendienteActual:
        return 'Pendiente en tu posición, leída del perfil congelado '
            '(GPX / HGT), no de sensores.';
      case SegmentCockpitField.pendienteMediaSegmento:
        return 'Pendiente media de todo el segmento.';
      case SegmentCockpitField.velocidad:
        return 'Tu velocidad instantánea.';
      case SegmentCockpitField.velocidadMediaSegmento:
        return 'Velocidad media desde que entraste al segmento.';
      case SegmentCockpitField.frecuenciaCardiaca:
        return 'FC en vivo (necesita sensor).';
      case SegmentCockpitField.potencia:
        return 'Potencia en vivo (necesita medidor).';
      case SegmentCockpitField.cadencia:
        return 'Cadencia en vivo (necesita sensor o medidor de potencia).';
      case SegmentCockpitField.altitud:
        return 'Altitud actual sobre el nivel del mar.';
    }
  }

  SegmentFieldDisplay display(SegmentLiveData d) {
    String v;
    String u = '';
    switch (this) {
      case SegmentCockpitField.mapaSegmento:
      case SegmentCockpitField.perfilAltimetria:
      case SegmentCockpitField.barraProgreso:
        // Bloques visuales -- la grilla los renderiza como widget, no
        // como número. Esto solo se usaría si alguien llama `display`
        // sobre ellos por error.
        v = '';
      case SegmentCockpitField.tiempoEnSegmento:
        v = formatElapsedShort(d.elapsedInSegment);
      case SegmentCockpitField.deltaPr:
        v = d.deltaVsPr == null ? '--' : formatSignedDuration(d.deltaVsPr!);
      case SegmentCockpitField.proyeccionMeta:
        v = d.projectedFinish == null
            ? '--'
            : formatElapsedShort(d.projectedFinish!);
      case SegmentCockpitField.mejorTiempo:
        v = d.bestTime == null ? '--' : formatElapsedShort(d.bestTime!);
      case SegmentCockpitField.distanciaRecorrida:
        v = _meters(d.alongMeters);
        u = _metersUnit(d.alongMeters);
      case SegmentCockpitField.distanciaRestante:
        v = _meters(d.remainingMeters);
        u = _metersUnit(d.remainingMeters);
      case SegmentCockpitField.progreso:
        v = (d.progressFraction * 100).round().toString();
        u = '%';
      case SegmentCockpitField.desnivelRestante:
        v = d.remainingElevationGainMeters.toStringAsFixed(0);
        u = 'm';
      case SegmentCockpitField.pendienteActual:
        v = formatSlopePercent(d.currentSlopePercent);
        u = '%';
      case SegmentCockpitField.pendienteMediaSegmento:
        v = formatSlopePercent(d.avgSegmentSlopePercent);
        u = '%';
      case SegmentCockpitField.velocidad:
        v = formatSpeedKmh(d.currentSpeedKmh);
        u = 'km/h';
      case SegmentCockpitField.velocidadMediaSegmento:
        v = formatSpeedKmh(d.avgSpeedInSegmentKmh);
        u = 'km/h';
      case SegmentCockpitField.frecuenciaCardiaca:
        v = d.heartRateBpm?.toString() ?? '--';
        u = 'bpm';
      case SegmentCockpitField.potencia:
        v = d.powerWatts?.toString() ?? '--';
        u = 'W';
      case SegmentCockpitField.cadencia:
        v = d.cadenceRpm?.round().toString() ?? '--';
        u = 'rpm';
      case SegmentCockpitField.altitud:
        v = d.currentAltitudeMeters.toStringAsFixed(0);
        u = 'm';
    }
    return SegmentFieldDisplay(
      label: label,
      icon: icon,
      color: color,
      value: v,
      unit: u,
    );
  }

  String _meters(double m) =>
      m >= 1000 ? (m / 1000).toStringAsFixed(2) : m.toStringAsFixed(0);
  String _metersUnit(double m) => m >= 1000 ? 'km' : 'm';
}
