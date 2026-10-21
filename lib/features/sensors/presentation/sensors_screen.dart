import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/heart_rate_provider.dart';
import '../../../core/ui/ui.dart';
import '../domain/discovered_device.dart';
import '../domain/sensor_kind.dart';
import '../application/ble_sensor_controller.dart';
import '../application/cadence_providers.dart';
import '../application/power_providers.dart';
import '../application/sensors_providers.dart';
import '../application/speed_providers.dart';
import 'cadence_source_dialog.dart';
import 'wheel_size_dialog.dart';

/// Pantalla de sensores BLE: un resumen arriba ("N de 4 listos") cuyas
/// cuatro fichas -- pulso, velocidad, cadencia y potencia -- funcionan
/// como filtro, y debajo sólo la tarjeta del tipo elegido, con su propio
/// flujo escanear -> conectar -> ajustar -> desconectar.
///
/// Sólo se escanea el tipo elegido, y sólo los dispositivos que anuncian
/// su servicio: con las cuatro tarjetas abiertas a la vez, los escaneos
/// se pisaban y la lista de pulso terminaba mostrando sensores de
/// velocidad. Todo es 100% local: la comunicación es directa entre el
/// teléfono y el sensor.
class SensorsScreen extends ConsumerStatefulWidget {
  const SensorsScreen({super.key});

  @override
  ConsumerState<SensorsScreen> createState() => _SensorsScreenState();
}

/// Orden de los chips: el de la prueba de campo (pulso y velocidad son
/// lo primero que se conecta; la potencia, cuando hay medidor).
const _kindOrder = [
  SensorKind.heartRate,
  SensorKind.speed,
  SensorKind.cadence,
  SensorKind.power,
];

class _SensorsScreenState extends ConsumerState<SensorsScreen> {
  late SensorKind _selected;

  StateNotifierProvider<dynamic, SensorConnectionState> _providerFor(
    SensorKind kind,
  ) => switch (kind) {
    SensorKind.heartRate => heartRateSensorControllerProvider,
    SensorKind.power => powerSensorControllerProvider,
    SensorKind.speed => speedSensorControllerProvider,
    SensorKind.cadence => cadenceSensorControllerProvider,
  };

  /// Los controladores se guardan al abrir: en `dispose` ya no se puede
  /// usar `ref`, y ahí hace falta detener el escaneo.
  late final Map<SensorKind, BleSensorController<Object?>> _controllers;

