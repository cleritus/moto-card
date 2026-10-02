import 'package:flutter/material.dart';

import '../../config/theme.dart';

/// Name-plate row set — §5 "tabliczka znamionowa".
///
/// Mono uppercase key on the left, mono value on the right, a dotted leader
/// filling the gap, hairline under each row. Lines are layout here, not
/// noise (§4).
class DataPlate extends StatelessWidget {
  const DataPlate({
    super.key,
    required this.rows,
    this.onPaper = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 14),
  });

  final List<DataPlateRow> rows;

  /// Paper variant used inside `PaperSheet`: dark ink on aged paper.
  final bool onPaper;

  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < rows.length; i++)
            _PlateRowView(
              row: rows[i],
              onPaper: onPaper,
              last: i == rows.length - 1,
            ),
        ],
      ),
    );
  }
}

@immutable
class DataPlateRow {
  const DataPlateRow(this.label, this.value, {this.emphasis = false});

  final String label;
  final String value;

  /// Bigger, heavier value — used for the cost line on a service sheet.
  final bool emphasis;
}

class _PlateRowView extends StatelessWidget {
  const _PlateRowView({
    required this.row,
    required this.onPaper,
    required this.last,
  });

  final DataPlateRow row;
  final bool onPaper;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final keyColor =
        onPaper ? AppColors.paperInkFaded : AppColors.fadedInk;
    final valueColor =
        onPaper ? const Color(0xFF231F17) : AppColors.bone;
    final dotColor = onPaper ? AppColors.paperHairline : AppColors.leaderDot;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(
                bottom: BorderSide(
                  color: onPaper ? AppColors.paperHairline : AppColors.hairline,
                  width: 1,
                ),
              ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Text(
              row.label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.label(size: 9.5, color: keyColor),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: CustomPaint(
                size: const Size(double.infinity, 1),
                painter: _DottedLeaderPainter(dotColor),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 3,
            child: Text(
              row.value,
              maxLines: 2,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: AppText.data(
                size: row.emphasis ? 15 : 12.5,
                weight: row.emphasis ? FontWeight.w600 : FontWeight.w500,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DottedLeaderPainter extends CustomPainter {
  const _DottedLeaderPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 4) {
      canvas.drawLine(Offset(x, 0), Offset(x + 1, 0), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DottedLeaderPainter oldDelegate) =>
      oldDelegate.color != color;
}
