// Etiquetas lingüísticas del coach. El orden de declaración importa: va
// de menor a mayor, y así lo usa la revisión de suavidad de las reglas.

// --- Entradas del motor de estado (biométricas) ---

enum IntensityLevel { suave, umbral, duro, insostenible }

enum HeartRateLevel { baja, media, alta, tope }

enum TorqueLevel { ligero, normal, pesado, atascado }

enum ReserveLevel { agotada, comprometida, sana }

enum SufficiencyLevel { insuficiente, justa, holgada }

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
/// Además de mover las reglas, cada objetivo dice qué parte de la
/// reserva anaeróbica se puede gastar en este segmento. Esa fracción es
/// la que decide con qué potencia se llega a la cima: el modo a tope
/// llega vacío, el modo duro llega con un resto y el fondo casi no toca
/// el tanque.
enum Goal {
  /// Fondo: se entrena, no se compite. Trabaja cerca de la potencia
  /// crítica y deja el tanque casi intacto.
  recuperacion('Fondo', 0.35),

  /// Duro: aprieta de verdad pero llega con algo guardado.
  ritmo('Duro', 0.85),

  /// A tope: el tanque se vacía justo al coronar.
  pr('A tope', 1.0);

  /// Cómo se llama el modo en la app.
  final String label;

  /// Fracción de W′bal que este modo autoriza a gastar.
  final double spendable;

  const Goal(this.label, this.spendable);

  String get description => switch (this) {
    Goal.recuperacion => 'Trabajo cerca del umbral, sin vaciarte.',
    Goal.ritmo => 'Aprietas fuerte y coronas con algo de resto.',
    Goal.pr => 'Todo lo que tengas, dosificado para llegar justo.',
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
