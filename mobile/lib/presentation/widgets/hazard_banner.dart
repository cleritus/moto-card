import 'package:flutter/material.dart';

import '../../config/theme.dart';

/// Diagonal hazard stripes, 45°, dirtyYellow over oilBlack (§5).
///
/// Used only for the overdue state, at most one per screen (§7.3). The copy
/// sits on a solid dirtyYellow plaque inside the striped frame so the text
/// always lands on 7.28:1 and never on a dark stripe.
class HazardBanner extends StatelessWidget {
  const HazardBanner({
    super.key,
    required this.text,
    this.margin = const EdgeInsets.fromLTRB(
      AppGeo.screenMargin,
      18,
      AppGeo.screenMargin,
      0,
    ),
  });

  final String text;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.dirtyYellow, width: 1.5),
      ),
      child: CustomPaint(
        painter: const _HazardStripePainter(),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Container(
            width: double.infinity,
            color: AppColors.dirtyYellow,
            padding: const EdgeInsets.fromLTRB(8, 9, 8, 7),
            child: Text(
              text.toUpperCase(),
              textAlign: TextAlign.center,
              style: AppText.button(size: 16, color: AppColors.grease)
                  .copyWith(letterSpacing: 16 * 0.06),
            ),
          ),
        ),
      ),
    );
  }
}

/// `repeating-linear-gradient(45deg, #C9A33B 0 11px, #1B1A17 11px 22px)`.
class _HazardStripePainter extends CustomPainter {
  const _HazardStripePainter();

  static const double _stripe = 11;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.oilBlack,
    );

    final paint = Paint()
      ..color = AppColors.dirtyYellow
      ..style = PaintingStyle.stroke
      // A 45° band of width 11 needs a stroke of 11 * sqrt(2) when stepped
      // along the x axis by 2 * 11 * sqrt(2).
      ..strokeWidth = _stripe * 1.41421356;

    final step = _stripe * 2 * 1.41421356;
    final span = size.width + size.height;
    for (double x = -span; x < span; x += step) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HazardStripePainter oldDelegate) => false;
}
