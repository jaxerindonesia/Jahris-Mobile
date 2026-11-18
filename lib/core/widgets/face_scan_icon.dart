import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/dashboard_theme.dart';

/// Ikon pemindai wajah dengan sudut pemindaian dan ekspresi wajah.
class FaceScanIcon extends StatelessWidget {
  const FaceScanIcon({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.square(
    dimension: 42,
    child: CustomPaint(painter: _FaceScanPainter()),
  );
}

class _FaceScanPainter extends CustomPainter {
  const _FaceScanPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 42, size.height / 42);
    final pen = Paint()
      ..color = DashboardTheme.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 4; i++) {
      canvas.drawArc(
        const Rect.fromLTWH(3, 3, 36, 36),
        (i * 90 + 12) * math.pi / 180,
        48 * math.pi / 180,
        false,
        pen,
      );
    }
    canvas.drawLine(const Offset(14, 15), const Offset(14, 19), pen);
    canvas.drawLine(const Offset(28, 15), const Offset(28, 19), pen);
    canvas.drawPath(
      Path()
        ..moveTo(21, 15)
        ..lineTo(21, 23)
        ..lineTo(18, 24),
      pen,
    );
    canvas.drawArc(
      const Rect.fromLTWH(13, 22, 16, 10),
      0.2,
      math.pi - 0.4,
      false,
      pen,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FaceScanPainter oldDelegate) => false;
}
