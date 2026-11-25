import 'package:flutter/material.dart';
import '../../core/colors/app_colors.dart';
import '../../core/dimensions/app_dimensions.dart';
import '../../core/typography/app_text_styles.dart';

/// Reusable checkbox with label widget matching Figma.
class CommonCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final String label;

  const CommonCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(AppDimensions.radiusXS),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: SizedBox(
              height: 20,
              width: 20,
              child: Checkbox(
                value: value,
                onChanged: onChanged,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                activeColor: AppColors.primary,
                checkColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5.0),
                ),
                side: const BorderSide(color: AppColors.border, width: 1.5),
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.p8),
          Flexible(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: const Color(0xFF4B5563),
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
