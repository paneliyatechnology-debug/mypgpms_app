import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/colors/app_colors.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/storage/preferences_service.dart';
import '../../../../core/typography/app_text_styles.dart';
import '../../../../injection_container.dart' as di;
import '../widgets/splash_cottage_illustration.dart';

/// Pixel-perfect Splash Screen for MYPGPMS.
/// Checks persisted auth session and routes to Dashboard (Invitation) or Login.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(
      const Duration(milliseconds: AppConstants.splashDurationMs),
      _checkAuthAndNavigate,
    );
  }

  void _checkAuthAndNavigate() {
    if (!mounted) return;
    final prefService = di.sl<PreferencesService>();
    if (prefService.isLoggedIn) {
      if (!prefService.isCompleteProfile) {
        // When is_complete_profile = false -> show complete profile / invitation screen (First SS)
        Navigator.of(context).pushReplacementNamed(AppRoutes.invitation);
      } else {
        // When is_complete_profile = true -> show resident dashboard (Second SS)
        Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
      }
    } else {
      // No saved session -> Show Login Screen
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.splashBackground,
      body: SafeArea(
        bottom: false,
        child: GestureDetector(
          onTap: _checkAuthAndNavigate,
          behavior: HitTestBehavior.opaque,
          child: Column(
            children: [
              const Spacer(flex: 3),

              // 1. House Emblem (Figma: 94 x 80) - Preserved unchanged
              Image.asset(
                AppAssets.logoEmblem,
                width: 94.0,
                height: 80.0,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 16.0),

              // 2. MYPGPMS Wordmark
              Text(
                AppStrings.appName,
                style: AppTextStyles.h1.copyWith(
                  fontSize: 32.0,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16.0),

              // 3. Brand Tagline
              Text(
                AppStrings.appTagline,
                style: AppTextStyles.splashTagline,
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 4),

              // 4. Architectural House & Tree Illustration (Figma: 360 x 308)
              Flexible(
                flex: 12,
                child: Image.asset(
                  AppAssets.splashHouse,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomCenter,
                  errorBuilder: (context, error, stackTrace) {
                    return const SplashCottageIllustration(height: 240.0);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
