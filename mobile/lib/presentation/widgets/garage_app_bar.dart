import 'package:flutter/material.dart';

import '../../config/theme.dart';
import 'double_rule.dart';

/// App bar for pushed screens: flat oilBlack, condensed caps title, optional
/// mono counter on the right of the title, closed with the §4 double rule.
/// No red bar, no elevation, no tint.
class GarageAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GarageAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
  });

  final String title;

  /// Mono marking under the title, e.g. `WPIS Nº 0148`.
  final String? subtitle;

  final List<Widget>? actions;

  static const double _ruleHeight = DoubleRule.height;

  double get _toolbarHeight => subtitle == null ? 56 : 68;

  @override
  Size get preferredSize => Size.fromHeight(_toolbarHeight + _ruleHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: _toolbarHeight,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title.toUpperCase(), style: AppText.h2(size: 19)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!.toUpperCase(), style: AppText.micro()),
          ],
        ],
      ),
      actions: actions,
      bottom: const _RuleBottom(),
    );
  }
}

class _RuleBottom extends StatelessWidget implements PreferredSizeWidget {
  const _RuleBottom();

  @override
  Size get preferredSize => const Size.fromHeight(DoubleRule.height);

  @override
  Widget build(BuildContext context) => const DoubleRule();
}
