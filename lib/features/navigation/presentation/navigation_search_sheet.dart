import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../data/geocoding_service.dart';
import 'navigation_providers.dart';

/// Abre el buscador de destino, calcula la ruta y la deja activa en
/// `activeNavigationRouteProvider`. Devuelve true si se armó una ruta,
/// false si el usuario canceló.
Future<bool> showNavigationSearchSheet(
  BuildContext context,
  WidgetRef ref, {
  required double fromLat,
  required double fromLng,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.panelBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _NavigationSearchSheetContent(
      fromLat: fromLat,
      fromLng: fromLng,
    ),
  );
  return result ?? false;
}

class _NavigationSearchSheetContent extends ConsumerStatefulWidget {
  final double fromLat;
  final double fromLng;

  const _NavigationSearchSheetContent({
    required this.fromLat,
    required this.fromLng,
  });

  @override
  ConsumerState<_NavigationSearchSheetContent> createState() =>
      _NavigationSearchSheetContentState();
}

class _NavigationSearchSheetContentState
    extends ConsumerState<_NavigationSearchSheetContent> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<GeocodingResult> _results = [];
  bool _searching = false;
  bool _routing = false;
  String? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
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
        final results = await ref.read(geocodingServiceProvider).search(
              query,
              nearLat: widget.fromLat,
              nearLng: widget.fromLng,
            );
        if (mounted) setState(() => _results = results);
      } catch (e) {
        if (mounted) setState(() => _error = 'No se pudo buscar: $e');
      } finally {
        if (mounted) setState(() => _searching = false);
      }
    });
  }

  Future<void> _selectDestination(GeocodingResult result) async {
    setState(() {
      _routing = true;
      _error = null;
    });
    try {
      await ref.read(navigationControllerProvider).calculateRoute(
            fromLat: widget.fromLat,
            fromLng: widget.fromLng,
            toLat: result.lat,
            toLng: result.lng,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _routing = false;
        _error = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color:
                      AppColors.textSecondaryOnPanel.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '¿A dónde vamos?',
              style: TextStyle(
                color: AppColors.textPrimaryOnPanel,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _controller,
              autofocus: true,
              onChanged: _onQueryChanged,
              style: const TextStyle(color: AppColors.textPrimaryOnPanel),
              decoration: InputDecoration(
                hintText: 'Ej: Los Patios, Cúcuta',
                hintStyle: const TextStyle(
                  color: AppColors.textSecondaryOnPanel,
                ),
                prefixIcon: const Icon(Icons.search,
                    color: AppColors.textSecondaryOnPanel),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_searching)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    color: AppColors.recordButtonActive,
                    fontSize: 12.5,
                  ),
                ),
              ),
            if (_routing)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'Calculando la ruta más corta…',
                    style: TextStyle(color: AppColors.textSecondaryOnPanel),
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _results.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final result = _results[index];
                    return Material(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _selectDestination(result),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.place_outlined,
                                  color: AppColors.primary, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  result.displayName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textPrimaryOnPanel,
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
