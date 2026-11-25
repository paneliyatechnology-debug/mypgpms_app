import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/colors/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/dimensions/app_dimensions.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/typography/app_text_styles.dart';
import '../../../../core/utils/app_validators.dart';
import '../../../../common/widgets/common_app_bar.dart';
import '../../../../common/widgets/common_button.dart';
import '../../../../common/widgets/common_checkbox.dart';
import '../../../../common/widgets/common_logo.dart';
import '../../../../common/widgets/common_text_field.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// Pixel-perfect Login Screen for MYPGPMS.
/// Matches exact Figma spacing, input styling, colors, and pill button radii.
/// Overflow-safe on all screen sizes with keyboard open or closed.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLoginPressed() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            LoginSubmitted(
              emailOrPhone: _emailController.text.trim(),
              password: _passwordController.text,
              rememberMe: _rememberMe,
            ),
          );
    }
  }

  void _onForgotPasswordPressed() {
    Navigator.of(context).pushNamed(AppRoutes.forgotPassword);
  }

  @override
  Widget build(BuildContext context) {
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
          } else if (state is AuthLoginSuccess) {
            context.showSnackBar(state.message.isNotEmpty ? state.message : 'Login successful');
            if (!state.user.isCompleteProfile) {
              Navigator.of(context).pushReplacementNamed(AppRoutes.invitation);
            } else {
              Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
            }
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
                            // 1. Top Brand Logo
                            const CommonLogo(
                              iconSize: 34.0,
                              fontSize: 24.0,
                            ),
                            const SizedBox(height: 24.0),

                            // 2. Headline
                            Text(
                              AppStrings.welcomeBack,
                              style: AppTextStyles.welcomeTitle,
                            ),
                            const SizedBox(height: 8.0),

                            // 3. Subtitle
                            Text(
                              AppStrings.loginSubtitle,
                              style: AppTextStyles.welcomeSubtitle,
                            ),
                            const SizedBox(height: 28.0),

                            // 4. Email field
                            CommonTextField(
                              label: AppStrings.emailLabel,
                              hintText: AppStrings.emailHint,
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              validator: AppValidators.validateEmail,
                              borderRadius: 16.0,
                              fillColor: AppColors.white,
                            ),
                            const SizedBox(height: 18.0),

                            // 5. Password field
                            CommonTextField(
                              label: AppStrings.passwordLabel,
                              hintText: AppStrings.passwordHint,
                              controller: _passwordController,
                              obscureText: true,
                              validator: AppValidators.validatePassword,
                              borderRadius: 16.0,
                              fillColor: AppColors.white,
                            ),
                            const SizedBox(height: 14.0),

                            // 6. Remember Me & Forgot Password Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: CommonCheckbox(
                                    label: AppStrings.rememberMe,
                                    value: _rememberMe,
                                    onChanged: (val) {
                                      setState(() {
                                        _rememberMe = val ?? false;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8.0),
                                InkWell(
                                  onTap: _onForgotPasswordPressed,
                                  child: Text(
                                    AppStrings.forgotPassword,
                                    style: AppTextStyles.link.copyWith(
                                      color: AppColors.primary,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 28.0),

                            // 7. Pill Log In Button
                            CommonButton(
                              text: AppStrings.logIn,
                              isLoading: isLoading,
                              height: AppDimensions.buttonHeight,
                              borderRadius: AppDimensions.radiusFull,
                              backgroundColor: AppColors.primary,
                              onPressed: _onLoginPressed,
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
