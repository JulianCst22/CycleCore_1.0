import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/ui.dart';
import '../../../profile/profile.dart';
import '../../../stats/stats.dart';

/// «Tiempo en zonas»: cuánto del tiempo en movimiento se pasó en cada zona
/// de potencia y de FC, con las zonas actuales del perfil. Solo aparece
/// lo que la salida tiene: sin potenciómetro no hay bloque de potencia.
/// Los segundos sin lectura se muestran aparte para que el total cuadre
/// con el tiempo en movimiento.
class ActivityZonesSection extends ConsumerWidget {
  final ActivitySeries series;

  const ActivityZonesSection({super.key, required this.series});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPower = series.powerSeconds > 0;
    final hasHeartRate = series.heartRateSeconds > 0;
    if (!hasPower && !hasHeartRate) return const SizedBox.shrink();

    final profile = ref.watch(profileProvider).valueOrNull;
    final zones =
        ref.watch(zonesProvider).valueOrNull ??
        (profile == null ? null : TrainingZones.computeDefaults(profile));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ActivitySectionLabel('Tiempo en zonas'),
        if (hasPower) ...[
          const SizedBox(height: 12),
          _ZoneBlock(
            title: 'Potencia',
            icon: Icons.electric_bolt,
            color: CcColors.mPower,
            unit: 'W',
            zones: zones?.powerZones ?? const [],
            series: series.power,
            missingZones: 'Añade tu FTP para ver tus zonas de potencia.',
          ),
        ],
        if (hasHeartRate) ...[
          const SizedBox(height: 16),
          _ZoneBlock(
            title: 'Frecuencia cardíaca',
            icon: Icons.favorite,
            color: CcColors.mHeartRate,
            unit: 'ppm',
            zones: zones?.heartRateZones ?? const [],
            series: series.heartRate,
            missingZones: 'Añade tu FC máxima para ver tus zonas de pulso.',
          ),
        ],
      ],
    );
  }
}

class _ZoneBlock extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String unit;
  final List<TrainingZone> zones;
  final List<double?> series;
  final String missingZones;

  const _ZoneBlock({
    required this.title,
    required this.icon,
    required this.color,
    required this.unit,
    required this.zones,
    required this.series,
    required this.missingZones,
  });

  /// Cada bloque usa **su** color: la potencia es morada y el pulso
  /// rojo, los mismos del resto de la app. Antes los dos compartían un
  /// arcoíris que iba de azul a morado, y eso hacía que la potencia se
  /// leyera amarilla o naranja en las zonas centrales, que son
  /// justamente donde más tiempo se pasa.
  ///
  /// Dentro del bloque las zonas van de tenue a pleno: la más suave
  /// casi apagada, la más dura a todo color.
  Color _zoneColor(int i, int count) {
    if (count <= 1) return color;
    final t = i / (count - 1);
    return Color.lerp(color.withValues(alpha: 0.35), color, t)!;
  }

  @override
  Widget build(BuildContext context) {
    final result = secondsInZones(series, [for (final z in zones) z.min]);
    final total = series.length;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: CcColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CcColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 7),
              Text(title, style: CcType.displayStyle(size: 13.5)),
            ],
          ),
          const SizedBox(height: 10),
          if (zones.isEmpty)
            _Hint(missingZones)
          else if (result == null)
            const _Hint(
              'Tus zonas no van en orden creciente: revísalas en Ajustes.',
            )
          else ...[
            for (var i = 0; i < zones.length; i++)
              _ZoneRow(
                name: zones[i].name,
                range: _rangeOf(zones[i], unit),
                seconds: result.seconds[i],
                total: total,
                color: _zoneColor(i, zones.length),
              ),
            if (result.withoutReading > 0)
              _ZoneRow(
                name: 'Sin lectura',
                range: '',
                seconds: result.withoutReading,
                total: total,
                color: CcColors.inkFaint,
              ),
          ],
        ],
      ),
    );
  }

  static String _rangeOf(TrainingZone zone, String unit) {
    final max = zone.max;
    return max == null ? '≥ ${zone.min} $unit' : '${zone.min}–$max $unit';
  }
}

class _ZoneRow extends StatelessWidget {
  final String name;
  final String range;
  final int seconds;
  final int total;
  final Color color;

  const _ZoneRow({
    required this.name,
    required this.range,
    required this.seconds,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = total == 0 ? 0.0 : seconds / total;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 112,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: CcColors.ink,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (range.isNotEmpty)
                  Text(
                    range,
                    style: const TextStyle(
                      color: CcColors.inkFaint,
                      fontSize: 9.5,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                children: [
                  Container(height: 10, color: CcColors.surfaceInset),
                  FractionallySizedBox(
                    widthFactor: fraction.clamp(0.0, 1.0),
                    child: Container(height: 10, color: color),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 50,
            child: Text(
              formatElapsedShort(Duration(seconds: seconds)),
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: CcColors.ink,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            width: 38,
            child: Text(
              '${(fraction * 100).round()} %',
              textAlign: TextAlign.right,
              style: const TextStyle(color: CcColors.inkDim, fontSize: 10.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  final String text;

  const _Hint(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(color: CcColors.inkDim, fontSize: 12, height: 1.4),
    );
  }
}
