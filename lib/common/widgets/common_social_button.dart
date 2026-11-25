import 'package:flutter/material.dart';
import '../../core/colors/app_colors.dart';
import '../../core/dimensions/app_dimensions.dart';
import '../../core/typography/app_text_styles.dart';

enum SocialType { google, apple }

/// Reusable social authentication pill button matching Figma.
class CommonSocialButton extends StatelessWidget {
  final SocialType type;
  final VoidCallback onPressed;
  final double height;
  final double borderRadius;

  const CommonSocialButton({
    super.key,
    required this.type,
    required this.onPressed,
    this.height = AppDimensions.buttonHeight,
    this.borderRadius = AppDimensions.radiusFull,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.p16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: AppColors.border, width: 1.0),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (type == SocialType.google) ...[
                const _GoogleIcon(),
                const SizedBox(width: AppDimensions.p8),
                Text(
                  'Google',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ] else ...[
                const Icon(
                  Icons.apple,
                  color: AppColors.black,
                  size: 24,
                ),
                const SizedBox(width: AppDimensions.p8),
                Text(
                  'Apple',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Paint blue arm
    final bluePaint = Paint()..color = const Color(0xFF4285F4);
    final bluePath = Path()
      ..moveTo(w * 0.95, h * 0.5)
      ..lineTo(w * 0.5, h * 0.5)
      ..lineTo(w * 0.5, h * 0.68)
      ..lineTo(w * 0.77, h * 0.68)
      ..arcToPoint(
        Offset(w * 0.73, h * 0.8),
        radius: Radius.circular(w * 0.5),
        clockwise: true,
      )
      ..lineTo(w * 0.95, h * 0.5);
    canvas.drawPath(bluePath, bluePaint);

    // Green section
    final greenPaint = Paint()..color = const Color(0xFF34A853);
    final greenPath = Path()
      ..moveTo(w * 0.5, h)
      ..arcToPoint(
        Offset(w * 0.85, h * 0.82),
        radius: Radius.circular(w * 0.5),
        clockwise: false,
      )
      ..lineTo(w * 0.68, h * 0.68)
      ..arcToPoint(
        Offset(w * 0.5, h * 0.76),
        radius: Radius.circular(w * 0.32),
        clockwise: true,
      )
      ..lineTo(w * 0.5, h);
    canvas.drawPath(greenPath, greenPaint);

    // Yellow section
    final yellowPaint = Paint()..color = const Color(0xFFFBBC05);
    final yellowPath = Path()
      ..moveTo(w * 0.15, h * 0.75)
      ..arcToPoint(
        Offset(w * 0.15, h * 0.25),
        radius: Radius.circular(w * 0.5),
        clockwise: false,
      )
      ..lineTo(w * 0.32, h * 0.38)
      ..arcToPoint(
        Offset(w * 0.32, h * 0.62),
        radius: Radius.circular(w * 0.32),
        clockwise: true,
      )
      ..lineTo(w * 0.15, h * 0.75);
    canvas.drawPath(yellowPath, yellowPaint);

    // Red section
    final redPaint = Paint()..color = const Color(0xFFEA4335);
    final redPath = Path()
      ..moveTo(w * 0.5, 0)
      ..arcToPoint(
        Offset(w * 0.85, h * 0.18),
        radius: Radius.circular(w * 0.5),
        clockwise: true,
      )
      ..lineTo(w * 0.68, h * 0.32)
      ..arcToPoint(
        Offset(w * 0.5, h * 0.24),
        radius: Radius.circular(w * 0.32),
        clockwise: false,
      )
      ..lineTo(w * 0.5, 0);
    canvas.drawPath(redPath, redPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
