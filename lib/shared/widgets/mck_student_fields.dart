import 'package:flutter/material.dart';

import '../../core/campus/mck_ktits.dart';
import '../../core/l10n/app_ru.dart';

/// Выпадающие списки курса и специальности МЦК-КТИТС (+ группа текстом).
class MckStudentFields extends StatelessWidget {
  const MckStudentFields({
    super.key,
    required this.course,
    required this.specialty,
    required this.groupController,
    required this.onCourseChanged,
    required this.onSpecialtyChanged,
    this.requireAll = true,
  });

  final int? course;
  final MckSpecialty? specialty;
  final TextEditingController groupController;
  final ValueChanged<int?> onCourseChanged;
  final ValueChanged<MckSpecialty?> onSpecialtyChanged;
  final bool requireAll;

  @override
  Widget build(BuildContext context) {
    final department = (course != null && specialty != null)
        ? MckKtits.departmentFor(course: course!, specialty: specialty!)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<int>(
          key: ValueKey('course-$course'),
          initialValue: course,
          decoration: const InputDecoration(labelText: AppRu.course),
          items: [
            for (final c in MckKtits.courses)
              DropdownMenuItem(value: c, child: Text('$c курс')),
          ],
          onChanged: onCourseChanged,
          validator: requireAll
              ? (v) => v == null ? AppRu.requiredField : null
              : null,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<MckSpecialty>(
          key: ValueKey('spec-${specialty?.shortLabel}'),
          initialValue: specialty,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: AppRu.specialtyName,
            helperText: AppRu.specialtyHelper,
          ),
          items: [
            for (final s in MckKtits.specialties)
              DropdownMenuItem(
                value: s,
                child: Text(
                  s.shortLabel,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
          ],
          selectedItemBuilder: (context) => [
            for (final s in MckKtits.specialties)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  s.shortLabel,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
          ],
          onChanged: onSpecialtyChanged,
          validator: requireAll
              ? (v) => v == null ? AppRu.requiredField : null
              : null,
        ),
        if (department != null) ...[
          const SizedBox(height: 6),
          Text(
            '${AppRu.departmentName}: $department',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
          ),
        ],
        const SizedBox(height: 8),
        TextFormField(
          controller: groupController,
          decoration: const InputDecoration(
            labelText: AppRu.groupName,
            hintText: AppRu.groupHint,
          ),
          validator: requireAll
              ? (v) =>
                  (v == null || v.trim().isEmpty) ? AppRu.requiredField : null
              : null,
        ),
      ],
    );
  }
}
