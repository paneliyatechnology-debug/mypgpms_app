import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../common/widgets/common_logo.dart';
import '../../../../core/colors/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/storage/preferences_service.dart';
import '../../../../injection_container.dart' as di;

class DigitalIdPage extends StatelessWidget {
  const DigitalIdPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth > 600 ? (screenWidth - 460) / 2 : 16.0;

    // Load dynamic resident data
    final prefService = di.sl<PreferencesService>();
    final savedUser = prefService.getSavedUser();
    final personalInfo = savedUser?['personal_info'] as Map<String, dynamic>?;
    final roomInfo = savedUser?['room_info'] as Map<String, dynamic>?;
    final contactInfo = savedUser?['contact_info'] as Map<String, dynamic>?;

    final String fullName = (savedUser?['name'] ?? personalInfo?['name'])?.toString() ?? 'Kamil Patel';
    final String residentId = 'CLV - ${savedUser?['id'] ?? 1024}';
    final String propertyName = (roomInfo?['pg_name'] ?? roomInfo?['building_name'] ?? savedUser?['pg']?['name'])?.toString() ?? 'MYPGPMS Green Park';
    final String roomNo = roomInfo?['room_no']?.toString() ?? 'A-204';
    final String bedNo = roomInfo?['bed_number']?.toString() ?? 'B-2';
    final String branch = contactInfo?['city']?.toString() ?? 'Ahmedabad';
    final String? photoUrl = (savedUser?['profile_photo_url'] ?? savedUser?['profile_image_url']) as String?;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8F6),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary, size: 20.0),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Digital Resident ID',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18.0,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 10.0),
          child: Column(
            children: [
              // Main Digital ID Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18.0),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0C000000),
                      blurRadius: 16.0,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Card Top Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F3ED),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(17.0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CommonLogo(
                            iconSize: 24.0,
                            fontSize: 18.0,
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            AppStrings.appTagline,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.0,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Card Body
                    Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        children: [
                          // Resident Profile Row
                          Row(
                            children: [
                              Container(
                                width: 58.0,
                                height: 58.0,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFFE5E7EB), width: 2.0),
                                  color: const Color(0xFFE8F3ED),
                                ),
                                child: ClipOval(
                                  child: _buildAvatar(photoUrl, fullName),
                                ),
                              ),
                              const SizedBox(width: 14.0),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      fullName,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2.0),
                                    Text(
                                      'Resident ID : $residentId',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12.5,
                                        color: const Color(0xFF6B7280),
                                      ),
                                    ),
                                    const SizedBox(height: 5.0),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 9.0, vertical: 3.0),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2563EB),
                                        borderRadius: BorderRadius.circular(6.0),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 13.0),
                                          const SizedBox(width: 4.0),
                                          Text(
                                            'Verified',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11.0,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14.0),

                          // Key-Value Table Rows
                          _buildIdTableRow('Property', propertyName),
                          _buildIdTableRow('Room No.', roomNo),
                          _buildIdTableRow('Bed No.', bedNo),
                          _buildIdTableRow('Branch', branch),
                          _buildIdTableRow('Valid till', '31 Dec 2026'),
                          const SizedBox(height: 16.0),

                          // QR Code for verification
                          Container(
                            width: 160.0,
                            height: 160.0,
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14.0),
                              border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.qr_code_2_rounded,
                                size: 140.0,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10.0),

                          Text(
                            'Scan this QR code for verification',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.0,
                              color: const Color(0xFF9CA3AF),
                            ),
                          ),
                          const SizedBox(height: 6.0),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIdTableRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9.0),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1.0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.0,
              color: const Color(0xFF6B7280),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.0,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String? photoUrl, String name) {
    if (photoUrl != null && photoUrl.isNotEmpty) {
      if (photoUrl.startsWith('http://') || photoUrl.startsWith('https://')) {
        return Image.network(
          photoUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _fallbackAvatar(name),
        );
      }
      try {
        final file = File(photoUrl);
        if (file.existsSync()) {
          return Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _fallbackAvatar(name),
          );
        }
      } catch (_) {}
    }
    return _fallbackAvatar(name);
  }

  Widget _fallbackAvatar(String name) {
    final initials = name.trim().isNotEmpty ? name.trim().split(' ').map((e) => e[0]).take(2).join() : 'U';
    return Center(
      child: Text(
        initials,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 22.0,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
