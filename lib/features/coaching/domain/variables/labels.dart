// Etiquetas lingüísticas del coach. El orden de declaración importa: va
// de menor a mayor, y así lo usa la revisión de suavidad de las reglas.

// --- Entradas del motor de estado (biométricas) ---

enum IntensityLevel { suave, umbral, duro, insostenible }

enum HeartRateLevel { baja, media, alta, tope }

enum TorqueLevel { ligero, normal, pesado, atascado }

enum ReserveLevel { agotada, comprometida, sana }

enum SufficiencyLevel { insuficiente, justa, holgada }

/// Cómo va la potencia frente al ritmo que pide el modo del día.
enum PlanGapLevel { porDebajo, enPlan, porEncima }

enum DecouplingLevel { nula, incipiente, marcada }

enum VariabilityLevel { pareja, irregular }

// --- Entradas del motor de demanda (terreno) ---

enum GradientLevel { llano, repecho, sostenida, muro }

enum RoughnessLevel { regular, escalonado }

enum ClimbLevel { poco, medio, mucho }

enum PhaseLevel { arranque, primerTercio, medio, remate }

enum RecordPaceLevel { retrasado, enRitmo, adelante }

/// Objetivo que el ciclista declara al entrar al segmento.
///
/// Cada modo es un ritmo: una parte de la potencia con la que el
/// ciclista subiría el segmento a tope. Esa potencia a tope sale del
/// modelo de potencia crítica, `CP + reserva / tiempo que falta`, y la
/// reserva anaeróbica es pequeña frente a una subida larga: repartida
/// en veinte minutos son unos pocos vatios. Por eso los modos no se
/// distinguen por cuánta reserva dejan (subirían casi igual), sino por
/// su ritmo; la reserva queda como el límite que cada modo no cruza.
///
/// Con el ciclista de ejemplo, que a tope sube Patios en 20 minutos,
/// duro son unos 21:30 y fondo unos 24.
enum Goal {
  /// Fondo: ritmo tempo, por debajo del umbral. No baja la reserva del
  /// 30 %.
  recuperacion('Fondo', intensity: 0.83, reserveFloor: 0.30),

  /// Duro: ritmo de umbral. No baja la reserva del 10 %, que es donde
  /// la literatura ubica lo «duro sin reventar» (Skiba et al., 2014) y
  /// lo que se equivoca la medición del tanque.
  ritmo('Duro', intensity: 0.93, reserveFloor: 0.10),

  /// A tope: todo lo que da el modelo, planeando gastar un 5 % más de
  /// reserva de la calibrada; en el tramo final pide todavía más.
  pr('A tope', intensity: 1.0, reserveFloor: -0.05);

  /// Cómo se llama el modo en la app.
  final String label;

  /// Parte de la potencia a tope que pide este modo.
  final double intensity;

  /// Fracción del tanque (W′) por debajo de la cual este modo no deja
  /// bajar la reserva. Negativa: se planea gastar más que el tanque
  /// calibrado.
  final double reserveFloor;

  const Goal(this.label, {required this.intensity, required this.reserveFloor});

  String get description => switch (this) {
    Goal.recuperacion => 'Ritmo tempo, controlado y sin vaciarte.',
    Goal.ritmo => 'Ritmo de umbral y remate fuerte en el último tramo.',
    Goal.pr => 'Todo lo que tengas y un poco más para llegar vacío.',
  };

  static Goal byName(String? name) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return Goal.ritmo;
  }
}

// --- Salidas ---

/// Estado del ciclista (motor A): cuánto le queda.
enum EffortState { fundido, alLimite, justo, comodo, sobrado }

/// Demanda del terreno (motor B): cuánto va a pedir lo que viene.
enum Demand { recuperacion, llano, repecho, sostenida, muro }

/// Ajuste de la intensidad (motor C).
enum Adjustment { soltarMucho, soltar, mantener, apretar, apretarMucho }

/// Cadencia objetivo (motor C).
enum CadenceLevel { baja, media, alta }

/// Urgencia de comunicar (motor C).
enum Urgency { nula, baja, media, alta }
