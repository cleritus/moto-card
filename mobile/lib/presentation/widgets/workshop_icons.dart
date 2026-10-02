import 'package:flutter/material.dart';

/// Hand-coded line icons for the bottom navigation.
///
/// §11 flags the Material icon set as the thing that "gives Flutter away and
/// breaks the manual feel", and a bespoke 16-icon SVG set is a P1 graphic-
/// design task that has not happened yet. These five are transcribed from
/// the approved HTML preview's inline SVGs (24×24 viewBox, 1.7 stroke) so
/// the nav bar at least matches the mockup without a single asset file.
enum WorkshopIconKind { vehicle, fuel, wrench, bell, camera }

class WorkshopIcon extends StatelessWidget {
  const WorkshopIcon({
    super.key,
    required this.kind,
    required this.color,
    this.size = 20,
  });

  final WorkshopIconKind kind;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _WorkshopIconPainter(kind, color)),
    );
  }
}

class _WorkshopIconPainter extends CustomPainter {
  const _WorkshopIconPainter(this.kind, this.color);

  final WorkshopIconKind kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24;
    canvas.save();
    canvas.scale(scale);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (kind) {
      case WorkshopIconKind.vehicle:
        canvas.drawCircle(const Offset(5.6, 16.4), 3.4, paint);
        canvas.drawCircle(const Offset(18.4, 16.4), 3.4, paint);
        canvas.drawPath(
          Path()
            ..moveTo(9, 16.4)
            ..lineTo(13.2, 16.4)
            ..lineTo(16.3, 11.2)
            ..lineTo(18.6, 11.2),
          paint,
        );
        canvas.drawPath(
          Path()
            ..moveTo(13.2, 11.2)
            ..lineTo(9.6, 11.2)
            ..lineTo(7.9, 13.8),
          paint,
        );
        canvas.drawPath(
          Path()
            ..moveTo(12.4, 11.2)
            ..lineTo(11, 7.4)
            ..lineTo(8.8, 7.4),
          paint,
        );
      case WorkshopIconKind.fuel:
        canvas.drawRect(const Rect.fromLTWH(4, 3.5, 9.5, 17), paint);
        canvas.drawLine(const Offset(4, 10), const Offset(13.5, 10), paint);
        canvas.drawPath(
          Path()
            ..moveTo(16.5, 7.5)
            ..lineTo(18.3, 7.5)
            ..arcToPoint(
              const Offset(20.5, 9.7),
              radius: const Radius.circular(2.2),
            )
            ..lineTo(20.5, 16)
            ..arcToPoint(
              const Offset(22, 17.7),
              radius: const Radius.circular(1.7),
              clockwise: false,
            ),
          paint,
        );
      case WorkshopIconKind.wrench:
        canvas.drawCircle(const Offset(7.3, 7.3), 3.4, paint);
        canvas.drawLine(const Offset(9.8, 9.8), const Offset(19.5, 19.5), paint);
        canvas.drawLine(const Offset(17, 15.6), const Offset(20.6, 19.2), paint);
      case WorkshopIconKind.bell:
        canvas.drawPath(
          Path()
            ..moveTo(12, 3.4)
            ..arcToPoint(
              const Offset(6.9, 8.5),
              radius: const Radius.circular(5.1),
              clockwise: false,
            )
            ..lineTo(6.9, 11.9)
            ..lineTo(5.2, 15.4)
            ..lineTo(18.8, 15.4)
            ..lineTo(17.1, 11.9)
            ..lineTo(17.1, 8.5)
            ..arcToPoint(
              const Offset(12, 3.4),
              radius: const Radius.circular(5.1),
              clockwise: false,
            )
            ..close(),
          paint,
        );
        canvas.drawPath(
          Path()
            ..moveTo(10, 18.2)
            ..arcToPoint(
              const Offset(14, 18.2),
              radius: const Radius.circular(2.1),
              clockwise: false,
            ),
          paint,
        );
      case WorkshopIconKind.camera:
        canvas.drawPath(
          Path()
            ..moveTo(3.5, 7.5)
            ..lineTo(6.7, 7.5)
            ..lineTo(8.2, 5.3)
            ..lineTo(15.8, 5.3)
            ..lineTo(17.3, 7.5)
            ..lineTo(20.5, 7.5)
            ..lineTo(20.5, 19.5)
            ..lineTo(3.5, 19.5)
            ..close(),
          paint,
        );
        canvas.drawCircle(const Offset(12, 13), 3.6, paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WorkshopIconPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.kind != kind;
}
