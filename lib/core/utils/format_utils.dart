/// Formatea una duración como "mm:ss" o "hh:mm:ss" si supera una hora.
/// Usado para mostrar el tiempo de recorrido en el panel de datos.
String formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);

  final minutesStr = minutes.toString().padLeft(2, '0');
  final secondsStr = seconds.toString().padLeft(2, '0');

  if (hours > 0) {
    final hoursStr = hours.toString().padLeft(2, '0');
    return '$hoursStr:$minutesStr:$secondsStr';
  }
  return '$minutesStr:$secondsStr';
}

/// Convierte metros a kilómetros formateados con 2 decimales.
/// Ej: 1834.2 metros -> "1.83"
String formatDistanceKm(double meters) {
  final km = meters / 1000;
  return km.toStringAsFixed(2);
}

/// Agrupa los miles con punto, al estilo español: 3980 -> "3.980",
/// 214 -> "214". Sin decimales -- para totales grandes (desnivel
/// acumulado, calorías) donde un separador ayuda a leer la magnitud
/// de un vistazo. Evita depender de `NumberFormat` (que necesita
/// datos de locale cargados) para algo tan simple.
String formatThousands(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// Formatea velocidad en km/h con 1 decimal, protegiendo contra
/// valores negativos o ruidosos que a veces reporta el GPS cuando
/// el dispositivo está casi estático.
String formatSpeedKmh(double kmh) {
  final safeValue = kmh < 0.5 ? 0.0 : kmh;
  return safeValue.toStringAsFixed(1);
}

/// Formatea pendiente en porcentaje con 1 decimal y signo explícito
/// (+ para subida, - para bajada), útil para que el ciclista distinga
/// de un vistazo si está subiendo o bajando.
String formatSlopePercent(double slope) {
  final sign = slope > 0 ? '+' : '';
  return '$sign${slope.toStringAsFixed(1)}';
}

/// "m:ss" para tramos de menos de una hora, "h:mm:ss" si pasa de una
/// hora -- SIN cero a la izquierda en la unidad más significativa
/// ("4:32", "1:05:12"). Pensado para tiempos de esfuerzo/segmento,
/// donde `formatDuration` (que siempre rellena a "MM:SS") se ve raro.
///
/// Antes esto estaba reimplementado como `_formatDuration` dentro de
/// `segment_detail_screen.dart` -- ahora vive acá y se comparte.
String formatElapsedShort(Duration duration) {
  final totalSeconds = duration.inSeconds.abs();
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  final ss = seconds.toString().padLeft(2, '0');
  if (hours > 0) {
    final mm = minutes.toString().padLeft(2, '0');
    return '$hours:$mm:$ss';
  }
  return '$minutes:$ss';
}

/// Diferencia de tiempo con signo explícito, para comparar contra un
/// fantasma / mejor marca: "+0:12" (vas más lento), "-0:05" (vas más
/// rápido), "0:00" (empate exacto). Usa [formatElapsedShort] para el
/// valor absoluto.
String formatSignedDuration(Duration delta) {
  if (delta.inSeconds == 0) return '0:00';
  final sign = delta.isNegative ? '-' : '+';
  return '$sign${formatElapsedShort(delta)}';
}
