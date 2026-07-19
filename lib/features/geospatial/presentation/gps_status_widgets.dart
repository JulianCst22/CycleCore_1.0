import 'package:flutter/material.dart';

import '../../../core/theme/cyclecore_palette.dart';
import 'slope_ribbon.dart';

/// Overlay a pantalla completa mientras se espera un fix de GPS
/// estable justo después de tocar "grabar" (ver
/// `LocationService.waitForStableFix` / `RouteRecordingState.isAcquiringGps`).
///
/// Antes de esto, `isAcquiringGps` se calculaba pero no se mostraba en
/// ningún lado -- el usuario tocaba grabar y no pasaba nada visible
/// hasta 8 segundos después. Este overlay reemplaza ese silencio.
class GpsAcquiringOverlay extends StatelessWidget {
  const GpsAcquiringOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CyclecorePalette.grafito.withValues(alpha: 0.82),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PulsingRadarDot(color: CyclecorePalette.paramo, size: 88),
            const SizedBox(height: 20),
            const Text(
              'Buscando señal GPS…',
              style: TextStyle(
                color: CyclecorePalette.hueso,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Un momento antes de arrancar mejora la precisión\nde toda la actividad',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: CyclecorePalette.niebla,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Badge tocable que reemplaza el ícono con `Tooltip` del modo
/// aproximado -- en móvil, `Tooltip` solo aparece con long-press, así
/// que la mayoría de usuarios nunca llegaba a leer esa explicación.
/// Ahora es un tap normal que abre una hoja explicando qué significa.
class ApproximateElevationBadge extends StatelessWidget {
  const ApproximateElevationBadge({super.key});

  void _showExplanation(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: CyclecorePalette.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _ApproximateExplanationSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showExplanation(context),
      child: const Padding(
        // Área de toque cómoda (44dp) aunque el ícono visual sea chico.
        padding: EdgeInsets.all(6),
        child: Icon(
          Icons.signal_cellular_alt_outlined,
          size: 14,
          color: CyclecorePalette.niebla,
        ),
      ),
    );
  }
}

class _ApproximateExplanationSheet extends StatelessWidget {
  const _ApproximateExplanationSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 4,
              alignment: Alignment.center,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: CyclecorePalette.niebla.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Row(
              children: [
                Icon(Icons.signal_cellular_alt_outlined,
                    color: CyclecorePalette.niebla, size: 18),
                SizedBox(width: 8),
                Text(
                  'Pendiente en modo aproximado',
                  style: TextStyle(
                    color: CyclecorePalette.hueso,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Por ahora no hay un mapa de elevación confiable para esta '
              'zona, o el sistema detectó un posible puente o viaducto. '
              'Mientras tanto, la pendiente se calcula con el GPS y el '
              'barómetro del teléfono en vez del modelo de elevación -- '
              'sigue siendo útil, pero un poco menos precisa.',
              style: TextStyle(
                color: CyclecorePalette.niebla,
                fontSize: 13.5,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.06),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Entendido',
                  style: TextStyle(
                    color: CyclecorePalette.paramo,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
