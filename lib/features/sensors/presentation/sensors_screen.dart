import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/heart_rate_provider.dart';
import 'package:core_ui/core_ui.dart';
import '../domain/discovered_device.dart';
import '../domain/sensor_kind.dart';
import '../application/cadence_providers.dart';
import '../application/power_providers.dart';
import '../application/sensors_providers.dart';
import '../application/speed_providers.dart';
import 'wheel_size_dialog.dart';

/// Pantalla de sensores BLE: un resumen arriba ("N de 4 listos") y un
/// slot por sensor -- frecuencia cardíaca, potencia, velocidad y
/// cadencia -- cada uno con su propio flujo escanear -> conectar ->
/// desconectar y su propia conexión física.
///
/// El escaneo de cada sensor sólo corre mientras su tarjeta está abierta,
/// para no encender los 4 radios BLE a la vez. Todo es 100% local: la
/// comunicación es directa entre el teléfono y el sensor.
class SensorsScreen extends ConsumerStatefulWidget {
  const SensorsScreen({super.key});

  @override
  ConsumerState<SensorsScreen> createState() => _SensorsScreenState();
}

class _SensorsScreenState extends ConsumerState<SensorsScreen> {
  final Set<SensorKind> _expanded = {};

  StateNotifierProvider<dynamic, SensorConnectionState> _providerFor(
    SensorKind kind,
  ) => switch (kind) {
    SensorKind.heartRate => heartRateSensorControllerProvider,
    SensorKind.power => powerSensorControllerProvider,
    SensorKind.speed => speedSensorControllerProvider,
    SensorKind.cadence => cadenceSensorControllerProvider,
  };

  dynamic _controllerFor(SensorKind kind) =>
      ref.read(_providerFor(kind).notifier);

  @override
  void dispose() {
    // Si el usuario sale mientras alguna tarjeta seguía escaneando (sin
    // conectar nada), detenemos ese escaneo para no gastar batería.
    for (final kind in _expanded) {
      final state = ref.read(_providerFor(kind));
      if (state.isScanning) _controllerFor(kind).stopScan();
    }
    super.dispose();
  }

  Future<void> _toggleExpand(SensorKind kind) async {
    final controller = _controllerFor(kind);
    final state = ref.read(_providerFor(kind));

    if (_expanded.contains(kind)) {
      if (state.isScanning) await controller.stopScan();
      setState(() => _expanded.remove(kind));
      return;
    }

    setState(() => _expanded.add(kind));
    if (state.status == SensorConnectionStatus.disconnected) {
      await _guard(controller.startScan());
    }
  }

  Future<void> _connect(SensorKind kind, DiscoveredDevice device) => _guard(
    _controllerFor(kind).connectTo(device),
    prefix: 'No se pudo conectar',
  );

