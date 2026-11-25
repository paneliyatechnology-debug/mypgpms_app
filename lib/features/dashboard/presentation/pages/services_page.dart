import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../common/widgets/common_bottom_nav_bar.dart';
import '../../../../core/colors/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/storage/preferences_service.dart';
import '../../../../injection_container.dart' as di;
import '../../data/models/complaint_model.dart';

class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  List<Map<String, dynamic>> _getAllServices() {
    return [
      {
        'title': 'Maintenance',
        'subtitle': 'Complaints',
        'icon': Icons.handyman_outlined,
        'route': AppRoutes.reportIssue,
        'category': null,
      },
      {
        'title': 'Staff contact',
        'subtitle': 'Get in touch',
        'icon': Icons.group_outlined,
        'route': AppRoutes.staffDirectory,
        'category': null,
      },
      {
        'title': 'Room shift',
        'subtitle': 'Request change',
        'icon': Icons.bed_outlined,
        'route': AppRoutes.roomShift,
        'category': null,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth > 600 ? (screenWidth - 460) / 2 : 16.0;
    final canPop = Navigator.of(context).canPop();
    final allServices = _getAllServices();

    ComplaintItemModel? latestComplaint;
    try {
      final prefService = di.sl<PreferencesService>();
      final cached = prefService.getSavedComplaintsList();
      if (cached != null && cached.isNotEmpty) {
        latestComplaint = ComplaintItemModel.fromJson(cached.first);
      }
    } catch (_) {}

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8F6),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary, size: 20.0),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: Text(
          'Services',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18.0,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async => await Future.delayed(const Duration(milliseconds: 400)),
          color: AppColors.primary,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8.0),
            children: [
              // 1. Need any support? Top Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F3ED),
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56.0,
                      height: 56.0,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.support_agent_rounded,
                        color: AppColors.primary,
                        size: 32.0,
                      ),
                    ),
                    const SizedBox(width: 14.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Need any support?',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15.0,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 3.0),
                          Text(
                            "We're here to help!",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.0,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18.0),

              // 2. Our services Section
              Text(
                'Our services',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12.0),

              // Services 3-column Grid
              Wrap(
                spacing: 12.0,
                runSpacing: 12.0,
                children: allServices.map((item) {
                  final availableWidth = screenWidth > 600 ? 460.0 : screenWidth - 32.0;
                  final cardWidth = (availableWidth - 24.0) / 3;
                  return SizedBox(
                    width: cardWidth,
                    child: InkWell(
                      onTap: () {
                        final route = item['route'] as String;
                        final category = item['category'] as String?;
                        Navigator.of(context).pushNamed(route, arguments: category);
                      },
                      borderRadius: BorderRadius.circular(16.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 8.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.0),
                          border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x04000000),
                              blurRadius: 6.0,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 48.0,
                              height: 48.0,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE8F3ED),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                item['icon'] as IconData,
                                color: AppColors.primary,
                                size: 24.0,
                              ),
                            ),
                            const SizedBox(height: 10.0),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                item['title'] as String,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 3.0),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                item['subtitle'] as String,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  color: const Color(0xFF9CA3AF),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18.0),

              // 3. My Complaints Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My Complaints',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.of(context).pushNamed(AppRoutes.myComplaints);
                    },
                    child: Row(
                      children: [
                        Text(
                          'View my complaints',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.0,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 2.0),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 11.0, color: AppColors.primary),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10.0),

              // Complaint Card
              InkWell(
                onTap: () {
                  if (latestComplaint != null) {
                    Navigator.of(context).pushNamed(
                      AppRoutes.complaintDetails,
                      arguments: latestComplaint,
                    );
                  } else {
                    Navigator.of(context).pushNamed(AppRoutes.myComplaints);
                  }
                },
                borderRadius: BorderRadius.circular(14.0),
                child: Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14.0),
                    border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x04000000),
                        blurRadius: 6.0,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36.0,
                            height: 36.0,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE8F3ED),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              latestComplaint?.categoryIcon ?? Icons.wifi_rounded,
                              color: AppColors.primary,
                              size: 18.0,
                            ),
                          ),
                          const SizedBox(width: 12.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  latestComplaint?.displayId ?? '#CL-1024',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.0,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2.0),
                                Text(
                                  latestComplaint?.title ?? 'WiFi not working',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.5,
                                    color: const Color(0xFF4B5563),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9.0, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: latestComplaint?.statusBgColor ?? const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                            child: Text(
                              latestComplaint?.displayStatus ?? 'In Progress',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.0,
                                fontWeight: FontWeight.w700,
                                color: latestComplaint?.statusTextColor ?? const Color(0xFF4F46E5),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6.0),
                      Padding(
                        padding: const EdgeInsets.only(left: 48.0),
                        child: Text(
                          latestComplaint?.displayLocation ?? 'Room A-204  •  05 march 2026, 10:30 AM',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.0,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20.0),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CommonBottomNavBar(currentIndex: 2),
    );
  }
}
