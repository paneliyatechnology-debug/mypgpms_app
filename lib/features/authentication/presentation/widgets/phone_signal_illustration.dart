import 'package:flutter/material.dart';
import '../../../../core/colors/app_colors.dart';

/// Vector illustration of phone with signal and check badge.
class PhoneSignalIllustration extends StatelessWidget {
  final double size;

  const PhoneSignalIllustration({
    super.key,
    this.size = 80.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PhoneSignalPainter(),
      ),
    );
  }
}

class _PhoneSignalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final phonePaint = Paint()
      ..color = const Color(0xFF6E9F88)
      ..style = PaintingStyle.fill;

    // Phone body
    final phoneRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.52, h * 0.52),
        width: w * 0.38,
        height: h * 0.60,
      ),
      const Radius.circular(8.0),
    );
    canvas.drawRRect(phoneRect, phonePaint);

    // Screen inside phone
    final screenPaint = Paint()..color = const Color(0xFF9FC4B3);
    final screenRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.52, h * 0.50),
        width: w * 0.28,
        height: h * 0.44,
      ),
      const Radius.circular(4.0),
    );
    canvas.drawRRect(screenRect, screenPaint);

    // Home indicator pill
    final homePaint = Paint()..color = Colors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w * 0.52, h * 0.76),
          width: 14,
          height: 3,
        ),
        const Radius.circular(2),
      ),
      homePaint,
    );

    // Signal waves on left
    final wavePaint = Paint()
      ..color = const Color(0xFF9FC4B3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final arc1 = Path()
      ..addArc(
        Rect.fromCircle(center: Offset(w * 0.45, h * 0.42), radius: 24),
        2.5,
        1.2,
      );
    canvas.drawPath(arc1, wavePaint);

    final arc2 = Path()
      ..addArc(
        Rect.fromCircle(center: Offset(w * 0.45, h * 0.42), radius: 32),
        2.6,
        1.0,
      );
    canvas.drawPath(arc2, wavePaint);

    // Signal waves on right
    final arc3 = Path()
      ..addArc(
        Rect.fromCircle(center: Offset(w * 0.59, h * 0.42), radius: 24),
        -0.6,
        1.2,
      );
    canvas.drawPath(arc3, wavePaint);

    final arc4 = Path()
      ..addArc(
        Rect.fromCircle(center: Offset(w * 0.59, h * 0.42), radius: 32),
        -0.5,
        1.0,
      );
    canvas.drawPath(arc4, wavePaint);

    // Green verification checkmark badge at bottom right
    final badgePaint = Paint()..color = AppColors.accentLeaf;
    final badgeCenter = Offset(w * 0.70, h * 0.76);
    canvas.drawCircle(badgeCenter, 10, badgePaint);

    // Checkmark
    final checkPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final checkPath = Path()
      ..moveTo(badgeCenter.dx - 4, badgeCenter.dy)
      ..lineTo(badgeCenter.dx - 1, badgeCenter.dy + 3)
      ..lineTo(badgeCenter.dx + 4, badgeCenter.dy - 3);
    canvas.drawPath(checkPath, checkPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

