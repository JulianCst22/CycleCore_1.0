import 'package:cyclecore_app/core/fuzzy_type2/fuzzy_type2.dart';
import 'package:cyclecore_app/features/coaching/domain/coaching_parameters.dart';
import 'package:cyclecore_app/features/coaching/domain/engine/coaching_engine.dart';
import 'package:cyclecore_app/features/coaching/domain/variables/labels.dart';

/// Una superficie de control: cómo cambia una salida del motor al mover
/// dos entradas y dejar las demás quietas.
///
/// Es la figura clásica de un sistema difuso y la que muestra de un
/// vistazo que la respuesta es continua, sin escalones.
final class ControlSurface {
  final String name;
  final String xLabel;
  final String yLabel;
  final String zLabel;
  final List<double> xs;
  final List<double> ys;

  /// `z[fila y][columna x]`; `null` donde ninguna regla aportó evidencia.
  final List<List<double?>> z;

  /// Qué se dejó fijo, para el pie de figura.
  final String held;

  const ControlSurface({
    required this.name,
    required this.xLabel,
    required this.yLabel,
    required this.zLabel,
    required this.xs,
    required this.ys,
    required this.z,
    required this.held,
  });

  ({double lo, double hi}) get range {
    var lo = double.infinity, hi = double.negativeInfinity;
    for (final row in z) {
      for (final value in row) {
        if (value == null) continue;
        if (value < lo) lo = value;
        if (value > hi) hi = value;
      }
    }
    return lo > hi ? (lo: 0, hi: 1) : (lo: lo, hi: hi);
  }

  /// Celdas donde alguna regla aportó evidencia, sobre el total.
  ///
  /// Una celda vacía no es un error del dibujo: es un punto donde
  /// ninguna regla habla y el coach se queda callado. Verlo en la
  /// superficie es la forma más clara de encontrar un hueco en la base
  /// de reglas.
  double get covered {
    var defined = 0, total = 0;
    for (final row in z) {
      for (final value in row) {
        total++;
        if (value != null) defined++;
      }
    }
    return total == 0 ? 0 : defined / total;
  }

  String toCsv() {
    final buffer = StringBuffer('${yLabel}_vs_$xLabel');
    for (final x in xs) {
      buffer.write(',${x.toStringAsFixed(3)}');
    }
    buffer.writeln();
    for (var i = 0; i < ys.length; i++) {
      buffer.write(ys[i].toStringAsFixed(3));
      for (var j = 0; j < xs.length; j++) {
        buffer.write(',${z[i][j]?.toStringAsFixed(3) ?? ''}');
      }
      buffer.writeln();
    }
    return buffer.toString();
  }
}

/// Las cuatro superficies que van al documento: las dos de los motores
/// de entrada y las dos del motor de decisión.
List<ControlSurface> defaultSurfaces({
  InferenceMode mode = InferenceMode.type2,
  CoachingParameters parameters = const CoachingParameters(),
  int steps = 41,
}) {
  final engine = CoachingEngine(mode: mode, parameters: parameters);
  final v = engine.variables;

  // --- Motor A: estado del ciclista ---
  final effort = _surface(
    name: 'estado',
    xLabel: 'intensidad',
    yLabel: 'reserva de W′ (%)',
    zLabel: 'estado',
    x: (variable: v.intensity, from: 0.6, to: 1.5),
    y: (variable: v.reserve, from: 0, to: 100),
    steps: steps,
    held:
        'reserva cardíaca 0,80 · torque 1,10 · suficiencia 1,00 · '
        'deriva 2 % · variabilidad 1,02',
    load: (inputs) => inputs
      ..crisp(v.heartRateReserve, 0.80)
      ..crisp(v.torque, 1.10)
      ..crisp(v.sufficiency, 1.00)
      ..crisp(v.decoupling, 2)
      ..crisp(v.variability, 1.02),
    infer: (inputs) => engine.effortEngine.infer(inputs)[v.effort],
  );

  // --- Motor B: demanda del terreno ---
  final demand = _surface(
    name: 'demanda',
    xLabel: 'pendiente que viene (%)',
    yLabel: 'desnivel restante (m)',
    zLabel: 'demanda',
    x: (variable: v.gradientAhead, from: -2, to: 15),
    y: (variable: v.climbLeft, from: 0, to: 600),
    steps: steps,
    held: 'rampa máxima = pendiente + 1,5 · rugosidad 1,2 · avance 40 %',
    load: (inputs) => inputs
      ..crisp(v.roughness, 1.2)
      ..crisp(v.phase, 40),
    perPoint: (inputs, x, y) => inputs..crisp(v.maxRamp, x + 1.5),
    infer: (inputs) => engine.terrainEngine.infer(inputs)[v.demand],
  );

  // --- Motor C: la decisión, con los puertos de A y B como entradas ---
  ControlSurface decision(String zLabel, LinguisticVariable<Enum> output) =>
      _surface(
        name: zLabel,
        xLabel: 'estado',
        yLabel: 'demanda',
        zLabel: zLabel,
        x: (variable: v.effort, from: 0, to: 100),
        y: (variable: v.demand, from: 0, to: 100),
        steps: steps,
        held:
            'objetivo récord · suficiencia 1,00 · desnivel 300 m · '
            'avance 40 % · ventaja 0 s · torque 1,10',
        load: (inputs) => inputs
          ..crisp(v.goal, Goal.pr.index.toDouble())
          ..crisp(v.sufficiency, 1.00)
          ..crisp(v.climbLeft, 300)
          ..crisp(v.phase, 40)
          ..crisp(v.recordPace, 0)
          ..crisp(v.torque, 1.10),
        infer: (inputs) => engine.decisionEngine.infer(inputs)[output],
      );

  return [
    effort,
    demand,
    decision('ajuste (%)', v.adjustment),
    decision('urgencia', v.urgency),
  ];
}

typedef _Axis = ({LinguisticVariable<Enum> variable, double from, double to});

/// Barre la malla y evalúa el motor en cada punto.
ControlSurface _surface({
  required String name,
  required String xLabel,
  required String yLabel,
  required String zLabel,
  required _Axis x,
  required _Axis y,
  required int steps,
  required String held,
  required FuzzyInputs Function(FuzzyInputs inputs) load,
  required OutputInference Function(FuzzyInputs inputs) infer,
  FuzzyInputs Function(FuzzyInputs inputs, double x, double y)? perPoint,
}) {
  final xs = [
    for (var i = 0; i < steps; i++) x.from + (x.to - x.from) * i / (steps - 1),
  ];
  final ys = [
    for (var i = 0; i < steps; i++) y.from + (y.to - y.from) * i / (steps - 1),
  ];
  final z = <List<double?>>[];
  for (final yValue in ys) {
    final row = <double?>[];
    for (final xValue in xs) {
      var inputs = load(FuzzyInputs());
      inputs = perPoint?.call(inputs, xValue, yValue) ?? inputs;
      inputs
        ..crisp(x.variable, xValue)
        ..crisp(y.variable, yValue);
      row.add(infer(inputs).value);
    }
    z.add(row);
  }
  return ControlSurface(
    name: name,
    xLabel: xLabel,
    yLabel: yLabel,
    zLabel: zLabel,
    xs: xs,
    ys: ys,
    z: z,
    held: held,
  );
}
