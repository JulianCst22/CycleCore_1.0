import '../../../core/physiology/physiology.dart'
    show RidingResistance, cadenceInGear;

/// Tipo de bicicleta. Cambia lo que rueda y lo que frena el aire, así
/// que cambia la potencia que el motor estima cuando no hay
/// potenciómetro.
enum BikeKind {
  ruta,
  montana;

  static BikeKind byName(String? name) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return BikeKind.ruta;
  }

  String get label => switch (this) {
    BikeKind.ruta => 'Ruta',
    BikeKind.montana => 'Montaña',
  };

  String get description => switch (this) {
    BikeKind.ruta => 'Llanta delgada, posición agachada',
    BikeKind.montana => 'Llanta ancha y taco, posición erguida',
  };

  /// Peso típico, para proponer algo mientras el ciclista pesa la suya.
  double get typicalWeightKg => switch (this) {
    BikeKind.ruta => 9,
    BikeKind.montana => 13,
  };

  /// Resistencia a la rodadura sobre asfalto.
  ///
  /// Una llanta de ruta a presión alta rueda con Crr ≈ 0,004; una de
  /// montaña con taco, sobre el mismo asfalto, cuesta el doble o más.
  /// En subida la rodadura pesa poco frente a la gravedad, pero en
  /// llano se nota.
  double get rollingResistance => switch (this) {
    BikeKind.ruta => 0.004,
    BikeKind.montana => 0.010,
  };

  double get rollingResistanceUncertainty => switch (this) {
    BikeKind.ruta => 0.0012,
    BikeKind.montana => 0.0030,
  };

  /// Área frontal por coeficiente de arrastre: la de ruta va más
  /// agachada y con manillar curvo.
  double get dragArea => switch (this) {
    BikeKind.ruta => 0.32,
    BikeKind.montana => 0.42,
  };

  double get dragAreaUncertainty => switch (this) {
    BikeKind.ruta => 0.05,
    BikeKind.montana => 0.07,
  };

  /// Desarrollo más suave típico: plato pequeño y piñón grande.
  ///
  /// Una de ruta moderna de montaña colombiana anda en 34×32; una de
  /// montaña, con monoplato, en 30×51.
  ({int chainring, int cog}) get typicalLowestGear => switch (this) {
    BikeKind.ruta => (chainring: 34, cog: 32),
    BikeKind.montana => (chainring: 30, cog: 51),
  };

  /// Desarrollo más duro típico: plato grande y piñón chico. En ruta
  /// 50×11; en montaña, monoplato de 30 con el piñón de 10.
  ({int chainring, int cog}) get typicalHighestGear => switch (this) {
    BikeKind.ruta => (chainring: 50, cog: 11),
    BikeKind.montana => (chainring: 30, cog: 10),
  };

  /// Perímetro de rueda típico, en milímetros (700×28 y 29×2.2).
  int get typicalWheelCircumferenceMm => switch (this) {
    BikeKind.ruta => 2136,
    BikeKind.montana => 2300,
  };

  /// Desarrollo duro que se supone sin saber qué bicicleta lleva: a
  /// propósito más suave que el típico (46×12 y 30×12), por la misma
  /// razón que el otro, al revés: si se supone más duro del que tiene,
  /// se le pediría bajar a una cadencia que no puede alcanzar.
  double get cautiousHighestGearMeters => switch (this) {
    BikeKind.ruta => 46 / 12 * typicalWheelCircumferenceMm / 1000,
    BikeKind.montana => 30 / 12 * typicalWheelCircumferenceMm / 1000,
  };

  /// Desarrollo que se supone cuando **no se sabe** qué bicicleta lleva:
  /// a propósito más duro que el típico (34×28 y 30×42).
  ///
  /// Suponer de más en este número es el único error caro: con un
  /// desarrollo supuesto más suave que el real, el coach pediría una
  /// cadencia que la bicicleta no da y sugeriría subir un piñón que no
  /// existe. Suponiendo de menos, a lo sumo se queda callado.
  double get cautiousLowestGearMeters => switch (this) {
    BikeKind.ruta => 34 / 28 * typicalWheelCircumferenceMm / 1000,
    BikeKind.montana => 30 / 42 * typicalWheelCircumferenceMm / 1000,
  };
}

/// Una bicicleta del ciclista.
///
/// No es solo una etiqueta para la actividad: su peso entra en la masa
/// total y su tipo en la rodadura y el arrastre, que es de lo que sale
/// la potencia estimada cuando no hay potenciómetro.
final class Bike {
  final int id;
  final String name;
  final String? brand;
  final BikeKind kind;

  /// Peso de la bicicleta lista para rodar. `null` = sin pesar; se usa
  /// el típico de su tipo y la banda se ensancha.
  final double? weightKg;

  /// Color de su ficha, en ARGB.
  final int? color;
  final String? photoPath;
  final String? notes;
  final bool isDefault;
  final DateTime createdAt;

  /// Los dos extremos de su transmisión. `null` = el típico de su tipo.
  final int? lowestChainring;
  final int? largestCog;
  final int? largestChainring;
  final int? smallestCog;
  final int? wheelCircumferenceMm;

