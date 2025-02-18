import 'package:flutter/material.dart';
import 'dart:math';

class ClockPainter extends CustomPainter {
  final double progress; // 當前進度（0 ~ 1）
  final int workMinutes; // 工作時間
  final int breakMinutes; // 休息時間

  ClockPainter(this.progress, this.workMinutes, this.breakMinutes);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final totalMinutes = workMinutes + breakMinutes;
    final workRatio = workMinutes / totalMinutes;

    // **根據進度決定指針顏色**
    final isWorking = progress < workRatio;
    final needleColor = isWorking ? Colors.blue : Colors.green;

    // 畫指針
    final double angle = 2 * pi * progress - pi / 2;
    final needlePaint = Paint()
      ..color = needleColor
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final needleEnd = Offset(
      center.dx + radius * cos(angle),
      center.dy + radius * sin(angle),
    );

    canvas.drawLine(center, needleEnd, needlePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}