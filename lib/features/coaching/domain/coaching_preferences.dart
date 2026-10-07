import 'variables/labels.dart';

/// Cuánto habla el coach.
enum CoachingDetail {
  /// Solo el núcleo: estado, acción y motivo. Sin adornos ni
  /// seguimientos.
  esencial,

  /// Como una conversación: adornos de la voz y seguimientos que
  /// confirman si el ciclista hizo caso.
  completo;

  static CoachingDetail byName(String? name) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return CoachingDetail.completo;
  }

  String get label => switch (this) {
    CoachingDetail.esencial => 'Esencial',
    CoachingDetail.completo => 'Completo',
  };

  String get description => switch (this) {
    CoachingDetail.esencial => 'Solo lo necesario: qué hacer y por qué.',
    CoachingDetail.completo => 'Con el estilo de la voz y seguimientos.',
  };
}

/// Cada cuánto quiere el ciclista el aviso normal.
///
/// Es una preferencia, no una regla del motor: hay quien quiere
/// compañía cada minuto y quien prefiere que le hablen una vez por
/// kilómetro. Por tiempo o por distancia, porque en una subida de
/// veinte minutos no es lo mismo.
///
/// Los momentos clave no pasan por acá: si algo urgente aparece entre
/// dos avisos, se dice igual. De nada serviría avisar de una rampa
/// cuando ya se subió.
enum CoachingPace {
  cadaMinuto('Cada minuto', seconds: 60),
  cadaDosMinutos('Cada dos minutos', seconds: 120),
  cadaMedioKilometro('Cada 500 metros', meters: 500),
  cadaKilometro('Cada kilómetro', meters: 1000);

  final String label;

  /// Segundos entre avisos, si la cadencia es por tiempo.
  final int? seconds;

  /// Metros entre avisos, si es por distancia.
  final double? meters;

  const CoachingPace(this.label, {this.seconds, this.meters});

  static CoachingPace byName(String? name) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return CoachingPace.cadaDosMinutos;
  }
}

/// Lo que el ciclista eligió del coach.
final class CoachingPreferences {
  final bool enabled;
  final CoachingDetail detail;
  final CoachingPace pace;

  /// Cómo quiere subir: es lo que decide cuánta reserva se puede gastar
  /// y, con ella, la potencia con la que se llega a la cima.
  final Goal goal;

  /// Antes de grabar se muestra lo que el coach recomienda para la
  /// salida (sensores, modo, cada cuánto habla) para ajustarlo.
  final bool askBeforeRide;

  const CoachingPreferences({
    this.enabled = true,
    this.detail = CoachingDetail.completo,
    this.pace = CoachingPace.cadaDosMinutos,
    this.goal = Goal.ritmo,
    this.askBeforeRide = true,
  });

  /// Lo que el coach recomienda para una subida cualquiera, y por eso
  /// también lo que trae de fábrica:
  ///  - «Duro»: aprieta de verdad sin vaciarse; «A tope» tiene sentido
  ///    cuando se va por la marca, y «Fondo» cuando se entrena suave.
  ///  - Cada dos minutos: en una subida de media hora son unos quince
  ///    turnos, y lo urgente (una rampa, el pulso arriba) igual entra
  ///    cuando aparece. Cada minuto satura; por kilómetro deja huecos
  ///    largos donde la pendiente es fuerte y se va lento.
  ///  - Completo: los seguimientos confirman si se hizo caso.
  static const recommended = CoachingPreferences();

  CoachingPreferences copyWith({
    bool? enabled,
    CoachingDetail? detail,
    CoachingPace? pace,
    Goal? goal,
    bool? askBeforeRide,
  }) => CoachingPreferences(
    enabled: enabled ?? this.enabled,
    detail: detail ?? this.detail,
    pace: pace ?? this.pace,
    goal: goal ?? this.goal,
    askBeforeRide: askBeforeRide ?? this.askBeforeRide,
  );
}
