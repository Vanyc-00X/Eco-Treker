import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/l10n/app_ru.dart';
import '../data/admin_repository.dart';

final adminRepositoryProvider = Provider((_) => AdminRepository());

class AdminShell extends StatelessWidget {
  const AdminShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppRu.adminHub),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: const AdminPanelBody(),
    );
  }
}

/// Контент админ-панели (вкладки) — для `/admin` и вкладки «Работа».
class AdminPanelBody extends ConsumerStatefulWidget {
  const AdminPanelBody({super.key});

  @override
  ConsumerState<AdminPanelBody> createState() => _AdminPanelBodyState();
}

class _AdminPanelBodyState extends ConsumerState<AdminPanelBody> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: IndexedStack(
            index: _tab,
            children: const [
              _AnalyticsTab(),
              _UsersTab(),
              _ChallengesTab(),
              _PointsTab(),
              _OpsTab(),
            ],
          ),
        ),
        NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.analytics_outlined),
              label: 'Аналитика',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              label: 'Юзеры',
            ),
            NavigationDestination(
              icon: Icon(Icons.emoji_events_outlined),
              label: 'Челленджи',
            ),
            NavigationDestination(
              icon: Icon(Icons.place_outlined),
              label: 'Пункты',
            ),
            NavigationDestination(
              icon: Icon(Icons.inbox_outlined),
              label: 'Очередь',
            ),
          ],
        ),
      ],
    );
  }
}

class _AnalyticsTab extends ConsumerWidget {
  const _AnalyticsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: ref.read(adminRepositoryProvider).fetchAnalytics(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final a = snap.data!;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _metric('Студенты', '${a['students']}'),
            _metric('Баллы', '${a['points']}'),
            _metric('Сдано кг', '${a['kg']}'),
            _metric('CO₂ кг', '${a['co2']}'),
            _metric('Заявки pending', '${a['pending']}'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                final csv =
                    ref.read(adminRepositoryProvider).analyticsToCsv(a);
                SharePlus.instance.share(ShareParams(text: csv));
              },
              icon: const Icon(Icons.download),
              label: const Text(AppRu.exportCsv),
            ),
          ],
        );
      },
    );
  }

  Widget _metric(String title, String value) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
    );
  }
}

class _UsersTab extends ConsumerStatefulWidget {
  const _UsersTab();

  @override
  ConsumerState<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends ConsumerState<_UsersTab> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(adminRepositoryProvider).fetchUsers();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final users = snap.data!;
        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, i) {
            final u = users[i];
            return ListTile(
              title: Text('${u['full_name']}'),
              subtitle: Text('${u['email']} · ${u['role']}'),
              trailing: PopupMenuButton<String>(
                onSelected: (role) async {
                  await ref
                      .read(adminRepositoryProvider)
                      .setUserRole(u['id'] as String, role);
                  setState(() {
                    _future = ref.read(adminRepositoryProvider).fetchUsers();
                  });
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'student', child: Text('student')),
                  PopupMenuItem(value: 'volunteer', child: Text('volunteer')),
                  PopupMenuItem(value: 'admin', child: Text('admin')),
                ],
              ),
              onLongPress: () async {
                await ref.read(adminRepositoryProvider).setVerified(
                      u['id'] as String,
                      !(u['verified'] as bool? ?? false),
                    );
                setState(() {
                  _future = ref.read(adminRepositoryProvider).fetchUsers();
                });
              },
            );
          },
        );
      },
    );
  }
}

class _ChallengesTab extends ConsumerStatefulWidget {
  const _ChallengesTab();

  @override
  ConsumerState<_ChallengesTab> createState() => _ChallengesTabState();
}

