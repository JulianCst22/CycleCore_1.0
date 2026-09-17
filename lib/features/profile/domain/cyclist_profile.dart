/// Perfil del ciclista: datos base que alimentan el motor de lógica
/// difusa para comparar el esfuerzo en vivo (FC, potencia) contra los
/// límites personales, más los datos "visuales" de identidad (foto,
/// ciudad, bio) que muestra la pantalla de Perfil.
///
/// **Ningún dato deportivo es obligatorio.** No todo el mundo conoce su
/// FTP o su FC máxima, ni todo el mundo usa potenciómetro. Cuando un
/// dato falta, la parte de la app que lo necesita simplemente se apaga
/// (sin zonas de potencia si no hay FTP, calorías por peso en vez de por
/// vatios, etc.) y el usuario lo completa después desde "Editar perfil".
class CyclistProfile {
  final String name;

  /// Peso en kg. `null` = sin registrar (las calorías sin potenciómetro
  /// no se pueden estimar).
  final double? weightKg;

  /// FTP en vatios. `null` = sin registrar (no se calculan zonas de
  /// potencia ni la relación W/kg).
  final int? ftpWatts;

  /// FC máxima en lpm. `null` = sin registrar (no se calculan zonas de
  /// FC). Se puede estimar con [estimatedMaxHrFromAge] si hay fecha de
  /// nacimiento.
  final int? maxHr;

  /// Opcional. Si está presente (junto con [maxHr]), se usa la fórmula de
  /// Karvonen (reserva de FC) en vez de un simple porcentaje de FC
  /// máxima, lo cual es más preciso para detectar sobreesfuerzo real.
  final int? restingHr;

  /// Fecha de nacimiento. Sólo se usa para calcular la edad (y con ella
  /// un estimado de FC máxima). `null` = no registrada.
  final DateTime? birthDate;

  /// Ruta local a la foto de perfil. Null = sin foto.
  final String? avatarPath;

  /// Ciudad del usuario. Opcional.
  final String? city;

  /// Biografía corta tipo Strava/Garmin Connect. Opcional.
  final String? bio;

  const CyclistProfile({
    required this.name,
    this.weightKg,
    this.ftpWatts,
    this.maxHr,
    this.restingHr,
    this.birthDate,
    this.avatarPath,
    this.city,
    this.bio,
  });

  /// Relación potencia/peso (W/kg). `null` si falta el FTP o el peso.
  double? get powerToWeight {
    final ftp = ftpWatts;
    final weight = weightKg;
    if (ftp == null || weight == null || weight <= 0) return null;
    return ftp / weight;
  }

  /// Reserva de FC (fórmula de Karvonen). `null` si falta FC máxima o FC
  /// en reposo.
  int? get hrReserve {
    final max = maxHr;
    final rest = restingHr;
    if (max == null || rest == null) return null;
    return max - rest;
  }

  /// Edad en años cumplidos. `null` si no hay fecha de nacimiento.
  int? get age {
    final dob = birthDate;
    if (dob == null) return null;
    final now = DateTime.now();
    var years = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      years--;
    }
    return years < 0 ? null : years;
  }

  /// Estimado de FC máxima a partir de la edad (Tanaka: 208 − 0.7·edad).
  /// `null` si no hay fecha de nacimiento. Es sólo una sugerencia -- la
  /// UI lo ofrece, no lo impone.
  int? get estimatedMaxHrFromAge {
    final a = age;
    if (a == null) return null;
    return (208 - 0.7 * a).round();
  }

  /// Porcentaje de esfuerzo cardiaco (0.0 - ~1.2) dado un valor de FC en
  /// vivo. Usa Karvonen si hay FC en reposo; si no, un porcentaje simple
  /// sobre la FC máxima. `null` si no hay FC máxima registrada.
  double? effortPercentFromHr(int liveHr) {
    final reserve = hrReserve;
    if (reserve != null && reserve > 0) {
      return ((liveHr - restingHr!) / reserve).clamp(0.0, 1.2);
    }
    final max = maxHr;
    if (max == null || max <= 0) return null;
    return (liveHr / max).clamp(0.0, 1.2);
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'weightKg': weightKg,
    'ftpWatts': ftpWatts,
    'maxHr': maxHr,
    'restingHr': restingHr,
    'birthDate': birthDate?.toIso8601String(),
    'avatarPath': avatarPath,
    'city': city,
    'bio': bio,
  };

  /// Perfiles guardados antes de esta versión traían `weightKg` /
  /// `ftpWatts` / `maxHr` siempre presentes y sin `birthDate`; el cast
  /// sobre una clave ausente devuelve `null` sin lanzar, así que cargan
  /// sin migración.
  factory CyclistProfile.fromJson(Map<String, dynamic> json) {
    final rawBirth = json['birthDate'] as String?;
    return CyclistProfile(
      name: json['name'] as String,
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      ftpWatts: (json['ftpWatts'] as num?)?.toInt(),
      maxHr: (json['maxHr'] as num?)?.toInt(),
      restingHr: (json['restingHr'] as num?)?.toInt(),
      birthDate: rawBirth == null ? null : DateTime.tryParse(rawBirth),
      avatarPath: json['avatarPath'] as String?,
      city: json['city'] as String?,
      bio: json['bio'] as String?,
    );
  }

  /// `copyWith` con el patrón `?? this.x` NO distingue "no tocar" de
  /// "vaciar a null". Para vaciar un dato deportivo a propósito (o la
  /// ciudad/bio) hay que construir un `CyclistProfile` nuevo a mano.
  CyclistProfile copyWith({
    String? name,
    double? weightKg,
    int? ftpWatts,
    int? maxHr,
    int? restingHr,
    DateTime? birthDate,
    String? avatarPath,
    String? city,
    String? bio,
  }) {
    return CyclistProfile(
      name: name ?? this.name,
      weightKg: weightKg ?? this.weightKg,
      ftpWatts: ftpWatts ?? this.ftpWatts,
      maxHr: maxHr ?? this.maxHr,
      restingHr: restingHr ?? this.restingHr,
      birthDate: birthDate ?? this.birthDate,
      avatarPath: avatarPath ?? this.avatarPath,
      city: city ?? this.city,
      bio: bio ?? this.bio,
    );
  }
}
