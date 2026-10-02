import 'package:flutter/material.dart';

import '../../config/theme.dart';
import 'double_rule.dart';

/// Section heading — condensed caps on the left, an optional mono marking on
/// the right, closed by the §4 double rule.
class SectionHeader extends StatelessWidget {
  const SectionHeader(
    this.title, {
    super.key,
    this.tag,
    this.padded = true,
    this.topGap = 26,
    this.bottomGap = 16,
  });

  final String title;

  /// Mono note on the right, e.g. `4 POZYCJE` or `TABLICZKA`.
  final String? tag;

  /// When false, drops the horizontal padding (inside already-padded forms).
  final bool padded;

  final double topGap;
  final double bottomGap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        padded ? AppGeo.screenMargin : 0,
        topGap,
        padded ? AppGeo.screenMargin : 0,
        bottomGap,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: Text(title.toUpperCase(), style: AppText.h2())),
              if (tag != null) ...[
                const SizedBox(width: 12),
                Text(tag!.toUpperCase(), style: AppText.micro()),
              ],
            ],
          ),
          const DoubleRule(margin: EdgeInsets.only(top: 10)),
        ],
      ),
    );
  }
}
