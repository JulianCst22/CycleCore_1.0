import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:core_ui/core_ui.dart';
import '../../domain/cyclist_profile.dart';
import '../../domain/ftp_level.dart';
import '../profile_edit_screen.dart';
import '../../application/profile_providers.dart';
import '../training_zones_screen.dart';

/// Tarjeta "Rendimiento": pone el FTP en contexto. Muestra los vatios,
/// la relación W/kg, el nivel que eso representa en una escala, y el
/// peso / FC máxima. Tocarla abre las zonas de entrenamiento.
///
/// Si falta el FTP o el peso, en vez de la tarjeta va una invitación a
/// completarlos -- así el dato deja de ser obligatorio en el registro.
class FtpLevelCard extends ConsumerWidget {
  const FtpLevelCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).valueOrNull;
    if (profile == null) return const SizedBox.shrink();
    if (profile.powerToWeight == null) {
      return _AddDataPrompt(
        needsFtp: profile.ftpWatts == null,
        needsWeight: profile.weightKg == null,
      );
    }
    return _Card(profile: profile);
  }
}

class _AddDataPrompt extends StatelessWidget {
  final bool needsFtp;
  final bool needsWeight;

  const _AddDataPrompt({required this.needsFtp, required this.needsWeight});

  @override
  Widget build(BuildContext context) {
    final missing = [
      if (needsFtp) 'tu FTP',
      if (needsWeight) 'tu peso',
    ].join(' y ');

    return GestureDetector(
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const ProfileEditScreen())),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: CcColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: CcColors.line),
        ),
        child: Row(
          children: [
            const Icon(Icons.bolt_outlined, color: CcColors.mPower, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Añade $missing', style: CcType.displayStyle(size: 14)),
                  const SizedBox(height: 2),
                  const Text(
                    'Para ver tu relación W/kg, tu nivel y tus zonas de potencia.',
                    style: TextStyle(
                      color: CcColors.inkDim,
                      fontSize: 11.5,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: CcColors.inkFaint, size: 20),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final CyclistProfile profile;

  const _Card({required this.profile});

  @override
  Widget build(BuildContext context) {
    final wkg = profile.powerToWeight!;
    final level = ftpLevelFor(wkg);
    final position = ftpScalePosition(wkg);
    final rampColor = _rampColor(position);

    return GestureDetector(
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const TrainingZonesScreen())),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              CcColors.mPower.withValues(alpha: 0.1),
              CcColors.mPower.withValues(alpha: 0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: CcColors.mPower.withValues(alpha: 0.28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${profile.ftpWatts!}',
                  style: CcType.displayStyle(size: 26, weight: FontWeight.w800),
                ),
                const SizedBox(width: 3),
                const Padding(
                  padding: EdgeInsets.only(bottom: 3),
                  child: Text(
                    'W',
                    style: TextStyle(
                      color: CcColors.inkDim,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '${wkg.toStringAsFixed(1)} ',
                    style: const TextStyle(
                      color: CcColors.mPower,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 3),
                  child: Text(
                    'W/kg',
                    style: TextStyle(color: CcColors.inkDim, fontSize: 10),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: rampColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    level.label.toUpperCase(),
                    style: const TextStyle(
                      color: CcColors.bg,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            _Scale(position: position),
            const SizedBox(height: 11),
            Row(
              children: [
                _MiniFact(
                  label: 'Peso',
                  value: '${_trimWeight(profile.weightKg!)} kg',
                ),
                const SizedBox(width: 14),
                _MiniFact(
                  label: 'FC máx',
                  value: profile.maxHr?.toString() ?? '—',
                ),
                const Spacer(),
                Text(
                  'Ver zonas ▸',
                  style: TextStyle(
                    color: CcColors.blue,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _trimWeight(double kg) {
    final rounded = kg.toStringAsFixed(1);
    return rounded.endsWith('.0')
        ? rounded.substring(0, rounded.length - 2)
        : rounded;
  }

  static Color _rampColor(double t) {
    if (t <= 0.55) {
      return Color.lerp(CcColors.slopeFlat, CcColors.slopeMid, t / 0.55)!;
    }
    return Color.lerp(
      CcColors.slopeMid,
      CcColors.slopeHard,
      (t - 0.55) / 0.45,
    )!;
  }
}

class _Scale extends StatelessWidget {
  final double position;

  const _Scale({required this.position});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox(
              height: 15,
              width: constraints.maxWidth,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      height: 7,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                        gradient: LinearGradient(
                          colors: [
                            CcColors.slopeFlat,
                            CcColors.slopeMid,
                            CcColors.slopeHard,
                          ],
                          stops: [0.0, 0.55, 1.0],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: (constraints.maxWidth - 4) * position,
                    top: 0,
                    child: Container(
                      width: 4,
                      height: 15,
                      decoration: BoxDecoration(
                        color: CcColors.ink,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: const [
                          BoxShadow(color: Colors.black54, blurRadius: 3),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 5),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '1.5 W/kg',
              style: TextStyle(color: CcColors.inkFaint, fontSize: 8.5),
            ),
            Text(
              '6.5 W/kg',
              style: TextStyle(color: CcColors.inkFaint, fontSize: 8.5),
            ),
          ],
        ),
      ],
    );
  }
}

class _MiniFact extends StatelessWidget {
  final String label;
  final String value;

  const _MiniFact({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 11, color: CcColors.inkDim),
        children: [
          TextSpan(text: '$label '),
          TextSpan(
            text: value,
            style: const TextStyle(
              color: CcColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
