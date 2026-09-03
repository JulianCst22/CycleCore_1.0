import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' as latlng;

import '../../../core/database/app_database.dart';
import '../../../core/theme/cc_colors.dart';
import '../../../core/theme/cc_type.dart';
import '../../geospatial/presentation/map_providers.dart';
import '../data/geocoding_service.dart';
import '../domain/climb_detection.dart';
import '../domain/navigation_target.dart';
import 'navigation_providers.dart';
import 'pick_location_screen.dart';

/// Bogotá -- centro de fallback si todavía no hay un fix de GPS.
const _fallbackCenter = latlng.LatLng(4.65, -74.06);

/// Ajustes › Mapa › Ubicaciones -- la lista de lugares guardados, con
/// añadir (buscando por nombre o marcando un punto en el mapa) y borrar
/// (deslizando).
class SavedPlacesScreen extends ConsumerWidget {
  const SavedPlacesScreen({super.key});

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final method = await _pickAddMethod(context);
    if (method == null || !context.mounted) return;

    final position = ref.read(currentPositionProvider).valueOrNull;
    var suggestedName = '';
    late final double lat;
    late final double lng;

    if (method == _AddMethod.search) {
      final result = await showModalBottomSheet<GeocodingResult>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _AddPlaceSheet(
          nearLat: position?.latitude,
          nearLng: position?.longitude,
        ),
      );
      if (result == null || !context.mounted) return;
      suggestedName = result.displayName.split(',').first.trim();
      lat = result.lat;
      lng = result.lng;
    } else {
      final center = position != null
          ? latlng.LatLng(position.latitude, position.longitude)
          : _fallbackCenter;
      final picked = await Navigator.of(context).push<latlng.LatLng>(
        MaterialPageRoute(
          builder: (_) => PickLocationScreen(initialCenter: center),
        ),
      );
      if (picked == null || !context.mounted) return;
      lat = picked.latitude;
      lng = picked.longitude;
    }

    final data = await _askNameAndKind(context, suggestedName);
    if (data == null || !context.mounted) return;

    await ref
        .read(savedPlacesRepositoryProvider)
        .add(name: data.$1, lat: lat, lng: lng, kind: data.$2);
  }

  Future<_AddMethod?> _pickAddMethod(BuildContext context) {
    return showModalBottomSheet<_AddMethod>(
      context: context,
      backgroundColor: CcColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: CcColors.inkFaint,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 6),
            ListTile(
              leading: const Icon(Icons.search, color: CcColors.blue),
              title: const Text(
                'Buscar por nombre',
                style: TextStyle(color: CcColors.ink),
              ),
              onTap: () => Navigator.of(sheetContext).pop(_AddMethod.search),
            ),
            ListTile(
              leading: const Icon(
                Icons.push_pin_outlined,
                color: CcColors.blue,
              ),
              title: const Text(
                'Marcar un punto en el mapa',
                style: TextStyle(color: CcColors.ink),
              ),
              subtitle: const Text(
                'Para un sitio sin dirección, como tu casa',
                style: TextStyle(color: CcColors.inkDim, fontSize: 12),
              ),
              onTap: () => Navigator.of(sheetContext).pop(_AddMethod.map),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<(String, PlaceKind)?> _askNameAndKind(
    BuildContext context,
    String suggestedName,
  ) async {
    final controller = TextEditingController(text: suggestedName);
    var kind = looksLikeClimb(suggestedName)
        ? PlaceKind.peak
        : PlaceKind.generic;

    return showDialog<(String, PlaceKind)>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: CcColors.surfaceHi,
          title: const Text(
            'Guardar ubicación',
            style: TextStyle(color: CcColors.ink),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  style: const TextStyle(color: CcColors.ink),
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    labelStyle: TextStyle(color: CcColors.inkDim),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final k in PlaceKind.values)
                      ChoiceChip(
                        label: Text(_kindLabel(k)),
                        selected: kind == k,
                        onSelected: (_) => setState(() => kind = k),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isEmpty) return;
                Navigator.of(context).pop((name, kind));
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    SavedPlace place,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: CcColors.surfaceHi,
        title: const Text(
          '¿Borrar ubicación?',
          style: TextStyle(color: CcColors.ink),
        ),
        content: Text(
          '"${place.name}" se quita de tus guardadas.',
          style: const TextStyle(color: CcColors.inkDim),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Borrar',
              style: TextStyle(color: CcColors.danger),
            ),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(savedPlacesRepositoryProvider).delete(place.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final placesAsync = ref.watch(savedPlacesProvider);

    return Scaffold(
      backgroundColor: CcColors.bg,
      appBar: AppBar(
        backgroundColor: CcColors.bg,
        title: const Text('Ubicaciones', style: TextStyle(color: CcColors.ink)),
        iconTheme: const IconThemeData(color: CcColors.ink),
      ),
      body: placesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: CcColors.orange),
        ),
        error: (e, _) => Center(
          child: Text(
            'No se pudieron cargar: $e',
            style: const TextStyle(color: CcColors.inkDim),
          ),
        ),
        data: (places) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            const Text(
              'Tus lugares fijos. Aparecen primero al tocar "Navegar" y '
              'con estrella en el mapa.',
              style: TextStyle(
                color: CcColors.inkDim,
                fontSize: 12.5,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            if (places.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Todavía no tienes ninguna.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: CcColors.inkFaint),
                ),
              )
            else
              for (final place in places)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Dismissible(
                    key: ValueKey(place.id),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (_) async {
                      await _confirmDelete(context, ref, place);
                      return false;
                    },
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: CcColors.danger.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.white,
                      ),
                    ),
                    child: _PlaceTile(place: place),
                  ),
                ),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              onPressed: () => _add(context, ref),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Añadir ubicación'),
              style: OutlinedButton.styleFrom(
                foregroundColor: CcColors.blue,
                side: const BorderSide(color: CcColors.line),
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _AddMethod { search, map }

String _kindLabel(PlaceKind k) => switch (k) {
  PlaceKind.home => 'Casa',
  PlaceKind.peak => 'Alto',
  PlaceKind.generic => 'Lugar',
};

class _PlaceTile extends StatelessWidget {
  final SavedPlace place;

  const _PlaceTile({required this.place});

  @override
  Widget build(BuildContext context) {
    final kind = PlaceKind.fromWire(place.kind);
    final (icon, color) = switch (kind) {
      PlaceKind.home => (Icons.home_outlined, CcColors.blue),
      PlaceKind.peak => (Icons.terrain_outlined, CcColors.mSlope),
      PlaceKind.generic => (Icons.place_outlined, CcColors.inkDim),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: CcColors.surfaceHi.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CcColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              place.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: CcColors.ink,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Icon(Icons.star, size: 17, color: CcColors.gold),
        ],
      ),
    );
  }
}