  BleSensorController<Object?> _controllerFor(SensorKind kind) =>
      _controllers[kind]!;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final kind in SensorKind.values)
        kind:
            ref.read(_providerFor(kind).notifier)
                as BleSensorController<Object?>,
    };
    // Se abre en el primer tipo que falta por conectar y se busca de una:
    // a esta pantalla casi siempre se viene a conectar algo.
    final hub = ref.read(sensorsHubProvider);
    _selected = _kindOrder.firstWhere(
      (k) => hub.of(k).status == SensorConnectionStatus.disconnected,
      orElse: () => _kindOrder.first,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scanIfIdle(_selected);
    });
  }

  @override
  void dispose() {
    // Si el usuario sale mientras seguía escaneando (sin conectar nada),
    // detenemos ese escaneo para no gastar batería. Si no estaba
    // escaneando, no cambia nada.
    _controllerFor(_selected).stopScan();
    super.dispose();
  }

  Future<void> _select(SensorKind kind) async {
    final previous = _selected;
    if (previous == kind) return;
    setState(() => _selected = kind);
    if (ref.read(_providerFor(previous)).isScanning) {
      await _controllerFor(previous).stopScan();
    }
    if (!mounted || _selected != kind) return;
    await _scanIfIdle(kind);
  }

  Future<void> _scanIfIdle(SensorKind kind) async {
    if (ref.read(_providerFor(kind)).status !=
        SensorConnectionStatus.disconnected) {
      return;
    }
    await _guard(_controllerFor(kind).startScan());
  }

  Future<void> _connect(SensorKind kind, DiscoveredDevice device) async {
    await _guard(
      _controllerFor(kind).connectTo(device),
      prefix: 'No se pudo conectar',
    );
    // Si ya había otro sensor que mide la cadencia (p. ej. el de
    // cadencia y ahora llega el potenciómetro), se pregunta de cuál
    // tomarla.
    if (!mounted || !ref.read(_providerFor(kind)).isConnected) return;
    if (kind == SensorKind.power || kind == SensorKind.cadence) {
      await askCadenceSource(context, ref);
    }
  }

  Future<void> _guard(Future<void> action, {String? prefix}) async {
    try {
      await action;
    } catch (e) {
      if (!mounted) return;
      final detail = e is StateError ? e.message : '$e';
      final msg = prefix == null ? detail : '$prefix: $detail';
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
    final kind = _selected;

    // Aparatos ya conectados en OTRO tipo: un combo o un potenciómetro
    // también anuncian el servicio de velocidad/cadencia.
    final takenBy = <String, SensorKind>{
      for (final k in SensorKind.values)
        if (k != kind && hub.of(k).connectedDeviceId != null)
          hub.of(k).connectedDeviceId!: k,
    };

    return Scaffold(
      backgroundColor: CcColors.bg,
      appBar: AppBar(title: const Text('Sensores')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
        children: [
          _SummaryStrip(
            hub: hub,
            liveValueFor: _liveValue,
            selected: kind,
            onSelect: _select,
          ),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _SlotCard(
              key: ValueKey(kind),
              kind: kind,
              state: hub.of(kind),
              liveValue: _liveValue(kind),
              takenBy: takenBy,
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
                  ? (v) {
                      (_controllerFor(SensorKind.speed)
                              as SpeedSensorController)
                          .setAlsoProvidesCadence(v);
                      if (v) askCadenceSource(context, ref);
                    }
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          const CadenceSourceRow(),
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

/// Qué deja pasar el filtro de cada tipo, dicho en corto bajo la lista.
String _filterNote(SensorKind kind) => switch (kind) {
  SensorKind.heartRate =>
    'Sólo aparecen bandas y relojes que transmiten pulso.',
  SensorKind.power => 'Sólo aparecen medidores que transmiten potencia.',
  SensorKind.speed =>
    'Velocidad y cadencia comparten la misma señal Bluetooth: al conectar '
        'revisamos que el sensor mida la rueda.',
  SensorKind.cadence =>
    'Velocidad y cadencia comparten la misma señal Bluetooth: al conectar '
        'revisamos que el sensor mida la biela.',
};

({int bars, String label}) _signal(int rssi) {
  if (rssi >= -55) return (bars: 4, label: 'señal fuerte');
  if (rssi >= -67) return (bars: 3, label: 'señal buena');
  if (rssi >= -80) return (bars: 2, label: 'señal débil');
  return (bars: 1, label: 'señal muy débil');
}

// --- Resumen + filtro ----------------------------------------------

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({
    required this.hub,
    required this.liveValueFor,
    required this.selected,
    required this.onSelect,
  });

  final SensorsHubSnapshot hub;
  final String? Function(SensorKind) liveValueFor;
  final SensorKind selected;
  final ValueChanged<SensorKind> onSelect;

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
          const SizedBox(height: 4),
          Text(
            'Elige qué sensor vas a conectar o ajustar.',
            style: CcType.label(size: 11, color: CcColors.inkDim),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final kind in _kindOrder) ...[
                if (kind != _kindOrder.first) const SizedBox(width: 8),
                Expanded(
                  child: _KindChip(
                    kind: kind,
                    state: hub.of(kind),
                    value: liveValueFor(kind),
                    selected: kind == selected,
                    onTap: () => onSelect(kind),
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

/// Ficha de un tipo de sensor: dice su estado y, al tocarla, filtra la
/// pantalla a ese tipo.
class _KindChip extends StatelessWidget {
  const _KindChip({
    required this.kind,
    required this.state,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final SensorKind kind;
  final SensorConnectionState state;
  final String? value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final meta = _meta(kind);
    final on = state.isConnected;
    final warn = state.isReconnecting;
    final reading = on && value != null ? '$value ${kind.unit}' : '—';
    return Semantics(
      button: true,
      selected: selected,
      label: '${kind.shortLabel}, ${on ? 'conectado' : 'sin conectar'}',
      child: Material(
        color: selected
            ? meta.color.withValues(alpha: 0.13)
            : CcColors.surfaceInset,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(11),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.fromLTRB(4, 9, 4, 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: selected
                    ? meta.color.withValues(alpha: 0.75)
                    : CcColors.lineSoft,
                width: selected ? 1.4 : 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      meta.icon,
                      size: 16,
                      color: on || selected ? meta.color : CcColors.inkFaint,
                    ),
                    if (on || warn) ...[
                      const SizedBox(width: 4),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: warn ? CcColors.warn : CcColors.ok,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  kind.shortLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CcType.label(
                    size: 11,
                    color: selected ? CcColors.ink : CcColors.inkDim,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    reading,
                    maxLines: 1,
                    style: CcType.displayStyle(
                      size: 12,
                      color: on ? CcColors.ink : CcColors.inkFaint,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- Tarjeta del tipo elegido --------------------------------------

class _SlotCard extends StatelessWidget {
  const _SlotCard({
    super.key,
    required this.kind,
    required this.state,
    required this.liveValue,
    required this.takenBy,
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
  final Map<String, SensorKind> takenBy;
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
              : meta.color.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(13),
            child: _Header(kind: kind, state: state, liveValue: liveValue),
          ),
          const Divider(height: 1, color: CcColors.lineSoft),
          Padding(
            padding: const EdgeInsets.fromLTRB(13, 12, 13, 14),
            child: _body(context),
          ),
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
          takenBy: takenBy,
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
  });

  final SensorKind kind;
  final SensorConnectionState state;
  final String? liveValue;

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
        if (connected && liveValue != null) ...[
          const SizedBox(width: 6),
          _LiveValue(kind: kind, value: liveValue!),
          const SizedBox(width: 4),
        ],
      ],
    );
  }

  String _statusLine() {
    final name = state.connectedDeviceName;
    return switch (state.status) {
      SensorConnectionStatus.connected => name ?? 'Conectado',
      SensorConnectionStatus.connecting => 'Conectando…',
      SensorConnectionStatus.scanning =>
        'Buscando sensores de ${kind.shortLabel.toLowerCase()} cerca…',
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
    required this.takenBy,
    required this.onRescan,
    required this.onDeviceTap,
  });

  final SensorKind kind;
  final SensorConnectionState state;
  final Map<String, SensorKind> takenBy;
  final VoidCallback onRescan;
  final void Function(DiscoveredDevice) onDeviceTap;

  @override
  Widget build(BuildContext context) {
    final meta = _meta(kind);
    final devices = state.discoveredDevices;
    final scanning = state.isScanning;
    final what = kind.shortLabel.toLowerCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Sensores de $what cerca',
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
              label: Text(devices.isEmpty ? 'Buscar' : 'Volver a buscar'),
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
                  : 'Ningún sensor de $what encontrado. Enciéndelo, '
                        'acércalo al teléfono y toca "Buscar".',
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
              takenBy: takenBy[device.id],
              onTap: () => onDeviceTap(device),
            ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 1),
              child: Icon(
                Icons.filter_alt_outlined,
                size: 13,
                color: CcColors.inkFaint,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _filterNote(kind),
                style: const TextStyle(
                  color: CcColors.inkFaint,
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DeviceRow extends StatelessWidget {
  const _DeviceRow({
    required this.kind,
    required this.device,
    required this.takenBy,
    required this.onTap,
  });

  final SensorKind kind;
  final DiscoveredDevice device;

  /// Tipo en el que este mismo aparato ya está conectado, si lo está.
  final SensorKind? takenBy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final meta = _meta(kind);
    final taken = takenBy;
    return InkWell(
      onTap: taken == null ? onTap : null,
      child: Opacity(
        opacity: taken == null ? 1 : 0.5,
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
                      taken == null
                          ? device.id
                          : 'Ya conectado como ${taken.shortLabel.toLowerCase()}',
                      style: CcType.label(size: 10, color: CcColors.inkFaint),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _SignalBars(bars: _signal(device.rssi).bars, color: meta.color),
              const SizedBox(width: 8),
              Icon(
                taken == null ? Icons.chevron_right : Icons.link,
                size: 16,
                color: CcColors.inkFaint,
              ),
            ],
          ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  foregroundColor: CcColors.inkDim,
                  side: const BorderSide(color: CcColors.line),
                ),
                icon: const Icon(Icons.swap_horiz, size: 16),
                label: const Text('Cambiar'),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onDisconnect,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12),
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
