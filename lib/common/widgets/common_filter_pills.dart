import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/colors/app_colors.dart';

/// Reusable horizontal scrollable filter pills component.
/// Matches the standard MYPGPMS rounded capsule pill design.
class CommonFilterPills extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final EdgeInsetsGeometry padding;

  const CommonFilterPills({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    this.padding = const EdgeInsets.only(right: 8.0),
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(labels.length, (index) {
          final isSelected = selectedIndex == index;
          return Padding(
            padding: padding,
            child: InkWell(
              onTap: () => onSelected(index),
              borderRadius: BorderRadius.circular(999.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 7.0),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : const Color(0xFFE8F3ED),
                  borderRadius: BorderRadius.circular(999.0),
                ),
                child: Text(
                  labels[index],
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.0,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.primary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
