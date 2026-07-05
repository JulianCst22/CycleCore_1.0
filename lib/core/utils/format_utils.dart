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
