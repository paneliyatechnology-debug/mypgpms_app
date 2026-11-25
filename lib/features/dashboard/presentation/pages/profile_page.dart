import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../common/widgets/common_bottom_nav_bar.dart';
import '../../../../common/widgets/common_version_text.dart';
import '../../../../core/colors/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/storage/preferences_service.dart';
import '../../../../injection_container.dart' as di;
import '../../data/datasources/dashboard_remote_data_source.dart';
import '../../../authentication/data/datasources/auth_remote_data_source.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _savedUser;
  Map<String, dynamic>? _savedDashboard;

  @override
  void initState() {
    super.initState();
    _loadLocalData();
    _fetchFreshData();
  }

  void _loadLocalData() {
    try {
      final prefService = di.sl<PreferencesService>();
      setState(() {
        _savedUser = prefService.getSavedUser();
        _savedDashboard = prefService.getSavedDashboard();
      });
    } catch (_) {}
  }

  Future<void> _fetchFreshData() async {
    try {
      final prefService = di.sl<PreferencesService>();
      final authDataSource = di.sl<AuthRemoteDataSource>();

      try {
        final user = await authDataSource.getMe();
        final userMap = user.rawJson.isNotEmpty ? Map<String, dynamic>.from(user.rawJson) : user.toJson();
        await prefService.saveUserData(userMap);
      } catch (_) {}

      final dataSource = di.sl<DashboardRemoteDataSource>();
      final result = await dataSource.getDashboardData();
      if (result.data != null) {
        await prefService.saveDashboardData(result.data!.toJson());
      }

      if (mounted) {
        setState(() {
          _savedDashboard = prefService.getSavedDashboard();
          _savedUser = prefService.getSavedUser();
        });
      }
    } catch (_) {}
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        title: Text(
          'Logout',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 16.0,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to logout from MYPGPMS?',
          style: GoogleFonts.plusJakartaSans(fontSize: 13.0, color: const Color(0xFF4B5563)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6B7280),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
            ),
            onPressed: () async {
              final nav = Navigator.of(context);
              nav.pop();
              try {
                final prefService = di.sl<PreferencesService>();
                await prefService.clearAuth();
              } catch (_) {}
              if (mounted) {
                nav.pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
              }
            },
            child: Text(
              'Logout',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth > 600 ? (screenWidth - 460) / 2 : 16.0;

    // Dynamic data resolution
    final greeting = _savedDashboard?['greeting'] as Map<String, dynamic>?;
    final stay = _savedDashboard?['stay'] as Map<String, dynamic>?;
    final rentDue = _savedDashboard?['rent_due'] as Map<String, dynamic>?;
    final personalInfo = _savedUser?['personal_info'] as Map<String, dynamic>?;
    final roomInfo = _savedUser?['room_info'] as Map<String, dynamic>?;
    final paymentInfo = _savedUser?['payment_info'] as Map<String, dynamic>?;

    final String fullName = greeting?['resident_name']?.toString() ??
        _savedUser?['name']?.toString() ??
        personalInfo?['name']?.toString() ??
        'Kamil Patel';

    final String? photoUrl = greeting?['photo_url']?.toString() ??
        _savedUser?['profile_photo_url']?.toString() ??
        _savedUser?['profile_image_url']?.toString();

    final String residentId = _savedUser?['resident_id']?.toString() ??
        (_savedUser?['id'] != null ? 'CLV - ${_savedUser!['id']}' : 'CLV - 1024');

    final String roomNo = stay?['room_no']?.toString() ??
        roomInfo?['room_no']?.toString() ??
        'A-204';

    final String rawBed = stay?['bed_number']?.toString() ??
        roomInfo?['bed_number']?.toString() ??
        'B-2';
    final String bedNo = rawBed.startsWith('B-') ? rawBed : 'B-$rawBed';

    final String rent = rentDue?['formatted']?.toString() ??
        (rentDue?['amount'] != null
            ? '₹${rentDue!['amount']}/mo'
            : (paymentInfo?['rent'] != null
                ? '₹${paymentInfo!['rent']}/mo'
                : '₹12,000/mo'));

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8F6),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary, size: 22.0),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.dashboard, (route) => false);
            }
          },
        ),
        title: Text(
          'Profile',
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
          onRefresh: _fetchFreshData,
          color: AppColors.primary,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8.0),
            children: [
              // Top Profile Header
              Row(
                children: [
                  // Dynamic Avatar
                  Container(
                    width: 68.0,
                    height: 68.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.0),
                      color: const Color(0xFFE8F3ED),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 8.0,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: _buildAvatar(photoUrl, fullName),
                    ),
                  ),
                  const SizedBox(width: 14.0),

                  // Name & ID
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Verified pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDBEAFE),
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.verified_rounded,
                                size: 13.0,
                                color: Color(0xFF2563EB),
                              ),
                              const SizedBox(width: 4.0),
                              Text(
                                'Verified',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF2563EB),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          fullName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16.0,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          'Resident ID : $residentId',
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
              const SizedBox(height: 14.0),

              // Edit Profile Button
              InkWell(
                onTap: () async {
                  final result = await Navigator.of(context).pushNamed(AppRoutes.editProfile);
                  if (result == true || mounted) {
                    _loadLocalData();
                    _fetchFreshData();
                  }
                },
                borderRadius: BorderRadius.circular(999.0),
                child: Container(
                  width: double.infinity,
                  height: 44.0,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(999.0),
                  ),
                  child: Text(
                    'Edit Profile',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14.0),

              // Room / Bed / Rent Details Card (Dynamic)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14.0),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStayInfoColumn('Room No.', roomNo),
                    ),
                    Container(width: 1.0, height: 32.0, color: const Color(0xFFE5E7EB)),
                    Expanded(
                      child: _buildStayInfoColumn('Bed No.', bedNo),
                    ),
                    Container(width: 1.0, height: 32.0, color: const Color(0xFFE5E7EB)),
                    Expanded(
                      child: _buildStayInfoColumn('Rent', rent),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14.0),

              // Menu Items List Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
                ),
                child: Column(
                  children: [
                    _buildMenuItem(
                      icon: Icons.person_outline_rounded,
                      title: 'Personal Information',
                      onTap: () => Navigator.of(context).pushNamed(AppRoutes.personalInformation),
                    ),
                    const Divider(height: 1.0, indent: 52.0, color: Color(0xFFF3F4F6)),
                    _buildMenuItem(
                      icon: Icons.door_front_door_outlined,
                      title: 'Room & Property Details',
                      onTap: () => Navigator.of(context).pushNamed(AppRoutes.roomPropertyDetails),
                    ),
                    const Divider(height: 1.0, indent: 52.0, color: Color(0xFFF3F4F6)),
                    _buildMenuItem(
                      icon: Icons.description_outlined,
                      title: 'Document & Agreement',
                      onTap: () => Navigator.of(context).pushNamed(AppRoutes.documentsAgreement),
                    ),
                    const Divider(height: 1.0, indent: 52.0, color: Color(0xFFF3F4F6)),
                    _buildMenuItem(
                      icon: Icons.exit_to_app_rounded,
                      title: 'Checkout Request',
                      onTap: () => Navigator.of(context).pushNamed(AppRoutes.checkoutRequest),
                    ),
                    const Divider(height: 1.0, indent: 52.0, color: Color(0xFFF3F4F6)),
                    _buildMenuItem(
                      icon: Icons.contact_emergency_outlined,
                      title: 'Emergency Contact',
                      onTap: () => Navigator.of(context).pushNamed(AppRoutes.emergencyContact),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14.0),

              // Logout Card
              InkWell(
                onTap: _showLogoutDialog,
                borderRadius: BorderRadius.circular(14.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(14.0),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32.0,
                        height: 32.0,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.logout_rounded,
                          color: Color(0xFFEF4444),
                          size: 17.0,
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: Text(
                          'Logout',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 20.0,
                        color: Color(0xFFEF4444),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18.0),

              // Version Code & App Version
              const Center(
                child: CommonVersionText(showAppName: true),
              ),
              const SizedBox(height: 20.0),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CommonBottomNavBar(currentIndex: 4),
    );
  }

  Widget _buildAvatar(String? photoUrl, String fullName) {
    if (photoUrl == null || photoUrl.isEmpty) {
      return _buildAvatarFallback(fullName);
    }
    if (photoUrl.startsWith('http://') || photoUrl.startsWith('https://')) {
      return Image.network(
        photoUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildAvatarFallback(fullName),
      );
    }
    try {
      final file = File(photoUrl);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildAvatarFallback(fullName),
        );
      }
    } catch (_) {}
    return _buildAvatarFallback(fullName);
  }

  Widget _buildAvatarFallback(String fullName) {
    final initials = fullName.trim().isNotEmpty
        ? fullName
            .trim()
            .split(' ')
            .take(2)
            .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
            .join()
        : 'KP';

    return Container(
      color: const Color(0xFFE8F3ED),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 22.0,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildStayInfoColumn(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.0,
            color: const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.0,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        child: Row(
          children: [
            Container(
              width: 32.0,
              height: 32.0,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F3ED),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Icon(icon, color: AppColors.primary, size: 17.0),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20.0,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
