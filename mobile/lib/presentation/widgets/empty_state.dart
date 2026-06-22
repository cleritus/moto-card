import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// Styled empty-state placeholder: greyed icon, uppercase title and subtitle.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: AppColors.darkBorder),
            const SizedBox(height: 16),
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 16,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
                color: AppColors.darkLabel,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.darkOnSurface.withAlpha(153),
              ),
            ),
          ],
        ),
      );
}