  Future<void> _guard(Future<void> action, {String? prefix}) async {
    try {
      await action;
    } catch (e) {
      if (!mounted) return;
      final msg = prefix == null ? '$e' : '$prefix: $e';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _confirmSwitchSensor(SensorKind kind, String currentName) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: CcColors.surfaceHi,
        title: Text('Cambiar sensor', style: CcType.displayStyle(size: 18)),
        content: Text(
          'Esto desconectará "$currentName" y volverá a buscar.',
          style: const TextStyle(color: CcColors.inkDim),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _controllerFor(kind).disconnect();
    if (!_expanded.contains(kind)) setState(() => _expanded.add(kind));
    await _guard(_controllerFor(kind).startScan());
  }

  String? _liveValue(SensorKind kind) {
    switch (kind) {
      case SensorKind.heartRate:
        final v = ref.watch(heartRateBpmProvider);
        return v?.toString();
      case SensorKind.power:
        final v = ref.watch(powerWattsProvider);
        return v?.toString();
      case SensorKind.speed:
        final v = ref.watch(speedKmhProvider);
        return v?.toStringAsFixed(1).replaceAll('.', ',');
      case SensorKind.cadence:
        final v = ref.watch(dedicatedCadenceRpmProvider);
        return v?.round().toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    // El popup de talla de rueda aparece solo cuando el sensor de
    // velocidad reporta datos de rueda sin circunferencia configurada.
    ref.listen<SensorConnectionState>(speedSensorControllerProvider, (
      prev,
      next,
    ) {
      if (next.needsWheelSizeSetup && !(prev?.needsWheelSizeSetup ?? false)) {
        showWheelSizeDialog(context);
      }
    });

    final hub = ref.watch(sensorsHubProvider);

    return Scaffold(
      backgroundColor: CcColors.bg,
      appBar: AppBar(title: const Text('Sensores')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
        children: [
          _SummaryStrip(hub: hub, liveValueFor: _liveValue),
          const SizedBox(height: 14),
          for (final kind in SensorKind.values) ...[
            _SlotCard(
              kind: kind,
              state: hub.of(kind),
              liveValue: _liveValue(kind),
              expanded: _expanded.contains(kind),
              onToggleExpand: () => _toggleExpand(kind),
              onRescan: () => _guard(_controllerFor(kind).startScan()),
              onDeviceTap: (d) => _connect(kind, d),
              onDisconnect: () => _controllerFor(kind).disconnect(),
              onRetry: () => _controllerFor(kind).retryConnection(),
              onSwitchSensor: () => _confirmSwitchSensor(
                kind,
                hub.of(kind).connectedDeviceName ?? 'este sensor',
              ),
              onWheelSize: kind == SensorKind.speed
                  ? () => showWheelSizeDialog(context)
                  : null,
              onToggleCombo: kind == SensorKind.speed
                  ? (v) =>
                        (_controllerFor(SensorKind.speed)
                                as SpeedSensorController)
                            .setAlsoProvidesCadence(v)
                  : null,
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

// --- Metadatos por tipo de sensor -----------------------------------

({IconData icon, Color color}) _meta(SensorKind kind) => switch (kind) {
  SensorKind.heartRate => (icon: Icons.favorite, color: CcColors.mHeartRate),
  SensorKind.power => (icon: Icons.bolt, color: CcColors.mPower),
  SensorKind.speed => (icon: Icons.speed, color: CcColors.mSpeed),
  SensorKind.cadence => (icon: Icons.autorenew, color: CcColors.mCadence),
};

({int bars, String label}) _signal(int rssi) {
  if (rssi >= -55) return (bars: 4, label: 'señal fuerte');
  if (rssi >= -67) return (bars: 3, label: 'señal buena');
  if (rssi >= -80) return (bars: 2, label: 'señal débil');
  return (bars: 1, label: 'señal muy débil');
}

// --- Resumen -------------------------------------------------------

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.hub, required this.liveValueFor});

  final SensorsHubSnapshot hub;
  final String? Function(SensorKind) liveValueFor;

  @override
  Widget build(BuildContext context) {
    final n = hub.connectedCount;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CcColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CcColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: n > 0 ? CcColors.ok : CcColors.inkFaint,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                n == 0
                    ? 'Ningún sensor conectado'
                    : '$n de ${hub.total} sensores listos para rodar',
                style: CcType.label(size: 13, color: CcColors.ink),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final kind in SensorKind.values) ...[
                if (kind != SensorKind.values.first) const SizedBox(width: 8),
                Expanded(
                  child: _SummaryChip(
                    kind: kind,
                    on: hub.of(kind).isConnected,
                    value: liveValueFor(kind),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.kind,
    required this.on,
    required this.value,
  });

  final SensorKind kind;
  final bool on;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final meta = _meta(kind);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
      decoration: BoxDecoration(
        color: CcColors.surfaceInset,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: CcColors.lineSoft),
      ),
      child: Column(
        children: [
          Icon(meta.icon, size: 16, color: on ? meta.color : CcColors.inkFaint),
          const SizedBox(height: 4),
          Text(
            on ? (value ?? '—') : '—',
            style: CcType.displayStyle(
              size: 13,
              color: on ? CcColors.ink : CcColors.inkFaint,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            kind.unit,
            style: CcType.label(size: 9, color: CcColors.inkFaint),
          ),
        ],
      ),
    );
  }
}

// --- Tarjeta de un sensor ----------------------------------------

class _SlotCard extends StatelessWidget {
  const _SlotCard({
    required this.kind,
    required this.state,
    required this.liveValue,
    required this.expanded,
    required this.onToggleExpand,
    required this.onRescan,
    required this.onDeviceTap,
    required this.onDisconnect,
    required this.onRetry,
    required this.onSwitchSensor,
    this.onWheelSize,
    this.onToggleCombo,
  });

  final SensorKind kind;
  final SensorConnectionState state;
  final String? liveValue;
  final bool expanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onRescan;
  final void Function(DiscoveredDevice) onDeviceTap;
  final VoidCallback onDisconnect;
  final VoidCallback onRetry;
  final VoidCallback onSwitchSensor;
  final VoidCallback? onWheelSize;
  final ValueChanged<bool>? onToggleCombo;

  bool get _isSpeed => kind == SensorKind.speed;

  @override
  Widget build(BuildContext context) {
    final meta = _meta(kind);
    final warn = state.isReconnecting;

    return Container(
      decoration: BoxDecoration(
        color: CcColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: warn
              ? CcColors.warn.withValues(alpha: 0.45)
              : (expanded ? meta.color.withValues(alpha: 0.4) : CcColors.line),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggleExpand,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(13),
              child: _Header(
                kind: kind,
                state: state,
                liveValue: liveValue,
                expanded: expanded,
                onScan: onToggleExpand,
              ),
            ),
          ),
          if (expanded) ...[
            const Divider(height: 1, color: CcColors.lineSoft),
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 12, 13, 14),
              child: _body(context),
            ),
          ],
        ],
      ),
    );
  }

  Widget _body(BuildContext context) {
    switch (state.status) {
      case SensorConnectionStatus.connected:
        return _ConnectedDetail(
          kind: kind,
          state: state,
          onDisconnect: onDisconnect,
          onSwitchSensor: onSwitchSensor,
          onWheelSize: _isSpeed ? onWheelSize : null,
          onToggleCombo: _isSpeed ? onToggleCombo : null,
        );
      case SensorConnectionStatus.connecting:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _meta(kind).color,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Conectando…',
                  style: TextStyle(color: CcColors.inkDim, fontSize: 13),
                ),
              ],
            ),
          ),
        );
      case SensorConnectionStatus.reconnecting:
        return _ReconnectBody(
          state: state,
          onRetry: onRetry,
          onDisconnect: onDisconnect,
        );
      case SensorConnectionStatus.scanning:
      case SensorConnectionStatus.disconnected:
        return _ScanBody(
          kind: kind,
          state: state,
          onRescan: onRescan,
          onDeviceTap: onDeviceTap,
        );
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.kind,
    required this.state,
    required this.liveValue,
    required this.expanded,
    required this.onScan,
  });

  final SensorKind kind;
  final SensorConnectionState state;
  final String? liveValue;
  final bool expanded;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final meta = _meta(kind);
    final connected = state.isConnected;
    final warn = state.isReconnecting;

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: (warn ? CcColors.warn : meta.color).withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            meta.icon,
            size: 21,
            color: warn ? CcColors.inkFaint : meta.color,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(kind.label, style: CcType.displayStyle(size: 15)),
              const SizedBox(height: 2),
              Text(
                _statusLine(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CcType.label(
                  size: 11,
                  color: warn ? CcColors.warn : CcColors.inkDim,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        if (connected && liveValue != null) ...[
          _LiveValue(kind: kind, value: liveValue!),
          const SizedBox(width: 4),
        ] else if (!expanded &&
            !connected &&
            state.status == SensorConnectionStatus.disconnected)
          OutlinedButton(
            onPressed: onScan,
            style: OutlinedButton.styleFrom(
              foregroundColor: CcColors.blue,
              side: const BorderSide(color: CcColors.blue),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Buscar'),
          ),
        Icon(
          expanded ? Icons.expand_less : Icons.expand_more,
          color: CcColors.inkFaint,
          size: 22,
        ),
      ],
    );
  }

  String _statusLine() {
    final name = state.connectedDeviceName;
    return switch (state.status) {
      SensorConnectionStatus.connected => name ?? 'Conectado',
      SensorConnectionStatus.connecting => 'Conectando…',
      SensorConnectionStatus.scanning => 'Buscando sensores cerca…',
      SensorConnectionStatus.reconnecting => 'Señal perdida — reintentando',
      SensorConnectionStatus.disconnected => 'Sin conectar',
    };
  }
}

