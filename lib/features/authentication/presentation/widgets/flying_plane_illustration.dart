import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Vector illustration of flying paper airplane and envelope.
class FlyingPlaneIllustration extends StatelessWidget {
  final double width;
  final double height;

  const FlyingPlaneIllustration({
    super.key,
    this.width = 160.0,
    this.height = 120.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _FlyingPlanePainter(),
      ),
    );
  }
}

class _FlyingPlanePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Envelope at bottom left
    final envelopePaint = Paint()
      ..color = const Color(0xFF7FA895)
      ..style = PaintingStyle.fill;

    final envLeft = w * 0.12;
    final envTop = h * 0.58;
    final envWidth = 44.0;
    final envHeight = 30.0;
    final envRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(envLeft, envTop, envWidth, envHeight),
      const Radius.circular(6.0),
    );
    canvas.drawRRect(envRRect, envelopePaint);

    // Envelope flap lines
    final flapPaint = Paint()
      ..color = const Color(0xFF678F7C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final flapPath = Path()
      ..moveTo(envLeft, envTop)
      ..lineTo(envLeft + envWidth / 2, envTop + envHeight * 0.55)
      ..lineTo(envLeft + envWidth, envTop);
    canvas.drawPath(flapPath, flapPaint);

    // Dashed flight curve
    final dashedPaint = Paint()
      ..color = const Color(0xFF94B5A5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final curvePath = Path();
    curvePath.moveTo(envLeft + envWidth + 4, envTop + 10);
    curvePath.cubicTo(
      w * 0.45,
      envTop + 12,
      w * 0.52,
      h * 0.42,
      w * 0.65,
      h * 0.38,
    );

    _drawDashedPath(canvas, curvePath, dashedPaint, 4.0, 4.0);

    // Paper airplane at top right
    final planeCenter = Offset(w * 0.78, h * 0.28);
    canvas.save();
    canvas.translate(planeCenter.dx, planeCenter.dy);
    canvas.rotate(-math.pi / 7);

    final planePaintDark = Paint()..color = const Color(0xFF5D9B7B);
    final planePaintLight = Paint()..color = const Color(0xFF7CB897);

    // Right wing
    final rightWing = Path()
      ..moveTo(0, -20)
      ..lineTo(14, 14)
      ..lineTo(0, 8)
      ..close();
    canvas.drawPath(rightWing, planePaintLight);

    // Left wing
    final leftWing = Path()
      ..moveTo(0, -20)
      ..lineTo(-14, 14)
      ..lineTo(0, 8)
      ..close();
    canvas.drawPath(leftWing, planePaintDark);

    canvas.restore();
  }

  void _drawDashedPath(
    Canvas canvas,
    Path path,
    Paint paint,
    double dashWidth,
    double dashSpace,
  ) {
    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double length = math.min(dashWidth, metric.length - distance);
        final Path extract = metric.extractPath(distance, distance + length);
        canvas.drawPath(extract, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

