import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/eco_card.dart';
import '../../../shared/widgets/loading_view.dart';
import '../data/map_repository.dart';
import '../models/collection_point.dart';

final _pointsProvider =
    FutureProvider.autoDispose<List<CollectionPoint>>((ref) {
  return MapRepository().fetchPoints();
});

class MapFilterNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  void setFilter(String value) => state = value;
}

final _filterProvider =
    NotifierProvider<MapFilterNotifier, String>(MapFilterNotifier.new);

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _mapController = MapController();
  final _searchCtrl = TextEditingController();
  CollectionPoint? _selected;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _openDirections(CollectionPoint point) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${point.latitude},${point.longitude}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
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
          final matchesFilter = filter == 'all' ||
              p.acceptedFractions.contains(filter) ||
              (filter == 'specialty' &&
                  p.acceptedFractions.contains('hazardous'));
          final matchesQuery = query.isEmpty ||
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
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'ru.campus.campus_eco_tracker',
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
                          Icons.delete_rounded,
                          size: selected ? 40 : 34,
                          color: selected ? AppColors.accent : AppColors.primary,
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
                    EcoCard(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Search recycling stations...',
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.search),
                          filled: false,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 38,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _FilterChip(
                            label: 'All Bins',
                            selected: filter == 'all',
                            onTap: () =>
                                ref.read(_filterProvider.notifier).setFilter('all'),
                          ),
                          _FilterChip(
                            label: 'Plastic',
                            selected: filter == 'plastic',
                            onTap: () => ref
                                .read(_filterProvider.notifier)
                                .setFilter('plastic'),
                          ),
                          _FilterChip(
                            label: 'Paper',
                            selected: filter == 'paper',
                            onTap: () => ref
                                .read(_filterProvider.notifier)
                                .setFilter('paper'),
                          ),
                          _FilterChip(
                            label: 'Metal',
                            selected: filter == 'metal',
                            onTap: () => ref
                                .read(_filterProvider.notifier)
                                .setFilter('metal'),
                          ),
                          _FilterChip(
                            label: 'Specialty',
                            selected: filter == 'specialty',
                            onTap: () => ref
                                .read(_filterProvider.notifier)
                                .setFilter('specialty'),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                        Text(
                          'Recycles: ${_selected!.acceptedFractions.join(', ')}',
                          style: const TextStyle(color: AppColors.muted),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Text('Fill Capacity Status'),
                            const Spacer(),
                            Text(
                              '${_selected!.fillPercent ?? 0}% Full',
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
                            label: const Text('Get Directions'),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Report sent to eco-operators'),
                              ),
                            );
                          },
                          child: const Text(
                            'Report Full Bin',
                            style: TextStyle(color: AppColors.muted),
                          ),
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