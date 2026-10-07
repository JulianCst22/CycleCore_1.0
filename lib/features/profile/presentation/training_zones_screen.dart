import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/ui.dart';
import '../application/profile_providers.dart';
import '../application/zones_providers.dart';
import '../domain/cyclist_profile.dart';
import '../domain/training_zones.dart';
import '../domain/zone_edits.dart';
import 'profile_edit_screen.dart';
import 'widgets/cadence_reference_card.dart';
import 'widgets/zone_detail_sheet.dart';
import 'widgets/zone_spectrum.dart';

/// Zonas de entrenamiento: una barra con todas en proporción real y una
/// fila por zona. Tocar una abre su ficha —para qué sirve, cómo se
/// siente, cuánto se aguanta— y ahí mismo se ajustan sus límites con
/// +/−; la zona vecina se mueve sola, así que nunca quedan pisadas ni
/// con huecos.
///
/// Lo que se ajusta se guarda al cerrar la ficha. Mientras nadie las
/// toque, las zonas siguen saliendo del FTP y la FC del perfil.
class TrainingZonesScreen extends ConsumerStatefulWidget {
  const TrainingZonesScreen({super.key});

  @override
  ConsumerState<TrainingZonesScreen> createState() =>
      _TrainingZonesScreenState();
}

class _TrainingZonesScreenState extends ConsumerState<TrainingZonesScreen> {
  ZoneKind? _kind;

  /// Lo que se está ajustando y todavía no se guardó.
  TrainingZones? _draft;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final zonesAsync = ref.watch(zonesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Zonas de entrenamiento')),
      body: profileAsync.when(
        skipLoadingOnReload: true,
        loading: () => const _Loading(),
        error: (error, _) => _Message('No se pudo cargar tu perfil:\n$error'),
        data: (profile) {
          if (profile == null) {
            return const _Message(
              'Completa primero tu perfil para calcular tus zonas.',
            );
          }
          if (zonesAsync.isLoading && !zonesAsync.hasValue) {
            return const _Loading();
          }
          return _body(profile, zonesAsync.valueOrNull);
        },
      ),
    );
  }

  Widget _body(CyclistProfile profile, TrainingZones? saved) {
    final computed = TrainingZones.computeDefaults(profile);
    final current = _draft ?? saved ?? computed;
    final kind =
        _kind ??
        (current.powerZones.isEmpty && current.heartRateZones.isNotEmpty
            ? ZoneKind.heartRate
            : ZoneKind.power);
    final isPower = kind == ZoneKind.power;
    final zones = isPower ? current.powerZones : current.heartRateZones;
    final defaults = isPower ? computed.powerZones : computed.heartRateZones;
    final scale = ZoneScale(
      kind: kind,
      zones: zones,
      ftp: profile.ftpWatts,
      maxHr: profile.maxHr,
      restingHr: profile.restingHr,
    );
    final custom = defaults.isNotEmpty && !ZoneEdits.sameZones(zones, defaults);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          _Hero(profile: profile),
          const SizedBox(height: 16),
          _KindSwitch(kind: kind, onChanged: (k) => setState(() => _kind = k)),
          const SizedBox(height: 16),
          if (zones.isEmpty)
            _MissingData(kind: kind)
          else ...[
            ZoneSpectrum(scale: scale),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    custom ? 'Ajustadas por ti' : _origin(profile, kind),
                    style: CcType.label(size: 12, color: CcColors.inkDim),
                  ),
                ),
                if (custom)
                  TextButton(
                    onPressed: () => _reset(kind, current, computed),
                    style: TextButton.styleFrom(
                      foregroundColor: CcColors.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 34),
                    ),
                    child: const Text('Restablecer calculadas'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < zones.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              _ZoneRow(
                scale: scale,
                index: i,
                onTap: () => _openZone(scale, i, current),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              'Toca una zona para ver para qué sirve y ajustar sus límites.',
              textAlign: TextAlign.center,
              style: CcType.label(size: 11.5, color: CcColors.inkFaint),
            ),
          ],
          const SizedBox(height: 24),
          const CadenceReferenceCard(),
        ],
      ),
    );
  }

  static String _origin(CyclistProfile profile, ZoneKind kind) {
    if (kind == ZoneKind.power) {
      return 'Calculadas con tu FTP de ${profile.ftpWatts} W';
    }
    return profile.restingHr == null
        ? 'Calculadas con tu FC máxima'
        : 'Calculadas con tu FC máxima y en reposo';
  }

  TrainingZones _with(
    TrainingZones base,
    ZoneKind kind,
    List<TrainingZone> zones,
  ) => kind == ZoneKind.power
      ? TrainingZones(powerZones: zones, heartRateZones: base.heartRateZones)
      : TrainingZones(powerZones: base.powerZones, heartRateZones: zones);

  Future<void> _openZone(ZoneScale scale, int index, TrainingZones base) async {
    await showZoneDetailSheet(
      context,
      scale: scale,
      index: index,
      onChanged: (zones) {
        if (!mounted) return;
        setState(() => _draft = _with(_draft ?? base, scale.kind, zones));
      },
    );
    await _persist();
  }

  /// Guarda el borrador si cambió algo. Si nunca se tocó, no se guarda
  /// nada: así las zonas siguen el FTP cuando el perfil cambie.
  Future<void> _persist() async {
    final draft = _draft;
    if (draft == null || !mounted) return;
    final profile = ref.read(profileProvider).valueOrNull;
    final saved = ref.read(zonesProvider).valueOrNull;
    final reference =
        saved ??
        (profile == null ? null : TrainingZones.computeDefaults(profile));
    if (reference != null &&
        ZoneEdits.sameZones(draft.powerZones, reference.powerZones) &&
        ZoneEdits.sameZones(draft.heartRateZones, reference.heartRateZones)) {
      return;
    }
    await ref.read(zonesProvider.notifier).saveZones(draft);
  }

  Future<void> _reset(
    ZoneKind kind,
    TrainingZones current,
    TrainingZones computed,
  ) async {
    final restored = _with(
      current,
      kind,
      kind == ZoneKind.power ? computed.powerZones : computed.heartRateZones,
    );
    setState(() => _draft = restored);
    await _persist();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            kind == ZoneKind.power
                ? 'Zonas de potencia restablecidas'
                : 'Zonas de pulso restablecidas',
          ),
          action: SnackBarAction(
            label: 'Deshacer',
            onPressed: () async {
              if (!mounted) return;
              setState(() => _draft = current);
              await _persist();
            },
          ),
        ),
      );
  }
}

