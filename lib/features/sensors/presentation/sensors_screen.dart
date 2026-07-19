import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/heart_rate_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/discovered_device.dart';
import 'cadence_providers.dart';
import 'power_providers.dart';
import 'sensors_providers.dart';
import 'speed_providers.dart';
import 'wheel_size_dialog.dart';

/// Pantalla dedicada a la gestión de sensores BLE.
///
/// Orquesta 4 tarjetas colapsables e independientes -- frecuencia
/// cardíaca, potencia, velocidad y cadencia -- cada una con su propio
/// flujo completo de escanear -> conectar -> desconectar, y cada una su
/// propia conexión BLE física. Velocidad y Cadencia se separaron a
/// propósito en dos tarjetas (antes eran una sola, "Velocidad y
/// cadencia") para poder usar dos sensores físicos distintos al mismo
/// tiempo -- un sensor de rueda y un sensor de manivela, cada uno por su
/// lado. Si en cambio tienes un sensor combo (un solo aparato que
/// reporta las dos cosas), lo conectas solo en la tarjeta de Velocidad
/// y marcas "este sensor también me da cadencia" ahí -- ver el toggle
/// en su vista conectada.
///
/// Ninguna tarjeta arranca su escaneo automáticamente al abrir la
/// pantalla; el escaneo de cada sensor solo corre mientras su tarjeta
/// está expandida, para no encender los 4 radios BLE a la vez y gastar
/// batería sin necesidad.
///
/// Todo lo que ocurre aquí es 100% local -- la comunicación BLE es
/// directa entre el teléfono y el sensor, sin pasar por ningún
/// servidor.
class SensorsScreen extends ConsumerStatefulWidget {
  const SensorsScreen({super.key});

  @override
  ConsumerState<SensorsScreen> createState() => _SensorsScreenState();
}

class _SensorsScreenState extends ConsumerState<SensorsScreen> {
  bool _heartRateExpanded = false;
  bool _powerExpanded = false;
  bool _speedExpanded = false;
  bool _cadenceExpanded = false;

  @override
  void dispose() {
    // Si el usuario sale de la pantalla mientras alguna tarjeta seguía
    // escaneando (sin haber conectado nada), detenemos ese escaneo para
    // no gastar batería de fondo innecesariamente.
    _stopScanIfActive(
      ref.read(sensorsControllerProvider).status,
      () => ref.read(sensorsControllerProvider.notifier).stopScan(),
    );
    _stopScanIfActive(
      ref.read(powerSensorControllerProvider).status,
      () => ref.read(powerSensorControllerProvider.notifier).stopScan(),
    );
    _stopScanIfActive(
      ref.read(speedSensorControllerProvider).status,
      () => ref.read(speedSensorControllerProvider.notifier).stopScan(),
    );
    _stopScanIfActive(
      ref.read(cadenceSensorControllerProvider).status,
      () => ref.read(cadenceSensorControllerProvider.notifier).stopScan(),
    );
    super.dispose();
  }

  void _stopScanIfActive(SensorConnectionStatus status, VoidCallback stop) {
    if (status == SensorConnectionStatus.scanning) stop();
  }

