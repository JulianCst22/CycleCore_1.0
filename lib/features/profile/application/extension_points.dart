import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/physiology/physiology.dart';

/// Puntos de extensión de `profile` para features ajenas (hoy,
/// `activities` y `coaching`): vacíos/null por defecto, se completan una
/// sola vez desde la raíz de composición de la app (ver `main.dart`).
/// `profile` nunca importa esas features directamente.

/// Abre el detalle de una actividad guardada -- lo usan widgets de
/// profile (la hoja de detalle de un día del calendario, la grilla de
/// fotos destacadas) para saltar a la actividad de origen sin que
/// profile dependa de `activities`. `null` hasta que se registre.
typedef OpenActivityDetail = void Function(
  BuildContext context,
  int activityId,
);

final openActivityDetailProvider = Provider<OpenActivityDetail?>(
  (ref) => null,
);

/// Potencia crítica y W′ del ciclista, con una frase que dice de dónde
/// salen. Los calibra `coaching` (que depende de profile, así que profile
/// no puede preguntarle directamente). `null` hasta que se registre o si
/// no hay datos de potencia.
typedef CriticalPowerSummary = ({CriticalPowerModel model, String basis});

final criticalPowerSummaryProvider = Provider<CriticalPowerSummary?>(
  (ref) => null,
);
