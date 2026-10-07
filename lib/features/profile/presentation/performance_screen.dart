import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/ui.dart';
import '../../stats/stats.dart';
import 'widgets/curves_card.dart';
import 'widgets/ftp_level_card.dart';

/// Rendimiento: el FTP, los vatios por kilo, el nivel y las curvas de
/// potencia y pulso.
///
/// Vive aparte de las estadísticas a propósito. Son dos preguntas
/// distintas —«cuánto rodé» y «cuánto puedo»— y mezclarlas llenaba una
/// sola pantalla de números que nadie lee de corrido. Acá el periodo es
/// suyo: se puede mirar la curva de todo el histórico mientras las
/// estadísticas siguen en la semana que corre.
class PerformanceScreen extends ConsumerWidget {
  const PerformanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sample = ref.watch(curvesSampleProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rendimiento'),
        actions: [
          // SOLO PARA PRUEBAS: curvas de ejemplo, como el candado del
          // Vestidor. Quitar antes de entregar.
          IconButton(
            tooltip: 'Curvas de ejemplo (test)',
            icon: Icon(
              sample ? Icons.lock_open : Icons.lock_outline,
              color: sample ? CcColors.gold : null,
            ),
            onPressed: () =>
                ref.read(curvesSampleProvider.notifier).state = !sample,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
          children: [
            if (sample) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: CcColors.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Modo prueba: las curvas muestran valores de ejemplo, no '
                  'tus salidas.',
                  style: CcType.label(size: 11.5, color: CcColors.gold),
                ),
              ),
              const SizedBox(height: 12),
            ],
            const CurvesPeriodSelector(),
            const SizedBox(height: 18),
            const FtpLevelCard(),
            const SizedBox(height: 16),
            const CurvesCard(),
            const SizedBox(height: 18),
            Text(
              'La curva toma, para cada duración, la mejor media que has '
              'hecho en el periodo. De ahí salen la potencia crítica y la '
              'reserva con las que trabaja el coach.',
              style: CcType.label(size: 11.5, color: CcColors.inkDim),
            ),
          ],
        ),
      ),
    );
  }
}
