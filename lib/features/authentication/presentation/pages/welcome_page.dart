import 'package:flutter/material.dart';
import '../../../../core/colors/app_colors.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/dimensions/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/typography/app_text_styles.dart';
import '../../../../common/widgets/common_button.dart';
import '../../../../common/widgets/common_logo.dart';

/// Pixel-perfect Welcome / Onboarding Screen with 3-slide carousel.
/// Matches exact Figma spacing, pill button shapes, colors, and authentic assets.
class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<String> _carouselImages = [
    AppAssets.onboardingRoom,
    AppAssets.roomImage2,
    AppAssets.roomImage3,
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onGetStarted() {
    Navigator.of(context).pushNamed(AppRoutes.phoneVerification);
  }

  void _onAlreadyHaveAccount() {
    Navigator.of(context).pushNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.onboardingBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Brand Logo (Horizontal header: Emblem + MYPGPMS)
              const CommonLogo(
                iconSize: 32.0,
                fontSize: 22.0,
              ),
              const SizedBox(height: 24.0),

              // 2. Bold Headline
              Text(
                AppStrings.welcomeTitle,
                style: AppTextStyles.welcomeTitle,
              ),
              const SizedBox(height: 12.0),

              // 3. Subtitle Description
              Text(
                AppStrings.welcomeSubtitle,
                style: AppTextStyles.welcomeSubtitle,
              ),
              const SizedBox(height: 20.0),

              // 4. Room Image Carousel Card
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _carouselImages.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return _buildCarouselCard(_carouselImages[index], isLocal: index == 0);
                  },
                ),
              ),
              const SizedBox(height: 16.0),

              // 5. Indicator Dots
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(_carouselImages.length, (index) {
                    final isActive = index == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                      width: 8.0,
                      height: 8.0,
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.dotActive : AppColors.dotInactive,
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 28.0),

              // 6. Pill Primary "Get Started" Button
              CommonButton(
                text: AppStrings.getStarted,
                height: AppDimensions.buttonHeight,
                borderRadius: AppDimensions.radiusFull,
                backgroundColor: AppColors.primary,
                onPressed: _onGetStarted,
              ),
              const SizedBox(height: 12.0),

              // 7. Pill Outlined "I already have an account" Button
              CommonButton.outlined(
                text: AppStrings.alreadyHaveAccount,
                height: AppDimensions.buttonHeight,
                borderRadius: AppDimensions.radiusFull,
                borderColor: AppColors.primary,
                textColor: AppColors.primary,
                backgroundColor: AppColors.white,
                onPressed: _onAlreadyHaveAccount,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCarouselCard(String imageSource, {required bool isLocal}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2.0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.0),
        child: isLocal
            ? Image.asset(
                imageSource,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                alignment: Alignment.center,
              )
            : Image.network(
                imageSource,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    AppAssets.onboardingRoom,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  );
                },
              ),
      ),
    );
  }
}
