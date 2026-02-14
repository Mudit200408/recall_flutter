import 'package:flutter/material.dart';

class StripedProgressPainter extends CustomPainter {
  final double progress;
  final Color color;

  StripedProgressPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final double filledWidth = size.width * progress;
    if (filledWidth <= 0) return;

    // Clip to the filled region
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, filledWidth, size.height));

    // Draw the base fill (dark grey)
    final basePaint = Paint()..color = color;
    canvas.drawRect(Rect.fromLTWH(0, 0, filledWidth, size.height), basePaint);

    // Draw diagonal stripes as filled parallelograms (edge-to-edge)
    final stripePaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.fill;

    const double stripeWidth = 14;
    const double stripeSpacing = 28;
    final double h = size.height;
    final double totalSpan = size.width + h * 2;

    for (double i = -totalSpan; i < totalSpan; i += stripeSpacing) {
      final path = Path()
        ..moveTo(i, h)
        ..lineTo(i + stripeWidth, h)
        ..lineTo(i + h + stripeWidth, 0)
        ..lineTo(i + h, 0)
        ..close();
      canvas.drawPath(path, stripePaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant StripedProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
