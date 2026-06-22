import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// An uppercase red section title with a decorative line filling the row.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.padded = true});

  final String title;

  /// When false, drops the horizontal padding (use inside already-padded forms).
  final bool padded;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(padded ? 16 : 0, 20, padded ? 16 : 0, 12),
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
