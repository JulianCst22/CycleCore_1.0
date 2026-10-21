import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/ui.dart';
import '../domain/cockpit_field.dart';
import '../domain/cockpit_tile_config.dart';
import 'cockpit_grid_layout.dart';
import '../application/cockpit_layout_providers.dart';
import 'cockpit_settings_sheet.dart';

/// Vista de cockpit en pantalla completa, estilo ciclocomputador Garmin.
///
/// Un solo botón "Ajustar" arriba abre un menú corto con todo lo que se
/// cambia a mitad de salida:
/// - Sensores: va directo a conectarlos (si la pantalla que lo muestra
///   pasa [onOpenSensors]; el cockpit no conoce la feature de sensores).
/// - Elegir campos: CUÁNTOS y CUÁLES (`showCockpitSettingsSheet`).
/// - Mover y cambiar tamaño: modo edición para ARRASTRAR los campos y
///   ajustar su TAMAÑO -- los cambios quedan en un borrador hasta tocar
///   "Guardar"; "Cancelar" vuelve al layout guardado.
class CockpitFullscreenView extends ConsumerStatefulWidget {
  final List<CockpitTileConfig> tiles;
  final CockpitLiveData liveData;
  final VoidCallback onSwipeDown;

  /// Abre la pantalla de sensores; sin él, el menú no muestra la opción.
  final VoidCallback? onOpenSensors;

  /// Cómo van los sensores, para el menú ("2 de 4 conectados").
  final String? sensorsSummary;

  /// Algún sensor se está reconectando: el botón lleva un punto de aviso.
  final bool sensorsWarning;

  const CockpitFullscreenView({
    super.key,
    required this.tiles,
    required this.liveData,
    required this.onSwipeDown,
    this.onOpenSensors,
    this.sensorsSummary,
    this.sensorsWarning = false,
  });

  @override
  ConsumerState<CockpitFullscreenView> createState() =>
      _CockpitFullscreenViewState();
}

class _CockpitFullscreenViewState extends ConsumerState<CockpitFullscreenView> {
  bool _editing = false;
  late List<CockpitTileConfig> _draftTiles;

  @override
  void initState() {
    super.initState();
    _draftTiles = List.of(widget.tiles);
  }