class _LiveValue extends StatelessWidget {
  const _LiveValue({required this.kind, required this.value});
  final SensorKind kind;
  final String value;

  @override
  Widget build(BuildContext context) {
    final color = _meta(kind).color;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(right: 5),
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        Text(value, style: CcType.displayStyle(size: 21, color: color)),
        const SizedBox(width: 3),
        Text(kind.unit, style: CcType.label(size: 10, color: CcColors.inkDim)),
      ],
    );
  }
}

// --- Cuerpo: lista de escaneo -----------------------------------

class _ScanBody extends StatelessWidget {
  const _ScanBody({
    required this.kind,
    required this.state,
    required this.onRescan,
    required this.onDeviceTap,
  });

  final SensorKind kind;
  final SensorConnectionState state;
  final VoidCallback onRescan;
  final void Function(DiscoveredDevice) onDeviceTap;

  @override
  Widget build(BuildContext context) {
    final meta = _meta(kind);
    final devices = state.discoveredDevices;
    final scanning = state.isScanning;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Dispositivos cerca',
              style: CcType.label(size: 11, color: CcColors.inkDim),
            ),
            TextButton.icon(
              onPressed: scanning ? null : onRescan,
              style: TextButton.styleFrom(
                foregroundColor: CcColors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.refresh, size: 15),
              label: const Text('Volver a buscar'),
            ),
          ],
        ),
        if (scanning)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: CcColors.line,
                color: meta.color,
              ),
            ),
          ),
        const SizedBox(height: 4),
        if (devices.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 4),
            child: Text(
              scanning
                  ? 'Buscando… Asegúrate de que el sensor esté encendido y cerca.'
                  : 'Ningún sensor encontrado. Toca "Volver a buscar".',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: CcColors.inkDim,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          )
        else
          for (final device in devices)
            _DeviceRow(
              kind: kind,
              device: device,
              onTap: () => onDeviceTap(device),
            ),
      ],
    );
  }
}

