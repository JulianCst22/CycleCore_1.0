import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/discovered_device.dart';
import 'sensors_providers.dart';

/// Pantalla dedicada a la gestión de sensores BLE.
///
/// Es una pantalla completa y no un popup a propósito: el flujo tiene
/// varios estados (escaneando, lista de resultados, conectando,
/// conectado, reintentando) que no caben cómodamente en un diálogo sin
/// volverse confuso. Todo lo que ocurre aquí es 100% local -- la
/// comunicación BLE es directa entre el teléfono y el sensor, sin pasar
/// por ningún servidor.
class SensorsScreen extends ConsumerStatefulWidget {
  const SensorsScreen({super.key});

  @override
  ConsumerState<SensorsScreen> createState() => _SensorsScreenState();
}

class _SensorsScreenState extends ConsumerState<SensorsScreen> {
  @override
  void initState() {
    super.initState();
    // Al abrir la pantalla, si no hay nada conectado, arrancamos el
    // escaneo de una vez -- le ahorra un toque extra al usuario.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final status = ref.read(sensorsControllerProvider).status;
      if (status == SensorConnectionStatus.disconnected) {
        _startScan();
      }
    });
  }

  Future<void> _startScan() async {
    try {
      await ref.read(sensorsControllerProvider.notifier).startScan();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  void dispose() {
    // Si el usuario sale de la pantalla mientras escaneaba (sin haber
    // conectado nada), detenemos el escaneo para no gastar batería de
    // fondo innecesariamente.
    final controller = ref.read(sensorsControllerProvider.notifier);
    if (ref.read(sensorsControllerProvider).status ==
        SensorConnectionStatus.scanning) {
      controller.stopScan();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sensorsState = ref.watch(sensorsControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.panelBackground,
      appBar: AppBar(
        backgroundColor: AppColors.panelBackground,
        foregroundColor: AppColors.textPrimaryOnPanel,
        title: const Text('Sensor de frecuencia cardíaca'),
      ),
      body: Column(
        children: [
          _ConnectionStatusCard(state: sensorsState),
          if (sensorsState.showReconnectAlert)
            _ReconnectAlertBanner(
              timeoutSeconds: sensorsState.reconnectTimeoutSeconds,
            ),
          Expanded(child: _buildBody(sensorsState)),
        ],
      ),
    );
  }

  Widget _buildBody(SensorsState state) {
    switch (state.status) {
      case SensorConnectionStatus.connected:
        return _ConnectedView(
          deviceName: state.connectedDeviceName ?? 'Sensor',
          onDisconnect: () =>
              ref.read(sensorsControllerProvider.notifier).disconnect(),
        );

      case SensorConnectionStatus.connecting:
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text(
                'Conectando...',
                style: TextStyle(color: AppColors.textSecondaryOnPanel),
              ),
            ],
          ),
        );

      case SensorConnectionStatus.scanning:
      case SensorConnectionStatus.disconnected:
      case SensorConnectionStatus.reconnecting:
        return _ScanResultsList(
          devices: state.discoveredDevices,
          isScanning: state.status == SensorConnectionStatus.scanning,
          onDeviceTap: (device) async {
            try {
              await ref
                  .read(sensorsControllerProvider.notifier)
                  .connectTo(device);
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('No se pudo conectar: $e')),
                );
              }
            }
          },
          onRescan: _startScan,
        );
    }
  }
}

class _ConnectionStatusCard extends StatelessWidget {
  final SensorsState state;

  const _ConnectionStatusCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (state.status) {
      SensorConnectionStatus.connected => (
        'Conectado a ${state.connectedDeviceName}',
        AppColors.recordButtonInactive,
      ),
      SensorConnectionStatus.connecting => (
        'Conectando...',
        AppColors.accentSlope,
      ),
      SensorConnectionStatus.scanning => (
        'Buscando sensores cercanos...',
        AppColors.accentSpeed,
      ),
      SensorConnectionStatus.reconnecting => (
        'Señal perdida, reintentando...',
        AppColors.recordButtonActive,
      ),
      SensorConnectionStatus.disconnected => (
        'Sin sensor conectado',
        AppColors.textSecondaryOnPanel,
      ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: color.withValues(alpha: 0.12),
      child: Row(
        children: [
          Icon(Icons.favorite, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReconnectAlertBanner extends StatelessWidget {
  final int timeoutSeconds;

  const _ReconnectAlertBanner({required this.timeoutSeconds});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.recordButtonActive.withValues(alpha: 0.2),
      padding: const EdgeInsets.all(12),
      child: Text(
        'No se ha podido reconectar el sensor en más de $timeoutSeconds '
        'segundos. Verifica que esté encendido y cerca del teléfono.',
        style: const TextStyle(color: AppColors.textPrimaryOnPanel),
      ),
    );
  }
}

class _ScanResultsList extends StatelessWidget {
  final List<DiscoveredDevice> devices;
  final bool isScanning;
  final void Function(DiscoveredDevice) onDeviceTap;
  final VoidCallback onRescan;

  const _ScanResultsList({
    required this.devices,
    required this.isScanning,
    required this.onDeviceTap,
    required this.onRescan,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Dispositivos disponibles',
                style: TextStyle(
                  color: AppColors.textPrimaryOnPanel,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              TextButton.icon(
                onPressed: isScanning ? null : onRescan,
                icon: const Icon(Icons.refresh, color: AppColors.primary),
                label: const Text(
                  'Buscar',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
        if (devices.isEmpty)
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  isScanning
                      ? 'Buscando...\nAsegúrate de que el sensor esté '
                            'encendido y cerca.'
                      : 'Ningún sensor encontrado.\nToca "Buscar" para '
                            'intentar de nuevo.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondaryOnPanel,
                  ),
                ),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final device = devices[index];
                return Card(
                  color: Colors.white.withValues(alpha: 0.05),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.favorite,
                      color: AppColors.accentHeartRate,
                    ),
                    title: Text(
                      device.name,
                      style: const TextStyle(
                        color: AppColors.textPrimaryOnPanel,
                      ),
                    ),
                    subtitle: Text(
                      device.id,
                      style: const TextStyle(
                        color: AppColors.textSecondaryOnPanel,
                        fontSize: 11,
                      ),
                    ),
                    trailing: Text(
                      '${device.rssi} dBm',
                      style: const TextStyle(
                        color: AppColors.textSecondaryOnPanel,
                      ),
                    ),
                    onTap: () => onDeviceTap(device),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _ConnectedView extends StatelessWidget {
  final String deviceName;
  final VoidCallback onDisconnect;

  const _ConnectedView({required this.deviceName, required this.onDisconnect});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle,
            color: AppColors.recordButtonInactive,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            deviceName,
            style: const TextStyle(
              color: AppColors.textPrimaryOnPanel,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Recibiendo datos en tiempo real',
            style: TextStyle(color: AppColors.textSecondaryOnPanel),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: onDisconnect,
            icon: const Icon(
              Icons.link_off,
              color: AppColors.recordButtonActive,
            ),
            label: const Text(
              'Desconectar',
              style: TextStyle(color: AppColors.recordButtonActive),
            ),
          ),
        ],
      ),
    );
  }
}
