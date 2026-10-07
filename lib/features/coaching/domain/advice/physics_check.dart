/// Contraste entre los dos caminos que llegan al mismo número.
///
/// El motor difuso razona con etiquetas («vas al límite», «viene un
/// muro») y no conoce la ecuación de la reserva; la física calcula
/// `P_sost = CP + W′bal / t_restante` y no sabe nada de reglas. Que los
/// dos den lo mismo es la verificación independiente que pide la
/// especificación (F12): si se separan más de un diez por ciento, el
/// que está mal es el que se puede arreglar —la base de reglas—, y
/// conviene saberlo antes de creerle al consejo.
///
/// Se compara contra lo que las reglas **pidieron**, no contra el
/// objetivo ya recortado por el techo sostenible: comparar el número
/// recortado con la física es preguntarle a alguien si está de acuerdo
/// consigo mismo.
final class PhysicsCheck {
  /// Vatios que pidieron las reglas, sin recortar.
  final double advised;

  /// Vatios que salen de la física de W′bal.
  final double sustainable;

  /// Diferencia relativa con signo: positiva si las reglas piden más de
  /// lo que la física aguanta.
  final double difference;

  /// Separación máxima que se considera acuerdo.
  final double tolerance;

  const PhysicsCheck({
    required this.advised,
    required this.sustainable,
    required this.difference,
    required this.tolerance,
  });

  /// Los dos caminos no coinciden: hay que revisar la base de reglas.
  bool get needsReview => difference.abs() > tolerance;

  /// Diferencia en puntos porcentuales, que es como se lee.
  double get differencePercent => difference * 100;

  @override
  String toString() =>
      '${advised.round()} W vs ${sustainable.round()} W '
      '(${differencePercent >= 0 ? '+' : ''}'
      '${differencePercent.toStringAsFixed(1)} %)';
}

/// Arma el contraste de un instante. `null` cuando falta alguno de los
/// dos caminos: sin potencia sostenible no hay con qué comparar.
PhysicsCheck? physicsCheckOf({
  required double? advised,
  required double? sustainable,
  double tolerance = 0.10,
}) {
  if (advised == null || sustainable == null || sustainable <= 0) return null;
  return PhysicsCheck(
    advised: advised,
    sustainable: sustainable,
    difference: (advised - sustainable) / sustainable,
    tolerance: tolerance,
  );
}

/// Lo que se acumula a lo largo de una subida.
///
/// La especificación pide que el contraste se registre **en cada
/// evaluación**, no solo en las que se hablan. Guardar una fila por
/// segundo no tendría sentido, así que se lleva el resumen: cuántas
/// veces se miró, cuántas se separaron y cuál fue la peor.
final class PhysicsReview {
  int _evaluations = 0;
  int _flagged = 0;
  double _worst = 0;

  int get evaluations => _evaluations;
  int get flagged => _flagged;

  /// Mayor separación vista, con su signo.
  double get worst => _worst;

  /// Parte de las evaluaciones en las que los dos caminos no coinciden.
  double get flaggedShare => _evaluations == 0 ? 0 : _flagged / _evaluations;

  void add(PhysicsCheck? check) {
    if (check == null) return;
    _evaluations++;
    if (check.needsReview) _flagged++;
    if (check.difference.abs() > _worst.abs()) _worst = check.difference;
  }

  @override
  String toString() {
    if (_evaluations == 0) return 'sin evaluaciones';
    final percent = (100 * flaggedShare).toStringAsFixed(0);
    final worstPercent = (100 * _worst).toStringAsFixed(1);
    return '$_flagged de $_evaluations fuera de rango ($percent %), '
        'peor ${_worst >= 0 ? '+' : ''}$worstPercent %';
  }
}

/// Redondeo de la diferencia para guardarla: décimas de punto, que es
/// todo lo que se va a leer después.
double roundDifference(double difference) =>
    (difference * 1000).roundToDouble() / 10;
