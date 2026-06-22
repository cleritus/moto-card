import 'package:flutter/material.dart';
import '../../config/theme.dart';

class InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const InfoCard({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        border: Border.all(color: AppColors.darkBorder),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.darkPrimary, size: 20),
                const SizedBox(width: 8),
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkOnBackground,
                  ),
                ),
              ],
            ),
            const Divider(color: AppColors.darkBorder, height: 24),
            ...children,
          ],
        ),
      ),
    );
  }
}
