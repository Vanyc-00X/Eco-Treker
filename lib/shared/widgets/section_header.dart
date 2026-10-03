import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.serif = false,
  });

  final String title;
  final String? subtitle;
  final bool serif;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: (serif
                  ? GoogleFonts.libreBaskerville
                  : GoogleFonts.dmSans)(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
            height: 1.15,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: AppColors.muted,
              height: 1.3,
            ),
          ),
        ],
      ],
    );
  }
}