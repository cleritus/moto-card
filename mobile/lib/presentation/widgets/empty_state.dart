import 'package:flutter/material.dart';

import '../../config/theme.dart';
import 'double_rule.dart';

/// Empty state in workshop voice (§10) — a note on the wall, not a system
/// message. Condensed headline, prose sub-line in Barlow, optional technical
/// marking. No oversized greyed-out Material icon.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.tag,
  });

  /// Condensed caps, max ~4 words.
  final String title;

  /// Prose, mixed case, never uppercase (§3).
  final String subtitle;

  /// Mono marking above the headline, e.g. `REJESTR PUSTY`.
  final String? tag;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppGeo.screenMargin + 12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (tag != null) ...[
              Text(tag!.toUpperCase(), style: AppText.micro()),
              const SizedBox(height: 10),
            ],
            const DoubleRule(),
            const SizedBox(height: 16),
            Text(title.toUpperCase(), style: AppText.h1(size: 28)),
            const SizedBox(height: 10),
            Text(subtitle, style: AppText.body(color: AppColors.fadedInk)),
          ],
        ),
      ),
    );
  }
}
