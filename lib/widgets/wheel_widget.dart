import 'package:flutter/material.dart';
import 'dart:math';

class WheelWidget extends StatelessWidget {
  final List<String> rewards;

  const WheelWidget({super.key, required this.rewards});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(250, 250),
      painter: WheelPainter(rewards),
    );
  }
}

class WheelPainter extends CustomPainter {
  final List<String> rewards;

  WheelPainter(this.rewards);

  final List<Color> wheelColors = [
    const Color(0xFFFF6B6B),
    const Color(0xFFFFA94D),
    const Color(0xFFFFE066),
    const Color(0xFF69DB7C),
    const Color(0xFF4DABF7),
    const Color(0xFF748FFC),
    const Color(0xFFB197FC),
    const Color(0xFFF783AC),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final basePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.grey.shade200;

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Colors.grey.shade400;

    canvas.drawCircle(center, radius, basePaint);
    canvas.drawCircle(center, radius, borderPaint);

    if (rewards.isEmpty) {
      final textPainter = TextPainter(
        text: const TextSpan(
          text: 'Добави\nнагради',
          style: TextStyle(
            fontSize: 18,
            color: Colors.black54,
            fontWeight: FontWeight.w600,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout(maxWidth: 140);
      textPainter.paint(
        canvas,
        Offset(
          center.dx - textPainter.width / 2,
          center.dy - textPainter.height / 2,
        ),
      );
      return;
    }

    final paint = Paint()..style = PaintingStyle.fill;
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    final angle = (2 * pi) / rewards.length;

    for (int i = 0; i < rewards.length; i++) {
      paint.color = wheelColors[i % wheelColors.length];

      final startAngle = -pi / 2 + i * angle;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        angle,
        true,
        paint,
      );

      final text = rewards[i];
      textPainter.text = TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 11,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      );

      textPainter.layout(maxWidth: 70);

      final textRadius = radius * 0.58;
      final textX = center.dx +
          cos(startAngle + angle / 2) * textRadius -
          textPainter.width / 2;
      final textY = center.dy +
          sin(startAngle + angle / 2) * textRadius -
          textPainter.height / 2;

      textPainter.paint(canvas, Offset(textX, textY));
    }

    canvas.drawCircle(center, radius, borderPaint);
    canvas.drawCircle(
      center,
      18,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}