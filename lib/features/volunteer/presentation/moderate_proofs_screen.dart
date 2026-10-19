import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_ru.dart';
import 'scan_screen.dart';

class ModerateProofsScreen extends ConsumerStatefulWidget {
  const ModerateProofsScreen({super.key});

  @override
  ConsumerState<ModerateProofsScreen> createState() =>
      _ModerateProofsScreenState();
}

class _ModerateProofsScreenState extends ConsumerState<ModerateProofsScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = ref.read(volunteerRepositoryProvider).fetchPendingProofs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Пруфы челленджей'),
        actions: [
          IconButton(
            onPressed: () => setState(_reload),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data!;
          if (items.isEmpty) {
            return const Center(child: Text('Нет пруфов'));
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, i) {
              final p = items[i];
              final challenge = p['challenges'];
              final title = challenge is Map ? challenge['title'] : 'Челлендж';
              return Card(
                margin: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    ListTile(
                      title: Text('$title'),
                      subtitle: Text(p['comment'] as String? ?? ''),
                    ),
                    if (p['photo_url'] != null)
                      Image.network(p['photo_url'] as String, height: 160),
                    OverflowBar(
                      children: [
                        TextButton(
                          onPressed: () async {
                            await ref
                                .read(volunteerRepositoryProvider)
                                .moderateProof(
                                  proofId: p['id'] as String,
                                  approve: true,
                                );
                            setState(_reload);
                          },
                          child: const Text(AppRu.confirm),
                        ),
                        TextButton(
                          onPressed: () async {
                            await ref
                                .read(volunteerRepositoryProvider)
                                .moderateProof(
                                  proofId: p['id'] as String,
                                  approve: false,
                                  note: 'rejected',
                                );
                            setState(_reload);
                          },
                          child: const Text(AppRu.cancel),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
