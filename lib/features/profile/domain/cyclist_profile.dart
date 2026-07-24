/// Perfil del ciclista: datos base que alimentan el motor de lógica difusa
/// para comparar el esfuerzo en vivo (FC, potencia) contra los límites
/// personales del usuario, más los datos "visuales" de identidad
/// (foto, ciudad, bio) que muestra la pantalla de Perfil.
class CyclistProfile {
  final String name;
  final double weightKg;
  final int ftpWatts;
  final int maxHr;

  /// Opcional. Si está presente, se usa la fórmula de Karvonen (reserva
  /// de FC) en vez de un simple porcentaje de FC máxima, lo cual es más
  /// preciso para detectar sobreesfuerzo real.
  final int? restingHr;

  /// Ruta local a la foto de perfil (copiada a almacenamiento permanente
  /// de la app, igual que las fotos de actividades). Null = sin foto.
  final String? avatarPath;

  /// Ciudad del usuario, mostrada bajo el nombre en el encabezado del
  /// perfil. Opcional -- no todos los usuarios querrán compartirla.
  final String? city;

  /// Biografía corta tipo Strava/Garmin Connect. Opcional.
  final String? bio;

  const CyclistProfile({
    required this.name,
    required this.weightKg,
    required this.ftpWatts,
    required this.maxHr,
    this.restingHr,
    this.avatarPath,
    this.city,
    this.bio,
  });

  /// Relación potencia/peso (W/kg) — clave para comparar esfuerzo en
  /// pendiente entre ciclistas de distinto tamaño.
  double get powerToWeight => ftpWatts / weightKg;

  /// Reserva de FC (fórmula de Karvonen). Null si no hay FC en reposo.
  int? get hrReserve => restingHr != null ? maxHr - restingHr! : null;

  /// Porcentaje de esfuerzo cardiaco (0.0 - ~1.2) dado un valor de FC en
  /// vivo. Usa Karvonen si hay FC en reposo registrada; si no, cae a un
  /// porcentaje simple sobre la FC máxima.
  double effortPercentFromHr(int liveHr) {
    final reserve = hrReserve;
    if (reserve != null && reserve > 0) {
      return ((liveHr - restingHr!) / reserve).clamp(0.0, 1.2);
    }
    if (maxHr <= 0) return 0;
    return (liveHr / maxHr).clamp(0.0, 1.2);
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'weightKg': weightKg,
        'ftpWatts': ftpWatts,
        'maxHr': maxHr,
        'restingHr': restingHr,
        'avatarPath': avatarPath,
        'city': city,
        'bio': bio,
      };

  /// Los campos nuevos (`avatarPath`, `city`, `bio`) simplemente no
  /// existen en perfiles guardados antes de esta versión -- el cast
  /// `as String?` sobre una clave ausente devuelve null sin lanzar,
  /// así que perfiles antiguos siguen cargando sin migración.
  factory CyclistProfile.fromJson(Map<String, dynamic> json) {
    return CyclistProfile(
      name: json['name'] as String,
      weightKg: (json['weightKg'] as num).toDouble(),
      ftpWatts: json['ftpWatts'] as int,
      maxHr: json['maxHr'] as int,
      restingHr: json['restingHr'] as int?,
      avatarPath: json['avatarPath'] as String?,
      city: json['city'] as String?,
      bio: json['bio'] as String?,
    );
  }

  CyclistProfile copyWith({
    String? name,
    double? weightKg,
    int? ftpWatts,
    int? maxHr,
    int? restingHr,
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
      avatarPath: avatarPath ?? this.avatarPath,
      city: city ?? this.city,
      bio: bio ?? this.bio,
    );
  }
}
