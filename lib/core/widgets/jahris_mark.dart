import 'package:flutter/material.dart';

import '../theme/dashboard_theme.dart';

class JahrisMark extends StatelessWidget {
  const JahrisMark({super.key});

  @override
  Widget build(BuildContext context) =>
      const CustomPaint(painter: _MarkPainter());
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width * 0.82, size.height)
      ..lineTo(size.width / 2, size.height * 0.62)
      ..lineTo(size.width * 0.18, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = DashboardTheme.ink);
    for (final right in [false, true]) {
      final accent = Path()
        ..moveTo(right ? size.width : 0, size.height)
        ..lineTo(size.width / 2, size.height * 0.62)
        ..lineTo(size.width * (right ? 0.82 : 0.18), size.height)
        ..close();
      canvas.drawPath(accent, Paint()..color = DashboardTheme.green);
    }
  }

  @override
  bool shouldRepaint(_MarkPainter oldDelegate) => false;
}