/// FTP y FC máxima: los dos números de los que salen las zonas.
class _Hero extends StatelessWidget {
  final CyclistProfile profile;

  const _Hero({required this.profile});

  @override
  Widget build(BuildContext context) {
    final ftp = profile.ftpWatts;
    final wkg = profile.powerToWeight;
    final maxHr = profile.maxHr;
    final rest = profile.restingHr;
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            label: 'FTP',
            value: ftp == null ? '—' : '$ftp',
            unit: 'W',
            sub: ftp == null
                ? 'Sin dato'
                : wkg == null
                ? 'Sin peso para W/kg'
                : '${wkg.toStringAsFixed(1).replaceAll('.', ',')} W/kg',
            color: CcColors.mPower,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            label: 'FC MÁX',
            value: maxHr == null ? '—' : '$maxHr',
            unit: 'ppm',
            sub: maxHr == null
                ? 'Sin dato'
                : rest == null
                ? 'Sin FC en reposo'
                : 'En reposo $rest',
            color: CcColors.mHeartRate,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final String sub;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.sub,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: CcColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CcColors.lineSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: CcType.label(
                  size: 10.5,
                  color: CcColors.inkFaint,
                ).copyWith(letterSpacing: 1.2),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: CcType.displayStyle(size: 26, weight: FontWeight.w800),
              ),
              const SizedBox(width: 3),
              Text(unit, style: CcType.label(size: 12, color: CcColors.inkDim)),
            ],
          ),
          const SizedBox(height: 3),
          Text(sub, style: CcType.label(size: 11.5, color: CcColors.inkDim)),
        ],
      ),
    );
  }
}

/// Potencia | Pulso.
class _KindSwitch extends StatelessWidget {
  final ZoneKind kind;
  final ValueChanged<ZoneKind> onChanged;

  const _KindSwitch({required this.kind, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget option(ZoneKind k, String label, Color color) {
      final on = k == kind;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(k),
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? CcColors.surfaceHi : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: on ? CcColors.line : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: on ? color : CcColors.inkFaint,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: TextStyle(
                    color: on ? CcColors.ink : CcColors.inkDim,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: CcColors.surfaceInset,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          option(ZoneKind.power, 'Potencia', CcColors.mPower),
          const SizedBox(width: 3),
          option(ZoneKind.heartRate, 'Pulso', CcColors.mHeartRate),
        ],
      ),
    );
  }
}

class _ZoneRow extends StatelessWidget {
  final ZoneScale scale;
  final int index;
  final VoidCallback onTap;

  const _ZoneRow({
    required this.scale,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final guide = scale.guideOf(index);
    final percent = scale.percentOf(index);
    return Material(
      color: CcColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: CcColors.lineSoft),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(
            children: [
              ZoneBadge(code: scale.codeOf(index), color: scale.colorOf(index)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scale.labelOf(index),
                      style: const TextStyle(
                        color: CcColors.ink,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (guide != null)
                      Text(
                        guide.hint,
                        style: CcType.label(
                          size: 11.5,
                          color: CcColors.inkDim,
                          weight: FontWeight.w400,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: scale.rangeOf(index)),
                        TextSpan(
                          text: ' ${scale.unit}',
                          style: CcType.label(size: 11, color: CcColors.inkDim),
                        ),
                      ],
                    ),
                    style: CcType.displayStyle(
                      size: 15.5,
                      weight: FontWeight.w700,
                    ),
                  ),
                  if (percent != null)
                    Text(
                      percent,
                      style: CcType.label(size: 10.5, color: CcColors.inkDim),
                    ),
                ],
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: CcColors.inkFaint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sin FTP (o sin FC máxima) no hay de dónde sacar las zonas.
class _MissingData extends StatelessWidget {
  final ZoneKind kind;

  const _MissingData({required this.kind});

  @override
  Widget build(BuildContext context) {
    final isPower = kind == ZoneKind.power;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CcColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CcColors.lineSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isPower
                ? 'Añade tu FTP para calcular tus zonas de potencia.'
                : 'Añade tu FC máxima para calcular tus zonas de pulso.',
            style: const TextStyle(
              color: CcColors.ink,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
            ),
            style: TextButton.styleFrom(
              foregroundColor: CcColors.blue,
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 36),
            ),
            child: const Text('Editar perfil'),
          ),
        ],
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: CcColors.orange),
    );
  }
}

class _Message extends StatelessWidget {
  final String text;

  const _Message(this.text);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: CcColors.inkDim),
        ),
      ),
    );
  }
}
