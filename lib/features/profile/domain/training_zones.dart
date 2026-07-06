import 'cyclist_profile.dart';

/// Una zona de entrenamiento genérica (potencia o FC), con límite inferior
/// y superior. `max == null` significa "sin límite superior" (última zona).
class TrainingZone {
  final String name;
  final int min;
  final int? max;

  const TrainingZone({required this.name, required this.min, this.max});

  Map<String, dynamic> toJson() => {'name': name, 'min': min, 'max': max};

  factory TrainingZone.fromJson(Map<String, dynamic> json) => TrainingZone(
        name: json['name'] as String,
        min: json['min'] as int,
        max: json['max'] as int?,
      );

  TrainingZone copyWith({String? name, int? min, int? max, bool clearMax = false}) {
    return TrainingZone(
      name: name ?? this.name,
      min: min ?? this.min,
      max: clearMax ? null : (max ?? this.max),
    );
  }
}

/// Conjunto completo de zonas del ciclista: potencia (basadas en FTP) y
/// frecuencia cardíaca (basadas en FC máxima / reserva de Karvonen).
class TrainingZones {
  final List<TrainingZone> powerZones;
  final List<TrainingZone> heartRateZones;

  const TrainingZones({required this.powerZones, required this.heartRateZones});

  Map<String, dynamic> toJson() => {
        'powerZones': powerZones.map((z) => z.toJson()).toList(),
        'heartRateZones': heartRateZones.map((z) => z.toJson()).toList(),
      };

  factory TrainingZones.fromJson(Map<String, dynamic> json) => TrainingZones(
        powerZones: (json['powerZones'] as List)
            .map((z) => TrainingZone.fromJson(z as Map<String, dynamic>))
            .toList(),
        heartRateZones: (json['heartRateZones'] as List)
            .map((z) => TrainingZone.fromJson(z as Map<String, dynamic>))
            .toList(),
      );

  /// Calcula zonas por defecto a partir del perfil, usando el modelo
  /// estándar de Coggan (7 zonas de potencia sobre % FTP) y un modelo de
  /// 5 zonas de FC sobre % de FC máxima (o reserva de Karvonen si hay
  /// FC en reposo registrada).
  factory TrainingZones.computeDefaults(CyclistProfile profile) {
    return TrainingZones(
      powerZones: _computePowerZones(profile.ftpWatts),
      heartRateZones: _computeHeartRateZones(profile),
    );
  }

  static List<TrainingZone> _computePowerZones(int ftp) {
    int pct(double p) => (ftp * p).round();
    return [
      TrainingZone(name: 'Z1 · Recuperación', min: 0, max: pct(0.55)),
      TrainingZone(name: 'Z2 · Resistencia', min: pct(0.55) + 1, max: pct(0.75)),
      TrainingZone(name: 'Z3 · Tempo', min: pct(0.75) + 1, max: pct(0.90)),
      TrainingZone(name: 'Z4 · Umbral', min: pct(0.90) + 1, max: pct(1.05)),
      TrainingZone(name: 'Z5 · VO2 máx', min: pct(1.05) + 1, max: pct(1.20)),
      TrainingZone(name: 'Z6 · Anaeróbica', min: pct(1.20) + 1, max: pct(1.50)),
      TrainingZone(name: 'Z7 · Neuromuscular', min: pct(1.50) + 1, max: null),
    ];
  }

  static List<TrainingZone> _computeHeartRateZones(CyclistProfile profile) {
    final maxHr = profile.maxHr;
    final resting = profile.restingHr;

    // Karvonen si hay FC en reposo; si no, % simple de FC máxima.
    int atPercent(double p) {
      if (resting != null) {
        return (resting + p * (maxHr - resting)).round();
      }
      return (p * maxHr).round();
    }

    return [
      TrainingZone(name: 'Z1 · Muy suave', min: atPercent(0.50), max: atPercent(0.60)),
      TrainingZone(name: 'Z2 · Suave', min: atPercent(0.60) + 1, max: atPercent(0.70)),
      TrainingZone(name: 'Z3 · Moderado', min: atPercent(0.70) + 1, max: atPercent(0.80)),
      TrainingZone(name: 'Z4 · Duro', min: atPercent(0.80) + 1, max: atPercent(0.90)),
      TrainingZone(name: 'Z5 · Máximo', min: atPercent(0.90) + 1, max: maxHr),
    ];
  }
}
