import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/colors/app_colors.dart';

class CheckoutStatusPage extends StatelessWidget {
  const CheckoutStatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth > 600 ? (screenWidth - 460) / 2 : 16.0;

    final steps = [
      {
        'title': 'Request Submitted',
        'subtitle': '05 March 2026 | 10:30 AM',
        'isCompleted': true,
      },
      {
        'title': 'Under Review',
        'subtitle': '05 March 2026 | 10:30 AM',
        'isCompleted': true,
      },
      {
        'title': 'Room Clearance',
        'subtitle': 'In Progress',
        'isCompleted': true,
      },
      {
        'title': 'NOC issued',
        'subtitle': 'Pending',
        'isCompleted': false,
      },
      {
        'title': 'Refund Processed',
        'subtitle': 'Pending',
        'isCompleted': false,
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8F6),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary, size: 20.0),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Checkout Status',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18.0,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8.0),
          children: [
            // Timeline Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
              ),
              child: Column(
                children: List.generate(steps.length, (index) {
                  final step = steps[index];
                  final isLast = index == steps.length - 1;
                  final isCompleted = step['isCompleted'] as bool;

                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Node & Vertical Line
                        Column(
                          children: [
                            Container(
                              width: 24.0,
                              height: 24.0,
                              decoration: BoxDecoration(
                                color: isCompleted ? AppColors.primary : Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isCompleted ? AppColors.primary : const Color(0xFFD1D5DB),
                                  width: 2.0,
                                ),
                              ),
                              child: isCompleted
                                  ? const Icon(
                                      Icons.check_rounded,
                                      size: 14.0,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                            if (!isLast)
                              Expanded(
                                child: Container(
                                  width: 2.0,
                                  color: isCompleted ? AppColors.primary : const Color(0xFFE5E7EB),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 14.0),

                        // Right Title & Subtitle
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(bottom: isLast ? 0.0 : 26.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  step['title'] as String,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2.0),
                                Text(
                                  step['subtitle'] as String,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 14.0),

            // Estimated Refund Card
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estimated Refund',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.0,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  Text(
                    '₹4,200',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22.0,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    'Will be credited after final clearance',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20.0),
          ],
        ),
      ),
    );
  }
}
