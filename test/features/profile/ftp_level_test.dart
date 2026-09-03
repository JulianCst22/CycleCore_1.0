import 'package:cyclecore_app/features/profile/domain/ftp_level.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ftpLevelFor ubica cada W/kg en su tramo', () {
    expect(ftpLevelFor(1.4), FtpLevel.principiante);
    expect(ftpLevelFor(1.69), FtpLevel.principiante);
    expect(ftpLevelFor(1.7), FtpLevel.recreativo);
    expect(ftpLevelFor(2.4), FtpLevel.aficionado);
    expect(ftpLevelFor(3.0), FtpLevel.bueno);
    expect(ftpLevelFor(3.44), FtpLevel.bueno); // 248 W / 72 kg
    expect(ftpLevelFor(3.8), FtpLevel.fuerte);
    expect(ftpLevelFor(4.5), FtpLevel.muyFuerte);
    expect(ftpLevelFor(5.2), FtpLevel.competitivo);
    // Un amateur muy bueno (~5.7 W/kg) cae en Élite, no en el tope.
    expect(ftpLevelFor(5.7), FtpLevel.elite);
    expect(ftpLevelFor(6.3), FtpLevel.excepcional);
  });

  test('ftpScalePosition interpola y recorta a 0..1', () {
    expect(ftpScalePosition(1.0), 0.0); // por debajo del mínimo
    expect(ftpScalePosition(kFtpScaleMin), 0.0);
    expect(ftpScalePosition(kFtpScaleMax), 1.0);
    expect(ftpScalePosition(9.0), 1.0); // por encima del máximo
    // 4.0 está a mitad de camino entre 1.5 y 6.5.
    expect(ftpScalePosition(4.0), closeTo(0.5, 0.001));
    // 5.7 W/kg queda alto pero todavía con tramo por delante.
    expect(ftpScalePosition(5.7), lessThan(0.9));
  });
}
