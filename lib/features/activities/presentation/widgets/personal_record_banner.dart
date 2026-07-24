import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/activity_records.dart';
import 'activity_record_badge.dart';

/// Banner que explica DE QUÉ fue el récord personal -- a diferencia del
/// badge de la lista (que solo dice "Récord personal"), aquí se listan
/// las métricas concretas (distancia, duración, potencia máx., etc.)
/// con su valor, cada una teñida con su color habitual mezclado con
/// dorado para que se sienta parte del mismo sistema de récords sin
/// perder la identidad de color de cada dato.
class PersonalRecordBanner extends StatelessWidget {
  final Activity activity;
  final Set<RecordType> records;

  const PersonalRecordBanner({
    super.key,
    required this.activity,
    required this.records,
  });

  @override
  Widget build(BuildContext context) {
    final ordered = RecordType.values.where(records.contains).toList();
    if (ordered.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ActivityRecordBadge.goldEnd.withValues(alpha: 0.16),
            ActivityRecordBadge.goldStart.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ActivityRecordBadge.goldEnd.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.emoji_events,
                size: 16,
                color: ActivityRecordBadge.goldStart,
              ),
              const SizedBox(width: 6),
              const Text(
                'Récord personal',
                style: TextStyle(
                  color: ActivityRecordBadge.goldStart,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ordered.map((type) {
              final tint = Color.lerp(
                type.accentColor,
                ActivityRecordBadge.goldEnd,
                0.5,
              )!;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: tint.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(type.icon, size: 13, color: tint),
                    const SizedBox(width: 5),
                    Text(
                      '${type.label}: ${type.formattedValue(activity)}',
                      style: const TextStyle(
                        color: AppColors.textPrimaryOnPanel,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
