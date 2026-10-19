import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/l10n/app_ru.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_page.dart';
import '../../auth/providers/auth_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _fullName = TextEditingController();
  final _phone = TextEditingController();
  final _course = TextEditingController();
  final _group = TextEditingController();
  final _faculty = TextEditingController();
  DateTime? _dob;
  bool _loading = false;
  bool _inited = false;

  @override
  void dispose() {
    _fullName.dispose();
    _phone.dispose();
    _course.dispose();
    _group.dispose();
    _faculty.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar(ImageSource source) async {
    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final ext = file.name.split('.').last.toLowerCase();
    try {
      await ref.read(authRepositoryProvider).uploadAvatar(
            bytes,
            ext == 'png' ? 'png' : 'jpeg',
          );
      ref.invalidate(currentProfileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppRu.profileSaved)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppRu.profileSaveFailed}: $e')),
        );
      }
    }
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).updateProfile(
            fullName: _fullName.text.trim(),
            phone: _phone.text.trim(),
            course: int.tryParse(_course.text.trim()),
            groupName: _group.text.trim(),
            facultyName: _faculty.text.trim(),
            dateOfBirth: _dob,
          );
      ref.invalidate(currentProfileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppRu.profileSaved)),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppRu.profileSaveFailed}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);
    return Scaffold(
      appBar: AppBar(title: const Text(AppRu.editProfile)),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text(AppRu.profileNotFound));
          }
          if (!_inited) {
            _fullName.text = profile.fullName;
            _phone.text = profile.phone ?? '';
            _course.text = profile.course?.toString() ?? '';
            _group.text = profile.groupName ?? '';
            _faculty.text = profile.facultyName ?? '';
            _dob = profile.dateOfBirth;
            _inited = true;
          }
          return AppPage(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundImage: profile.avatarUrl != null
                            ? NetworkImage(profile.avatarUrl!)
                            : null,
                        child: profile.avatarUrl == null
                            ? const Icon(Icons.person, size: 40)
                            : null,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton.icon(
                            onPressed: () => _pickAvatar(ImageSource.camera),
                            icon: const Icon(Icons.photo_camera_outlined),
                            label: const Text(AppRu.takePhoto),
                          ),
                          TextButton.icon(
                            onPressed: () => _pickAvatar(ImageSource.gallery),
                            icon: const Icon(Icons.photo_outlined),
                            label: const Text(AppRu.chooseGallery),
                          ),
                        ],
                      ),
                      Text(
                        '${profile.ecoLevelLabel} · ${profile.greenPoints} ${AppRu.pointsShort}',
                        style: const TextStyle(color: AppColors.muted),
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(value: profile.levelProgress),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _fullName,
                  decoration: const InputDecoration(labelText: AppRu.fullName),
                ),
                TextField(
                  controller: _phone,
                  decoration: const InputDecoration(labelText: AppRu.phone),
                ),
                TextField(
                  controller: _group,
                  decoration: const InputDecoration(labelText: AppRu.groupName),
                ),
                TextField(
                  controller: _faculty,
                  decoration:
                      const InputDecoration(labelText: AppRu.facultyName),
                ),
                TextField(
                  controller: _course,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: AppRu.course),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(AppRu.dateOfBirth),
                  subtitle: Text(
                    _dob == null
                        ? AppRu.notSpecified
                        : _dob!.toIso8601String().substring(0, 10),
                  ),
                  trailing: const Icon(Icons.calendar_today_outlined),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime(1980),
                      lastDate: DateTime.now(),
                      initialDate: _dob ?? DateTime(2005),
                    );
                    if (picked != null) setState(() => _dob = picked);
                  },
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _loading ? null : _save,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const Text(AppRu.save),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
