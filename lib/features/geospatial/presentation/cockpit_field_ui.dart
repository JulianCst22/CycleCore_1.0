import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format_utils.dart';
import '../domain/cockpit_field.dart';

/// Resultado ya armado (ícono, color, etiqueta, valor formateado y
/// unidad) para un campo del cockpit, listo para pintar en un tile.
class CockpitFieldDisplay {
  final String label;
  final IconData icon;
  final Color color;
  final String value;
  final String unit;

  const CockpitFieldDisplay({
    required this.label,
    required this.icon,
    required this.color,
    required this.value,
    required this.unit,
  });
}

/// Todo lo que necesita Flutter (íconos, colores, formateo) para pintar
/// un `CockpitField` -- separado del enum puro en `domain/` para que
/// ese archivo se quede sin dependencias de Flutter, igual que el resto
/// de `domain/` en este feature.
extension CockpitFieldX on CockpitField {
  String get label {
    switch (this) {
      case CockpitField.tiempo:
        return 'TIEMPO';
      case CockpitField.distancia:
        return 'DISTANCIA';
      case CockpitField.velocidad:
        return 'VELOCIDAD';
      case CockpitField.velocidadProm:
        return 'VEL. PROM.';
      case CockpitField.velocidadMax:
        return 'VEL. MÁX';
      case CockpitField.desnivel:
        return 'DESNIVEL';
      case CockpitField.pendiente:
        return 'PENDIENTE';
      case CockpitField.frecuenciaCardiaca:
        return 'FRECUENCIA CARDÍACA';
      case CockpitField.potencia:
        return 'POTENCIA';
      case CockpitField.potenciaMax:
        return 'POT. MÁX';
      case CockpitField.cadencia:
        return 'CADENCIA';
      case CockpitField.cadenciaMax:
        return 'CAD. MÁX';
    }
  }

  IconData get icon {
    switch (this) {
      case CockpitField.tiempo:
        return Icons.timer_outlined;
      case CockpitField.distancia:
        return Icons.straighten;
      case CockpitField.velocidad:
        return Icons.speed;
      case CockpitField.velocidadProm:
        return Icons.bar_chart;
      case CockpitField.velocidadMax:
        return Icons.bolt;
      case CockpitField.desnivel:
        return Icons.terrain;
      case CockpitField.pendiente:
        return Icons.trending_up;
      case CockpitField.frecuenciaCardiaca:
        return Icons.favorite;
      case CockpitField.potencia:
        return Icons.electric_bolt;
      case CockpitField.potenciaMax:
        return Icons.bolt;
      case CockpitField.cadencia:
        return Icons.autorenew;
      case CockpitField.cadenciaMax:
        return Icons.loop;
    }
  }

  Color get color {
    switch (this) {
      case CockpitField.tiempo:
        return AppColors.accentTime;
      case CockpitField.distancia:
        return AppColors.accentDistance;
      case CockpitField.velocidad:
      case CockpitField.velocidadProm:
      case CockpitField.velocidadMax:
        return AppColors.accentSpeed;
      case CockpitField.desnivel:
        return AppColors.accentElevation;
      case CockpitField.pendiente:
        return AppColors.accentSlope;
      case CockpitField.frecuenciaCardiaca:
        return AppColors.accentHeartRate;
      case CockpitField.potencia:
      case CockpitField.potenciaMax:
        return AppColors.accentPower;
      case CockpitField.cadencia:
      case CockpitField.cadenciaMax:
        return AppColors.accentCadence;
    }
  }

  /// Arma valor + unidad a partir del snapshot de datos en vivo. Los
  /// campos sin dato disponible (sensor no conectado) muestran '--' --
  /// mismo criterio que el resto de la app.
  CockpitFieldDisplay display(CockpitLiveData data) {
    switch (this) {
      case CockpitField.tiempo:
        return CockpitFieldDisplay(
          label: label,
          icon: icon,
          color: color,
          value: formatDuration(data.elapsed),
          unit: '',
        );
      case CockpitField.distancia:
        return CockpitFieldDisplay(
          label: label,
          icon: icon,
          color: color,
          value: formatDistanceKm(data.distanceMeters),
          unit: 'km',
        );
      case CockpitField.velocidad:
        return CockpitFieldDisplay(
          label: label,
          icon: icon,
          color: color,
          value: formatSpeedKmh(data.currentSpeedKmh),
          unit: 'km/h',
        );
      case CockpitField.velocidadProm:
        return CockpitFieldDisplay(
          label: label,
          icon: icon,
          color: color,
          value: formatSpeedKmh(data.avgSpeedKmh),
          unit: 'km/h',
        );
      case CockpitField.velocidadMax:
        return CockpitFieldDisplay(
          label: label,
          icon: icon,
          color: color,
          value: formatSpeedKmh(data.maxSpeedKmh),
          unit: 'km/h',
        );
      case CockpitField.desnivel:
        return CockpitFieldDisplay(
          label: label,
          icon: icon,
          color: color,
          value: data.elevationGainMeters.toStringAsFixed(0),
          unit: 'm',
        );
      case CockpitField.pendiente:
        return CockpitFieldDisplay(
          label: label,
          icon: icon,
          color: color,
          value: formatSlopePercent(data.slopePercent),
          unit: '%',
        );
      case CockpitField.frecuenciaCardiaca:
        return CockpitFieldDisplay(
          label: label,
          icon: icon,
          color: color,
          value: data.heartRateBpm?.toString() ?? '--',
          unit: 'bpm',
        );
      case CockpitField.potencia:
        return CockpitFieldDisplay(
          label: label,
          icon: icon,
          color: color,
          value: data.powerWatts?.toString() ?? '--',
          unit: 'W',
        );
      case CockpitField.potenciaMax:
        return CockpitFieldDisplay(
          label: label,
          icon: icon,
          color: color,
          value: data.maxPowerWattsSoFar?.toString() ?? '--',
          unit: 'W',
        );
      case CockpitField.cadencia:
        return CockpitFieldDisplay(
          label: label,
          icon: icon,
          color: color,
          value: data.cadenceRpm?.round().toString() ?? '--',
          unit: 'rpm',
        );
      case CockpitField.cadenciaMax:
        return CockpitFieldDisplay(
          label: label,
          icon: icon,
          color: color,
          value: data.maxCadenceRpmSoFar?.round().toString() ?? '--',
          unit: 'rpm',
        );
    }
  }
}
