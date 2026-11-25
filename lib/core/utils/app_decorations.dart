import 'package:flutter/material.dart';
import '../colors/app_colors.dart';
import '../dimensions/app_dimensions.dart';

/// Centralized decoration styles.
class AppDecorations {
  AppDecorations._();

  static BoxDecoration cardDecoration = BoxDecoration(
    color: AppColors.background,
    borderRadius: AppDimensions.borderRadiusL,
    border: Border.all(color: AppColors.border),
    boxShadow: const [
      BoxShadow(
        color: AppColors.shadow,
        blurRadius: 10,
        offset: Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration socialButtonDecoration = BoxDecoration(
    color: AppColors.background,
    borderRadius: AppDimensions.borderRadiusM,
    border: Border.all(color: AppColors.border, width: 1.0),
  );

  static BoxDecoration otpBoxDecoration({
    required bool isFocused,
    required bool hasValue,
  }) {
    return BoxDecoration(
      color: AppColors.background,
      borderRadius: AppDimensions.borderRadiusM,
      border: Border.all(
        color: isFocused
            ? AppColors.primary
            : (hasValue ? AppColors.textPrimary : AppColors.border),
        width: isFocused ? 1.5 : 1.0,
      ),
    );
  }
}