class _ChallengesTabState extends ConsumerState<_ChallengesTab> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = ref.read(adminRepositoryProvider).fetchChallengesRaw();
  }

  Future<void> _edit([Map<String, dynamic>? existing]) async {
    final title = TextEditingController(text: existing?['title'] as String?);
    final desc =
        TextEditingController(text: existing?['description'] as String?);
    final type = ValueNotifier(existing?['challenge_type'] as String? ?? 'individual');
    final points = TextEditingController(
      text: '${existing?['reward_points'] ?? 50}',
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Новый челлендж' : 'Редактировать'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: title, decoration: const InputDecoration(labelText: 'Название')),
              TextField(controller: desc, decoration: const InputDecoration(labelText: 'Описание')),
              TextField(controller: points, decoration: const InputDecoration(labelText: 'Баллы')),
              DropdownButtonFormField<String>(
                initialValue: type.value,
                items: const [
                  DropdownMenuItem(value: 'individual', child: Text('individual')),
                  DropdownMenuItem(value: 'team', child: Text('team')),
                  DropdownMenuItem(value: 'daily', child: Text('daily')),
                  DropdownMenuItem(value: 'weekly', child: Text('weekly')),
                  DropdownMenuItem(value: 'seasonal', child: Text('seasonal')),
                  DropdownMenuItem(value: 'special', child: Text('special')),
                ],
                onChanged: (v) => type.value = v ?? 'individual',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text(AppRu.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text(AppRu.save)),
        ],
      ),
    );
    if (ok != true) return;
    final data = <String, dynamic>{
      if (existing?['id'] != null) 'id': existing!['id'],
      'title': title.text.trim(),
      'description': desc.text.trim(),
      'challenge_type': type.value,
      'reward_points': int.tryParse(points.text) ?? 50,
      'is_published': true,
      'starts_at': existing?['starts_at'] ??
          DateTime.now().toUtc().toIso8601String(),
      'ends_at': existing?['ends_at'] ??
          DateTime.now().add(const Duration(days: 14)).toUtc().toIso8601String(),
    };
    await ref.read(adminRepositoryProvider).saveChallenge(data);
    setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _edit(),
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data!;
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, i) {
              final c = items[i];
              return ListTile(
                title: Text('${c['title']}'),
                subtitle: Text('${c['challenge_type']} · ${c['reward_points']} б.'),
                onTap: () => _edit(Map<String, dynamic>.from(c)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    await ref
                        .read(adminRepositoryProvider)
                        .deleteChallenge(c['id'] as String);
                    setState(_reload);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _PointsTab extends ConsumerStatefulWidget {
  const _PointsTab();

  @override
  ConsumerState<_PointsTab> createState() => _PointsTabState();
}

class _PointsTabState extends ConsumerState<_PointsTab> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = ref.read(adminRepositoryProvider).fetchPoints();
  }

  Future<void> _edit([Map<String, dynamic>? existing]) async {
    final name = TextEditingController(text: existing?['name'] as String?);
    final address =
        TextEditingController(text: existing?['address'] as String?);
    final lat = TextEditingController(text: '${existing?['latitude'] ?? 55.75}');
    final lng = TextEditingController(text: '${existing?['longitude'] ?? 37.62}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Новый пункт' : 'Пункт'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Название')),
            TextField(controller: address, decoration: const InputDecoration(labelText: 'Адрес')),
            TextField(controller: lat, decoration: const InputDecoration(labelText: 'Lat')),
            TextField(controller: lng, decoration: const InputDecoration(labelText: 'Lng')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text(AppRu.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text(AppRu.save)),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(adminRepositoryProvider).savePoint({
      if (existing?['id'] != null) 'id': existing!['id'],
      'name': name.text.trim(),
      'address': address.text.trim(),
      'latitude': double.tryParse(lat.text) ?? 55.75,
      'longitude': double.tryParse(lng.text) ?? 37.62,
      'is_active': true,
      'accepted_fractions': existing?['accepted_fractions'] ??
          ['plastic', 'paper', 'glass', 'metal', 'hazardous'],
      'work_hours': existing?['work_hours'] ?? '09:00–18:00',
    });
    setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _edit(),
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data!;
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, i) {
              final p = items[i];
              return ListTile(
                title: Text('${p['name']}'),
                subtitle: Text('${p['address'] ?? ''}'),
                onTap: () => _edit(Map<String, dynamic>.from(p)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    await ref
                        .read(adminRepositoryProvider)
                        .deletePoint(p['id'] as String);
                    setState(_reload);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _OpsTab extends ConsumerWidget {
  const _OpsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(adminRepositoryProvider);
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(tabs: [
            Tab(text: 'Обмены'),
            Tab(text: 'Жалобы'),
          ]),
          Expanded(
            child: TabBarView(
              children: [
                FutureBuilder(
                  future: repo.fetchRedeemRequests(),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return ListView(
                      children: snap.data!
                          .map(
                            (r) => ListTile(
                              title: Text('${r['reward_title']}'),
                              subtitle: Text('${r['status']} · ${r['points_cost']} б.'),
                              trailing: PopupMenuButton<String>(
                                onSelected: (s) =>
                                    repo.setRedeemStatus(r['id'] as String, s),
                                itemBuilder: (_) => const [
                                  PopupMenuItem(value: 'approved', child: Text('approved')),
                                  PopupMenuItem(value: 'fulfilled', child: Text('fulfilled')),
                                  PopupMenuItem(value: 'rejected', child: Text('rejected')),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
                FutureBuilder(
                  future: repo.fetchBinReports(),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return ListView(
                      children: snap.data!.map((r) {
                        final cp = r['collection_points'];
                        final name = cp is Map ? cp['name'] : r['collection_point_id'];
                        return ListTile(
                          title: Text('$name'),
                          subtitle: Text('${r['note'] ?? ''} · ${r['status']}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.check),
                            onPressed: () => repo.setBinReportStatus(
                              r['id'] as String,
                              'resolved',
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