  Future<void> _toggleCard({
    required bool expanded,
    required SensorConnectionStatus status,
    required void Function(bool) setExpanded,
    required Future<void> Function() startScan,
    required Future<void> Function() stopScan,
  }) async {
    if (expanded) {
      // Se está colapsando: si estaba escaneando sin haber conectado
      // nada, detenemos el escaneo (ahorro de batería).
      if (status == SensorConnectionStatus.scanning) {
        await stopScan();
      }
      setExpanded(false);
      return;
    }

    setExpanded(true);
    // Si ya está conectado, solo expandimos para mostrar la vista
    // conectada -- no tiene sentido volver a escanear.
    if (status == SensorConnectionStatus.disconnected) {
      try {
        await startScan();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    }
  }

  Future<bool> _confirmSwitchSensor(String currentDeviceName) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.panelBackground,
        title: const Text(
          'Conectar otro sensor',
          style: TextStyle(color: AppColors.textPrimaryOnPanel),
        ),
        content: Text(
          'Esto desconectará "$currentDeviceName". ¿Quieres continuar y '
          'buscar otro sensor?',
          style: const TextStyle(color: AppColors.textSecondaryOnPanel),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textSecondaryOnPanel),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final heartRateState = ref.watch(sensorsControllerProvider);
    final powerState = ref.watch(powerSensorControllerProvider);
    final speedState = ref.watch(speedSensorControllerProvider);
    final cadenceState = ref.watch(cadenceSensorControllerProvider);

    final bpm = ref.watch(heartRateBpmProvider);
    final watts = ref.watch(powerWattsProvider);
    final speedKmh = ref.watch(speedKmhProvider);
    // Cada tarjeta muestra la lectura de SU PROPIO sensor físico (no la
    // cadencia ya fusionada) -- así, si estás verificando que tu sensor
    // dedicado de cadencia funcione, ves su dato real y no el de
    // potencia tapándolo por prioridad.
    final dedicatedCadenceRpm = ref.watch(dedicatedCadenceRpmProvider);

    // El popup de talla de rueda aparece solo -- no es un paso de
    // onboarding, se dispara la primera vez que el sensor de velocidad
    // reporta datos de rueda sin que exista una circunferencia
    // configurada.
    ref.listen<SpeedConnectionState>(speedSensorControllerProvider, (
      previous,
      next,
    ) {
      final justStartedNeedingSetup =
          next.needsWheelSizeSetup &&
          !(previous?.needsWheelSizeSetup ?? false);
      if (justStartedNeedingSetup) {
        showWheelSizeDialog(context);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.panelBackground,
      appBar: AppBar(
        backgroundColor: AppColors.panelBackground,
        foregroundColor: AppColors.textPrimaryOnPanel,
        title: const Text('Sensores'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _SensorCard(
            title: 'Frecuencia cardíaca',
            icon: Icons.favorite,
            color: AppColors.accentHeartRate,
            state: heartRateState,
            liveValueLabel: bpm != null ? '$bpm bpm' : '--',
            expanded: _heartRateExpanded,
            onToggleExpand: () => _toggleCard(
              expanded: _heartRateExpanded,
              status: heartRateState.status,
              setExpanded: (v) => setState(() => _heartRateExpanded = v),
              startScan: () =>
                  ref.read(sensorsControllerProvider.notifier).startScan(),
              stopScan: () =>
                  ref.read(sensorsControllerProvider.notifier).stopScan(),
            ),
            onRescan: () =>
                ref.read(sensorsControllerProvider.notifier).startScan(),
            onDeviceTap: (device) => _connectTo(
              () => ref
                  .read(sensorsControllerProvider.notifier)
                  .connectTo(device),
            ),
            onDisconnect: () =>
                ref.read(sensorsControllerProvider.notifier).disconnect(),
            onConnectAnother: () => _connectAnother(
              currentDeviceName: heartRateState.connectedDeviceName ?? '',
              disconnect: () =>
                  ref.read(sensorsControllerProvider.notifier).disconnect(),
              startScan: () =>
                  ref.read(sensorsControllerProvider.notifier).startScan(),
            ),
          ),
          _SensorCard(
            title: 'Potencia',
            icon: Icons.bolt,
            color: AppColors.accentPower,
            state: powerState,
            liveValueLabel: watts != null ? '$watts W' : '--',
            expanded: _powerExpanded,
            onToggleExpand: () => _toggleCard(
              expanded: _powerExpanded,
              status: powerState.status,
              setExpanded: (v) => setState(() => _powerExpanded = v),
              startScan: () => ref
                  .read(powerSensorControllerProvider.notifier)
                  .startScan(),
              stopScan: () =>
                  ref.read(powerSensorControllerProvider.notifier).stopScan(),
            ),
            onRescan: () =>
                ref.read(powerSensorControllerProvider.notifier).startScan(),
            onDeviceTap: (device) => _connectTo(
              () => ref
                  .read(powerSensorControllerProvider.notifier)
                  .connectTo(device),
            ),
            onDisconnect: () =>
                ref.read(powerSensorControllerProvider.notifier).disconnect(),
            onConnectAnother: () => _connectAnother(
              currentDeviceName: powerState.connectedDeviceName ?? '',
              disconnect: () => ref
                  .read(powerSensorControllerProvider.notifier)
                  .disconnect(),
              startScan: () => ref
                  .read(powerSensorControllerProvider.notifier)
                  .startScan(),
            ),
          ),
          _SensorCard(
            title: 'Velocidad',
            icon: Icons.speed,
            color: AppColors.accentSpeed,
            state: speedState,
            liveValueLabel: speedKmh != null
                ? '${speedKmh.toStringAsFixed(1)} km/h'
                : '--',
            expanded: _speedExpanded,
            onToggleExpand: () => _toggleCard(
              expanded: _speedExpanded,
              status: speedState.status,
              setExpanded: (v) => setState(() => _speedExpanded = v),
              startScan: () =>
                  ref.read(speedSensorControllerProvider.notifier).startScan(),
              stopScan: () =>
                  ref.read(speedSensorControllerProvider.notifier).stopScan(),
            ),
            onRescan: () =>
                ref.read(speedSensorControllerProvider.notifier).startScan(),
            onDeviceTap: (device) => _connectTo(
              () => ref
                  .read(speedSensorControllerProvider.notifier)
                  .connectTo(device),
            ),
            onDisconnect: () =>
                ref.read(speedSensorControllerProvider.notifier).disconnect(),
            onConnectAnother: () => _connectAnother(
              currentDeviceName: speedState.connectedDeviceName ?? '',
              disconnect: () => ref
                  .read(speedSensorControllerProvider.notifier)
                  .disconnect(),
              startScan: () => ref
                  .read(speedSensorControllerProvider.notifier)
                  .startScan(),
            ),
            connectedExtra: _ComboCadenceToggle(
              value: speedState.alsoProvidesCadence,
              onChanged: (v) => ref
                  .read(speedSensorControllerProvider.notifier)
                  .setAlsoProvidesCadence(v),
            ),
            connectedHeight: 260,
          ),
          _SensorCard(
            title: 'Cadencia',
            icon: Icons.autorenew,
            color: AppColors.accentCadence,
            state: cadenceState,
            liveValueLabel: dedicatedCadenceRpm != null
                ? '${dedicatedCadenceRpm.round()} rpm'
                : '--',
            expanded: _cadenceExpanded,
            onToggleExpand: () => _toggleCard(
              expanded: _cadenceExpanded,
              status: cadenceState.status,
              setExpanded: (v) => setState(() => _cadenceExpanded = v),
              startScan: () => ref
                  .read(cadenceSensorControllerProvider.notifier)
                  .startScan(),
              stopScan: () => ref
                  .read(cadenceSensorControllerProvider.notifier)
                  .stopScan(),
            ),
            onRescan: () => ref
                .read(cadenceSensorControllerProvider.notifier)
                .startScan(),
            onDeviceTap: (device) => _connectTo(
              () => ref
                  .read(cadenceSensorControllerProvider.notifier)
                  .connectTo(device),
            ),
            onDisconnect: () => ref
                .read(cadenceSensorControllerProvider.notifier)
                .disconnect(),
            onConnectAnother: () => _connectAnother(
              currentDeviceName: cadenceState.connectedDeviceName ?? '',
              disconnect: () => ref
                  .read(cadenceSensorControllerProvider.notifier)
                  .disconnect(),
              startScan: () => ref
                  .read(cadenceSensorControllerProvider.notifier)
                  .startScan(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _connectTo(Future<void> Function() connect) async {
    try {
      await connect();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('No se pudo conectar: $e')));
      }
    }
  }

  Future<void> _connectAnother({
    required String currentDeviceName,
    required Future<void> Function() disconnect,
    required Future<void> Function() startScan,
  }) async {
    final confirmed = await _confirmSwitchSensor(currentDeviceName);
    if (!confirmed) return;
    await disconnect();
    try {
      await startScan();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
}

/// Contrato mínimo y común que necesita `_SensorCard` de cualquier
/// estado de sensor (FC / Potencia / Velocidad / Cadencia). Las 4 clases
/// de estado no comparten una clase base -- en vez de forzar una
/// jerarquía nueva entre archivos que hoy son clones independientes a
/// propósito, cada tarjeta simplemente lee estos 5 campos de lo que le
/// pasen.
class _SensorCardData {
  final SensorConnectionStatus status;
  final List<DiscoveredDevice> discoveredDevices;
  final String? connectedDeviceName;
  final int reconnectTimeoutSeconds;
  final bool showReconnectAlert;

  const _SensorCardData({
    required this.status,
    required this.discoveredDevices,
    required this.connectedDeviceName,
    required this.reconnectTimeoutSeconds,
    required this.showReconnectAlert,
  });
}

extension on SensorsState {
  _SensorCardData get card => _SensorCardData(
    status: status,
    discoveredDevices: discoveredDevices,
    connectedDeviceName: connectedDeviceName,
    reconnectTimeoutSeconds: reconnectTimeoutSeconds,
    showReconnectAlert: showReconnectAlert,
  );
}

extension on PowerConnectionState {
  _SensorCardData get card => _SensorCardData(
    status: status,
    discoveredDevices: discoveredDevices,
    connectedDeviceName: connectedDeviceName,
    reconnectTimeoutSeconds: reconnectTimeoutSeconds,
    showReconnectAlert: showReconnectAlert,
  );
}

extension on SpeedConnectionState {
  _SensorCardData get card => _SensorCardData(
    status: status,
    discoveredDevices: discoveredDevices,
    connectedDeviceName: connectedDeviceName,
    reconnectTimeoutSeconds: reconnectTimeoutSeconds,
    showReconnectAlert: showReconnectAlert,
  );
}

extension on CadenceConnectionState {
  _SensorCardData get card => _SensorCardData(
    status: status,
    discoveredDevices: discoveredDevices,
    connectedDeviceName: connectedDeviceName,
    reconnectTimeoutSeconds: reconnectTimeoutSeconds,
    showReconnectAlert: showReconnectAlert,
  );
}

/// Toggle que aparece solo en la vista conectada de la tarjeta de
/// Velocidad -- ver el comentario de `alsoProvidesCadence` en
/// `SpeedConnectionState` para el razonamiento completo.
class _ComboCadenceToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ComboCadenceToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        dense: true,
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.accentCadence,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        title: const Text(
          'Este sensor también me da cadencia',
          style: TextStyle(color: AppColors.textPrimaryOnPanel, fontSize: 13),
        ),
        subtitle: const Text(
          'Actívalo solo si es un sensor combo (un aparato, rueda + '
          'manivela)',
          style: TextStyle(
            color: AppColors.textSecondaryOnPanel,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

/// Tarjeta colapsable reutilizable para cualquiera de los 4 sensores.
/// No sabe nada de BLE ni de qué controlador la alimenta -- solo recibe
/// datos ya extraídos y callbacks. Esto es lo que permite usar la misma
/// UI para FC, potencia, velocidad y cadencia sin cuadriplicar código.
class _SensorCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final dynamic state; // SensorsState | PowerConnectionState | SpeedConnectionState | CadenceConnectionState
  final String liveValueLabel;
  final bool expanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onRescan;
  final void Function(DiscoveredDevice) onDeviceTap;
  final VoidCallback onDisconnect;
  final VoidCallback onConnectAnother;

  /// Contenido extra opcional que se muestra en la vista conectada,
  /// debajo del texto de estado y antes de los botones -- hoy solo lo
  /// usa la tarjeta de Velocidad, para el toggle de sensor combo.
  final Widget? connectedExtra;

  /// Alto del cuerpo expandido cuando está conectado. Por defecto 210;
  /// la tarjeta de Velocidad usa un valor mayor porque además muestra
  /// `connectedExtra`.
  final double connectedHeight;

  const _SensorCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.state,
    required this.liveValueLabel,
    required this.expanded,
    required this.onToggleExpand,
    required this.onRescan,
    required this.onDeviceTap,
    required this.onDisconnect,
    required this.onConnectAnother,
    this.connectedExtra,
    this.connectedHeight = 210,
  });

  _SensorCardData get _data {
    if (state is SensorsState) return (state as SensorsState).card;
    if (state is PowerConnectionState) {
      return (state as PowerConnectionState).card;
    }
    if (state is SpeedConnectionState) {
      return (state as SpeedConnectionState).card;
    }
    return (state as CadenceConnectionState).card;
  }

  String _statusLabel(SensorConnectionStatus status) => switch (status) {
    SensorConnectionStatus.connected => 'Conectado',
    SensorConnectionStatus.connecting => 'Conectando...',
    SensorConnectionStatus.scanning => 'Buscando...',
    SensorConnectionStatus.reconnecting => 'Señal perdida, reintentando...',
    SensorConnectionStatus.disconnected => 'Sin conectar',
  };

  @override
  Widget build(BuildContext context) {
    final data = _data;

    return Card(
      color: Colors.white.withValues(alpha: 0.05),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: onToggleExpand,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(icon, color: color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: AppColors.textPrimaryOnPanel,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          data.status == SensorConnectionStatus.connected
                              ? '${data.connectedDeviceName ?? 'Sensor'} · $liveValueLabel'
                              : _statusLabel(data.status),
                          style: const TextStyle(
                            color: AppColors.textSecondaryOnPanel,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (data.status == SensorConnectionStatus.connected)
                    Text(
                      liveValueLabel,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textSecondaryOnPanel,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const Divider(height: 1, color: Colors.white12),
            if (data.showReconnectAlert)
              _ReconnectAlertBanner(
                timeoutSeconds: data.reconnectTimeoutSeconds,
              ),
            SizedBox(
              height: data.status == SensorConnectionStatus.connected
                  ? connectedHeight
                  : 320,
              child: _buildBody(context, data),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, _SensorCardData data) {
    switch (data.status) {
      case SensorConnectionStatus.connected:
        return _ConnectedView(
          deviceName: data.connectedDeviceName ?? 'Sensor',
          color: color,
          onDisconnect: onDisconnect,
          onConnectAnother: onConnectAnother,
          extra: connectedExtra,
        );

      case SensorConnectionStatus.connecting:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: color),
              const SizedBox(height: 16),
              const Text(
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
          devices: data.discoveredDevices,
          isScanning: data.status == SensorConnectionStatus.scanning,
          icon: icon,
          color: color,
          onDeviceTap: onDeviceTap,
          onRescan: onRescan,
        );
    }
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
  final IconData icon;
  final Color color;
  final void Function(DiscoveredDevice) onDeviceTap;
  final VoidCallback onRescan;

  const _ScanResultsList({
    required this.devices,
    required this.isScanning,
    required this.icon,
    required this.color,
    required this.onDeviceTap,
    required this.onRescan,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Dispositivos disponibles',
                style: TextStyle(
                  color: AppColors.textPrimaryOnPanel,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
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
                    horizontal: 12,
                    vertical: 3,
                  ),
                  child: ListTile(
                    dense: true,
                    leading: Icon(icon, color: color),
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
  final Color color;
  final VoidCallback onDisconnect;
  final VoidCallback onConnectAnother;
  final Widget? extra;

  const _ConnectedView({
    required this.deviceName,
    required this.color,
    required this.onDisconnect,
    required this.onConnectAnother,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, color: color, size: 48),
          const SizedBox(height: 12),
          Text(
            deviceName,
            style: const TextStyle(
              color: AppColors.textPrimaryOnPanel,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Recibiendo datos en tiempo real',
            style: TextStyle(
              color: AppColors.textSecondaryOnPanel,
              fontSize: 12,
            ),
          ),
          if (extra != null) ...[const SizedBox(height: 14), extra!],
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            alignment: WrapAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: onConnectAnother,
                icon: const Icon(
                  Icons.swap_horiz,
                  color: AppColors.textSecondaryOnPanel,
                ),
                label: const Text(
                  'Conectar otro sensor',
                  style: TextStyle(color: AppColors.textSecondaryOnPanel),
                ),
              ),
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
        ],
      ),
    );
  }
}
