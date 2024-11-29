import 'package:flutter/material.dart';

class BorderPainter extends CustomPainter {
  final Color? color;
  final Gradient? gradient;
  final double strokeWidth;
  final Radius borderRadius;
  final EdgeInsets padding;

  BorderPainter({
    this.color,
    this.gradient,
    this.borderRadius = const Radius.circular(0.0),
    this.padding = EdgeInsets.zero,
    this.strokeWidth = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    if (color != null) {
      paint.color = color!;
    } else if (gradient != null) {
      paint.shader = gradient!.createShader(rect);
    }

    final borderRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2 + padding.left,
        strokeWidth / 2 + padding.top,
        size.width - strokeWidth - padding.horizontal,
        size.height - strokeWidth - padding.vertical,
      ),
      borderRadius,
    );

    canvas.drawRRect(borderRect, paint);
  }

  @override
  bool shouldRepaint(BorderPainter oldDelegate) =>
      color != oldDelegate.color ||
      gradient != oldDelegate.gradient ||
      borderRadius != oldDelegate.borderRadius ||
      padding != oldDelegate.padding ||
      strokeWidth != oldDelegate.strokeWidth;
}
