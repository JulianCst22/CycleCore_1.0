import 'dart:async';
import 'dart:isolate';

import '../domain/ch_router.dart';
import '../domain/navigation_route.dart';
import '../domain/road_graph.dart';
import '../domain/route_snapper.dart';
import '../domain/turn_instruction_builder.dart';

/// El origen o el destino quedan fuera del mapa descargado: la vía más
/// cercana está demasiado lejos para que el punto sea de ese mapa.
class OutsideMapException implements Exception {
  /// true si es el destino; false si es el origen.
  final bool destination;

  const OutsideMapException({required this.destination});

  @override
  String toString() => destination
      ? 'El destino queda por fuera del mapa descargado.'
      : 'Estás por fuera del mapa descargado.';
}

/// Un isolate que tiene cargado el grafo de una región y calcula rutas.
///
/// El grafo de Cundinamarca son ~100 MB en memoria. Antes se armaba en
/// el isolate de la interfaz -- la pantalla se quedaba congelada varios
/// segundos la primera vez -- y la búsqueda también corría ahí. Ahora el
/// grafo vive solo en este isolate: la interfaz le manda origen y
/// destino y recibe la ruta ya armada (unos pocos KB), y mientras tanto
/// puede seguir animando.
class RouteWorker {
  RouteWorker._(this._isolate, this._requests);

  final Isolate _isolate;
  final SendPort _requests;

  /// Levanta el isolate y carga el grafo de [filePath]. Termina cuando
  /// el grafo ya está listo para rutear.
  static Future<RouteWorker> start(String filePath) async {
    final ready = ReceivePort();
    final errors = ReceivePort();
    final isolate = await Isolate.spawn(
      _main,
      (ready.sendPort, filePath),
      onError: errors.sendPort,
      debugName: 'ruteo',
    );
    final first = await Future.any([ready.first, errors.first]);
    ready.close();
    errors.close();
    if (first is SendPort) return RouteWorker._(isolate, first);
    isolate.kill(priority: Isolate.immediate);
    throw StateError('No se pudo cargar el mapa de la región: $first');
  }

  /// Ruta entre dos coordenadas libres (se enganchan al nodo más
  /// cercano de la red vial).
  Future<NavigationRoute> route({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    final reply = ReceivePort();
    _requests.send((fromLat, fromLng, toLat, toLng, reply.sendPort));
    final answer = await reply.first;
    reply.close();
    if (answer is NavigationRoute) return answer;
    if (answer == _outsideOrigin) {
      throw const OutsideMapException(destination: false);
    }
    if (answer == _outsideDestination) {
      throw const OutsideMapException(destination: true);
    }
    throw Exception(answer as String);
  }

  static const _outsideOrigin = 'fuera-del-mapa:origen';
  static const _outsideDestination = 'fuera-del-mapa:destino';

  /// Más lejos que esto de la vía más cercana, el punto no es de este
  /// mapa: engancharlo daría una ruta absurda desde el borde del mapa.
  static const _maxSnapMeters = 3000.0;

  void dispose() => _isolate.kill(priority: Isolate.immediate);

  static Future<void> _main((SendPort, String) message) async {
    final (ready, filePath) = message;
    final graph = await RoadGraph.loadFromFileHere(filePath);
    final snapper = RouteSnapper(graph);
    final router = ChRouter(graph);
    final instructions = TurnInstructionBuilder(graph);

    final requests = ReceivePort();
    ready.send(requests.sendPort);
    await for (final request in requests) {
      final (fromLat, fromLng, toLat, toLng, reply) =
          request as (double, double, double, double, SendPort);
      try {
        final start = snapper.nearestNode(fromLat, fromLng);
        if (start.approxDistanceMeters > _maxSnapMeters) {
          reply.send(_outsideOrigin);
          continue;
        }
        final end = snapper.nearestNode(toLat, toLng);
        if (end.approxDistanceMeters > _maxSnapMeters) {
          reply.send(_outsideDestination);
          continue;
        }
        final path = router.findPath(
          startNodeIndex: start.nodeIndex,
          endNodeIndex: end.nodeIndex,
        );
        if (path == null) {
          reply.send(
            'No se encontró una ruta pavimentada hacia ese destino dentro '
            'de la región descargada.',
          );
          continue;
        }
        reply.send(instructions.build(path));
      } catch (e) {
        reply.send('No se pudo calcular la ruta: $e');
      }
    }
  }
}
