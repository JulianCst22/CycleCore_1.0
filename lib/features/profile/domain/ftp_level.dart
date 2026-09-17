/// Nivel de forma derivado de la relación potencia/peso (W/kg) sobre el
/// FTP -- el número que de verdad compara la capacidad entre ciclistas
/// de distinto tamaño. La escala es deliberadamente sencilla y sin
/// género (no reproducimos las tablas de Coggan con su "clase mundial"),
/// pero con recorrido de sobra en el tramo alto: un amateur fuerte
/// (~5.5-6 W/kg) cae en **Élite** y todavía tiene "Excepcional" por
/// delante, así que "muy bueno" no se siente como el tope.
enum FtpLevel {
  principiante('Principiante'),
  recreativo('Recreativo'),
  aficionado('Aficionado'),
  bueno('Bueno'),
  fuerte('Fuerte'),
  muyFuerte('Muy fuerte'),
  competitivo('Competitivo'),
  elite('Élite'),
  excepcional('Excepcional');

  const FtpLevel(this.label);

  final String label;
}

/// Límite inferior (en W/kg) de cada nivel a partir del segundo. El
/// primero (`principiante`) empieza en 0.
const _thresholds = <FtpLevel, double>{
  FtpLevel.recreativo: 1.7,
  FtpLevel.aficionado: 2.4,
  FtpLevel.bueno: 3.0,
  FtpLevel.fuerte: 3.7,
  FtpLevel.muyFuerte: 4.4,
  FtpLevel.competitivo: 5.0,
  FtpLevel.elite: 5.6,
  FtpLevel.excepcional: 6.2,
};

/// Extremos de la escala visual (la barra de rendimiento). No son
/// límites "reales" -- solo el rango que se dibuja: por debajo de 1.5 el
/// marcador se queda pegado a la izquierda, por encima de 6.5 a la
/// derecha.
const kFtpScaleMin = 1.5;
const kFtpScaleMax = 6.5;

/// W/kg -> nivel.
FtpLevel ftpLevelFor(double wattsPerKg) {
  FtpLevel level = FtpLevel.principiante;
  for (final entry in _thresholds.entries) {
    if (wattsPerKg >= entry.value) {
      level = entry.key;
    }
  }
  return level;
}

/// Posición del marcador en la barra de rendimiento, 0.0 (izquierda) a
/// 1.0 (derecha), interpolando [wattsPerKg] entre [kFtpScaleMin] y
/// [kFtpScaleMax].
double ftpScalePosition(double wattsPerKg) {
  final t = (wattsPerKg - kFtpScaleMin) / (kFtpScaleMax - kFtpScaleMin);
  return t.clamp(0.0, 1.0);
}