  const Bike({
    required this.id,
    required this.name,
    required this.kind,
    required this.isDefault,
    required this.createdAt,
    this.brand,
    this.weightKg,
    this.color,
    this.photoPath,
    this.notes,
    this.lowestChainring,
    this.largestCog,
    this.largestChainring,
    this.smallestCog,
    this.wheelCircumferenceMm,
  });

  /// Metros que avanza por pedalada en el desarrollo más suave.
  double get lowestGearMeters {
    final chainring = lowestChainring ?? kind.typicalLowestGear.chainring;
    final cog = largestCog ?? kind.typicalLowestGear.cog;
    final wheel =
        (wheelCircumferenceMm ?? kind.typicalWheelCircumferenceMm) / 1000;
    return chainring / cog * wheel;
  }

  /// Metros que avanza por pedalada en el desarrollo más duro.
  double get highestGearMeters {
    final chainring = largestChainring ?? kind.typicalHighestGear.chainring;
    final cog = smallestCog ?? kind.typicalHighestGear.cog;
    final wheel =
        (wheelCircumferenceMm ?? kind.typicalWheelCircumferenceMm) / 1000;
    return chainring / cog * wheel;
  }

  /// Cadencia que daría a [speedMetersPerSecond] **en el piñón más
  /// suave**: por debajo de esto no se puede pedalear más rápido con
  /// esta bicicleta.
  ///
  ///     rpm = v · 60 / (desarrollo por pedalada)
  ///
  /// Sirve para no dar un consejo imposible. Si alguien sube un muro a
  /// 6 km/h ya está en el último piñón: decirle «sube un piñón» es
  /// decirle algo que no puede hacer, y eso quema la confianza más
  /// rápido que un consejo malo.
  double cadenceInLowestGear(double speedMetersPerSecond) =>
      cadenceInGear(speedMetersPerSecond, lowestGearMeters);

  /// Si le queda piñón para subir la cadencia hasta [targetCadence]
  /// yendo a [speedMetersPerSecond].
  ///
  /// Se deja un margen de 3 rpm: estar justo en el límite tampoco
  /// sirve.
  bool canReachCadence(double targetCadence, double speedMetersPerSecond) =>
      cadenceInLowestGear(speedMetersPerSecond) >= targetCadence + 3;

  /// Peso con el que se hacen las cuentas: el que pesó el ciclista o el
  /// típico de su tipo.
  double get effectiveWeightKg => weightKg ?? kind.typicalWeightKg;

  /// Lo que el motor necesita para estimar la potencia: la masa total
  /// (ciclista + bicicleta) y cómo se comporta esta bici contra el piso
  /// y contra el aire.
  ///
  /// Si el peso no está medido, la incertidumbre de la masa se abre:
  /// suponer es válido, esconder que se supuso no.
  RidingResistance resistanceWith({required double riderWeightKg}) {
    return RidingResistance(
      massKg: riderWeightKg + effectiveWeightKg,
      massUncertaintyKg: weightKg == null ? 3.5 : 1.5,
      rollingResistance: kind.rollingResistance,
      rollingResistanceUncertainty: kind.rollingResistanceUncertainty,
      dragArea: kind.dragArea,
      dragAreaUncertainty: kind.dragAreaUncertainty,
      lowestGearMeters: lowestGearMeters,
      highestGearMeters: highestGearMeters,
    );
  }

  Bike copyWith({
    String? name,
    String? brand,
    BikeKind? kind,
    double? weightKg,
    int? color,
    String? photoPath,
    String? notes,
    bool? isDefault,
    int? lowestChainring,
    int? largestCog,
    int? largestChainring,
    int? smallestCog,
    int? wheelCircumferenceMm,
  }) => Bike(
    id: id,
    name: name ?? this.name,
    brand: brand ?? this.brand,
    kind: kind ?? this.kind,
    weightKg: weightKg ?? this.weightKg,
    color: color ?? this.color,
    photoPath: photoPath ?? this.photoPath,
    notes: notes ?? this.notes,
    isDefault: isDefault ?? this.isDefault,
    createdAt: createdAt,
    lowestChainring: lowestChainring ?? this.lowestChainring,
    largestCog: largestCog ?? this.largestCog,
    largestChainring: largestChainring ?? this.largestChainring,
    smallestCog: smallestCog ?? this.smallestCog,
    wheelCircumferenceMm: wheelCircumferenceMm ?? this.wheelCircumferenceMm,
  );
}

/// Lo que lleva rodado una bicicleta. Sale de sumar sus actividades, no
/// de un contador aparte: un contador se desincroniza en cuanto se borra
/// o se edita una salida.
typedef BikeUsage = ({
  int activities,
  double distanceMeters,
  Duration time,
  double elevationGainMeters,
  DateTime? lastRide,
});

const emptyBikeUsage = (
  activities: 0,
  distanceMeters: 0.0,
  time: Duration.zero,
  elevationGainMeters: 0.0,
  lastRide: null,
);
