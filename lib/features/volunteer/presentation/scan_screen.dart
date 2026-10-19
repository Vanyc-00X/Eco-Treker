import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/l10n/app_ru.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/points_calculator.dart';
import '../../auth/models/profile.dart';
import '../../recycle/models/waste_category.dart';
import '../../recycle/providers/recycle_providers.dart';
import '../data/volunteer_repository.dart';

final volunteerRepositoryProvider = Provider((_) => VolunteerRepository());

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key, this.embedded = false});

  /// Без AppBar — когда экран внутри вкладки «Работа».
  final bool embedded;

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  final _manual = TextEditingController();
  Profile? _student;
  WasteCategory? _category;
  final _weight = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _receipt;

  @override
  void dispose() {
    _manual.dispose();
    _weight.dispose();
    super.dispose();
  }

  Future<void> _resolve(String payload) async {
    setState(() {
      _loading = true;
      _error = null;
      _student = null;
      _receipt = null;
    });
    try {
      final profile =
          await ref.read(volunteerRepositoryProvider).lookupByQrPayload(payload);
      setState(() => _student = profile);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirm() async {
    final student = _student;
    final cat = _category;
    final w = double.tryParse(_weight.text.replaceAll(',', '.'));
    if (student == null || cat == null || w == null || w <= 0) return;

    final mult = PointsCalculator.computeMultiplier(
      when: DateTime.now(),
      inActiveChallenge: false,
      isFirstDrop: student.totalKg <= 0,
    );
    final preview = PointsCalculator.calculate(
      weightKg: w,
      pointsPerKg: cat.pointsPerKg,
      co2PerKg: cat.co2PerKg,
      multiplier: mult,
    );

    setState(() => _loading = true);
    try {
      final sub = await ref.read(volunteerRepositoryProvider).confirmDropoff(
            studentId: student.id,
            categoryId: cat.id,
            weightKg: w,
            bonusMultiplier: mult,
          );
      final text =
          'Квитанция Eco-Tracker\n${student.fullName}\n${cat.nameRu}: ${w} кг\n'
          'Баллы: ${sub.pointsAwarded > 0 ? sub.pointsAwarded : preview.points}\n'
          'CO₂: ${sub.co2SavedKg > 0 ? sub.co2SavedKg : preview.co2Kg} кг\n'
          'Множитель: ×$mult';
      setState(() {
        _receipt = text;
        _weight.clear();
      });
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(wasteCategoriesProvider);

    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(title: const Text(AppRu.scanQr)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!kIsWeb)
            SizedBox(
              height: 220,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: MobileScanner(
                  onDetect: (capture) {
                    final raw = capture.barcodes.firstOrNull?.rawValue;
                    if (raw != null && _student == null && !_loading) {
                      _resolve(raw);
                    }
                  },
                ),
              ),
            )
          else
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('На Web используйте ручной ввод Eco-ID / токена.'),
              ),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _manual,
            decoration: const InputDecoration(
              labelText: 'Ручной ввод eco:token или token',
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _loading ? null : () => _resolve(_manual.text),
            child: const Text('Найти студента'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppColors.danger)),
          ],
          if (_student != null) ...[
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                title: Text(_student!.fullName),
                subtitle: Text(
                  '${_student!.email}\n${_student!.greenPoints} б. · ${_student!.totalKg} кг',
                ),
                isThreeLine: true,
              ),
            ),
            categories.when(
              data: (cats) => DropdownButtonFormField<WasteCategory>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: AppRu.category),
                items: cats
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text('${c.nameRu} (${c.pointsPerKg}/кг)'),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _category = v),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('$e'),
            ),
            TextField(
              controller: _weight,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: AppRu.weightKg),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loading ? null : _confirm,
              child: const Text(AppRu.confirmDropoff),
            ),
          ],
          if (_receipt != null) ...[
            const SizedBox(height: 16),
            Card(
              color: AppColors.accentDeep.withValues(alpha: 0.08),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      AppRu.receipt,
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(_receipt!),
                    TextButton.icon(
                      onPressed: () => SharePlus.instance.share(
                        ShareParams(text: _receipt!),
                      ),
                      icon: const Icon(Icons.share),
                      label: const Text(AppRu.share),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
