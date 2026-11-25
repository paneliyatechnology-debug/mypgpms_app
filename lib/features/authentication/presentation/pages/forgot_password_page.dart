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
import '../../../../common/widgets/common_text_field.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/flying_plane_illustration.dart';

/// Pixel-perfect Forgot Password Screen matching Figma design.
/// Overflow-safe on all devices with keyboard open or closed.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _onSendResetLink() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            ForgotPasswordSubmitted(
              emailOrPhone: _emailController.text.trim(),
            ),
          );
    }
  }

  void _onLogIn() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = bottomInset > 0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.onboardingBackground,
      appBar: const CommonAppBar(
        backgroundColor: AppColors.onboardingBackground,
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            context.showSnackBar(state.message, isError: true);
          } else if (state is ForgotPasswordSuccess) {
            context.showSnackBar(
              state.message.isNotEmpty
                  ? state.message
                  : 'Password reset link has been sent to your email address.',
            );
            _onLogIn();
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Brand Logo
                            const CommonLogo(
                              iconSize: 34.0,
                              fontSize: 24.0,
                            ),
                            const SizedBox(height: 24.0),

                            // 2. Headline
                            Text(
                              AppStrings.forgotPasswordTitle,
                              style: AppTextStyles.welcomeTitle,
                            ),
                            const SizedBox(height: 8.0),

                            // 3. Subtitle
                            Text(
                              AppStrings.forgotPasswordSubtitle,
                              style: AppTextStyles.welcomeSubtitle,
                            ),
                            const SizedBox(height: 28.0),

                            // 4. Email Field
                            CommonTextField(
                              label: AppStrings.emailLabel,
                              hintText: AppStrings.emailHint,
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              validator: AppValidators.validateEmail,
                              borderRadius: 16.0,
                              fillColor: AppColors.white,
                            ),
                            const SizedBox(height: 24.0),

                            // 5. Pill Send Reset Link Button
                            CommonButton(
                              text: AppStrings.sendResetLink,
                              isLoading: isLoading,
                              height: AppDimensions.buttonHeight,
                              borderRadius: AppDimensions.radiusFull,
                              backgroundColor: AppColors.primary,
                              onPressed: _onSendResetLink,
                            ),

                            // 6. Flying Paper Airplane & Envelope Graphic
                            if (!isKeyboardOpen) ...[
                              const Spacer(),
                              Center(
                                child: Image.asset(
                                  AppAssets.forgotPasswordIllustration,
                                  width: 140.0,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const FlyingPlaneIllustration(
                                      width: 140.0,
                                      height: 100.0,
                                    );
                                  },
                                ),
                              ),
                              const Spacer(),
                            ] else ...[
                              const SizedBox(height: 32.0),
                            ],

                            // 7. Footer: Remember your password? Log In
                            Center(
                              child: GestureDetector(
                                onTap: _onLogIn,
                                child: RichText(
                                  text: TextSpan(
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: const Color(0xFF6B7280),
                                      fontSize: 14.0,
                                    ),
                                    children: [
                                      const TextSpan(text: "Remember your password? "),
                                      TextSpan(
                                        text: AppStrings.logIn,
                                        style: AppTextStyles.link.copyWith(
                                          color: AppColors.primary,
                                          fontSize: 14.0,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