class _DeviceRow extends StatelessWidget {
  const _DeviceRow({
    required this.kind,
    required this.device,
    required this.onTap,
  });

  final SensorKind kind;
  final DiscoveredDevice device;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final meta = _meta(kind);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            Icon(meta.icon, size: 18, color: meta.color),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CcType.label(size: 13, color: CcColors.ink),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    device.id,
                    style: CcType.label(size: 10, color: CcColors.inkFaint),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _SignalBars(bars: _signal(device.rssi).bars, color: meta.color),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 16, color: CcColors.inkFaint),
          ],
        ),
      ),
    );
  }
}

// --- Cuerpo: sensor conectado ----------------------------------

class _ConnectedDetail extends StatelessWidget {
  const _ConnectedDetail({
    required this.kind,
    required this.state,
    required this.onDisconnect,
    required this.onSwitchSensor,
    this.onWheelSize,
    this.onToggleCombo,
  });

  final SensorKind kind;
  final SensorConnectionState state;
  final VoidCallback onDisconnect;
  final VoidCallback onSwitchSensor;
  final VoidCallback? onWheelSize;
  final ValueChanged<bool>? onToggleCombo;

  @override
  Widget build(BuildContext context) {
    final color = _meta(kind).color;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _SignalBars(bars: 4, color: color),
            const SizedBox(width: 8),
            const Text(
              'Recibiendo datos en vivo',
              style: TextStyle(color: CcColors.inkDim, fontSize: 11.5),
            ),
          ],
        ),
        if (kind == SensorKind.speed && onToggleCombo != null) ...[
          const SizedBox(height: 6),
          _OptionRow(
            title: 'También me da cadencia',
            subtitle: 'Actívalo sólo si es un sensor combo (rueda + biela)',
            trailing: Switch(
              value: state.alsoProvidesCadence,
              onChanged: onToggleCombo,
              activeThumbColor: CcColors.mCadence,
            ),
          ),
          _OptionRow(
            title: 'Talla de rueda',
            subtitle: 'Necesaria para calcular la velocidad',
            onTap: onWheelSize,
            trailing: const Icon(
              Icons.chevron_right,
              size: 16,
              color: CcColors.inkFaint,
            ),
          ),
        ],
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onSwitchSensor,
                style: OutlinedButton.styleFrom(
                  foregroundColor: CcColors.inkDim,
                  side: const BorderSide(color: CcColors.line),
                ),
                icon: const Icon(Icons.swap_horiz, size: 16),
                label: const Text('Cambiar sensor'),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onDisconnect,
                style: OutlinedButton.styleFrom(
                  foregroundColor: CcColors.danger,
                  side: BorderSide(
                    color: CcColors.danger.withValues(alpha: 0.4),
                  ),
                ),
                icon: const Icon(Icons.link_off, size: 16),
                label: const Text('Desconectar'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: CcColors.lineSoft)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: CcType.label(size: 13, color: CcColors.ink),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: CcType.label(size: 10, color: CcColors.inkDim),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

