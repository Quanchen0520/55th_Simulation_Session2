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
    final maxMinutes = workMinutes + breakMinutes;

    final Paint circlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // 畫外圈
    canvas.drawCircle(center, radius, circlePaint);

    // 順序顯示數字
    for (int i = 1; i <= maxMinutes; i++) { // 改成從 1 開始遞增
      double tickAngle = -pi / 2 + (i / maxMinutes) * 2 * pi; // 讓數字順時鐘排列

      // 刻度線
      final tickStart = Offset(
        center.dx + cos(tickAngle) * (radius - 10),
        center.dy + sin(tickAngle) * (radius - 10),
      );
      final tickEnd = Offset(
        center.dx + cos(tickAngle) * radius,
        center.dy + sin(tickAngle) * radius,
      );
      canvas.drawLine(tickStart, tickEnd, circlePaint);

      // 顯示分鐘數字
      final textPainter = TextPainter(
        text: TextSpan(
          text: "$i",
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      final textOffset = Offset(
        center.dx + cos(tickAngle) * (radius - 25) - textPainter.width / 2,
        center.dy + sin(tickAngle) * (radius - 25) - textPainter.height / 2,
      );
      textPainter.paint(canvas, textOffset);
    }


    // 修正指針順時針旋轉
    final double angle = -pi / 2 + (2 * pi * progress);
    final needleLength = radius * 0.9;
    final needlePaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final needleEnd = Offset(
      center.dx + cos(angle) * needleLength,
      center.dy + sin(angle) * needleLength,
    );
    canvas.drawLine(center, needleEnd, needlePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}