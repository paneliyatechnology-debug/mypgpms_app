import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/colors/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/typography/app_text_styles.dart';
import '../../../../common/widgets/common_app_bar.dart';
import '../../../../common/widgets/common_checkbox.dart';
import '../bloc/admission_bloc.dart';
import '../bloc/admission_event.dart';
import '../widgets/admission_nav_buttons.dart';
import '../widgets/signature_pad_widget.dart';
import '../widgets/step_progress_header.dart';

class AgreementSignaturePage extends StatefulWidget {
  const AgreementSignaturePage({super.key});

  @override
  State<AgreementSignaturePage> createState() => _AgreementSignaturePageState();
}

class _AgreementSignaturePageState extends State<AgreementSignaturePage> {
  final GlobalKey<SignaturePadWidgetState> _sigKey = GlobalKey<SignaturePadWidgetState>();
  bool _agreed = true;
  bool _hasSignature = true;

  @override
  void initState() {
    super.initState();
    final state = context.read<AdmissionBloc>().state;
    _agreed = state.agreementAccepted;
    _hasSignature = state.hasSignature;
  }

  Future<void> _onNext() async {
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the terms and conditions to proceed'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final sigPath = await _sigKey.currentState?.exportSignatureToFile();
    if (!mounted) return;
    context.read<AdmissionBloc>().add(ToggleAgreement(_agreed));
    context.read<AdmissionBloc>().add(UpdateSignature(_hasSignature, signaturePath: sigPath));
    Navigator.of(context).pushNamed(AppRoutes.admissionReview);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F6),
      appBar: const CommonAppBar(
        title: 'Agreement & Signature',
        backgroundColor: Color(0xFFF7F8F6),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StepProgressHeader(currentStep: 4),
              const SizedBox(height: 20.0),

              Text(
                'Terms & Conditions',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20.0,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6.0),
              Text(
                'Please read the agreement carefully. It includes house rules, payment terms, visitor policy and other important details.',
                style: AppTextStyles.welcomeSubtitle.copyWith(fontSize: 13.5),
              ),
              const SizedBox(height: 20.0),

              // Resident Agreement File Card
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44.0,
                      height: 44.0,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F3ED),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.picture_as_pdf_rounded,
                          color: Color(0xFF146A4F),
                          size: 22.0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MYPGPMS Resident Agreement',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3.0),
                          Text(
                            'PDF • 2.3 MB',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.0,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.primary,
                      size: 24.0,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20.0),

              // Agreement Checkbox
              CommonCheckbox(
                label: 'I agree to the terms and conditions of MYPGPMS PG and confirm that all information is correct.',
                value: _agreed,
                onChanged: (val) {
                  setState(() => _agreed = val ?? false);
                },
              ),
              const SizedBox(height: 28.0),

              // Digital Signature
              Text(
                'Digital Signature',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12.0),

              SignaturePadWidget(
                key: _sigKey,
                onSignatureChanged: (hasSig) {
                  _hasSignature = hasSig;
                },
              ),
              const SizedBox(height: 36.0),

              AdmissionNavButtons(
                onBack: () => Navigator.of(context).pop(),
                onNext: _onNext,
              ),
              const SizedBox(height: 24.0),
            ],
          ),
        ),
      ),
    );
  }
}
