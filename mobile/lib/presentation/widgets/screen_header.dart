import 'package:flutter/material.dart';

import '../../config/theme.dart';
import 'double_rule.dart';

/// In-body screen header used by the tab screens (§6).
///
/// A micro breadcrumb row of technical markings, the H1 in condensed caps, a
/// mono sub-line, an optional action on the right, closed with the double
/// rule. The markings (`Nº 0148`, `FORM 02-A`, `WARSZTAT / PL`) do nothing
/// functionally and change how the whole thing reads (§10).
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.tagLeft,
    this.tagRight,
    this.onTagRightTap,
    this.subtitle,
    this.action,
    this.titleSize = 32,
  });

  final String title;
  final String? tagLeft;
  final String? tagRight;

  /// Makes [tagRight] tappable — used for marginal actions like signing out,
  /// which do not deserve a button.
  final VoidCallback? onTagRightTap;

  final String? subtitle;
  final Widget? action;
  final double titleSize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppGeo.screenMargin,
        10,
        AppGeo.screenMargin,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (tagLeft != null || tagRight != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    (tagLeft ?? '').toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.micro(),
                  ),
                ),
                if (tagRight != null)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onTagRightTap,
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: 12,
                        top: onTagRightTap != null ? 6 : 0,
                        bottom: onTagRightTap != null ? 6 : 0,
                      ),
                      child: Text(
                        tagRight!.toUpperCase(),
                        style: AppText.micro(
                          color: onTagRightTap != null
                              ? AppColors.oxideLit
                              : AppColors.fadedInk,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: AppText.h1(size: titleSize),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 7),
                      Text(subtitle!.toUpperCase(), style: AppText.micro()),
                    ],
                  ],
                ),
              ),
              if (action != null) ...[
                const SizedBox(width: 12),
                action!,
              ],
            ],
          ),
          const DoubleRule(margin: EdgeInsets.only(top: 14)),
        ],
      ),
    );
  }
}
