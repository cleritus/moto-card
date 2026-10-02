import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../utils/interval_status.dart';

/// The hero dial — §5 and §7.3 B.
///
/// 270° ring, bezel with 12 notches, percentage in mono at the centre with
/// the interval name underneath. Shows the *worst* interval of the vehicle:
/// the two-metre glance ("is it bad?"), while `IntervalBar` is the 30 cm
/// read ("what exactly, and by how much").
///
/// Past 100% the ring closes as a full dark-rust sweep and the excess burns
/// on top in oxideLit — the needle visibly went round twice.
class IntervalGauge extends StatelessWidget {
  const IntervalGauge({
    super.key,
    required this.status,
    this.size = 112,
    this.label,
  });

  final IntervalStatus status;
  final double size;

  /// Short caption under the percentage. Defaults to the first word of the
  /// interval title — condensed uppercase only reads well up to ~4 words.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final caption =
        (label ?? status.title.split(RegExp(r'\s+')).first).toUpperCase();

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _GaugePainter(status),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: size * 0.18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${status.percentLabel}%',
                  maxLines: 1,
                  style: AppText.data(
                    size: size * 0.19,
                    weight: FontWeight.w600,
                    color: status.textColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppText.stamp(
                    size: size * 0.098,
                    color: AppColors.fadedInk,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  const _GaugePainter(this.status);

  final IntervalStatus status;

  /// 135° — bottom-left. Sweeping 270° clockwise leaves the 90° gap at the
  /// bottom, like an instrument dial.
  static const double _start = 3 * math.pi / 4;
  static const double _sweep = 3 * math.pi / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final stroke = size.width * 0.08;
    final radius = size.width / 2 - stroke / 2 - size.width * 0.095;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Bezel: 12 notches, every 30°.
    final notch = Paint()
      ..color = const Color(0xFF5C5850)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.butt;
    final outer = size.width / 2 - 1.5;
    final inner = outer - size.width * 0.055;
    for (int i = 0; i < 12; i++) {
      final a = i * math.pi / 6 - math.pi / 2;
      canvas.drawLine(
        center + Offset(math.cos(a) * inner, math.sin(a) * inner),
        center + Offset(math.cos(a) * outer, math.sin(a) * outer),
        notch,
      );
    }

    Paint arc(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    // Track.
    canvas.drawArc(rect, _start, _sweep, false, arc(AppColors.grease));

    if (status.percent >= 1.0) {
      // Full lap in rust, then the excess lit on top.
      canvas.drawArc(rect, _start, _sweep, false, arc(AppColors.rustRed));
      final excess = (status.percent - 1.0).clamp(0.0, 1.0);
      if (excess > 0) {
        canvas.drawArc(
          rect,
          _start,
          _sweep * excess,
          false,
          arc(AppColors.oxideLit),
        );
      }
    } else if (status.percent > 0) {
      canvas.drawArc(
        rect,
        _start,
        _sweep * status.percent,
        false,
        arc(status.fillColor),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.status.percent != status.percent;
}
