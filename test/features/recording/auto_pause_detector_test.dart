import 'package:cyclecore_app/features/recording/domain/auto_pause_detector.dart';
import 'package:flutter_test/flutter_test.dart';

final _t0 = DateTime(2026, 9, 13, 7, 0);
DateTime _at(int seconds) => _t0.add(Duration(seconds: seconds));

void main() {
  late AutoPauseDetector detector;

  setUp(() {
    detector = AutoPauseDetector()..reset(_t0);
  });

  test('rodando no se pausa', () {
    for (var s = 2; s <= 30; s += 2) {
      expect(detector.onSpeed(22, _at(s)), isNull);
      expect(detector.onTick(_at(s)), isNull);
    }
    expect(detector.isPaused, isFalse);
  });

  test('se pausa tras 6 s sin movimiento, y solo una vez', () {
    detector.onSpeed(25, _at(10));

    expect(detector.onTick(_at(15)), isNull);
    expect(detector.onTick(_at(16)), AutoPauseTransition.paused);
    expect(detector.onTick(_at(17)), isNull);

    expect(detector.isPaused, isTrue);
    // La parada real fue en el último movimiento, no al confirmarla.
    expect(detector.lastMovementAt, _at(10));
  });

  test('la velocidad GPS de alguien quieto no cuenta como movimiento', () {
    detector.onSpeed(25, _at(0));
    detector.onSpeed(2.5, _at(3));
    detector.onSpeed(3.9, _at(5));

    expect(detector.onTick(_at(6)), AutoPauseTransition.paused);
    expect(detector.onSpeed(3.2, _at(8)), isNull);
    expect(detector.isPaused, isTrue);
  });

  test('se reanuda con la primera evidencia de movimiento', () {
    detector.onTick(_at(6));
    expect(detector.isPaused, isTrue);

    expect(detector.onSpeed(9, _at(40)), AutoPauseTransition.resumed);
    expect(detector.isPaused, isFalse);
    expect(detector.onSpeed(12, _at(42)), isNull);
  });

  test('la rueda girando reanuda sin importar la velocidad', () {
    detector.onTick(_at(6));

    expect(detector.onMovement(_at(20)), AutoPauseTransition.resumed);
    // Y cuenta desde ahí para la siguiente parada.
    expect(detector.onTick(_at(25)), isNull);
    expect(detector.onTick(_at(26)), AutoPauseTransition.paused);
  });

  test('reset vuelve a contar desde cero y quita la pausa', () {
    detector.onTick(_at(6));

    detector.reset(_at(100));

    expect(detector.isPaused, isFalse);
    expect(detector.onTick(_at(105)), isNull);
    expect(detector.onTick(_at(106)), AutoPauseTransition.paused);
  });

  test('sin reset no hay referencia y no decide nada', () {
    final fresh = AutoPauseDetector();
    expect(fresh.onTick(_at(60)), isNull);
    expect(fresh.isPaused, isFalse);
  });
}
