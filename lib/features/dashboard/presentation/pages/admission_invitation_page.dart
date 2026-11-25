import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/colors/app_colors.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/dimensions/app_dimensions.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/storage/preferences_service.dart';
import '../../../../core/typography/app_text_styles.dart';
import '../../../../injection_container.dart' as di;
import '../../../../common/widgets/common_button.dart';
import '../../../../common/widgets/common_logo.dart';

/// Responsive, pixel-perfect Admission Invitation Screen.
/// 100% matched with Figma design system.
class AdmissionInvitationPage extends StatelessWidget {
  const AdmissionInvitationPage({super.key});

  static String _formatRoomType(String? rawType) {
    if (rawType == null || rawType.trim().isEmpty) {
      return AppStrings.roomTypeSample;
    }
    final clean = rawType.trim();
    final lower = clean.toLowerCase();

    if (lower == 'triple' || lower == 'triple sharing' || lower == 'sharing triple') {
      return 'Triple Sharing';
    } else if (lower == 'double' || lower == 'double sharing' || lower == 'sharing double') {
      return 'Double Sharing';
    } else if (lower == 'single' || lower == 'single room' || lower == 'single sharing') {
      return 'Single Room';
    } else if (lower == 'four' || lower == 'quad' || lower == 'four sharing') {
      return 'Four Sharing';
    }

    final words = clean.split(RegExp(r'[\s_]+')).map((w) {
      if (w.isEmpty) return '';
      return '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}';
    }).toList();

    final result = words.join(' ');
    if (!result.toLowerCase().contains('sharing') && !result.toLowerCase().contains('room')) {
      return '$result Sharing';
    }
    return result;
  }

  void _onStartApplication(BuildContext context) {
    Navigator.of(context).pushNamed(AppRoutes.admissionPersonal);
  }

