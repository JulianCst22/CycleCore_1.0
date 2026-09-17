import 'level_info.dart';

/// Cómo se desbloquea algo (una pieza del vestidor, una voz de guía...).
/// Todo por **hacer cosas de ciclismo de verdad**, nunca por azar.
enum KitUnlockKind {
  always,
  rankReached,
  rankCompleted,
  totalKm,
  totalElevation,
  postales,
  rideSpeedKmh,
  longestRideKm,
}

class KitUnlockCondition {
  final KitUnlockKind kind;

  /// Umbral: nº de nivel, km, metros, cantidad de postales o km/h,
  /// según [kind]. Ignorado para [KitUnlockKind.always] y
  /// [KitUnlockKind.rankCompleted].
  final double value;

  /// Sólo para [KitUnlockKind.rankCompleted].
  final CyclistRank? rank;

  const KitUnlockCondition(this.kind, {this.value = 0, this.rank});

  static const always = KitUnlockCondition(KitUnlockKind.always);

  String get label {
    String grouped(double m) {
      final digits = m.round().abs().toString();
      final buffer = StringBuffer();
      for (var i = 0; i < digits.length; i++) {
        if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
        buffer.write(digits[i]);
      }
      return buffer.toString();
    }

    return switch (kind) {
      KitUnlockKind.always => 'Disponible',
      KitUnlockKind.rankReached => 'Nivel ${value.toInt()}',
      KitUnlockKind.rankCompleted => 'Corona el rango ${rank!.label}',
      KitUnlockKind.totalKm => '${grouped(value)} km en total',
      KitUnlockKind.totalElevation =>
        '${grouped(value)} m de desnivel en total',
      KitUnlockKind.postales => 'Descubre ${value.toInt()} postales',
      KitUnlockKind.rideSpeedKmh =>
        'Una salida a ${value.toStringAsFixed(0)} km/h de media',
      KitUnlockKind.longestRideKm => 'Una salida de ${value.toInt()} km',
    };
  }
}
