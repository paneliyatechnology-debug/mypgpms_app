import 'package:flutter/material.dart';
import '../../core/colors/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/dimensions/app_dimensions.dart';
import '../../core/typography/app_text_styles.dart';

/// Reusable 6-digit OTP input widget with active cursor and individual boxes.
class CommonOtpInput extends StatefulWidget {
  final int length;
  final String value;
  final ValueChanged<String>? onChanged;

  const CommonOtpInput({
    super.key,
    this.length = AppConstants.otpLength,
    required this.value,
    this.onChanged,
  });

  @override
  State<CommonOtpInput> createState() => _CommonOtpInputState();
}

class _CommonOtpInputState extends State<CommonOtpInput>
    with SingleTickerProviderStateMixin {
  late AnimationController _cursorController;

  @override
  void initState() {
    super.initState();
    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _cursorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(widget.length, (index) {
        final hasDigit = index < widget.value.length;
        final digit = hasDigit ? widget.value[index] : '';
        final isFocused = index == widget.value.length;

        return Container(
          width: AppDimensions.otpBoxSize,
          height: 54.0,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: AppDimensions.borderRadiusM,
            border: Border.all(
              color: isFocused
                  ? AppColors.primary
                  : (hasDigit ? AppColors.textPrimary : AppColors.border),
              width: isFocused ? 1.5 : 1.0,
            ),
          ),
          alignment: Alignment.center,
          child: hasDigit
              ? Text(
                  digit,
                  style: AppTextStyles.otpDigit,
                )
              : (isFocused
                  ? FadeTransition(
                      opacity: _cursorController,
                      child: Container(
                        width: 2.0,
                        height: 22.0,
                        color: AppColors.primary,
                      ),
                    )
                  : const SizedBox.shrink()),
        );
      }),
    );
  }
}
