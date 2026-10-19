import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_ru.dart';
import '../../../core/theme/app_colors.dart';
import 'scan_screen.dart';

class ModerateClaimsScreen extends ConsumerStatefulWidget {
  const ModerateClaimsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<ModerateClaimsScreen> createState() =>
      _ModerateClaimsScreenState();
}

class _ModerateClaimsScreenState extends ConsumerState<ModerateClaimsScreen> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = ref.read(volunteerRepositoryProvider).fetchPendingClaims();
  }

  Future<void> _act(String id, bool approve) async {
    final noteCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(approve ? 'Подтвердить' : 'Отклонить'),
        content: TextField(
          controller: noteCtrl,
          decoration: const InputDecoration(labelText: 'Комментарий'),
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
    if (ok != true) return;
    await ref.read(volunteerRepositoryProvider).moderate(
          submissionId: id,
          approve: approve,
          note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
        );
    setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(
              title: const Text(AppRu.moderateClaims),
              actions: [
                IconButton(
                  onPressed: () => setState(_reload),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
      floatingActionButton: widget.embedded
          ? FloatingActionButton.small(
              onPressed: () => setState(_reload),
              child: const Icon(Icons.refresh),
            )
          : null,
      body: FutureBuilder(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('${snap.error}'));
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('Нет заявок на модерации'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final s = items[i];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${s.categoryName ?? s.fraction} · ${s.weightKg} кг',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      if (s.note != null) Text(s.note!),
                      if (s.photoUrl != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Image.network(s.photoUrl!, height: 140),
                        ),
                      Row(
                        children: [
                          FilledButton(
                            onPressed: () => _act(s.id, true),
                            child: const Text('OK'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () => _act(s.id, false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.danger,
                            ),
                            child: const Text('Reject'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
