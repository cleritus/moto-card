import 'package:flutter/material.dart';

import '../../config/theme.dart';

/// The double rule from §4: 2 px steel, a 3 px gap, then a 1 px hairline.
///
/// Modern UI deletes lines; this direction adds them — the rule is a layout
/// element, not debris.
class DoubleRule extends StatelessWidget {
  const DoubleRule({super.key, this.margin = EdgeInsets.zero});

  final EdgeInsets margin;

  static const double height = 6;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: const [
          SizedBox(height: 2, child: ColoredBox(color: AppColors.steel)),
          SizedBox(height: 3),
          SizedBox(height: 1, child: ColoredBox(color: AppColors.hairline)),
        ],
      ),
    );
  }
}

/// Year divider in the service book — a thick rule with the year on the left
/// (§8).
class YearDivider extends StatelessWidget {
  const YearDivider({super.key, required this.year});

  final int year;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 22, 0, 14),
      child: Row(
        children: [
          Text(
            'ROK $year',
            style: AppText.data(
              size: 11,
              weight: FontWeight.w600,
              color: AppColors.fadedInk,
            ).copyWith(letterSpacing: 11 * 0.2),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: SizedBox(height: 2, child: ColoredBox(color: AppColors.steel)),
          ),
        ],
      ),
    );
  }
}
