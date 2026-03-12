import 'package:flutter/material.dart';

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
    if (wrap) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          value,
          style: TextStyle(
            color: isOverdue ? Theme.of(context).colorScheme.error : null,
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isOverdue ? Theme.of(context).colorScheme.error : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}