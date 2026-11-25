import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/colors/app_colors.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/dimensions/app_dimensions.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../common/widgets/common_app_bar.dart';
import '../../../../common/widgets/common_button.dart';

class RoomConfirmationPage extends StatelessWidget {
  const RoomConfirmationPage({super.key});

  Widget _buildStepItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 22.0,
            height: 22.0,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 15.0,
            ),
          ),
          const SizedBox(width: 14.0),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF374151),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F6),
      appBar: const CommonAppBar(
        backgroundColor: Color(0xFFF7F8F6),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Congratulations Green Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFD6EAE0),
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2.0),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 20.0,
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Congratulations!',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15.0,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            'Your room has been confirmed. Welcome to MYPGPMS!',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF2D6A4F),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18.0),

              // Room Photo Card
              ClipRRect(
                borderRadius: BorderRadius.circular(18.0),
                child: Stack(
                  children: [
                    Image.asset(
                      AppAssets.admissionRoom,
                      height: 190.0,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 190.0,
                          color: const Color(0xFFE2EFE7),
                          child: const Center(
                            child: Icon(Icons.hotel_rounded, size: 60.0, color: AppColors.primary),
                          ),
                        );
                      },
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.75),
                            ],
                            stops: const [0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16.0,
                      bottom: 16.0,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6.0),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: const Icon(Icons.apartment_rounded, color: Colors.white, size: 24.0),
                          ),
                          const SizedBox(width: 10.0),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'MYPGPMS Green Park',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Boys | Shared Room',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),

              // Room Specs Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Room No.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            'A-204',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18.0,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1.0, height: 36.0, color: const Color(0xFFE5E7EB)),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bed No.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              'B-2',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18.0,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(width: 1.0, height: 36.0, color: const Color(0xFFE5E7EB)),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rent',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              '₹12,000/mo',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15.0,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20.0),

              // Next Steps Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Next Steps',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    _buildStepItem('Complete your check-in formalities'),
                    _buildStepItem('Collect your room keys'),
                    _buildStepItem('Explore your new room'),
                  ],
                ),
              ),
              const SizedBox(height: 36.0),

              // Go to Dashboard Button
              CommonButton(
                text: 'Go to Dashboard',
                height: AppDimensions.buttonHeight,
                borderRadius: AppDimensions.radiusFull,
                backgroundColor: AppColors.primary,
                onPressed: () {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.dashboard,
                    (route) => false,
                  );
                },
              ),
              const SizedBox(height: 24.0),
            ],
          ),
        ),
      ),
    );
  }
}

