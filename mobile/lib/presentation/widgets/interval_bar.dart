import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../utils/format.dart';
import '../utils/interval_status.dart';
import 'stamp_badge.dart';

/// Per-alert interval bar — §7.3 A.
///
/// Three independent carriers of the same state: bar length, fill colour and
/// a worded stamp, plus the percentage in mono. Colour is never the only
/// signal (§12.3).
///
/// The track is notched every 10% so the fill reads as ten hard blocks — a
/// fuel gauge on an old dash, not a SaaS progress bar. No gradients, no
/// rounded ends. Overdue fills with rust under dirtyYellow hazard stripes
/// and a bone edge, because rust on the track is only 2.79:1 (§2.2).
class IntervalBar extends StatelessWidget {
  const IntervalBar({super.key, required this.status, this.showStamp = true});

  final IntervalStatus status;
  final bool showStamp;

  @override
  Widget build(BuildContext context) {
    final used = Fmt.km(status.used);
    final total = Fmt.km(status.intervalKm);
    final footer = status.isOverdue
        ? '$used / $total KM · ${Fmt.km(status.overdueBy)} KM PO TERMINIE'
        : '$used / $total KM';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                status.title.toUpperCase(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.condensed(
                  size: 16,
                  weight: FontWeight.w700,
                  color: AppColors.agedPaper,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${status.percentLabel}%',
              style: AppText.data(
                size: 13,
                weight: FontWeight.w600,
                color: status.textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        SizedBox(
          height: 9,
          child: CustomPaint(
            size: const Size(double.infinity, 9),
            painter: _IntervalTrackPainter(status),
          ),
        ),
        const SizedBox(height: 7),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                footer,
                style: AppText.data(size: 10.5, color: AppColors.fadedInk),
              ),
            ),
            if (showStamp) ...[
              const SizedBox(width: 10),
              StampBadge(
                label: status.stampLabel,
                variant: status.stampVariant,
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _IntervalTrackPainter extends CustomPainter {
  const _IntervalTrackPainter(this.status);

  final IntervalStatus status;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final borderColor = status.isOverdue ? AppColors.bone : AppColors.steel;

    canvas.save();
    canvas.clipRect(rect);

    // Track.
    canvas.drawRect(rect, Paint()..color = AppColors.grease);

    final inner = Rect.fromLTWH(1, 1, size.width - 2, size.height - 2);
    final fillWidth = inner.width * status.percent.clamp(0.0, 1.0);
    final fillRect = Rect.fromLTWH(inner.left, inner.top, fillWidth, inner.height);

    if (status.isOverdue) {
      // Rust base + 45° dirtyYellow hazard stripes.
      canvas.drawRect(inner, Paint()..color = AppColors.rustRed);
      canvas.save();
      canvas.clipRect(inner);
      final stripe = Paint()
        ..color = AppColors.dirtyYellow
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * 1.41421356;
      final step = 9 * 1.41421356;
      for (double x = -size.height; x < size.width + size.height; x += step) {
        canvas.drawLine(
          Offset(x, inner.bottom),
          Offset(x + inner.height, inner.top),
          stripe,
        );
      }
      canvas.restore();
    } else if (fillWidth > 0) {
      canvas.drawRect(fillRect, Paint()..color = status.fillColor);
    }

    // Notches every 10% — the fill reads as ten hard blocks.
    final notch = Paint()
      ..color = AppColors.oilBlack
      ..strokeWidth = 2;
    for (int i = 1; i < 10; i++) {
      final x = inner.left + inner.width * i / 10;
      canvas.drawLine(Offset(x, inner.top), Offset(x, inner.bottom), notch);
    }

    canvas.restore();

    canvas.drawRect(
      rect.deflate(0.5),
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _IntervalTrackPainter oldDelegate) =>
      oldDelegate.status.percent != status.percent;
}
