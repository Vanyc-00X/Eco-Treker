import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/l10n/app_ru.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/eco_card.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/map_repository.dart';
import '../models/collection_point.dart';

final _pointsProvider = FutureProvider.autoDispose<List<CollectionPoint>>((
  ref,
) {
  return MapRepository().fetchPoints();
});

class MapFilterNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  void setFilter(String value) => state = value;
}

final _filterProvider = NotifierProvider<MapFilterNotifier, String>(
  MapFilterNotifier.new,
);

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _mapController = MapController();
  final _searchCtrl = TextEditingController();
  CollectionPoint? _selected;
  bool _reporting = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _openDirections(CollectionPoint point) async {
    final uri = Uri.parse(
      'https://yandex.ru/maps/?rtext=~${point.latitude},${point.longitude}&rtt=auto',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _reportFullBin(CollectionPoint point) async {
    final noteCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppRu.reportFullBin),
        content: TextField(
          controller: noteCtrl,
          maxLines: 3,
          decoration: const InputDecoration(hintText: AppRu.reportNoteHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppRu.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(AppRu.confirm),
          ),
        ],
      ),
    );
    final note = noteCtrl.text.trim();
    noteCtrl.dispose();
    if (confirmed != true || !mounted) return;

    final profile = await ref.read(currentProfileProvider.future);
    if (profile == null || !mounted) return;

    setState(() => _reporting = true);
    try {
      await MapRepository().reportFullBin(
        reporterId: profile.id,
        collectionPointId: point.id,
        note: note.isEmpty ? null : note,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(AppRu.reportSent)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${AppRu.reportFailed}: $e')));
    } finally {
      if (mounted) setState(() => _reporting = false);
    }
  }

  String _fractionLabel(String key) {
    switch (key) {
      case 'plastic':
        return AppRu.plastic;
      case 'paper':
        return AppRu.paper;
      case 'metal':
        return AppRu.metal;
      case 'glass':
        return AppRu.glass;
      case 'hazardous':
        return AppRu.batteries;
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pointsAsync = ref.watch(_pointsProvider);
    final filter = ref.watch(_filterProvider);
    final query = _searchCtrl.text.trim().toLowerCase();

    return pointsAsync.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(_pointsProvider),
      ),
      data: (points) {
        final filtered = points.where((p) {
          final matchesFilter =
              filter == 'all' ||
              p.acceptedFractions.contains(filter) ||
              (filter == 'specialty' &&
                  p.acceptedFractions.contains('hazardous')) ||
              (filter == 'accessible' && p.isAccessible) ||
              (filter == 'full' && (p.fillPercent ?? 0) >= 80);
          final matchesQuery =
              query.isEmpty ||
              p.name.toLowerCase().contains(query) ||
              p.address.toLowerCase().contains(query);
          return matchesFilter && matchesQuery;
        }).toList();

        final center = filtered.isNotEmpty
            ? LatLng(filtered.first.latitude, filtered.first.longitude)
            : const LatLng(55.7558, 37.6173);

        return Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: 15,
                onTap: (_, _) => setState(() => _selected = null),
              ),
              children: [
                TileLayer(
                  // Яндекс.Карты в Web Mercator (совместимо с flutter_map)
                  urlTemplate:
                      'https://core-renderer-tiles.maps.yandex.net/tiles?l=map&x={x}&y={y}&z={z}&scale=1&lang=ru_RU&projection=web_mercator',
                  userAgentPackageName: 'ru.campus.campus_eco_tracker',
                  retinaMode: true,
                ),
                MarkerLayer(
                  markers: filtered.map((p) {
                    final selected = _selected?.id == p.id;
                    return Marker(
                      point: LatLng(p.latitude, p.longitude),
                      width: 44,
                      height: 44,
                      child: GestureDetector(
                        onTap: () => setState(() => _selected = p),
                        child: Icon(
                          Icons.location_on,
                          size: selected ? 42 : 36,
                          color: selected ? AppColors.accent : p.markerColor,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: EcoCard(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: TextField(
                              controller: _searchCtrl,
                              decoration: const InputDecoration(
                                hintText: AppRu.searchStations,
                                border: InputBorder.none,
                                prefixIcon: Icon(Icons.search),
                                filled: false,
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: AppRu.refresh,
                          onPressed: () => ref.invalidate(_pointsProvider),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            minimumSize: const Size(48, 48),
                          ),
                          icon: const Icon(
                            Icons.refresh_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 38,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _FilterChip(
                            label: AppRu.allBins,
                            selected: filter == 'all',
                            onTap: () => ref
                                .read(_filterProvider.notifier)
                                .setFilter('all'),
                          ),
                          _FilterChip(
                            label: AppRu.plastic,
                            selected: filter == 'plastic',
                            onTap: () => ref
                                .read(_filterProvider.notifier)
                                .setFilter('plastic'),
                          ),
                          _FilterChip(
                            label: AppRu.paper,
                            selected: filter == 'paper',
                            onTap: () => ref
                                .read(_filterProvider.notifier)
                                .setFilter('paper'),
                          ),
                          _FilterChip(
                            label: AppRu.metal,
                            selected: filter == 'metal',
                            onTap: () => ref
                                .read(_filterProvider.notifier)
                                .setFilter('metal'),
                          ),
                          _FilterChip(
                            label: AppRu.glass,
                            selected: filter == 'glass',
                            onTap: () => ref
                                .read(_filterProvider.notifier)
                                .setFilter('glass'),
                          ),
                          _FilterChip(
                            label: AppRu.specialty,
                            selected: filter == 'specialty',
                            onTap: () => ref
                                .read(_filterProvider.notifier)
                                .setFilter('specialty'),
                          ),
                          _FilterChip(
                            label: 'Доступность',
                            selected: filter == 'accessible',
                            onTap: () => ref
                                .read(_filterProvider.notifier)
                                .setFilter('accessible'),
                          ),
                          _FilterChip(
                            label: 'Полные',
                            selected: filter == 'full',
                            onTap: () => ref
                                .read(_filterProvider.notifier)
                                .setFilter('full'),
                          ),
                        ],
                      ),
                    ),
                    if (filtered.isEmpty) ...[
                      const SizedBox(height: 10),
                      EcoCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.search_off_rounded,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppRu.noMapResults,
                                    style: GoogleFonts.dmSans(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const Text(
                                    AppRu.noMapResultsHint,
                                    style: TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (_selected == null)
              const Positioned(
                left: 12,
                bottom: 12,
                child: Text(
                  '© Яндекс',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF666666),
                    backgroundColor: Color(0xCCFFFFFF),
                  ),
                ),
              ),
            if (_selected != null)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: EcoCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _selected!.name,
                                style: GoogleFonts.dmSans(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.mint,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _selected!.workHours,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        if (_selected!.address.isNotEmpty)
                          Text(
                            _selected!.address,
                            style: const TextStyle(color: AppColors.muted),
                          ),
                        Text(
                          '${AppRu.recycles}: ${_selected!.acceptedFractions.map(_fractionLabel).join(', ')}',
                          style: const TextStyle(color: AppColors.muted),
                        ),
                        if (_selected!.contactName != null ||
                            _selected!.contactPhone != null)
                          Text(
                            '${_selected!.contactName ?? ''} ${_selected!.contactPhone ?? ''}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        if (_selected!.isAccessible)
                          const Text(
                            'Доступно для маломобильных',
                            style: TextStyle(fontSize: 12, color: AppColors.primary),
                          ),
                        if (_selected!.photoUrl != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Image.network(
                              _selected!.photoUrl!,
                              height: 100,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Text(AppRu.fillCapacity),
                            const Spacer(),
                            Text(
                              '${_selected!.fillPercent ?? 0}${AppRu.percentFull}',
                              style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: ((_selected!.fillPercent ?? 0) / 100)
                                .clamp(0, 1)
                                .toDouble(),
                            minHeight: 8,
                            backgroundColor: AppColors.progressTrack,
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _openDirections(_selected!),
                            icon: const Icon(Icons.north_east_rounded),
                            label: const Text(AppRu.getDirections),
                          ),
                        ),
                        Row(
                          children: [
                            TextButton(
                              onPressed: _reporting
                                  ? null
                                  : () => _reportFullBin(_selected!),
                              child: Text(
                                _reporting
                                    ? AppRu.loading
                                    : AppRu.reportFullBin,
                                style: const TextStyle(color: AppColors.muted),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () async {
                                final profile = await ref
                                    .read(currentProfileProvider.future);
                                if (profile == null) return;
                                await MapRepository().toggleFavorite(
                                  userId: profile.id,
                                  pointId: _selected!.id,
                                  favorite: true,
                                );
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(AppRu.favorites),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.favorite_border, size: 18),
                              label: const Text(AppRu.favorites),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
