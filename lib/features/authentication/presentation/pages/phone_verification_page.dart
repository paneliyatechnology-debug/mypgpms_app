import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/colors/app_colors.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/dimensions/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/typography/app_text_styles.dart';
import '../../../../core/utils/app_validators.dart';
import '../../../../common/widgets/common_app_bar.dart';
import '../../../../common/widgets/common_button.dart';
import '../../../../common/widgets/common_logo.dart';
import '../../../../common/widgets/common_phone_field.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/phone_signal_illustration.dart';

/// Pixel-perfect Phone Number Verification Screen.
/// Matches exact Figma spacing, inputs, colors, and pill button radii.
class PhoneVerificationPage extends StatefulWidget {
  const PhoneVerificationPage({super.key});

  @override
  State<PhoneVerificationPage> createState() => _PhoneVerificationPageState();
}

class _PhoneVerificationPageState extends State<PhoneVerificationPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final String _selectedCountryCode = '+91';

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _onContinue() {
    if (_formKey.currentState?.validate() ?? false) {
      final fullPhoneNumber = '$_selectedCountryCode ${_phoneController.text.trim()}';
      context.read<AuthBloc>().add(
            PhoneVerificationSubmitted(phoneNumber: fullPhoneNumber),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.onboardingBackground,
      appBar: const CommonAppBar(
        backgroundColor: AppColors.onboardingBackground,
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            context.showSnackBar(state.message, isError: true);
          } else if (state is PhoneVerificationSuccess) {
            Navigator.of(context).pushNamed(
              AppRoutes.otpVerification,
              arguments: state.phoneNumber,
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Top Brand Logo
                    const CommonLogo(
                      iconSize: 34.0,
                      fontSize: 24.0,
                    ),
                    const SizedBox(height: 24.0),

                    // 2. Headline
                    Text(
                      AppStrings.verifyYourNumber,
                      style: AppTextStyles.welcomeTitle,
                    ),
                    const SizedBox(height: 8.0),

                    // 3. Subtitle
                    Text(
                      AppStrings.verifyPhoneSubtitle,
                      style: AppTextStyles.welcomeSubtitle,
                    ),
                    const SizedBox(height: 32.0),

                    // 4. Phone Input with Country Code & Error Handling
                    CommonPhoneField(
                      label: AppStrings.enterPhoneNumber,
                      controller: _phoneController,
                      countryCode: _selectedCountryCode,
                      hintText: AppStrings.phoneNumberHint,
                      validator: AppValidators.validatePhoneNumber,
                    ),
                    const SizedBox(height: 28.0),

                    // 6. Pill Continue Button
                    CommonButton(
                      text: AppStrings.continueBtn,
                      isLoading: isLoading,
                      height: AppDimensions.buttonHeight,
                      borderRadius: AppDimensions.radiusFull,
                      backgroundColor: AppColors.primary,
                      onPressed: _onContinue,
                    ),

                    const Spacer(),

                    // 7. Bottom Phone Signal Graphic
                    Center(
                      child: Image.asset(
                        AppAssets.phoneIllustration,
                        width: 110.0,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const PhoneSignalIllustration(size: 90.0);
                        },
                      ),
                    ),
                    const SizedBox(height: 48.0),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
