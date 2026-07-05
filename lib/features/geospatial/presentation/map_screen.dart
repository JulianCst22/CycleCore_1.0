import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' as latlng;

import 'map_providers.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    final currentPositionAsync = ref.watch(currentPositionProvider);
    final recordingState = ref.watch(routeRecordingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CycleCore — Mapa de ruta'),
      ),
      body: currentPositionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'No se pudo obtener tu ubicación:\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (position) {
          final initialCenter = latlng.LatLng(
            position.latitude,
            position.longitude,
          );

          // Convertimos los puntos grabados (RoutePoint) al tipo que
          // flutter_map necesita para dibujar la línea de la ruta.
          final recordedLatLngs = recordingState.points
              .map((p) => latlng.LatLng(p.latitude, p.longitude))
              .toList();

          return FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: 15,
            ),
            children: [
              // Capa de tiles de OpenStreetMap.
              // IMPORTANTE: en la fase piloto esto requiere conexión la
              // primera vez para descargar los tiles de la zona; luego
              // quedan en caché para uso offline (esto lo resolvemos en
              // el siguiente paso con flutter_map_tile_caching).
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.cyclecore_app',
              ),

              // Línea de la ruta que se está grabando en este momento.
              if (recordedLatLngs.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: recordedLatLngs,
                      strokeWidth: 4,
                      color: Colors.deepOrange,
                    ),
                  ],
                ),

              // Marcador de la posición actual del ciclista.
              MarkerLayer(
                markers: [
                  Marker(
                    point: recordedLatLngs.isNotEmpty
                        ? recordedLatLngs.last
                        : initialCenter,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.directions_bike,
                      color: Colors.blue,
                      size: 32,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor:
            recordingState.isRecording ? Colors.red : Colors.green,
        icon: Icon(
          recordingState.isRecording ? Icons.stop : Icons.fiber_manual_record,
        ),
        label: Text(
          recordingState.isRecording ? 'Detener grabación' : 'Grabar ruta',
        ),
        onPressed: () async {
          final controller = ref.read(routeRecordingProvider.notifier);
          if (recordingState.isRecording) {
            await controller.stopRecording();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Ruta grabada con ${recordingState.points.length} puntos.',
                  ),
                ),
              );
            }
          } else {
            try {
              await controller.startRecording();
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString())),
                );
              }
            }
          }
        },
      ),
    );
  }
}
