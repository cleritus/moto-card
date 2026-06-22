import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// A bold statistic tile used on the vehicle overview screen.
/// Shows an uppercase [label], a large [value] and an optional [unit].
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.compact = false,
  });

  final String label;
  final String value;
  final String? unit;

  /// Smaller variant used in the 3-up row (services / fuel / alerts).
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: compact ? 12 : 16,
        ),
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          border: Border.all(color: AppColors.darkBorder),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
                color: AppColors.darkLabel,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 22 : 28,
                fontWeight: FontWeight.bold,
                color: AppColors.darkOnBackground,
              ),
            ),
            if (unit != null) ...[
              const SizedBox(height: 2),
              Text(
                unit!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.darkLabel,
                ),
              ),
            ],
          ],
        ),
      );
}
