import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/ui/ui.dart';
import '../../domain/training_zones.dart';
import '../../domain/zone_edits.dart';
import 'zone_spectrum.dart';

/// Abre la ficha de la zona [index]: para qué sirve, cómo se siente,
/// cuánto se aguanta y sus límites, que se ajustan con +/−.
///
/// Cada cambio llega a [onChanged] al momento (la lista de atrás se
/// actualiza en vivo); quien la abre decide cuándo guardar, al cerrarse.
Future<void> showZoneDetailSheet(
  BuildContext context, {
  required ZoneScale scale,
  required int index,
  required ValueChanged<List<TrainingZone>> onChanged,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: CcColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) =>
        _ZoneDetailSheet(scale: scale, index: index, onChanged: onChanged),
  );
}

class _ZoneDetailSheet extends StatefulWidget {
  final ZoneScale scale;
  final int index;
  final ValueChanged<List<TrainingZone>> onChanged;

  const _ZoneDetailSheet({
    required this.scale,
    required this.index,
    required this.onChanged,
  });

  @override
  State<_ZoneDetailSheet> createState() => _ZoneDetailSheetState();
}

class _ZoneDetailSheetState extends State<_ZoneDetailSheet> {
  late ZoneScale _scale = widget.scale;

  int get _i => widget.index;
  TrainingZone get _zone => _scale.zones[_i];

  void _apply(List<TrainingZone> zones) {
    if (ZoneEdits.sameZones(zones, _scale.zones)) return;
    setState(() => _scale = _scale.withZones(zones));
    widget.onChanged(zones);
  }

