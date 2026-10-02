import 'package:flutter/material.dart';

import '../../config/theme.dart';

/// Binder perforation down the left edge of an entry — §8.
///
/// 22 px of [AppColors.grease] with punched holes. One element, and the list
/// stops being a list and starts being a book.
class BindingStrip extends StatelessWidget {
  const BindingStrip({
    super.key,
    this.width = 22,
    this.holes = 3,
    this.background = AppColors.grease,
    this.holeColor = AppColors.oilBlack,
    this.holeBorder = const Color(0xFF4A463C),
    this.edge = AppColors.hairline,
  });

  /// Paper-sheet variant: darker paper tone with paper-coloured holes (§8).
  const BindingStrip.paper({
    super.key,
    this.width = 22,
    this.holes = 4,
    this.background = AppColors.paperBinding,
    this.holeColor = AppColors.agedPaper,
    this.holeBorder = const Color(0xFF8E8064),
    this.edge = const Color(0xFFA8997A),
  });

  final double width;
  final int holes;
  final Color background;
  final Color holeColor;
  final Color holeBorder;
  final Color edge;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: background,
        border: Border(right: BorderSide(color: edge, width: 1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < holes; i++)
            Container(
              margin: EdgeInsets.only(top: i == 0 ? 0 : 18),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: holeColor,
                shape: BoxShape.circle,
                border: Border.all(color: holeBorder, width: 1),
              ),
            ),
        ],
      ),
    );
  }
}

/// The 24 px spine on a garage card, carrying a rotated mono bay number
/// (§5, "karta warsztatowa").
class SpineStrip extends StatelessWidget {
  const SpineStrip({super.key, required this.text, this.width = 24});

  final String text;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: const BoxDecoration(
        color: AppColors.grease,
        border: Border(right: BorderSide(color: AppColors.hairline, width: 1)),
      ),
      child: Center(
        child: RotatedBox(
          quarterTurns: 3,
          child: Text(
            text.toUpperCase(),
            maxLines: 1,
            softWrap: false,
            style: AppText.micro(size: 9.5, color: const Color(0xFF6E6859))
                .copyWith(letterSpacing: 9.5 * 0.2),
          ),
        ),
      ),
    );
  }
}
