import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/cyclecore_palette.dart';
import '../../../core/utils/format_utils.dart';
import '../../profile/presentation/profile_providers.dart';
import '../domain/activity_calories.dart';
import '../domain/activity_json_helpers.dart';
import '../domain/activity_records.dart';
import '../domain/activity_summary.dart';
import '../domain/elevation_gain_loss.dart';
import 'activities_providers.dart';
import 'widgets/share_route_art.dart';

/// Genera imágenes "lindas" de una actividad para compartir (Instagram,
/// WhatsApp, etc.) -- estilo Strava/Hevy/Garmin. Varios estilos que se
/// eligen deslizando; el botón exporta el que estás viendo a PNG y
/// abre el diálogo de compartir del sistema.
class ShareActivityScreen extends ConsumerStatefulWidget {
  final Activity activity;

  const ShareActivityScreen({super.key, required this.activity});

  @override
  ConsumerState<ShareActivityScreen> createState() =>
      _ShareActivityScreenState();
}

enum _Style { ruta, datos, altimetria, record }

class _ShareActivityScreenState extends ConsumerState<ShareActivityScreen> {
  final _controller = PageController();
  final Map<_Style, GlobalKey> _keys = {};
  int _page = 0;
  bool _sharing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _share(_Style style) async {
    setState(() => _sharing = true);
    try {
      final boundary = _keys[style]!.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1.0);
      final bytes =
          (await image.toByteData(format: ui.ImageByteFormat.png))!
              .buffer
              .asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File(
        p.join(dir.path, 'cyclecore_${widget.activity.id}_${style.name}.png'),
      );
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: widget.activity.title,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo generar la imagen: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activity = widget.activity;
    final points = activity.routePoints;
    final weightKg = ref.watch(profileProvider).valueOrNull?.weightKg;

    final records = ref.watch(activitiesListProvider).maybeWhen(
          data: (all) => computeActivityRecords(
            activity: activity,
            allActivities: all,
          ).records,
          orElse: () => const <RecordType>{},
        );

    final styles = <_Style>[
      _Style.ruta,
      _Style.datos,
      if (points.length > 1) _Style.altimetria,
      if (records.isNotEmpty) _Style.record,
    ];
    for (final s in styles) {
      _keys.putIfAbsent(s, () => GlobalKey());
    }
    final currentStyle = styles[_page.clamp(0, styles.length - 1)];

    return Scaffold(
      backgroundColor: AppColors.panelBackground,
      appBar: AppBar(
        backgroundColor: AppColors.panelBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimaryOnPanel),
        title: const Text(
          'Compartir actividad',
          style: TextStyle(color: AppColors.textPrimaryOnPanel),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: styles.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, i) {
                final style = styles[i];
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: FittedBox(
                      child: RepaintBoundary(
                        key: _keys[style],
                        child: SizedBox(
                          width: 1080,
                          height: 1080,
                          child: _ShareCard(
                            style: style,
                            activity: activity,
                            points: points,
                            weightKg: weightKg,
                            records: records,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < styles.length; i++)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _page ? 20 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: i == _page
                        ? AppColors.primary
                        : AppColors.textSecondaryOnPanel
                            .withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _sharing ? null : () => _share(currentStyle),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                icon: _sharing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.ios_share, color: Colors.white),
                label: Text(
                  _sharing ? 'Generando...' : 'Compartir esta imagen',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// La tarjeta (1080x1080). Todos los tamaños son grandes a
// propósito -- se renderiza a ese tamaño y se exporta tal cual.
// ============================================================

class _ShareCard extends StatelessWidget {
  final _Style style;
  final Activity activity;
  final List<RoutePointSnapshot> points;
  final double? weightKg;
  final Set<RecordType> records;

  const _ShareCard({
    required this.style,
    required this.activity,
    required this.points,
    required this.weightKg,
    required this.records,
  });

  String get _dateLabel {
    const months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic', //
    ];
    final d = activity.startedAt;
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF181C22), CyclecorePalette.grafito],
        ),
      ),
      padding: const EdgeInsets.all(64),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                activity.activityType == 'race'
                    ? 'CARRERA'
                    : 'ENTRENAMIENTO',
                style: const TextStyle(
                  color: CyclecorePalette.paramo,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              const Text(
                'CycleCore',
                style: TextStyle(
                  color: CyclecorePalette.hueso,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            activity.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: CyclecorePalette.hueso,
              fontSize: 58,
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _dateLabel,
            style: const TextStyle(
              color: CyclecorePalette.niebla,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 36),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    switch (style) {
      case _Style.ruta:
        return Column(
          children: [
            Expanded(child: ShareRouteArt(points: points)),
            const SizedBox(height: 28),
            _statStrip(_primaryStats()),
          ],
        );
      case _Style.altimetria:
        final loss = points.length < 2
            ? 0.0
            : computeGainLoss(points.map((p) => p.altitude).toList())
                .lossMeters;
        return Column(
          children: [
            Expanded(child: ShareElevationArt(points: points)),
            const SizedBox(height: 28),
            _statStrip([
              _Stat('DISTANCIA', '${formatDistanceKm(activity.distanceMeters)} km'),
              _Stat('DESNIVEL +',
                  '${activity.elevationGainMeters.toStringAsFixed(0)} m'),
              _Stat('DESNIVEL −', '${loss.toStringAsFixed(0)} m'),
              _Stat('TIEMPO',
                  formatDuration(Duration(seconds: activity.durationSeconds))),
            ]),
          ],
        );
      case _Style.datos:
        return _bigGrid(_allStats());
      case _Style.record:
        return _recordBody();
    }
  }

  List<_Stat> _primaryStats() => [
        _Stat('DISTANCIA', '${formatDistanceKm(activity.distanceMeters)} km'),
        _Stat('TIEMPO',
            formatDuration(Duration(seconds: activity.durationSeconds))),
        _Stat('DESNIVEL +',
            '${activity.elevationGainMeters.toStringAsFixed(0)} m'),
        _Stat('VEL. PROM', '${formatSpeedKmh(activity.avgSpeedKmh)} km/h'),
      ];

  List<_Stat> _allStats() {
    final calories = estimateCalories(
      avgPowerWatts: activity.avgPower,
      durationSeconds: activity.durationSeconds,
      elevationGainMeters: activity.elevationGainMeters,
      avgSpeedKmh: activity.avgSpeedKmh,
      weightKg: weightKg,
    );
    return [
      _Stat('DISTANCIA', '${formatDistanceKm(activity.distanceMeters)} km'),
      _Stat('TIEMPO',
          formatDuration(Duration(seconds: activity.durationSeconds))),
      _Stat('VEL. PROM', '${formatSpeedKmh(activity.avgSpeedKmh)} km/h'),
      _Stat('VEL. MÁX', '${formatSpeedKmh(activity.maxSpeedKmh)} km/h'),
      _Stat('DESNIVEL +',
          '${activity.elevationGainMeters.toStringAsFixed(0)} m'),
      if (activity.avgHeartRate != null)
        _Stat('FC PROM', '${activity.avgHeartRate} ppm'),
      if (activity.avgPower != null)
        _Stat('POTENCIA', '${activity.avgPower} W'),
      if (calories != null) _Stat('CALORÍAS', '$calories kcal'),
    ];
  }

  Widget _statStrip(List<_Stat> stats) {
    return Row(
      children: [
        for (final s in stats)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.value,
                  style: const TextStyle(
                    color: CyclecorePalette.hueso,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s.label,
                  style: const TextStyle(
                    color: CyclecorePalette.niebla,
                    fontSize: 20,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _bigGrid(List<_Stat> stats) {
    return GridView.count(
      crossAxisCount: 2,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 20,
      crossAxisSpacing: 20,
      childAspectRatio: 2.1,
      children: [
        for (final s in stats)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  s.label,
                  style: const TextStyle(
                    color: CyclecorePalette.niebla,
                    fontSize: 20,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    s.value,
                    style: const TextStyle(
                      color: CyclecorePalette.hueso,
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _recordBody() {
    final list = records.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.emoji_events, color: CyclecorePalette.paramo, size: 56),
            SizedBox(width: 16),
            Text(
              'RÉCORD PERSONAL',
              style: TextStyle(
                color: CyclecorePalette.hueso,
                fontSize: 40,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Expanded(
          child: ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, i) {
              final r = list[i];
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 22,
                ),
                decoration: BoxDecoration(
                  color: r.accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: r.accentColor.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(r.icon, color: r.accentColor, size: 40),
                    const SizedBox(width: 20),
                    Text(
                      r.label,
                      style: const TextStyle(
                        color: CyclecorePalette.hueso,
                        fontSize: 34,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      r.formattedValue(activity),
                      style: const TextStyle(
                        color: CyclecorePalette.hueso,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Stat {
  final String label;
  final String value;
  const _Stat(this.label, this.value);
}
