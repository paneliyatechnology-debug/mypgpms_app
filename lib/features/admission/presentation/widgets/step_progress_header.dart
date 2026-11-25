import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/colors/app_colors.dart';

/// Clean step progress indicator: "X of 5" + smooth green progress bar.
class StepProgressHeader extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const StepProgressHeader({
    super.key,
    required this.currentStep,
    this.totalSteps = 5,
  });

  @override
  Widget build(BuildContext context) {
    final progress = currentStep / totalSteps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            '$currentStep of $totalSteps',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.0,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6B7280),
            ),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(999.0),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 5.0,
            backgroundColor: const Color(0xFFD6EAE0),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }
}