// --- Cuerpo: señal perdida ------------------------------------

class _ReconnectBody extends StatelessWidget {
  const _ReconnectBody({
    required this.state,
    required this.onRetry,
    required this.onDisconnect,
  });

  final SensorConnectionState state;
  final VoidCallback onRetry;
  final VoidCallback onDisconnect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (state.showReconnectAlert)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CcColors.warn.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 17,
                  color: CcColors.warn,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Sin señal desde hace más de '
                    '${state.reconnectTimeoutSeconds} s. Revisa que el sensor '
                    'esté encendido, con batería y cerca del teléfono.',
                    style: const TextStyle(
                      color: CcColors.ink,
                      fontSize: 11.5,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Row(
            children: const [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: CcColors.warn,
                ),
              ),
              SizedBox(width: 10),
              Text(
                'Reintentando reconectar…',
                style: TextStyle(color: CcColors.inkDim, fontSize: 12),
              ),
            ],
          ),
        const SizedBox(height: 13),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  backgroundColor: CcColors.orange,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Reintentar ahora'),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onDisconnect,
                style: OutlinedButton.styleFrom(
                  foregroundColor: CcColors.danger,
                  side: BorderSide(
                    color: CcColors.danger.withValues(alpha: 0.4),
                  ),
                ),
                icon: const Icon(Icons.link_off, size: 16),
                label: const Text('Desconectar'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// --- Barras de señal ----------------------------------------

class _SignalBars extends StatelessWidget {
  const _SignalBars({required this.bars, required this.color});
  final int bars;
  final Color color;

  @override
  Widget build(BuildContext context) {
    const heights = [4.0, 7.0, 10.0, 13.0];
    return SizedBox(
      height: 13,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < 4; i++) ...[
            if (i > 0) const SizedBox(width: 2),
            Container(
              width: 3,
              height: heights[i],
              decoration: BoxDecoration(
                color: i < bars ? color : CcColors.inkFaint,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
