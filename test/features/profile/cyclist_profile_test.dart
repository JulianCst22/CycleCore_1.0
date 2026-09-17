import 'package:cyclecore_app/features/profile/domain/cyclist_profile.dart';
import 'package:cyclecore_app/features/profile/domain/training_zones.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('datos deportivos opcionales', () {
    test('sin FTP o sin peso, powerToWeight es null', () {
      expect(
        const CyclistProfile(name: 'A', weightKg: 70).powerToWeight,
        isNull,
      );
      expect(
        const CyclistProfile(name: 'A', ftpWatts: 250).powerToWeight,
        isNull,
      );
      expect(const CyclistProfile(name: 'A').powerToWeight, isNull);
    });

    test('con FTP y peso, powerToWeight se calcula', () {
      final p = const CyclistProfile(name: 'A', weightKg: 72, ftpWatts: 288);
      expect(p.powerToWeight, closeTo(4.0, 0.001));
    });

    test('hrReserve necesita FC máxima Y en reposo', () {
      expect(const CyclistProfile(name: 'A', maxHr: 190).hrReserve, isNull);
      expect(const CyclistProfile(name: 'A', restingHr: 50).hrReserve, isNull);
      expect(
        const CyclistProfile(name: 'A', maxHr: 190, restingHr: 50).hrReserve,
        140,
      );
    });

    test('effortPercentFromHr es null sin FC máxima', () {
      expect(const CyclistProfile(name: 'A').effortPercentFromHr(150), isNull);
      expect(
        const CyclistProfile(name: 'A', maxHr: 200).effortPercentFromHr(150),
        closeTo(0.75, 0.001),
      );
    });
  });

  group('edad y FC máxima estimada', () {
    test('sin fecha de nacimiento, edad y estimado son null', () {
      const p = CyclistProfile(name: 'A');
      expect(p.age, isNull);
      expect(p.estimatedMaxHrFromAge, isNull);
    });

    test('edad cumplida a partir de la fecha de nacimiento', () {
      final thirtyYearsAgo = DateTime(DateTime.now().year - 30, 1, 1);
      final p = CyclistProfile(name: 'A', birthDate: thirtyYearsAgo);
      // Al menos 29 (según el mes en que corra el test); nunca 30 exacto
      // salvo que hoy sea 1 de enero.
      expect(p.age, anyOf(29, 30));
    });

    test('estimado de FC máx: Tanaka 208 - 0.7·edad', () {
      final p = CyclistProfile(
        name: 'A',
        birthDate: DateTime(DateTime.now().year - 40, 1, 1),
      );
      // 40 años -> 208 - 28 = 180 (o 179 si aún no cumple en este año).
      expect(p.estimatedMaxHrFromAge, anyOf(180, 181));
    });
  });

  group('serialización', () {
    test('round-trip con datos parciales', () {
      final p = CyclistProfile(
        name: 'Julián',
        weightKg: 72,
        birthDate: DateTime(1996, 4, 12),
        city: 'Bogotá',
      );
      final back = CyclistProfile.fromJson(p.toJson());
      expect(back.name, 'Julián');
      expect(back.weightKg, 72);
      expect(back.ftpWatts, isNull);
      expect(back.maxHr, isNull);
      expect(back.birthDate, DateTime(1996, 4, 12));
      expect(back.city, 'Bogotá');
    });

    test('perfil viejo sin birthDate carga sin lanzar', () {
      final back = CyclistProfile.fromJson({
        'name': 'A',
        'weightKg': 70.0,
        'ftpWatts': 200,
        'maxHr': 185,
      });
      expect(back.birthDate, isNull);
      expect(back.ftpWatts, 200);
    });
  });

  group('TrainingZones.computeDefaults con datos parciales', () {
    test('sin FTP: sin zonas de potencia, pero sí de FC', () {
      final z = TrainingZones.computeDefaults(
        const CyclistProfile(name: 'A', maxHr: 190),
      );
      expect(z.powerZones, isEmpty);
      expect(z.heartRateZones, hasLength(5));
      expect(z.hasAny, isTrue);
    });

    test('sin FC máxima: sin zonas de FC, pero sí de potencia', () {
      final z = TrainingZones.computeDefaults(
        const CyclistProfile(name: 'A', ftpWatts: 250),
      );
      expect(z.powerZones, hasLength(7));
      expect(z.heartRateZones, isEmpty);
    });

    test('sin ningún dato: sin zonas', () {
      final z = TrainingZones.computeDefaults(const CyclistProfile(name: 'A'));
      expect(z.hasAny, isFalse);
    });
  });
}
