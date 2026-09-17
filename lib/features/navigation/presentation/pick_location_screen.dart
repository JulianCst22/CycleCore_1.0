import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;

import 'package:core_ui/core_ui.dart';

/// Pantalla para marcar un punto exacto en el mapa -- para guardar una
/// ubicación que no está en el grafo vial (la casa del usuario en una
/// calle chica, un sitio sin nombre en Nominatim...). El mapa se
/// arrastra bajo un pin fijo en el centro; "Usar este punto" devuelve
/// la coordenada del centro.
class PickLocationScreen extends StatefulWidget {
  final latlng.LatLng initialCenter;

  const PickLocationScreen({super.key, required this.initialCenter});

  @override
  State<PickLocationScreen> createState() => _PickLocationScreenState();
}

class _PickLocationScreenState extends State<PickLocationScreen> {
  final _mapController = MapController();
  late latlng.LatLng _center = widget.initialCenter;
  bool _moving = false;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CcColors.bg,
      appBar: AppBar(
        backgroundColor: CcColors.bg,
        title: const Text(
          'Marca el punto',
          style: TextStyle(color: CcColors.ink),
        ),
        iconTheme: const IconThemeData(color: CcColors.ink),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialCenter,
              initialZoom: 16,
              onPositionChanged: (camera, hasGesture) {
                _center = camera.center;
                if (hasGesture && !_moving) setState(() => _moving = true);
              },
              onMapEvent: (event) {
                if (event is MapEventMoveEnd ||
                    event is MapEventFlingAnimationEnd) {
                  setState(() => _moving = false);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.cyclecore_app',
              ),
            ],
          ),

          // Pin fijo en el centro -- el mapa se mueve por debajo.
          IgnorePointer(
            child: Center(
              child: Padding(
                // Compensa la "punta" del pin para que apunte al centro
                // exacto y no al centro del ícono.
                padding: const EdgeInsets.only(bottom: 34),
                child: AnimatedScale(
                  scale: _moving ? 1.12 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: const Icon(
                    Icons.location_on,
                    size: 44,
                    color: CcColors.orange,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: SafeArea(
              top: false,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(_center),
                style: FilledButton.styleFrom(
                  backgroundColor: CcColors.orange,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                ),
                child: const Text('Usar este punto'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
