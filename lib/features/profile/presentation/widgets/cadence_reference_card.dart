import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/ui.dart';
import '../../../stats/stats.dart';
import '../../application/profile_providers.dart';
import '../../domain/cyclist_profile.dart';

/// Cadencia de referencia en subida: la que el coach usa para medir si
/// vas pesado o ligero.
///
/// Se muestra de dónde sale —la recomendada, la que la app aprendió de
/// tus salidas, o la que pusiste a mano— porque no es lo mismo: contra
/// este número se decide si te dice «sube un piñón» o «baja uno», y
/// merece que se vea qué la está mandando.
class CadenceReferenceCard extends ConsumerStatefulWidget {
  const CadenceReferenceCard({super.key});

  @override
  ConsumerState<CadenceReferenceCard> createState() =>
      _CadenceReferenceCardState();
}

class _CadenceReferenceCardState extends ConsumerState<CadenceReferenceCard> {
  final _controller = TextEditingController();
  bool _editing = false;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save(CyclistProfile profile, int? rpm) async {
    setState(() => _saving = true);
    // Para volver a la automática hay que vaciar el dato, y `copyWith`
    // con `?? this.x` no sabe distinguir «no tocar» de «vaciar»: por eso
    // se construye el perfil a mano.
    await ref
        .read(profileProvider.notifier)
        .saveProfile(_withCadence(profile, rpm));
    if (!mounted) return;
    setState(() {
      _saving = false;
      _editing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).valueOrNull;
    if (profile == null) return const SizedBox.shrink();
    final learned = ref.watch(learnedClimbingCadenceProvider);
    final manual = profile.preferredCadence;
    final effective = manual ?? learned?.round() ?? recommendedCadenceRpm;

    final origin = manual != null
        ? 'La pusiste tú'
        : learned != null
        ? 'Aprendida de tus últimas salidas'
        : 'Recomendada mientras no haya salidas de las que aprender';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.rotate_right,
                size: 17,
                color: CcColors.mCadence,
              ),
              const SizedBox(width: 8),
              Text(
                'Cadencia de referencia',
                style: CcType.displayStyle(size: 14.5),
              ),
              const Spacer(),
              Text(
                '$effective rpm',
                style: CcType.displayStyle(
                  size: 17,
                  weight: FontWeight.w800,
                  color: CcColors.mCadence,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            origin,
            style: CcType.label(size: 11.5, color: CcColors.inkDim),
          ),
          if (learned != null && manual != null && learned.round() != manual)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Subiendo pedaleas a ${learned.round()} rpm.',
                style: CcType.label(size: 11.5, color: CcColors.inkFaint),
              ),
            ),
          const SizedBox(height: 12),
          if (!_editing)
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    _controller.text = '$effective';
                    setState(() => _editing = true);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: CcColors.blue,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 36),
                  ),
                  child: Text(manual == null ? 'Ponerla a mano' : 'Cambiarla'),
                ),
                if (manual != null) ...[
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: _saving ? null : () => _save(profile, null),
                    style: TextButton.styleFrom(
                      foregroundColor: CcColors.inkDim,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 36),
                    ),
                    child: const Text('Volver a la automática'),
                  ),
                ],
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: CcColors.ink),
                    decoration: InputDecoration(
                      isDense: true,
                      suffixText: 'rpm',
                      suffixStyle: const TextStyle(color: CcColors.inkDim),
                      filled: true,
                      fillColor: CcColors.surfaceInset,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: _saving
                      ? null
                      : () {
                          final rpm = int.tryParse(_controller.text.trim());
                          if (rpm == null || rpm < 40 || rpm > 130) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Ponla entre 40 y 130 rpm.'),
                              ),
                            );
                            return;
                          }
                          _save(profile, rpm);
                        },
                  child: const Text('Guardar'),
                ),
                TextButton(
                  onPressed: () => setState(() => _editing = false),
                  style: TextButton.styleFrom(foregroundColor: CcColors.inkDim),
                  child: const Text('Cancelar'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// El perfil con otra cadencia (o sin ninguna, para volver a la que
/// calcula la app).
CyclistProfile _withCadence(CyclistProfile p, int? rpm) => CyclistProfile(
  name: p.name,
  weightKg: p.weightKg,
  ftpWatts: p.ftpWatts,
  maxHr: p.maxHr,
  restingHr: p.restingHr,
  preferredCadence: rpm,
  birthDate: p.birthDate,
  avatarPath: p.avatarPath,
  city: p.city,
  bio: p.bio,
  yearsRiding: p.yearsRiding,
  weeklyHours: p.weeklyHours,
  declaredLevel: p.declaredLevel,
);
