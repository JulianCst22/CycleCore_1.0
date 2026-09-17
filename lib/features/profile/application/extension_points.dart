import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Puntos de extensión de `profile` para features ajenas (hoy,
/// `activities`): vacíos/null por defecto, se completan una sola vez
/// desde la raíz de composición de la app (ver `main.dart`). `profile`
/// nunca importa esas features directamente.

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
