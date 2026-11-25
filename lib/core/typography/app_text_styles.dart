import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../colors/app_colors.dart';

/// Centralized typography and text styles for MYPGPMS.
class AppTextStyles {
  AppTextStyles._();

  // Headings
  static TextStyle h1 = GoogleFonts.plusJakartaSans(
    fontSize: 26.0,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
    height: 1.25,
  );

  static TextStyle welcomeTitle = GoogleFonts.plusJakartaSans(
    fontSize: 28.0,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
    height: 1.25,
  );

  static TextStyle h2 = GoogleFonts.plusJakartaSans(
    fontSize: 22.0,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
    height: 1.3,
  );

  static TextStyle h3 = GoogleFonts.plusJakartaSans(
    fontSize: 18.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
  );

  // Body & Subtitles
  static TextStyle bodyLarge = GoogleFonts.plusJakartaSans(
    fontSize: 16.0,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static TextStyle bodyMedium = GoogleFonts.plusJakartaSans(
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.45,
  );

  static TextStyle bodySmall = GoogleFonts.plusJakartaSans(
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    height: 1.4,
  );

  // Subtitles / Descriptions
  static TextStyle subtitle = GoogleFonts.plusJakartaSans(
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.45,
  );

  static TextStyle welcomeSubtitle = GoogleFonts.plusJakartaSans(
    fontSize: 15.0,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.45,
  );

  // Form Labels
  static TextStyle label = GoogleFonts.plusJakartaSans(
    fontSize: 13.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // Input & Hints
  static TextStyle input = GoogleFonts.plusJakartaSans(
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static TextStyle hint = GoogleFonts.plusJakartaSans(
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );

  // Buttons
  static TextStyle button = GoogleFonts.plusJakartaSans(
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textWhite,
    letterSpacing: 0.1,
  );

  static TextStyle buttonOutlined = GoogleFonts.plusJakartaSans(
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
    letterSpacing: 0.1,
  );

  // Links & Captions
  static TextStyle link = GoogleFonts.plusJakartaSans(
    fontSize: 13.0,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );

  static TextStyle linkSecondary = GoogleFonts.plusJakartaSans(
    fontSize: 13.0,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static TextStyle caption = GoogleFonts.plusJakartaSans(
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );

  static TextStyle error = GoogleFonts.plusJakartaSans(
    fontSize: 12.0,
    fontWeight: FontWeight.w500,
    color: AppColors.error,
  );

  // Tagline (Splash)
  static TextStyle splashTagline = GoogleFonts.plusJakartaSans(
    fontSize: 16.0,
    fontWeight: FontWeight.w700,
    color: const Color(0xFF165A42),
    letterSpacing: 0.1,
  );

  // Keypad
  static TextStyle keypadDigit = GoogleFonts.plusJakartaSans(
    fontSize: 24.0,
    fontWeight: FontWeight.w500,
    color: AppColors.keypadKeyText,
  );

  static TextStyle keypadLetters = GoogleFonts.plusJakartaSans(
    fontSize: 9.0,
    fontWeight: FontWeight.w600,
    color: AppColors.keypadSubText,
    letterSpacing: 1.5,
  );

  // OTP Digits
  static TextStyle otpDigit = GoogleFonts.plusJakartaSans(
    fontSize: 20.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
}
