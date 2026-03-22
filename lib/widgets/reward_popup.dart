import 'dart:math' as math;
import 'package:flutter/material.dart';

class RewardPopup extends StatefulWidget {
  final String rewardText;
  final Color rewardColor;

  const RewardPopup({
    super.key,
    required this.rewardText,
    required this.rewardColor,
  });

  @override
  State<RewardPopup> createState() => _RewardPopupState();
}

class _RewardPopupState extends State<RewardPopup>
    with TickerProviderStateMixin {
  late AnimationController _confettiController;
  late AnimationController _cardController;

  late Animation<double> _cardScale;
  late Animation<double> _cardOpacity;
  late Animation<Offset> _cardSlide;

  @override
  void initState() {
    super.initState();

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _cardScale = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _cardController,
        curve: Curves.easeOutBack,
      ),
    );

    _cardOpacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _cardController,
        curve: Curves.easeOut,
      ),
    );

    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _cardController,
        curve: Curves.easeOutCubic,
      ),
    );

    _confettiController.forward();

    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) {
        _cardController.forward();
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.28),
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _confettiController,
              builder: (context, child) {
                return CustomPaint(
                  painter: ConfettiPainter(
                    progress: _confettiController.value,
                    color: widget.rewardColor,
                  ),
                );
              },
            ),
          ),
          Center(
            child: FadeTransition(
              opacity: _cardOpacity,
              child: SlideTransition(
                position: _cardSlide,
                child: ScaleTransition(
                  scale: _cardScale,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 180,
                      maxWidth: 280,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.16),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(
                        color: widget.rewardColor.withOpacity(0.35),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 54,
                          height: 6,
                          decoration: BoxDecoration(
                            color: widget.rewardColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          widget.rewardText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.rewardColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text("OK"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ConfettiPainter extends CustomPainter {
  final double progress;
  final Color color;

  ConfettiPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    final random = math.Random(42);

    for (int i = 0; i < 56; i++) {
      final fromLeft = i % 2 == 0;

      final startX = fromLeft ? -20.0 : size.width + 20;
      final endX = size.width * (0.25 + random.nextDouble() * 0.5);
      final x = startX + (endX - startX) * progress;

      final startY = size.height * (0.18 + random.nextDouble() * 0.5);
      final drift = (random.nextDouble() - 0.5) * 120;
      final y = startY +
          math.sin((progress * math.pi * 2) + i) * 18 +
          drift * progress * 0.15;

      final pieceW = 6 + random.nextDouble() * 8;
      final pieceH = 8 + random.nextDouble() * 10;
      final rotation = progress * math.pi * (1 + random.nextDouble() * 2);

      paint.color = i % 3 == 0
          ? color
          : i % 3 == 1
              ? color.withOpacity(0.78)
              : color.withOpacity(0.55);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      if (i % 2 == 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: pieceW,
              height: pieceH,
            ),
            const Radius.circular(3),
          ),
          paint,
        );
      } else {
        final path = Path()
          ..moveTo(0, -pieceH / 2)
          ..lineTo(pieceW / 2, pieceH / 2)
          ..lineTo(-pieceW / 2, pieceH / 2)
          ..close();
        canvas.drawPath(path, paint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}