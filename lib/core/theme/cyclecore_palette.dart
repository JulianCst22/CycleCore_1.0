import 'package:flutter/material.dart';

/// Paleta de identidad visual para los elementos NUEVOS de UX (cinta de
/// pendiente, overlays de estado, cockpit con jerarquía).
///
/// Deliberadamente separada de `AppColors`: no reemplaza esa paleta ni
/// obliga a migrar los widgets existentes de una vez -- convive con
/// ella. `AppColors` sigue siendo la fuente de verdad para todo lo que
/// ya funciona (StatTile, cockpit compacto, etc).
///
/// Por qué esta dirección y no azules/naranjas: Garmin y Wahoo usan
/// azul de marca; Strava usa naranja. Un verde-musgo de páramo andino y
/// un terracota-óxido de vía destapada son específicos del terreno que
/// esta app conoce (Zipaquirá, Cerros de Bogotá) -- no genéricos de
/// "app de fitness".
class CyclecorePalette {
  CyclecorePalette._();

  /// Fondo base -- un carbón con temperatura, no negro puro.
  static const Color grafito = Color(0xFF14181C);

  /// Superficie de tarjetas/paneles sobre el grafito.
  static const Color panel = Color(0xFF1C232B);

  /// Texto secundario, etiquetas, íconos inactivos.
  static const Color niebla = Color(0xFF8D98A6);

  /// Texto primario, números grandes.
  static const Color hueso = Color(0xFFF1F3F0);

  /// Acento de marca y de pendiente suave/plana. Verde-musgo, no el
  /// verde "success" genérico.
  static const Color paramo = Color.fromARGB(255, 255, 108, 54);

  /// Color del botón de recentrar el mapa cuando el seguimiento
  /// automático está activo. Alias de [paramo] -- es el mismo acento
  /// de marca, con nombre propio porque semánticamente representa otra
  /// cosa ("ubicación siguiendo activamente") y así queda más claro en
  /// el sitio donde se usa (`_RecenterButton`).
  static const Color ubicacionActiva = Color.fromARGB(255, 52, 81, 106); 

  /// Punto intermedio del gradiente de pendiente (uso interno de
  /// [slopeColorFor] -- rara vez se referencia directo).
  static const Color _ambarIntermedio = Color(0xFFD9A441);

  /// Acento de alerta / pendiente fuerte. Terracota-óxido.
  static const Color oxido = Color(0xFFE0663D);

  /// Color continuo de pendiente -- interpola Páramo → Ámbar → Óxido
  /// según el % de pendiente. Mismo criterio de gradiente continuo que
  /// ya usa `activity_charts.dart` para el historial, ahora también
  /// disponible para el cockpit en vivo (ver [SlopeRibbon]).
  ///
  /// [slopePercent] negativo (bajada) se trata igual que su valor
  /// absoluto para el color -- lo que importa visualmente es cuánto
  /// esfuerzo/atención exige el tramo, no el signo.
  static Color slopeColorFor(double slopePercent) {
    final magnitude = slopePercent.abs().clamp(0.0, 12.0);
    if (magnitude <= 6.0) {
      final t = magnitude / 6.0;
      return Color.lerp(paramo, _ambarIntermedio, t)!;
    }
    final t = ((magnitude - 6.0) / 6.0).clamp(0.0, 1.0);
    return Color.lerp(_ambarIntermedio, oxido, t)!;
  }
}
