import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/l10n/app_ru.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/points_calculator.dart';
import '../../../shared/widgets/eco_card.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../auth/providers/auth_providers.dart';
import '../../map/data/map_repository.dart';
import '../../map/models/collection_point.dart';
import '../data/recycle_repository.dart';
import '../models/waste_category.dart';
import '../providers/recycle_providers.dart';

final _categoriesProvider = FutureProvider.autoDispose<List<WasteCategory>>((
  ref,
) {
  return ref.watch(recycleRepositoryProvider).fetchCategories();
});

final _pointsProvider = FutureProvider.autoDispose<List<CollectionPoint>>((
  ref,
) {
  return MapRepository().fetchPoints();
});

class UploadClaimScreen extends ConsumerStatefulWidget {
  const UploadClaimScreen({super.key});

  @override
  ConsumerState<UploadClaimScreen> createState() => _UploadClaimScreenState();
}

class _UploadClaimScreenState extends ConsumerState<UploadClaimScreen> {
  final _weightCtrl = TextEditingController(text: '1.0');
  final _noteCtrl = TextEditingController();
  final _picker = ImagePicker();

  String? _categoryId;
  String? _pointId;
  Uint8List? _imageBytes;
  String _fileExt = 'jpg';
  bool _submitting = false;
  double? _lat;
  double? _lng;
  String? _previewText;

  static const _maxWeightKg = 50.0;

  Future<void> _captureGps() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
      });
    } catch (_) {}
  }

  void _updatePreview(List<WasteCategory> categories) {
    final weight = double.tryParse(_weightCtrl.text.replaceAll(',', '.'));
    final cat = categories.where((c) => c.id == _categoryId).firstOrNull;
    if (weight == null || cat == null) {
      _previewText = null;
      return;
    }
    final profile = ref.read(currentProfileProvider).asData?.value;
    final mult = PointsCalculator.computeMultiplier(
      when: DateTime.now(),
      inActiveChallenge: false,
      isFirstDrop: (profile?.totalKg ?? 0) <= 0,
    );
    final r = PointsCalculator.calculate(
      weightKg: weight,
      pointsPerKg: cat.pointsPerKg,
      co2PerKg: cat.co2PerKg,
      multiplier: mult,
    );
    _previewText =
        '${AppRu.calculatePreview}: ${r.points} б. · ${r.co2Kg} кг CO₂ (×${r.multiplier})';
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _showImageSourcePicker() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text(AppRu.takePhoto),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text(AppRu.chooseGallery),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    await _pickImage(source);
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      imageQuality: 75,
      maxWidth: 1600,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final ext = file.name.split('.').last.toLowerCase();
    setState(() {
      _imageBytes = bytes;
      _fileExt = (ext == 'png' || ext == 'webp' || ext == 'jpeg') ? ext : 'jpg';
      if (_fileExt == 'jpeg') _fileExt = 'jpg';
    });
  }

  Future<void> _submit() async {
    final profile = await ref.read(currentProfileProvider.future);
    if (!mounted || profile == null) return;

    final weight = double.tryParse(_weightCtrl.text.replaceAll(',', '.'));
    if (_categoryId == null || weight == null || weight <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(AppRu.selectCategoryWeight)));
      return;
    }
    if (weight > _maxWeightKg) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(AppRu.maxWeight)));
      return;
    }
    if (_imageBytes == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(AppRu.attachPhoto)));
      return;
    }

    setState(() => _submitting = true);
    try {
      final cats = await ref.read(_categoriesProvider.future);
      final cat = cats.where((c) => c.id == _categoryId).firstOrNull;
      final mult = PointsCalculator.computeMultiplier(
        when: DateTime.now(),
        inActiveChallenge: false,
        isFirstDrop: profile.totalKg <= 0,
      );
      await RecycleRepository().createPhotoClaimFull(
        studentId: profile.id,
        categoryId: _categoryId!,
        weightKg: weight,
        imageBytes: _imageBytes!,
        fileExt: _fileExt,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        collectionPointId: _pointId,
        latitude: _lat,
        longitude: _lng,
        bonusMultiplier: mult,
      );
      // ignore: unused_local_variable
      final _ = cat;
      invalidateRecycleData(ref);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          icon: const Icon(
            Icons.check_circle_rounded,
            color: AppColors.primary,
            size: 40,
          ),
          title: const Text(AppRu.claimSuccessTitle),
          content: const Text(AppRu.claimSuccessBody),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(AppRu.toRecycle),
            ),
          ],
        ),
      );
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${AppRu.submitFailed}: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(_categoriesProvider);
    final pointsAsync = ref.watch(_pointsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppRu.photoClaim),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: categoriesAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (categories) {
          _categoryId ??= categories.isNotEmpty ? categories.first.id : null;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              EcoCard(
                onTap: _showImageSourcePicker,
                child: _imageBytes == null
                    ? const SizedBox(
                        height: 160,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo_outlined,
                              size: 40,
                              color: AppColors.primary,
                            ),
                            SizedBox(height: 8),
                            Text(AppRu.tapChoosePhoto),
                          ],
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          _imageBytes!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              Text(
                AppRu.category,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _categoryId,
                items: categories
                    .map(
                      (c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(
                          '${c.nameRu} (${c.pointsPerKg} ${AppRu.pointsShort}/кг)',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() {
                  _categoryId = v;
                  _updatePreview(categories);
                }),
              ),
              const SizedBox(height: 16),
              Text(
                AppRu.weightKg,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _weightCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(hintText: AppRu.weightHint),
                onChanged: (_) => setState(() => _updatePreview(categories)),
              ),
              const SizedBox(height: 8),
              if (_previewText != null)
                Text(
                  _previewText!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _captureGps,
                icon: const Icon(Icons.my_location),
                label: Text(
                  _lat == null
                      ? 'Определить GPS'
                      : 'GPS: ${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppRu.collectionPoint,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              pointsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const Text(AppRu.pointsUnavailable),
                data: (points) {
                  return DropdownButtonFormField<String>(
                    initialValue: _pointId,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text(AppRu.notSpecified),
                      ),
                      ...points.map(
                        (p) =>
                            DropdownMenuItem(value: p.id, child: Text(p.name)),
                      ),
                    ],
                    onChanged: (v) => setState(() => _pointId = v),
                  );
                },
              ),
              const SizedBox(height: 16),
              Text(AppRu.note, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextField(
                controller: _noteCtrl,
                maxLines: 3,
                decoration: const InputDecoration(hintText: AppRu.noteHint),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(AppRu.submitClaim),
              ),
            ],
          );
        },
      ),
    );
  }
}
