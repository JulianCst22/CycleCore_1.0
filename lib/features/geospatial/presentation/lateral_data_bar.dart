import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/cyclecore_palette.dart';
import '../domain/cockpit_field.dart';
import 'cockpit_field_ui.dart';
import 'gauge_value.dart';
import 'gps_status_widgets.dart';

/// Barra lateral tipo "indicador de tráfico" de Waze/Google Maps: un
/// gauge vertical al costado del mapa, siempre visible mientras se
/// graba Y el cockpit está en su forma compacta.
///
/// Dos cambios respecto a la primera versión, por feedback directo:
/// - Visual más integrado al mapa: sin panel sólido ni sombra dura --
///   ahora es una forma tipo cápsula que se desvanece hacia los bordes
///   (gradiente a transparente), y su opacidad general sube o baja
///   según qué tan "intenso" es el valor actual (`gauge.fraction`) --
///   en un tramo plano o sin nada que destacar, se atenúa y casi se
///   funde con el mapa; en una subida fuerte o un pulso alto, se
///   vuelve más presente. Es "dinámica" en el sentido de que reacciona
///   a los datos, no solo al tacto.
/// - Ya NO se muestra cuando el cockpit está en pantalla completa
///   (`isCockpitExpanded`): si el mismo campo elegido aquí aparece
///   también como tile en la grilla, ESE tile adopta el estilo de
///   gauge (ver `CockpitGridLayout`) en vez de duplicar la barra al
///   lado -- se "funde" con el campo, como se pidió.
class LateralDataBar extends ConsumerWidget {
  final CockpitLiveData liveData;
  final bool isApproximate;
  final bool isCockpitExpanded;

  const LateralDataBar({
    super.key,
    required this.liveData,
    required this.isApproximate,
    this.isCockpitExpanded = false,
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
    final gauge = gaugeValueFor(field, liveData);
    final isSlope = field == CockpitField.pendiente;

    // Opacidad general de la barra: base baja (0.4) para que en reposo
    // se sienta parte del mapa y no un panel encima -- sube hasta 1.0
    // según qué tan intenso es el valor (una pendiente fuerte, un
    // pulso alto). `fraction` ya viene 0..1 desde gaugeValueFor.
final dynamicOpacity =
    (2.5 + (gauge.fraction.clamp(0.0, 1.0) * 0.6)).clamp(0.0, 1.0);
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 400),
      opacity: isCockpitExpanded ? 0.0 : dynamicOpacity,
      child: IgnorePointer(
        ignoring: isCockpitExpanded,
        child: Container(
          width: 38,
          decoration: BoxDecoration(
            // Gradiente horizontal hacia transparente en vez de un
            // panel sólido -- da la sensación de "emerger" del borde
            // del mapa en vez de flotar como una tarjeta aparte.
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                CyclecorePalette.grafito.withValues(alpha: 0.35),
                CyclecorePalette.grafito.withValues(alpha: 0.85),
              ],
            ),
            borderRadius: BorderRadius.circular(19),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Relleno tipo gauge -- crece desde abajo, animado.
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
                            alpha: (isSlope && isApproximate) ? 0.4 : 0.75,
                          ),
                          gauge.color.withValues(alpha: 0.15),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

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
                        size: 16,
                        color: AppColors.textPrimaryOnPanel,
                      ),
                    ),
                  ),
                ),
              ),

              if (isSlope && isApproximate)
                const Positioned(
                  top: 4,
                  right: 2,
                  child: ApproximateElevationBadge(),
                ),

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
                          fontSize: 14,
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
        ),
      ),
    );
  }
}
