import 'package:flutter/material.dart';
import '../../core/colors/app_colors.dart';
import '../../core/constants/app_assets.dart';
import '../../core/typography/app_text_styles.dart';

/// Reusable MYPGPMS Brand Logo.
/// Uses authentic Figma exported assets with crisp vector fallback.
/// Supports horizontal (header) and vertical (splash/hero) layouts.
class CommonLogo extends StatelessWidget {
  final double iconSize;
  final double fontSize;
  final bool isVertical;
  final bool showText;
  final Color? color;

  const CommonLogo({
    super.key,
    this.iconSize = 28.0,
    this.fontSize = 20.0,
    this.isVertical = false,
    this.showText = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (isVertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildEmblem(width: 94.0, height: 80.0),
          const SizedBox(height: 16.0),
          if (showText) _buildWordmark(),
        ],
      );
    }

    // Horizontal layout (app headers)
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildEmblem(width: iconSize, height: iconSize * (80.0 / 94.0)),
        const SizedBox(width: 8.0),
        if (showText) _buildWordmark(),
      ],
    );
  }

  Widget _buildEmblem({required double width, required double height}) {
    return Image.asset(
      AppAssets.logoEmblem,
      width: width,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return SizedBox(
          width: width,
          height: height,
          child: CustomPaint(
            painter: _MYPGPMSIconPainter(color: color ?? AppColors.primary),
          ),
        );
      },
    );
  }

  Widget _buildWordmark() {
    return Text(
      'MYPGPMS',
      style: AppTextStyles.h2.copyWith(
        fontSize: fontSize,
        color: color ?? AppColors.primary,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
    );
  }
}

/// Fallback vector painter for the MYPGPMS emblem.
class _MYPGPMSIconPainter extends CustomPainter {
  final Color color;

  _MYPGPMSIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.16;
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // Outer house outline
    final path = Path();
    path.moveTo(w * 0.16, h * 0.88);
    path.lineTo(w * 0.16, h * 0.44);
    path.lineTo(w * 0.50, h * 0.14);
    path.lineTo(w * 0.84, h * 0.44);
    path.lineTo(w * 0.84, h * 0.88);

    canvas.drawPath(path, strokePaint);

    // Inner arch
    final doorPaint = Paint()
      ..color = const Color(0xFF2E8B57)
      ..style = PaintingStyle.fill;

    final doorRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(w * 0.38, h * 0.52, w * 0.24, h * 0.36),
      topLeft: Radius.circular(w * 0.12),
      topRight: Radius.circular(w * 0.12),
    );
    canvas.drawRRect(doorRect, doorPaint);
  }

  @override
  bool shouldRepaint(covariant _MYPGPMSIconPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
