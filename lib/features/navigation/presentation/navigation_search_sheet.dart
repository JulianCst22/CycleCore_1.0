import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cyclecore_core/database/app_database.dart';
import 'package:cyclecore_core/theme/cc_colors.dart';
import 'package:cyclecore_core/theme/cc_type.dart';
import '../data/geocoding_service.dart';
import '../data/saved_places_repository.dart';
import '../domain/navigation_target.dart';
import 'navigation_providers.dart';

/// Abre el buscador de destino. Devuelve el [NavigationTarget] elegido
/// (una guardada, un reciente o un resultado de búsqueda), o `null` si
/// el usuario cerró sin elegir. **No calcula la ruta** -- de eso se
/// encarga el mapa, que después pide confirmación.
Future<NavigationTarget?> showNavigationSearchSheet(
  BuildContext context,
  WidgetRef ref, {
  required double fromLat,
  required double fromLng,
}) {
  return showModalBottomSheet<NavigationTarget>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _NavigationSearchSheet(fromLat: fromLat, fromLng: fromLng),
  );
}

class _NavigationSearchSheet extends ConsumerStatefulWidget {
  final double fromLat;
  final double fromLng;

  const _NavigationSearchSheet({required this.fromLat, required this.fromLng});

  @override
  ConsumerState<_NavigationSearchSheet> createState() =>
      _NavigationSearchSheetState();
}

class _NavigationSearchSheetState
    extends ConsumerState<_NavigationSearchSheet> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;
  List<GeocodingResult> _results = [];
  bool _searching = false;
  String? _error;

  bool get _isSearching => _controller.text.trim().length >= 3;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    setState(() {}); // refresca el switch guardadas/resultados
    if (query.trim().length < 3) {
      setState(() => _results = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() {
        _searching = true;
        _error = null;
      });
      try {
        final results = await ref
            .read(geocodingServiceProvider)
            .search(query, nearLat: widget.fromLat, nearLng: widget.fromLng);
        if (mounted) setState(() => _results = results);
      } catch (e) {
        if (mounted) setState(() => _error = 'No se pudo buscar: $e');
      } finally {
        if (mounted) setState(() => _searching = false);
      }
    });
  }

  void _pick(NavigationTarget target) => Navigator.of(context).pop(target);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.62,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
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
                      '¿A dónde vamos?',
                      style: CcType.displayStyle(
                        size: 19,
                        weight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 13),
                    _SearchField(
                      controller: _controller,
                      focusNode: _focus,
                      onChanged: _onQueryChanged,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isSearching
                    ? _ResultsList(
                        scrollController: scrollController,
                        results: _results,
                        searching: _searching,
                        error: _error,
                        onPick: (r) => _pick(
                          NavigationTarget(
                            name: _shortName(r.displayName),
                            lat: r.lat,
                            lng: r.lng,
                          ),
                        ),
                      )
                    : _SavedAndRecent(
                        scrollController: scrollController,
                        onPick: _pick,
                        onSearchTap: () => _focus.requestFocus(),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Nominatim devuelve nombres larguísimos ("Alto de Patios, La Calera,
/// Cundinamarca, RAP..., Colombia") -- para el chip/tarjeta nos quedamos
/// con las 2 primeras partes.
String _shortName(String displayName) {
  final parts = displayName.split(',').map((p) => p.trim()).toList();
  return parts.take(2).join(', ');
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      style: const TextStyle(color: CcColors.ink, fontSize: 15),
      cursorColor: CcColors.blue,
      decoration: InputDecoration(
        hintText: 'Busca un lugar…',
        hintStyle: const TextStyle(color: CcColors.inkFaint, fontSize: 15),
        prefixIcon: const Icon(Icons.search, color: CcColors.inkDim, size: 20),
        filled: true,
        fillColor: CcColors.surfaceInset,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: CcColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: CcColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: CcColors.blue, width: 1.5),
        ),
      ),
    );
  }
}

class _SavedAndRecent extends ConsumerWidget {
  final ScrollController scrollController;
  final ValueChanged<NavigationTarget> onPick;
  final VoidCallback onSearchTap;

  const _SavedAndRecent({
    required this.scrollController,
    required this.onPick,
    required this.onSearchTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedPlacesProvider).valueOrNull ?? const [];
    final recent =
        ref.watch(recentDestinationsProvider).valueOrNull ?? const [];

    if (saved.isEmpty && recent.isEmpty) {
      return GestureDetector(
        onTap: onSearchTap,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              'Busca tu destino arriba.\nLos que uses más se irán guardando aquí.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: CcColors.inkDim, height: 1.5),
            ),
          ),
        ),
      );
    }

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
      children: [
        if (saved.isNotEmpty) ...[
          const _SectionLabel('Guardadas'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final place in saved)
                _SavedChip(place: place, onTap: () => onPick(place.toTarget())),
            ],
          ),
          const SizedBox(height: 20),
        ],
        if (recent.isNotEmpty) ...[
          const _SectionLabel('Recientes'),
          const SizedBox(height: 6),
          for (final target in recent)
            _RecentRow(target: target, onTap: () => onPick(target)),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: CcType.label(
        size: 10.5,
        color: CcColors.inkFaint,
      ).copyWith(letterSpacing: 1.4),
    );
  }
}

class _SavedChip extends StatelessWidget {
  final SavedPlace place;
  final VoidCallback onTap;

  const _SavedChip({required this.place, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final kind = PlaceKind.fromWire(place.kind);
    final (icon, color) = switch (kind) {
      PlaceKind.home => (Icons.home_outlined, CcColors.blue),
      PlaceKind.peak => (Icons.terrain_outlined, CcColors.mSlope),
      PlaceKind.generic => (Icons.star, CcColors.gold),
    };
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: CcColors.surfaceInset,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CcColors.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              place.name,
              style: const TextStyle(
                color: CcColors.ink,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentRow extends StatelessWidget {
  final NavigationTarget target;
  final VoidCallback onTap;

  const _RecentRow({required this.target, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 2),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                target.kind == PlaceKind.peak
                    ? Icons.terrain_outlined
                    : Icons.history,
                size: 15,
                color: CcColors.inkDim,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                target.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: CcColors.ink,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultsList extends StatelessWidget {
  final ScrollController scrollController;
  final List<GeocodingResult> results;
  final bool searching;
  final String? error;
  final ValueChanged<GeocodingResult> onPick;

  const _ResultsList({
    required this.scrollController,
    required this.results,
    required this.searching,
    required this.error,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          error!,
          style: const TextStyle(color: CcColors.danger, fontSize: 12.5),
        ),
      );
    }
    if (searching && results.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: CcColors.blue,
            ),
          ),
        ),
      );
    }
    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: results.length,
      separatorBuilder: (_, _) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final result = results[index];
        return Material(
          color: CcColors.surfaceInset,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onPick(result),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                      result.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: CcColors.ink, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
