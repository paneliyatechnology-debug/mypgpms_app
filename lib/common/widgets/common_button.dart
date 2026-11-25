import 'package:flutter/material.dart';
import '../../core/colors/app_colors.dart';
import '../../core/dimensions/app_dimensions.dart';
import '../../core/typography/app_text_styles.dart';

enum ButtonType { filled, outlined, text }

/// Reusable configurable button component for MYPGPMS.
class CommonButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;
  final bool isLoading;
  final bool isFullWidth;
  final double? width;
  final double height;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;
  final double borderRadius;

  const CommonButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.type = ButtonType.filled,
    this.isLoading = false,
    this.isFullWidth = true,
    this.width,
    this.height = AppDimensions.buttonHeight,
    this.prefixIcon,
    this.suffixIcon,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.borderRadius = AppDimensions.radiusFull,
  });

  const CommonButton.outlined({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.width,
    this.height = AppDimensions.buttonHeight,
    this.prefixIcon,
    this.suffixIcon,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.borderRadius = AppDimensions.radiusFull,
  }) : type = ButtonType.outlined;

  @override
  Widget build(BuildContext context) {
    final effectiveWidth = isFullWidth ? double.infinity : width;

    Widget childContent;
    if (isLoading) {
      childContent = SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          valueColor: AlwaysStoppedAnimation<Color>(
            type == ButtonType.filled ? AppColors.white : AppColors.primary,
          ),
        ),
      );
    } else {
      childContent = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (prefixIcon != null) ...[
            prefixIcon!,
            const SizedBox(width: AppDimensions.p8),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: type == ButtonType.filled
                  ? AppTextStyles.button.copyWith(color: textColor ?? AppColors.white)
                  : AppTextStyles.buttonOutlined.copyWith(
                      color: textColor ?? AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
            ),
          ),
          if (suffixIcon != null) ...[
            const SizedBox(width: AppDimensions.p8),
            suffixIcon!,
          ],
        ],
      );
    }

    if (type == ButtonType.outlined) {
      return SizedBox(
        width: effectiveWidth,
        height: height,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: backgroundColor ?? AppColors.white,
            foregroundColor: textColor ?? AppColors.primary,
            side: BorderSide(
              color: borderColor ?? AppColors.primary,
              width: 1.4,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
          child: childContent,
        ),
      );
    }

    return SizedBox(
      width: effectiveWidth,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.primary,
          foregroundColor: textColor ?? AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: childContent,
      ),
    );
  }
}
