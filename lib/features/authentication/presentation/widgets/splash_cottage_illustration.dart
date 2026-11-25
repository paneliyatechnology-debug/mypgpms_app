import 'package:flutter/material.dart';

/// Clean vector line-art illustration of cottage and trees for Splash screen.
class SplashCottageIllustration extends StatelessWidget {
  final double height;

  const SplashCottageIllustration({
    super.key,
    this.height = 200.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _CottagePainter(),
      ),
    );
  }
}

class _CottagePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final linePaint = Paint()
      ..color = const Color(0xFF6F897B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = const Color(0x33B7CDC2)
      ..style = PaintingStyle.fill;

    // Ground line
    canvas.drawLine(
      Offset(w * 0.05, h * 0.95),
      Offset(w * 0.95, h * 0.95),
      linePaint,
    );
    canvas.drawLine(
      Offset(w * 0.08, h * 0.97),
      Offset(w * 0.92, h * 0.97),
      linePaint..strokeWidth = 1.0,
    );
    linePaint.strokeWidth = 1.6;

    // Left Tree
    final treeCenter = Offset(w * 0.16, h * 0.55);
    // Tree trunk
    final trunkPath = Path()
      ..moveTo(w * 0.15, h * 0.95)
      ..lineTo(w * 0.155, h * 0.58)
      ..lineTo(w * 0.165, h * 0.58)
      ..lineTo(w * 0.17, h * 0.95);
    canvas.drawPath(trunkPath, linePaint);

    // Tree foliage canopy (cloudy layers)
    for (int i = 0; i < 4; i++) {
      final yOffset = h * 0.55 - (i * 22);
      final r = 32.0 - (i * 4);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(treeCenter.dx, yOffset), width: r * 2.2, height: r * 1.1),
        fillPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(treeCenter.dx, yOffset), width: r * 2.2, height: r * 1.1),
        linePaint,
      );
    }

    // Main House Body (center to right)
    final houseRight = w * 0.88;
    final groundY = h * 0.95;

    // Left gable / wing
    final leftGableApex = Offset(w * 0.45, h * 0.32);
    final leftGableLeft = Offset(w * 0.28, h * 0.55);
    final leftGableRight = Offset(w * 0.62, h * 0.55);

    // Left Roof
    final roofPath = Path()
      ..moveTo(leftGableLeft.dx - 10, leftGableLeft.dy)
      ..lineTo(leftGableApex.dx, leftGableApex.dy)
      ..lineTo(leftGableRight.dx + 10, leftGableRight.dy);
    canvas.drawPath(roofPath, linePaint);

    // Attic Window
    final atticRect = Rect.fromCenter(center: Offset(leftGableApex.dx, h * 0.44), width: 22, height: 26);
    canvas.drawRRect(RRect.fromRectAndRadius(atticRect, const Radius.circular(3)), linePaint);
    canvas.drawLine(Offset(atticRect.center.dx, atticRect.top), Offset(atticRect.center.dx, atticRect.bottom), linePaint);
    canvas.drawLine(Offset(atticRect.left, atticRect.center.dy), Offset(atticRect.right, atticRect.center.dy), linePaint);

    // Right gable / main wing
    final rightRoofApex = Offset(w * 0.72, h * 0.42);
    final rightRoofRight = Offset(houseRight, h * 0.62);
    final rightRoofPath = Path()
      ..moveTo(leftGableRight.dx, leftGableRight.dy)
      ..lineTo(rightRoofApex.dx, rightRoofApex.dy)
      ..lineTo(rightRoofRight.dx, rightRoofRight.dy);
    canvas.drawPath(rightRoofPath, linePaint);

    // Outer walls
    canvas.drawLine(leftGableLeft, Offset(leftGableLeft.dx, groundY), linePaint);
    canvas.drawLine(rightRoofRight, Offset(rightRoofRight.dx, groundY), linePaint);

    // Ground floor details & porch
    final doorRect = Rect.fromLTWH(w * 0.40, h * 0.68, w * 0.12, groundY - h * 0.68);
    canvas.drawRect(doorRect, linePaint);
    // Door panels
    canvas.drawRect(Rect.fromLTWH(w * 0.42, h * 0.71, w * 0.08, h * 0.10), linePaint);
    canvas.drawRect(Rect.fromLTWH(w * 0.42, h * 0.83, w * 0.08, h * 0.09), linePaint);

    // Front steps
    canvas.drawLine(Offset(w * 0.38, groundY - 4), Offset(w * 0.54, groundY - 4), linePaint);

    // Left ground window
    final win1 = Rect.fromLTWH(w * 0.30, h * 0.68, w * 0.08, h * 0.16);
    canvas.drawRect(win1, linePaint);
    canvas.drawLine(Offset(win1.center.dx, win1.top), Offset(win1.center.dx, win1.bottom), linePaint);
    canvas.drawLine(Offset(win1.left, win1.center.dy), Offset(win1.right, win1.center.dy), linePaint);

    // Right windows
    final win2 = Rect.fromLTWH(w * 0.56, h * 0.66, w * 0.12, h * 0.18);
    canvas.drawRect(win2, linePaint);
    canvas.drawLine(Offset(win2.center.dx, win2.top), Offset(win2.center.dx, win2.bottom), linePaint);
    canvas.drawLine(Offset(win2.left, win2.center.dy), Offset(win2.right, win2.center.dy), linePaint);

    final win3 = Rect.fromLTWH(w * 0.72, h * 0.66, w * 0.12, h * 0.18);
    canvas.drawRect(win3, linePaint);
    canvas.drawLine(Offset(win3.center.dx, win3.top), Offset(win3.center.dx, win3.bottom), linePaint);
    canvas.drawLine(Offset(win3.left, win3.center.dy), Offset(win3.right, win3.center.dy), linePaint);

    // Little bushes in front
    final bushPaint = Paint()
      ..color = const Color(0x55B7CDC2)
      ..style = PaintingStyle.fill;
    canvas.drawOval(Rect.fromLTWH(w * 0.25, groundY - 14, 30, 16), bushPaint);
    canvas.drawOval(Rect.fromLTWH(w * 0.25, groundY - 14, 30, 16), linePaint);

    canvas.drawOval(Rect.fromLTWH(w * 0.84, groundY - 16, 36, 18), bushPaint);
    canvas.drawOval(Rect.fromLTWH(w * 0.84, groundY - 16, 36, 18), linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
