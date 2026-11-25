import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/colors/app_colors.dart';
import '../../../../core/dimensions/app_dimensions.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/typography/app_text_styles.dart';
import '../../../../common/widgets/common_app_bar.dart';
import '../../../../common/widgets/common_button.dart';
import '../bloc/admission_bloc.dart';
import '../bloc/admission_event.dart';
import '../bloc/admission_state.dart';
import '../widgets/step_progress_header.dart';

class ReviewDetailsPage extends StatelessWidget {
  const ReviewDetailsPage({super.key});

  Widget _buildSummaryItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onEdit,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14.0),
          child: Row(
            children: [
              Container(
                width: 44.0,
                height: 44.0,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F3ED),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(icon, color: AppColors.primary, size: 22.0),
                ),
              ),
              const SizedBox(width: 14.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15.0,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3.0),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.0,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(6.0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Text(
                    'Edit',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 1.0, color: Color(0xFFF3F4F6)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F6),
      appBar: const CommonAppBar(
        title: 'Review Your Details',
        backgroundColor: Color(0xFFF7F8F6),
      ),
      body: BlocConsumer<AdmissionBloc, AdmissionState>(
        listener: (context, state) {
          if (state.status == AdmissionStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile completed successfully!'),
                backgroundColor: Color(0xFF146A4F),
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.dashboard,
              (route) => false,
            );
          } else if (state.status == AdmissionStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.errorMessage.isNotEmpty
                      ? state.errorMessage
                      : 'Failed to complete profile. Please try again.',
                ),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state.status == AdmissionStatus.submitting;

          return SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const StepProgressHeader(currentStep: 5),
                  const SizedBox(height: 20.0),

                  Text(
                    'Review Your Details',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20.0,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  Text(
                    'Please review all the information before submitting your application.',
                    style: AppTextStyles.welcomeSubtitle.copyWith(fontSize: 13.5),
                  ),
                  const SizedBox(height: 24.0),

                  // Summary Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
                    ),
                    child: Column(
                      children: [
                        _buildSummaryItem(
                          icon: Icons.person_rounded,
                          title: 'Personal Details',
                          subtitle: state.fullName.isNotEmpty ? state.fullName : 'Name',
                          onEdit: () => Navigator.of(context).pushNamed(AppRoutes.admissionPersonal),
                        ),
                        _buildSummaryItem(
                          icon: Icons.location_on_rounded,
                          title: 'Address & Emergency Contact',
                          subtitle: '${state.city}, ${state.state}',
                          onEdit: () => Navigator.of(context).pushNamed(AppRoutes.admissionAddress),
                        ),
                        _buildSummaryItem(
                          icon: Icons.description_rounded,
                          title: 'Documents',
                          subtitle: '${state.uploadedDocuments.length + 1} files uploaded',
                          onEdit: () => Navigator.of(context).pushNamed(AppRoutes.admissionDocuments),
                        ),
                        _buildSummaryItem(
                          icon: Icons.handshake_rounded,
                          title: 'Agreement',
                          subtitle: state.agreementAccepted ? 'accepted' : 'pending',
                          onEdit: () => Navigator.of(context).pushNamed(AppRoutes.admissionAgreement),
                          showDivider: false,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36.0),

                  CommonButton(
                    text: 'Submit Application',
                    isLoading: isLoading,
                    height: AppDimensions.buttonHeight,
                    borderRadius: AppDimensions.radiusFull,
                    backgroundColor: AppColors.primary,
                    onPressed: () {
                      context.read<AdmissionBloc>().add(const SubmitAdmissionApplication());
                    },
                  ),
                  const SizedBox(height: 24.0),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

