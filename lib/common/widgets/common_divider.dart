import 'package:flutter/material.dart';
import '../../core/colors/app_colors.dart';
import '../../core/dimensions/app_dimensions.dart';
import '../../core/typography/app_text_styles.dart';

/// Reusable horizontal divider with centered label.
class CommonDivider extends StatelessWidget {
  final String text;

  const CommonDivider({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Divider(
            color: AppColors.border,
            thickness: 1.0,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.p12),
          child: Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textMuted,
              fontSize: 12.0,
            ),
          ),
        ),
        const Expanded(
          child: Divider(
            color: AppColors.border,
            thickness: 1.0,
          ),
        ),
      ],
    );
  }
}

