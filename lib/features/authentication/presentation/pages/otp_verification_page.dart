import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/colors/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/dimensions/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/typography/app_text_styles.dart';
import '../../../../common/widgets/common_app_bar.dart';
import '../../../../common/widgets/common_button.dart';
import '../../../../common/widgets/common_keypad.dart';
import '../../../../common/widgets/common_logo.dart';
import '../../../../common/widgets/common_otp_input.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// Pixel-perfect OTP Verification Screen with 6-digit input, timer & custom keypad.
class OtpVerificationPage extends StatefulWidget {
  final String? phoneNumber;

  const OtpVerificationPage({
    super.key,
    this.phoneNumber,
  });

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  String _otp = '';
  late int _remainingSeconds;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = AppConstants.resendOtpSeconds;
    _startTimer();
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _onDigitPressed(String digit) {
    if (_otp.length < AppConstants.otpLength) {
      setState(() {
        _otp += digit;
      });
    }
  }

  void _onBackspacePressed() {
    if (_otp.isNotEmpty) {
      setState(() {
        _otp = _otp.substring(0, _otp.length - 1);
      });
    }
  }

  void _onVerifyPressed() {
    if (_otp.length == AppConstants.otpLength) {
      final phone = widget.phoneNumber ?? AppStrings.samplePhoneNumber;
      context.read<AuthBloc>().add(
            OtpSubmitted(phoneNumber: phone, otp: _otp),
          );
    } else {
      context.showSnackBar('Please enter the 6-digit code', isError: true);
    }
  }

  void _onResendPressed() {
    if (_remainingSeconds == 0) {
      final phone = widget.phoneNumber ?? AppStrings.samplePhoneNumber;
      context.read<AuthBloc>().add(OtpResendRequested(phoneNumber: phone));
      setState(() {
        _remainingSeconds = AppConstants.resendOtpSeconds;
      });
      _startTimer();
    }
  }

  String _formatTimer(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final displayPhone = widget.phoneNumber ?? AppStrings.samplePhoneNumber;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CommonAppBar(),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            context.showSnackBar(state.message, isError: true);
          } else if (state is OtpResentSuccess) {
            context.showSnackBar(state.message);
          } else if (state is OtpVerificationSuccess) {
            context.showSnackBar('Phone verified successfully!');
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: AppDimensions.screenPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Brand Logo
                        const CommonLogo(
                          iconSize: 26.0,
                          fontSize: 20.0,
                        ),
                        const SizedBox(height: AppDimensions.p20),

                        // Title
                        Text(
                          AppStrings.verifyYourNumber,
                          style: AppTextStyles.h1,
                        ),
                        const SizedBox(height: AppDimensions.p6),

                        // Subtitle & Phone Number
                        Text(
                          AppStrings.otpSentSubtitle,
                          style: AppTextStyles.subtitle,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          displayPhone,
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.p28),

                        // 6-digit OTP Inputs
                        CommonOtpInput(
                          value: _otp,
                          length: AppConstants.otpLength,
                        ),
                        const SizedBox(height: AppDimensions.p16),

                        // Resend Code Countdown
                        Center(
                          child: _remainingSeconds > 0
                              ? RichText(
                                  text: TextSpan(
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                    children: [
                                      const TextSpan(text: AppStrings.resendCodeIn),
                                      TextSpan(
                                        text: _formatTimer(_remainingSeconds),
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : GestureDetector(
                                  onTap: _onResendPressed,
                                  child: Text(
                                    AppStrings.resendCode,
                                    style: AppTextStyles.link,
                                  ),
                                ),
                        ),
                        const SizedBox(height: AppDimensions.p24),

                        // Verify Button
                        CommonButton(
                          text: AppStrings.verify,
                          isLoading: isLoading,
                          onPressed: _onVerifyPressed,
                        ),
                      ],
                    ),
                  ),
                ),

                // In-App Numeric Keypad
                CommonKeypad(
                  onDigitPressed: _onDigitPressed,
                  onBackspacePressed: _onBackspacePressed,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
