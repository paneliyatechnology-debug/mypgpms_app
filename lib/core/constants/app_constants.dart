/// Centralized application constants.
class AppConstants {
  AppConstants._();

  // App Identity & Versioning
  static const String appName = 'MYPGPMS';
  static const String appVersion = '1.0.0';
  static const int appVersionCode = 2;
  static const String buildNumber = '2';
  static const String appVersionDisplay = 'Version $appVersion (Build $appVersionCode)';
  static const String appVersionShort = 'v$appVersion ($appVersionCode)';

  static const int splashDurationMs = 2500;
  static const int otpLength = 6;
  static const int resendOtpSeconds = 45;
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
}

