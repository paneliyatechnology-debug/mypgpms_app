import 'package:flutter/material.dart';
import '../../../../common/widgets/common_button.dart';
import '../../../../core/colors/app_colors.dart';
import '../../../../core/dimensions/app_dimensions.dart';

/// Reusable navigation button pair (Back & Next) for admission wizard.
class AdmissionNavButtons extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final String nextText;
  final String backText;
  final bool isLoading;

  const AdmissionNavButtons({
    super.key,
    required this.onNext,
    this.onBack,
    this.nextText = 'Next',
    this.backText = 'Back',
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (onBack == null) {
      return CommonButton(
        text: nextText,
        isLoading: isLoading,
        height: AppDimensions.buttonHeight,
        borderRadius: AppDimensions.radiusFull,
        backgroundColor: AppColors.primary,
        onPressed: onNext,
      );
    }

    return Row(
      children: [
        Expanded(
          child: CommonButton.outlined(
            text: backText,
            height: AppDimensions.buttonHeight,
            borderRadius: AppDimensions.radiusFull,
            textColor: AppColors.primary,
            borderColor: AppColors.primary,
            onPressed: onBack,
          ),
        ),
        const SizedBox(width: 14.0),
        Expanded(
          child: CommonButton(
            text: nextText,
            isLoading: isLoading,
            height: AppDimensions.buttonHeight,
            borderRadius: AppDimensions.radiusFull,
            backgroundColor: AppColors.primary,
            onPressed: onNext,
          ),
        ),
      ],
    );
  }
}
