import 'package:flutter/material.dart';
import '../../config/theme.dart';

class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool wrap;
  final bool isOverdue;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.wrap = false,
    this.isOverdue = false,
  });

  @override
  Widget build(BuildContext context) {
    final valueColor =
        isOverdue ? AppColors.darkAccent : AppColors.darkOnBackground;

    if (wrap) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label(),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 14, color: valueColor)),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: _label()),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label() => Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          letterSpacing: 1.5,
          fontWeight: FontWeight.bold,
          color: AppColors.darkLabel,
        ),
      );
}
