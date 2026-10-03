import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/eco_card.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../auth/providers/auth_providers.dart';
import '../../map/data/map_repository.dart';
import '../../map/models/collection_point.dart';
import '../data/recycle_repository.dart';
import '../models/waste_category.dart';

final _categoriesProvider =
    FutureProvider.autoDispose<List<WasteCategory>>((ref) {
  return RecycleRepository().fetchCategories();
});

final _pointsProvider =
    FutureProvider.autoDispose<List<CollectionPoint>>((ref) {
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

  @override
  void dispose() {
    _weightCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select category and enter valid weight')),
      );
      return;
    }
    if (_imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please attach a photo')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await RecycleRepository().createPhotoClaim(
        studentId: profile.id,
        categoryId: _categoryId!,
        weightKg: weight,
        imageBytes: _imageBytes!,
        fileExt: _fileExt,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        collectionPointId: _pointId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Claim submitted for verification')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
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
        title: const Text('Photo Claim'),
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
                onTap: _pickImage,
                child: _imageBytes == null
                    ? const SizedBox(
                        height: 160,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined,
                                size: 40, color: AppColors.primary),
                            SizedBox(height: 8),
                            Text('Tap to choose photo'),
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
              Text('Category', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _categoryId,
                items: categories
                    .map(
                      (c) => DropdownMenuItem(
                        value: c.id,
                        child: Text('${c.nameRu} (${c.pointsPerKg} pts/kg)'),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _categoryId = v),
              ),
              const SizedBox(height: 16),
              Text('Weight (kg)', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextField(
                controller: _weightCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(hintText: 'e.g. 2.5'),
              ),
              const SizedBox(height: 16),
              Text('Collection point',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              pointsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const Text('Points unavailable'),
                data: (points) {
                  return DropdownButtonFormField<String>(
                    initialValue: _pointId,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Not specified'),
                      ),
                      ...points.map(
                        (p) => DropdownMenuItem(
                          value: p.id,
                          child: Text(p.name),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _pointId = v),
                  );
                },
              ),
              const SizedBox(height: 16),
              Text('Note', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextField(
                controller: _noteCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Optional details for volunteer',
                ),
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
                    : const Text('Submit claim'),
              ),
            ],
          );
        },
      ),
    );
  }
}