import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pestaña activa del `AppShell` (0 Mapa, 1 Segmentos, 2 Actividad,
/// 3 Perfil).
///
/// Antes vivía como estado local (`setState`) dentro de `AppShell`. Se
/// movió a un provider para que una pantalla dentro de una pestaña pueda
/// llevar al usuario a otra sin pasar callbacks por medio proyecto -- en
/// concreto, el botón "grabar" de la lista de actividades salta al Mapa,
/// que es donde arranca un recorrido.
final appTabIndexProvider = StateProvider<int>((ref) => 0);
