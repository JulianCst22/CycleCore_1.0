import 'package:cyclecore_app/features/navigation/domain/climb_detection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('un nombre con término de montaña se detecta como alto', () {
    expect(looksLikeClimb('Alto de Patios'), isTrue);
    expect(looksLikeClimb('Paso de la Línea'), isTrue);
    expect(looksLikeClimb('Mirador de la Sabana'), isTrue);
    expect(looksLikeClimb('Páramo de Sumapaz'), isTrue);
    expect(looksLikeClimb('CUMBRE del cerro'), isTrue);
  });

  test('un nombre normal no es alto', () {
    expect(looksLikeClimb('Parque Nacional, Bogotá'), isFalse);
    expect(looksLikeClimb('Sopó, Cundinamarca'), isFalse);
    expect(looksLikeClimb('Calle 100'), isFalse);
  });

  test('un desnivel grande cuenta como alto aunque el nombre no lo diga', () {
    expect(
      looksLikeClimb(
        'Un lugar cualquiera',
        destinationAltitudeMeters: 2900,
        originAltitudeMeters: 2550,
      ),
      isTrue,
    );
    expect(
      looksLikeClimb(
        'Un lugar cualquiera',
        destinationAltitudeMeters: 2600,
        originAltitudeMeters: 2550,
      ),
      isFalse,
    );
  });

  test('sin altitudes y sin palabra clave -> no es alto', () {
    expect(looksLikeClimb('Un lugar cualquiera'), isFalse);
  });
}
