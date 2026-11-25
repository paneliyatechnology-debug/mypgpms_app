import 'package:flutter/material.dart';

/// Centralized dimensions, paddings, border radiuses, and sizes.
class AppDimensions {
  AppDimensions._();

  // Spacing & Padding
  static const double p2 = 2.0;
  static const double p4 = 4.0;
  static const double p6 = 6.0;
  static const double p8 = 8.0;
  static const double p12 = 12.0;
  static const double p14 = 14.0;
  static const double p16 = 16.0;
  static const double p20 = 20.0;
  static const double p24 = 24.0;
  static const double p28 = 28.0;
  static const double p32 = 32.0;
  static const double p40 = 40.0;
  static const double p48 = 48.0;

  // Screen Padding
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 24.0);
  static const EdgeInsets screenPaddingWithTop = EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 24.0);

  // Border Radii
  static const double radiusXS = 4.0;
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusCard = 24.0;
  static const double radiusFull = 999.0;

  static const BorderRadius borderRadiusXS = BorderRadius.all(Radius.circular(radiusXS));
  static const BorderRadius borderRadiusS = BorderRadius.all(Radius.circular(radiusS));
  static const BorderRadius borderRadiusM = BorderRadius.all(Radius.circular(radiusM));
  static const BorderRadius borderRadiusL = BorderRadius.all(Radius.circular(radiusL));
  static const BorderRadius borderRadiusXL = BorderRadius.all(Radius.circular(radiusXL));
  static const BorderRadius borderRadiusCard = BorderRadius.all(Radius.circular(radiusCard));
  static const BorderRadius borderRadiusFull = BorderRadius.all(Radius.circular(radiusFull));

  // Component Heights
  static const double buttonHeight = 56.0;
  static const double inputHeight = 52.0;
  static const double socialButtonHeight = 50.0;
  static const double appBarHeight = 56.0;
  static const double otpBoxSize = 48.0;

  // Icon Sizes
  static const double iconXS = 16.0;
  static const double iconS = 20.0;
  static const double iconM = 24.0;
  static const double iconL = 28.0;
  static const double iconXL = 36.0;
}