  void _onNeedHelp(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10.0),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F3ED),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.support_agent_rounded,
                        color: AppColors.primary,
                        size: 24.0,
                      ),
                    ),
                    const SizedBox(width: 14.0),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Need Assistance?',
                          style: AppTextStyles.h3.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          'Contact MYPGPMS PG Support',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20.0),
                ListTile(
                  leading: const Icon(Icons.phone_outlined, color: AppColors.primary),
                  title: const Text('Call PG Manager'),
                  subtitle: const Text('+91 98765 43210'),
                  onTap: () => Navigator.pop(context),
                  contentPadding: EdgeInsets.zero,
                ),
                ListTile(
                  leading: const Icon(Icons.mail_outline_rounded, color: AppColors.primary),
                  title: const Text('Email Support'),
                  subtitle: const Text('support@mypgpms.com'),
                  onTap: () => Navigator.pop(context),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;

    final savedUser = di.sl<PreferencesService>().getSavedUser();
    final pg = savedUser?['pg'] as Map<String, dynamic>?;
    final roomInfo = savedUser?['room_info'] as Map<String, dynamic>?;

    final propertyName = (roomInfo?['pg_name'] ?? pg?['name'])?.toString() ?? AppStrings.propertyNameSample;
    final propertyCity = (roomInfo?['branch_name'] ?? pg?['city'])?.toString() ?? AppStrings.propertyCitySample;

    final buildingNameRaw = roomInfo?['building_name']?.toString() ?? '';
    final buildingDisplay = buildingNameRaw.isNotEmpty
        ? (buildingNameRaw.toLowerCase().contains('block') || buildingNameRaw.toLowerCase().contains('building')
            ? buildingNameRaw
            : 'Building $buildingNameRaw')
        : '';

    final floorRaw = (roomInfo?['floor_name'] ?? (roomInfo?['floor_number'] != null ? 'Floor ${roomInfo!['floor_number']}' : null))?.toString() ?? '';
    final floorDisplay = floorRaw;

    final roomRaw = roomInfo?['room_no']?.toString();
    final roomDisplay = roomRaw != null && roomRaw.isNotEmpty
        ? (roomRaw.toLowerCase().contains('room') ? roomRaw : 'Room $roomRaw')
        : AppStrings.roomSample;

    final bedRaw = roomInfo?['bed_number']?.toString();
    final bedDisplay = bedRaw != null && bedRaw.isNotEmpty
        ? (bedRaw.toLowerCase().contains('bed') ? bedRaw : 'Bed $bedRaw')
        : AppStrings.bedSample;

    final roomTypeDisplay = _formatRoomType(roomInfo?['room_type']?.toString());
    final rentRaw = roomInfo?['monthly_rent'];
    final rentDisplay = rentRaw != null ? 'Rs. $rentRaw/month' : AppStrings.rentSample;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F6),
      body: Stack(
        children: [
          // 1. Full-width photographic building background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeight * 0.65,
            child: Image.asset(
              AppAssets.invitationBuilding,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFFE2EFE7),
                  child: const Center(
                    child: Icon(
                      Icons.apartment_rounded,
                      size: 80.0,
                      color: AppColors.primary,
                    ),
                  ),
                );
              },
            ),
          ),

          // 2. Foreground content with responsive layout pushing card to bottom
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Brand Section (Emblem + MYPGPMS + Tagline)
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 20.0,
                              top: 14.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const CommonLogo(
                                  iconSize: 34.0,
                                  fontSize: 24.0,
                                ),
                                const SizedBox(height: 4.0),
                                Padding(
                                  padding: const EdgeInsets.only(left: 2.0),
                                  child: Text(
                                    AppStrings.appTagline,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF165A42),
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Flexible spacer so the card sits perfectly at the bottom
                          const Spacer(),

                          // Floating White Invitation Card
                          Container(
                            width: double.infinity,
                            margin: EdgeInsets.symmetric(
                              horizontal: screenWidth > 600 ? (screenWidth - 460) / 2 : 16.0,
                              vertical: 16.0,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20.0,
                              vertical: 22.0,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 28.0,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Badge: Invitation Pill
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10.0,
                                    vertical: 5.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD6EAE0),
                                    borderRadius: BorderRadius.circular(20.0),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 24.0,
                                        height: 24.0,
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.mail_rounded,
                                          color: Colors.white,
                                          size: 13.0,
                                        ),
                                      ),
                                      const SizedBox(width: 8.0),
                                      Text(
                                        AppStrings.invitation,
                                        style: GoogleFonts.plusJakartaSans(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13.0,
                                        ),
                                      ),
                                      const SizedBox(width: 4.0),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16.0),

                                // Headline: "You are invited to join MYPGPMS!"
                                Text(
                                  AppStrings.invitedTitle,
                                  style: AppTextStyles.welcomeTitle.copyWith(
                                    fontSize: 25.0,
                                    height: 1.25,
                                  ),
                                ),
                                const SizedBox(height: 8.0),

                                // Subtitle
                                Text(
                                  AppStrings.invitedSubtitle,
                                  style: AppTextStyles.welcomeSubtitle.copyWith(
                                    fontSize: 13.5,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 18.0),

                                // Property & Room Card
                                Container(
                                  padding: const EdgeInsets.all(15.0),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16.0),
                                    border: Border.all(
                                      color: const Color(0xFFE5E7EB),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Row 1: Pin icon + Property Name & City
                                      Row(
                                        children: [
                                          Container(
                                            width: 42.0,
                                            height: 42.0,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFE8F3ED),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.location_on_rounded,
                                              color: AppColors.primary,
                                              size: 22.0,
                                            ),
                                          ),
                                          const SizedBox(width: 12.0),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  propertyName,
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 15.5,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                                const SizedBox(height: 2.0),
                                                Text(
                                                  propertyCity,
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 13.0,
                                                    fontWeight: FontWeight.w400,
                                                    color: AppColors.textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10.0),

                                      // Row 2: Building & Floor (if available)
                                      if (buildingDisplay.isNotEmpty || floorDisplay.isNotEmpty) ...[
                                        Row(
                                          children: [
                                            const SizedBox(width: 54.0),
                                            if (buildingDisplay.isNotEmpty)
                                              Text(
                                                buildingDisplay,
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 13.0,
                                                  fontWeight: FontWeight.w500,
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                            if (buildingDisplay.isNotEmpty && floorDisplay.isNotEmpty)
                                              Container(
                                                margin: const EdgeInsets.symmetric(horizontal: 10.0),
                                                width: 1.0,
                                                height: 12.0,
                                                color: const Color(0xFFD1D5DB),
                                              ),
                                            if (floorDisplay.isNotEmpty)
                                              Text(
                                                floorDisplay,
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 13.0,
                                                  fontWeight: FontWeight.w500,
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 5.0),
                                      ],

                                      // Row 3: Room & Bed
                                      Row(
                                        children: [
                                          const SizedBox(width: 54.0),
                                          Text(
                                            roomDisplay,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          Container(
                                            margin: const EdgeInsets.symmetric(horizontal: 10.0),
                                            width: 1.0,
                                            height: 14.0,
                                            color: const Color(0xFFD1D5DB),
                                          ),
                                          Text(
                                            bedDisplay,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14.0),
                                      const Divider(height: 1.0, color: Color(0xFFF3F4F6)),
                                      const SizedBox(height: 14.0),

                                      // Row 4: Dynamic Room Type (e.g. Triple Sharing) & Rent
                                      Row(
                                        children: [
                                          // Dynamic Sharing Room
                                          Expanded(
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  width: 28.0,
                                                  height: 28.0,
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFE8F3ED),
                                                    borderRadius: BorderRadius.circular(8.0),
                                                  ),
                                                  child: const Icon(
                                                    Icons.single_bed_outlined,
                                                    color: AppColors.primary,
                                                    size: 17.0,
                                                  ),
                                                ),
                                                const SizedBox(width: 8.0),
                                                Flexible(
                                                  child: Text(
                                                    roomTypeDisplay,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: GoogleFonts.plusJakartaSans(
                                                      fontSize: 12.0,
                                                      fontWeight: FontWeight.w600,
                                                      color: AppColors.textPrimary,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          Container(
                                            margin: const EdgeInsets.symmetric(horizontal: 8.0),
                                            width: 1.0,
                                            height: 22.0,
                                            color: const Color(0xFFF3F4F6),
                                          ),

                                          // Rent Amount
                                          Expanded(
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  width: 28.0,
                                                  height: 28.0,
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFE8F3ED),
                                                    borderRadius: BorderRadius.circular(8.0),
                                                  ),
                                                  child: const Icon(
                                                    Icons.receipt_long_outlined,
                                                    color: AppColors.primary,
                                                    size: 17.0,
                                                  ),
                                                ),
                                                const SizedBox(width: 8.0),
                                                Flexible(
                                                  child: Text(
                                                    rentDisplay,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: GoogleFonts.plusJakartaSans(
                                                      fontSize: 12.0,
                                                      fontWeight: FontWeight.w600,
                                                      color: AppColors.textPrimary,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 22.0),

                                // Action Button: Start Application
                                CommonButton(
                                  text: AppStrings.startApplication,
                                  height: AppDimensions.buttonHeight,
                                  borderRadius: AppDimensions.radiusFull,
                                  backgroundColor: AppColors.primary,
                                  onPressed: () => _onStartApplication(context),
                                ),
                                const SizedBox(height: 18.0),

                                // Need help? Link
                                Center(
                                  child: InkWell(
                                    onTap: () => _onNeedHelp(context),
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12.0,
                                        vertical: 4.0,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.headset_mic_outlined,
                                            color: AppColors.primary,
                                            size: 19.0,
                                          ),
                                          const SizedBox(width: 8.0),
                                          Text(
                                            AppStrings.needHelp,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 14.0,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4.0),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
