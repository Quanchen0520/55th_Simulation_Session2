import 'dart:math';
import 'package:flutter/material.dart';

class ClockPainter extends CustomPainter {
  final double progress;
  ClockPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paintCircle = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawCircle(center, radius, paintCircle);

    final angle = progress * 2 * pi;
    final handX = center.dx + radius * 0.8 * -sin(angle);
    final handY = center.dy + radius * 0.8 * cos(angle);
    final paintHand = Paint()
      ..color = Colors.red
      ..strokeWidth = 4;

    canvas.drawLine(center, Offset(handX, handY), paintHand);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