  @override
  Widget build(BuildContext context) {
    final scale = _scale;
    final zones = scale.zones;
    final guide = scale.guideOf(_i);
    final color = scale.colorOf(_i);
    final percent = scale.percentOf(_i);
    final unit = scale.unit;
    final canMin = ZoneEdits.canMoveMin(zones, _i);
    final canMax = ZoneEdits.canMoveMax(zones, _i);
    final (minLow, minHigh) = ZoneEdits.minRange(zones, _i);
    final (maxLow, maxHigh) = ZoneEdits.maxRange(zones, _i);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: CcColors.inkFaint,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ZoneBadge(code: scale.codeOf(_i), color: color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      scale.labelOf(_i),
                      style: CcType.displayStyle(size: 21),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    _zone.max == null
                        ? 'Desde ${_zone.min}'
                        : '${_zone.min} – ${_zone.max}',
                    style: CcType.displayStyle(
                      size: 30,
                      weight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      percent == null ? unit : '$unit · $percent',
                      style: CcType.label(size: 12.5, color: CcColors.inkDim),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ZoneSpectrum(
                scale: scale,
                highlight: _i,
                showTicks: false,
                height: 10,
              ),
              if (guide != null) ...[
                const SizedBox(height: 18),
                Text(
                  guide.purpose,
                  style: const TextStyle(
                    color: CcColors.ink,
                    fontSize: 14.5,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                _GuideLine(
                  icon: Icons.record_voice_over_outlined,
                  title: 'Cómo se siente',
                  text: guide.feel,
                ),
                const SizedBox(height: 10),
                _GuideLine(
                  icon: Icons.timer_outlined,
                  title: 'Cuánto se aguanta',
                  text: guide.duration,
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Chip(label: 'Esfuerzo ${guide.effort}', color: color),
                    _Chip(label: guide.fuel, color: color),
                  ],
                ),
              ],
              const SizedBox(height: 22),
              Text(
                'TUS LÍMITES',
                style: CcType.label(
                  size: 11,
                  color: CcColors.inkFaint,
                ).copyWith(letterSpacing: 1.2),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _Stepper(
                      label: 'Desde',
                      value: _zone.min,
                      unit: unit,
                      fixedText: canMin ? null : 'fijo',
                      onMinus: canMin && _zone.min > minLow
                          ? () => _apply(
                              ZoneEdits.moveMin(zones, _i, _zone.min - 1),
                            )
                          : null,
                      onPlus: canMin && _zone.min < minHigh
                          ? () => _apply(
                              ZoneEdits.moveMin(zones, _i, _zone.min + 1),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Stepper(
                      label: 'Hasta',
                      value: _zone.max,
                      unit: unit,
                      fixedText: canMax
                          ? null
                          : scale.isPower
                          ? 'Sin tope'
                          : 'tu FC máx.',
                      onMinus: canMax && _zone.max! > maxLow
                          ? () => _apply(
                              ZoneEdits.moveMax(zones, _i, _zone.max! - 1),
                            )
                          : null,
                      onPlus: canMax && _zone.max! < maxHigh
                          ? () => _apply(
                              ZoneEdits.moveMax(zones, _i, _zone.max! + 1),
                            )
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _neighboursNote(scale),
                style: CcType.label(
                  size: 12,
                  color: CcColors.inkDim,
                ).copyWith(height: 1.4, fontWeight: FontWeight.w400),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: CcColors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Listo',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Qué pasa con las vecinas: "Z3 termina en 257 W · Z5 empieza en
  /// 300 W".
  String _neighboursNote(ZoneScale scale) {
    final zones = scale.zones;
    final unit = scale.unit;
    final parts = [
      if (_i > 0)
        '${scale.codeOf(_i - 1)} termina en ${zones[_i - 1].max} $unit',
      if (_i + 1 < zones.length)
        '${scale.codeOf(_i + 1)} empieza en ${zones[_i + 1].min} $unit',
    ];
    return '${parts.join(' · ')}. Las vecinas se mueven solas: las zonas '
        'nunca se pisan ni dejan huecos.';
  }
}

/// La pastilla de color con el código de la zona.
class ZoneBadge extends StatelessWidget {
  final String code;
  final Color color;

  const ZoneBadge({super.key, required this.code, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        code,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _GuideLine extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _GuideLine({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 17, color: CcColors.inkDim),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: CcType.label(size: 11.5, color: CcColors.inkFaint),
              ),
              const SizedBox(height: 2),
              Text(
                text,
                style: const TextStyle(
                  color: CcColors.ink,
                  fontSize: 13.5,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: CcColors.ink,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Un límite con − y +. Dejar el dedo encima repite el paso, cada vez
/// más rápido, para no tener que tocar cuarenta veces.
class _Stepper extends StatelessWidget {
  final String label;
  final int? value;
  final String unit;

  /// Lo que se muestra cuando este límite no se puede mover.
  final String? fixedText;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  const _Stepper({
    required this.label,
    required this.value,
    required this.unit,
    required this.fixedText,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    final fixed = fixedText;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: CcColors.surfaceInset,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CcColors.lineSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: CcType.label(size: 11, color: CcColors.inkFaint)),
          const SizedBox(height: 6),
          if (fixed != null)
            SizedBox(
              height: 40,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  value == null ? fixed : '$value $unit · $fixed',
                  style: CcType.label(size: 13, color: CcColors.inkDim),
                ),
              ),
            )
          else
            Row(
              children: [
                _RepeatButton(icon: Icons.remove, onStep: onMinus),
                Expanded(
                  child: Text(
                    '${value ?? ''}',
                    textAlign: TextAlign.center,
                    style: CcType.displayStyle(
                      size: 22,
                      weight: FontWeight.w800,
                    ),
                  ),
                ),
                _RepeatButton(icon: Icons.add, onStep: onPlus),
              ],
            ),
        ],
      ),
    );
  }
}

class _RepeatButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onStep;

  const _RepeatButton({required this.icon, required this.onStep});

  @override
  State<_RepeatButton> createState() => _RepeatButtonState();
}

class _RepeatButtonState extends State<_RepeatButton> {
  Timer? _timer;

  void _start() {
    var ticks = 0;
    _timer?.cancel();
    widget.onStep?.call();
    _timer = Timer.periodic(const Duration(milliseconds: 60), (_) {
      // Lo que hay que llamar es el callback de la construcción más
      // reciente: el de la primera ya apunta a límites viejos.
      final step = widget.onStep;
      if (step == null) return _stop();
      ticks++;
      // Arranca lento (uno cada 180 ms) y acelera a uno cada 60 ms.
      if (ticks < 12 && ticks % 3 != 0) return;
      step();
    });
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onStep != null;
    return GestureDetector(
      onLongPressStart: enabled ? (_) => _start() : null,
      onLongPressEnd: (_) => _stop(),
      onLongPressCancel: _stop,
      child: Material(
        color: enabled ? CcColors.surfaceHi : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: enabled ? CcColors.line : CcColors.lineSoft),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: widget.onStep,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              widget.icon,
              size: 20,
              color: enabled ? CcColors.ink : CcColors.inkFaint,
            ),
          ),
        ),
      ),
    );
  }
}
