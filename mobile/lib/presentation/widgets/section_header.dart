import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// An uppercase red section title with a decorative line filling the row.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
        child: Row(
          children: [
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                letterSpacing: 2.5,
                fontWeight: FontWeight.bold,
                color: AppColors.darkPrimary,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Divider(color: AppColors.darkBorder, thickness: 1),
            ),
          ],
        ),
      );
}
