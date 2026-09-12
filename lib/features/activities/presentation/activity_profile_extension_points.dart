import 'package:flutter/material.dart';

import 'activity_detail_screen.dart';

/// Implementación del punto de extensión de `profile`
/// (`OpenActivityDetail`/`openActivityDetailProvider`, ver
/// `profile/presentation/extension_points.dart`) para abrir el detalle
/// de una actividad guardada. `main.dart` la registra ahí -- ninguna
/// otra parte de `activities` ni de `profile` necesita conocer este
/// archivo.
void openActivityDetail(BuildContext context, int activityId) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => ActivityDetailScreen(activityId: activityId),
    ),
  );
}
