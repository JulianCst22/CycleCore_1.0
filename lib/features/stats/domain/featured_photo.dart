/// Una foto "destacada" del perfil: viene de una actividad que fue
/// récord personal para su tipo (mismo criterio que ya usas en
/// `ActivitiesListScreen` para la medalla), para que "destacado" tenga
/// coherencia con la gamificación existente en vez de ser un concepto
/// nuevo y aislado.
class FeaturedPhoto {
  final String photoPath;
  final int activityId;
  final String activityTitle;
  final String activityType;
  final DateTime startedAt;

  const FeaturedPhoto({
    required this.photoPath,
    required this.activityId,
    required this.activityTitle,
    required this.activityType,
    required this.startedAt,
  });
}