class _AddPlaceSheet extends ConsumerStatefulWidget {
  final double? nearLat;
  final double? nearLng;

  const _AddPlaceSheet({this.nearLat, this.nearLng});

  @override
  ConsumerState<_AddPlaceSheet> createState() => _AddPlaceSheetState();
}

class _AddPlaceSheetState extends ConsumerState<_AddPlaceSheet> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<GeocodingResult> _results = [];
  bool _searching = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 3) {
      setState(() => _results = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _searching = true);
      try {
        final results = await ref
            .read(geocodingServiceProvider)
            .search(query, nearLat: widget.nearLat, nearLng: widget.nearLng);
        if (mounted) setState(() => _results = results);
      } catch (_) {
        // silencioso -- la lista simplemente queda vacía
      } finally {
        if (mounted) setState(() => _searching = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: CcColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: CcColors.inkFaint,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Buscar un lugar',
                    style: CcType.displayStyle(
                      size: 18,
                      weight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _controller,
                    autofocus: true,
                    onChanged: _onChanged,
                    style: const TextStyle(color: CcColors.ink),
                    cursorColor: CcColors.blue,
                    decoration: InputDecoration(
                      hintText: 'Nombre del lugar…',
                      hintStyle: const TextStyle(color: CcColors.inkFaint),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: CcColors.inkDim,
                        size: 20,
                      ),
                      filled: true,
                      fillColor: CcColors.surfaceInset,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(13),
                        borderSide: const BorderSide(color: CcColors.line),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_searching)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: CcColors.blue,
                  ),
                ),
              ),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: _results.length,
                separatorBuilder: (_, _) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final r = _results[index];
                  return Material(
                    color: CcColors.surfaceInset,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.of(context).pop(r),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.place_outlined,
                              color: CcColors.blue,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                r.displayName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: CcColors.ink,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