  @override
  void didUpdateWidget(covariant CockpitFullscreenView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si el layout guardado cambió desde afuera (p.ej. se cambiaron
    // los campos desde la hoja de ajustes) y no estamos editando,
    // el borrador se refresca para no mostrar datos viejos.
    if (!_editing && oldWidget.tiles != widget.tiles) {
      _draftTiles = List.of(widget.tiles);
    }
  }

  void _startEditing() {
    setState(() {
      _draftTiles = List.of(widget.tiles);
      _editing = true;
    });
  }

  void _cancelEditing() {
    setState(() {
      _draftTiles = List.of(widget.tiles);
      _editing = false;
    });
  }

  Future<void> _saveEditing() async {
    await ref.read(cockpitLayoutProvider.notifier).setTiles(_draftTiles);
    if (mounted) setState(() => _editing = false);
  }

  Future<void> _openMenu() async {
    final choice = await showModalBottomSheet<_MenuChoice>(
      context: context,
      backgroundColor: AppColors.panelBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CockpitMenu(
        showSensors: widget.onOpenSensors != null,
        sensorsSummary: widget.sensorsSummary,
        sensorsWarning: widget.sensorsWarning,
      ),
    );
    if (!mounted || choice == null) return;
    switch (choice) {
      case _MenuChoice.sensors:
        widget.onOpenSensors?.call();
      case _MenuChoice.fields:
        await showCockpitSettingsSheet(context, ref);
      case _MenuChoice.arrange:
        _startEditing();
    }
  }

  void _reorder(int fromIndex, int toIndex) {
    setState(() {
      final moved = _draftTiles.removeAt(fromIndex);
      _draftTiles.insert(toIndex, moved);
    });
  }

  void _resize(int index, CockpitTileSize size) {
    setState(() {
      _draftTiles[index] = _draftTiles[index].copyWith(size: size);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tilesToShow = _editing ? _draftTiles : widget.tiles;

    return Material(
      color: AppColors.panelBackground,
      child: SafeArea(
        child: Column(
          children: [
            // Solo esta franja de arriba (la manija + los botones)
            // escucha el gesto de deslizar hacia abajo para cerrar.
            // Antes el GestureDetector envolvía TODA la pantalla, y
            // competía por el gesto con el panel exterior que anima la
            // transición -- ambos "escuchaban" el mismo arrastre, y el
            // de aquí adentro ganaba la pelea pero estaba conectado a
            // un callback vacío, así que el resultado era que no pasaba
            // NADA al deslizar hacia abajo. Ahora solo hay un lugar que
            // reacciona a ese gesto en esta pantalla, y si el usuario
            // arrastra desde el cuerpo de la grilla, el gesto sigue de
            // largo hacia el panel exterior (que sí sabe colapsar).
            GestureDetector(
              onVerticalDragEnd: (details) {
                if (_editing) return;
                final velocity = details.primaryVelocity ?? 0;
                if (velocity > 200) widget.onSwipeDown();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textSecondaryOnPanel.withValues(
                          alpha: 0.4,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const Spacer(),
                    if (_editing) ...[
                      TextButton(
                        onPressed: _cancelEditing,
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(
                            color: AppColors.textSecondaryOnPanel,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _saveEditing,
                        child: const Text(
                          'Guardar',
                          style: TextStyle(
                            color: CyclecorePalette.paramo,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ] else
                      _MenuButton(
                        warning: widget.sensorsWarning,
                        onTap: _openMenu,
                      ),
                  ],
                ),
              ),
            ),
            if (_editing)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Mantén presionado un campo para moverlo. Toca S/M/L '
                  'para cambiar su tamaño.',
                  style: TextStyle(
                    color: AppColors.textSecondaryOnPanel,
                    fontSize: 12,
                  ),
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: CockpitGridLayout(
                  tiles: tilesToShow,
                  liveData: widget.liveData,
                  editing: _editing,
                  onReorder: _reorder,
                  onResize: _resize,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _MenuChoice { sensors, fields, arrange }

/// "Ajustar": la entrada al menú, con un punto si un sensor se cayó.
class _MenuButton extends StatelessWidget {
  final bool warning;
  final VoidCallback onTap;

  const _MenuButton({required this.warning, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.white.withValues(alpha: 0.06),
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 14, 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      Icons.tune,
                      size: 18,
                      color: AppColors.textPrimaryOnPanel,
                    ),
                    if (warning)
                      Positioned(
                        right: -3,
                        top: -3,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: CcColors.warn,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 6),
                const Text(
                  'Ajustar',
                  style: TextStyle(
                    color: AppColors.textPrimaryOnPanel,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
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

/// El menú: sensores primero (lo que más se necesita a mitad de salida),
/// después qué campos ver y cómo acomodarlos.
class _CockpitMenu extends StatelessWidget {
  final bool showSensors;
  final String? sensorsSummary;
  final bool sensorsWarning;

  const _CockpitMenu({
    required this.showSensors,
    required this.sensorsSummary,
    required this.sensorsWarning,
  });

  @override
  Widget build(BuildContext context) {
    void pick(_MenuChoice c) => Navigator.of(context).pop(c);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondaryOnPanel.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'Ajustar la pantalla',
                style: TextStyle(
                  color: AppColors.textPrimaryOnPanel,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (showSensors)
              _MenuRow(
                icon: Icons.sensors,
                title: 'Sensores',
                subtitle:
                    sensorsSummary ?? 'Conectar pulso, potencia, cadencia',
                warning: sensorsWarning,
                onTap: () => pick(_MenuChoice.sensors),
              ),
            _MenuRow(
              icon: Icons.view_module_outlined,
              title: 'Elegir campos',
              subtitle: 'Qué datos ves y cuántos',
              onTap: () => pick(_MenuChoice.fields),
            ),
            _MenuRow(
              icon: Icons.open_with,
              title: 'Mover y cambiar tamaño',
              subtitle: 'Arrastra los campos y elige S, M o L',
              onTap: () => pick(_MenuChoice.arrange),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool warning;
  final VoidCallback onTap;

  const _MenuRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.warning = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimaryOnPanel,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: warning
                          ? CcColors.warn
                          : AppColors.textSecondaryOnPanel,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondaryOnPanel,
            ),
          ],
        ),
      ),
    );
  }
}
