import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../common/widgets/common_bottom_nav_bar.dart';
import '../../../../common/widgets/common_logo.dart';
import '../../../../core/colors/app_colors.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/socket_service.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/storage/preferences_service.dart';
import '../../../../injection_container.dart' as di;
import '../../data/datasources/dashboard_remote_data_source.dart';
import '../../data/models/complaint_model.dart';
import '../../data/models/dashboard_response_model.dart';

/// Pixel-perfect, responsive Resident Dashboard Screen.
/// Fully integrated with GET /dashboard API, real-time caching, and graceful null handling.
class ResidentDashboardPage extends StatefulWidget {
  const ResidentDashboardPage({super.key});

  @override
  State<ResidentDashboardPage> createState() => _ResidentDashboardPageState();
}

class _ResidentDashboardPageState extends State<ResidentDashboardPage> {
  bool _isLoading = true;
  String? _errorMessage;
  DashboardDataModel? _dashboardData;
  Timer? _dashboardAutoSyncTimer;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _setupSocketListeners();
    // Auto-sync polling every 12 seconds to ensure fresh dashboard stats
    _dashboardAutoSyncTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      if (mounted) {
        _fetchDashboardData(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _dashboardAutoSyncTimer?.cancel();
    _teardownSocketListeners();
    super.dispose();
  }

  void _setupSocketListeners() {
    try {
      final socket = di.sl<SocketService>();
      socket.connect();
      socket.on(SocketEvents.dashboardStatsUpdated, _onDashboardStatsEvent);
      socket.onAny(_onSocketAnyEvent);
    } catch (_) {}
  }

  void _teardownSocketListeners() {
    try {
      final socket = di.sl<SocketService>();
      socket.off(SocketEvents.dashboardStatsUpdated, _onDashboardStatsEvent);
      socket.offAny(_onSocketAnyEvent);
    } catch (_) {}
  }

  void _onDashboardStatsEvent(dynamic data) {
    if (!mounted) return;
    debugPrint('[ResidentDashboardPage] Dashboard stats updated via socket.');
    _fetchDashboardData(silent: true);
  }

  void _onSocketAnyEvent(String event, dynamic data) {
    if (!mounted) return;
    final lower = event.toLowerCase();
    // Any mutation event dispatched by backend admin triggers silent dashboard refresh
    if (lower.contains('stats') ||
        lower.contains('dashboard') ||
        lower.contains('visitor') ||
        lower.contains('complaint') ||
        lower.contains('notice') ||
        lower.contains('payment') ||
        lower.contains('stay') ||
        lower.contains('room')) {
      debugPrint('[ResidentDashboardPage] Real-time event "$event" triggered silent refresh.');
      _fetchDashboardData(silent: true);
    }
  }

  void _loadInitialData() {
    final prefService = di.sl<PreferencesService>();
    final cached = prefService.getSavedDashboard();
    if (cached != null) {
      try {
        _dashboardData = DashboardDataModel.fromJson(cached);
        _isLoading = false;
      } catch (_) {}
    }
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData({bool silent = false}) async {
    if (!silent || _dashboardData == null) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final dataSource = di.sl<DashboardRemoteDataSource>();
      final result = await dataSource.getDashboardData();
      if (mounted) {
        setState(() {
          _dashboardData = result.data;
          _isLoading = false;
          _errorMessage = null;
        });
        if (result.data != null) {
          final prefService = di.sl<PreferencesService>();
          await prefService.saveDashboardData(result.data!.toJson());
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (_dashboardData == null) {
            _errorMessage = e.toString();
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;

    // Fallbacks from SharedPreferences if any API field is null
    final prefService = di.sl<PreferencesService>();
    final savedUser = prefService.getSavedUser();
    final personalInfo = savedUser?['personal_info'] as Map<String, dynamic>?;
    final roomInfo = savedUser?['room_info'] as Map<String, dynamic>?;

    final greeting = _dashboardData?.greeting;
    final String salutation = greeting?.salutation?.isNotEmpty == true ? greeting!.salutation! : 'Good morning';
    final String fullName = greeting?.residentName?.isNotEmpty == true
        ? greeting!.residentName!
        : ((savedUser?['name'] ?? personalInfo?['name'])?.toString() ?? 'Jasmin Korat');
    final String firstName = fullName.trim().isEmpty ? 'Jasmin' : fullName.trim().split(' ').first;
    final String subtitle = greeting?.subtitle?.isNotEmpty == true ? greeting!.subtitle! : AppStrings.appTagline;
    final String? photoUrl = greeting?.photoUrl?.isNotEmpty == true
        ? greeting!.photoUrl
        : (savedUser?['profile_photo_url'] ?? savedUser?['profile_image_url']) as String?;

    final stay = _dashboardData?.stay;
    final String? pgName = stay?.pgName ?? roomInfo?['pg_name'] ?? roomInfo?['building_name'] ?? savedUser?['pg']?['name']?.toString();
    final String? roomNo = stay?.roomNo ?? roomInfo?['room_no']?.toString();
    final String? bedNo = stay?.bedNumber ?? roomInfo?['bed_number']?.toString();
    final String? bannerImage = stay?.bannerImage;

    final rentDue = _dashboardData?.rentDue;
    final unreadCount = _dashboardData?.unreadNotificationsCount ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F6),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _fetchDashboardData,
          color: AppColors.primary,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth > 600 ? (screenWidth - 460) / 2 : 16.0,
              vertical: 10.0,
            ),
            children: [
              // 1. Top Header Row: MYPGPMS Logo + Notification Bell + Profile Avatar
              _buildTopBar(context, unreadCount, photoUrl, firstName),
              const SizedBox(height: 12.0),

              if (_isLoading && _dashboardData == null) ...[
                const SizedBox(height: 60.0),
                const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2.5,
                  ),
                ),
                const SizedBox(height: 60.0),
              ] else if (_errorMessage != null && _dashboardData == null) ...[
                _buildErrorState(),
              ] else ...[
                // 2. Greeting Section (Sun + Name + Tagline)
                _buildGreetingSection(salutation, fullName, subtitle),
                const SizedBox(height: 14.0),

                // 3. Green Property Banner Card
                _buildPropertyBanner(pgName, roomNo, bedNo, bannerImage),
                const SizedBox(height: 12.0),

                // 4. Next Rent Due Card
                _buildNextRentDueCard(rentDue),
                const SizedBox(height: 14.0),

                // 5. Quick Actions Grid (Pay Rent, Report Issue, Visitors)
                _buildQuickActionsRow(_dashboardData?.quickActions),
                const SizedBox(height: 16.0),

                // 6. Today's Menu Section
                _buildTodayMenuSection(_dashboardData?.todayMenu ?? []),
                const SizedBox(height: 16.0),

                // 7. My Complaints & Important Notices Section
                _buildComplaintsSection(roomNo ?? '101', _dashboardData?.recentComplaint, _dashboardData?.latestNotice),
                const SizedBox(height: 18.0),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CommonBottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36.0, horizontal: 20.0),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, color: Color(0xFF9CA3AF), size: 48.0),
          const SizedBox(height: 12.0),
          Text(
            'Unable to load dashboard data',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6.0),
          Text(
            _errorMessage ?? 'Please check your connection and try again.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 16.0),
          InkWell(
            onTap: _fetchDashboardData,
            borderRadius: BorderRadius.circular(999.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(999.0),
              ),
              child: Text(
                'Retry',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 1. Top Bar: MYPGPMS Logo + (First: Notification, Second: Profile Avatar)
  Widget _buildTopBar(BuildContext context, int unreadCount, String? photoUrl, String firstName) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const CommonLogo(
          iconSize: 26.0,
          fontSize: 18.0,
        ),
        Row(
          children: [
            // First: Notification Bell
            InkWell(
              onTap: () {
                Navigator.of(context).pushNamed(AppRoutes.notifications);
              },
              borderRadius: BorderRadius.circular(999.0),
              child: Stack(
                children: [
                  Container(
                    width: 38.0,
                    height: 38.0,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      color: AppColors.textPrimary,
                      size: 20.0,
                    ),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 7.0,
                      top: 7.0,
                      child: Container(
                        width: 7.0,
                        height: 7.0,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10.0),

            // Second: Profile Image
            InkWell(
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.profile),
              borderRadius: BorderRadius.circular(999.0),
              child: Container(
                width: 38.0,
                height: 38.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
                  color: const Color(0xFFE8F3ED),
                ),
                child: ClipOval(
                  child: _buildAvatar(photoUrl, firstName),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 2. Greeting Section (Sun + Name + Tagline)
  Widget _buildGreetingSection(String salutation, String fullName, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('☀️', style: TextStyle(fontSize: 13.0)),
            const SizedBox(width: 4.0),
            Text(
              '$salutation,',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.0,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2.0),
        Text(
          fullName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18.0,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 2.0),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.0,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(String? photoUrl, String firstName) {
    if (photoUrl == null || photoUrl.isEmpty) {
      return _buildAvatarFallback(firstName);
    }
    if (photoUrl.startsWith('http://') || photoUrl.startsWith('https://')) {
      return Image.network(
        photoUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildAvatarFallback(firstName),
      );
    }
    try {
      final file = File(photoUrl);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildAvatarFallback(firstName),
        );
      }
    } catch (_) {}
    return _buildAvatarFallback(firstName);
  }

  Widget _buildAvatarFallback(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'U',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 15.0,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }

  // 3. Green Property Banner
  Widget _buildPropertyBanner(String? pgName, String? roomNo, String? bedNo, String? bannerImage) {
    final hasPg = pgName != null && pgName.trim().isNotEmpty;
    final displayPgName = hasPg ? pgName : 'Data not available';

    final String displaySubtitle;
    if (roomNo != null && bedNo != null) {
      final r = roomNo.toLowerCase().contains('room') ? roomNo : 'Room No: $roomNo';
      final b = bedNo.toLowerCase().contains('bed') ? bedNo : 'Bed No: $bedNo';
      displaySubtitle = '$r   |   $b';
    } else if (roomNo != null) {
      displaySubtitle = 'Room No: $roomNo';
    } else {
      displaySubtitle = 'Data not available';
    }

    return Container(
      width: double.infinity,
      height: 76.0,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.0),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F4734),
            Color(0xFF165A42),
            Color(0xFF1F6F52),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x220F4734),
            blurRadius: 12.0,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 120.0,
              child: Opacity(
                opacity: 0.28,
                child: bannerImage != null && bannerImage.startsWith('http')
                    ? Image.network(
                        bannerImage,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Image.asset(
                          AppAssets.invitationBuilding,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Image.asset(
                        AppAssets.invitationBuilding,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    displayPgName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    displaySubtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFB7E4C7),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 4. Next Rent Due Card
  Widget _buildNextRentDueCard(RentDueModel? rentDue) {
    if (rentDue == null) {
      return Container(
        padding: const EdgeInsets.all(14.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Next Rent Due',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: Text(
                    'No Due',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6.0),
            Text(
              'Data not available',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16.0,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              'Due date: Data not available',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                color: const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      );
    }

    final amountText = rentDue.formatted ?? '₹ ${rentDue.amount ?? 0}';
    final dueDateText = rentDue.dueDateFormatted ?? (rentDue.dueDate != null ? 'Due on ${rentDue.dueDate}' : 'Data not available');
    final statusText = rentDue.displayStatus;
    final statusBg = rentDue.statusBgColor;
    final statusColor = rentDue.statusTextColor;
    final buttonText = rentDue.isInReview ? 'In Review' : (rentDue.isPaid ? 'Paid' : 'Pay Now');
    final buttonBg = rentDue.isInReview ? const Color(0xFF2563EB) : (rentDue.isPaid ? const Color(0xFF059669) : AppColors.primary);

    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Next Rent Due',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Text(
                  statusText,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  amountText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20.0,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
              if (!rentDue.isPaid) ...[
                const SizedBox(width: 8.0),
                InkWell(
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      AppRoutes.rentDetails,
                      arguments: rentDue.paymentId,
                    );
                  },
                  borderRadius: BorderRadius.circular(999.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 7.0),
                    decoration: BoxDecoration(
                      color: buttonBg,
                      borderRadius: BorderRadius.circular(999.0),
                    ),
                    child: Text(
                      buttonText,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4.0),
          Text(
            dueDateText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              color: const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  // 5. Quick Actions Grid
  Widget _buildQuickActionsRow(List<QuickActionModel>? actions) {
    final List<Map<String, dynamic>> items;

    if (actions != null && actions.isNotEmpty) {
      items = actions
          .where((act) => act.key != 'digital_id' && !act.key.toLowerCase().contains('digital'))
          .map((act) {
        IconData iconData;
        switch (act.key) {
          case 'pay_rent':
            iconData = Icons.receipt_long_outlined;
            break;
          case 'report_issue':
            iconData = Icons.warning_amber_rounded;
            break;
          case 'visitors':
            iconData = Icons.group_outlined;
            break;
          default:
            iconData = Icons.touch_app_outlined;
        }
        String title = act.label.isNotEmpty ? act.label : 'Action';
        if (act.key == 'report_issue' ||
            act.key == 'report' ||
            act.key == 'complaint' ||
            act.key == 'complaints' ||
            title.toLowerCase().contains('report') ||
            title.toLowerCase().contains('complain')) {
          title = 'Complaints';
        }
        return {
          'key': act.key,
          'title': title,
          'icon': iconData,
        };
      }).toList();
    } else {
      items = [
        {'key': 'pay_rent', 'icon': Icons.receipt_long_outlined, 'title': 'Pay Rent'},
        {'key': 'report_issue', 'icon': Icons.warning_amber_rounded, 'title': 'Complaints'},
        {'key': 'visitors', 'icon': Icons.group_outlined, 'title': 'Visitors'},
      ];
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: items.map((act) {
        return Expanded(
          child: InkWell(
            onTap: () {
              final key = act['key'] as String;
              if (key == 'pay_rent') {
                Navigator.of(context).pushNamed(AppRoutes.payments);
              } else if (key == 'visitors') {
                Navigator.of(context).pushNamed(AppRoutes.visitors);
              } else if (key == 'digital_id') {
                Navigator.of(context).pushNamed(AppRoutes.digitalId);
              } else if (key == 'report_issue' || key == 'report' || key == 'complaint' || key == 'complaints') {
                Navigator.of(context).pushNamed(AppRoutes.reportIssue);
              }
            },
            borderRadius: BorderRadius.circular(12.0),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            focusColor: Colors.transparent,
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3.5),
              padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 2.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 34.0,
                    height: 34.0,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F3ED),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Icon(
                      act['icon'] as IconData,
                      color: AppColors.primary,
                      size: 18.0,
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  Text(
                    act['title'] as String,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.0,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // 6. Today's Menu Section
  Widget _buildTodayMenuSection(List<TodayMenuModel> todayMenuList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                "Today's Menu",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            InkWell(
              onTap: () {
                Navigator.of(context).pushNamed(AppRoutes.todayMenu);
              },
              child: Row(
                children: [
                  Text(
                    'View full menu',
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
        if (todayMenuList.isEmpty)
          InkWell(
            onTap: () {
              Navigator.of(context).pushNamed(AppRoutes.todayMenu);
            },
            borderRadius: BorderRadius.circular(14.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14.0),
                border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44.0,
                    height: 44.0,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8F3ED),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.restaurant_outlined, color: AppColors.primary, size: 22.0),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Today's Menu",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          'Menu not available',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.0,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...todayMenuList.map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8.0),
              child: InkWell(
                onTap: () {
                  Navigator.of(context).pushNamed(AppRoutes.todayMenu);
                },
                borderRadius: BorderRadius.circular(14.0),
                child: Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14.0),
                    border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x04000000),
                        blurRadius: 4.0,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10.0),
                        child: item.imageUrl != null && item.imageUrl!.startsWith('http')
                            ? Image.network(
                                item.imageUrl!,
                                width: 56.0,
                                height: 56.0,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => _menuImageFallback(item.mealType),
                              )
                            : _menuImageFallback(item.mealType),
                      ),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.mealType ?? 'Meal',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2.0),
                            Text(
                              item.items ?? item.foodName ?? 'Food',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.0,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFD97706),
                              ),
                            ),
                            const SizedBox(height: 2.0),
                            Text(
                              item.timings ?? (item.startTime != null && item.endTime != null ? '${item.startTime} - ${item.endTime}' : ''),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.0,
                                color: const Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _menuImageFallback([String? mealType]) {
    IconData icon = Icons.restaurant_outlined;
    final m = (mealType ?? '').toLowerCase();
    if (m.contains('break')) {
      icon = Icons.free_breakfast_outlined;
    } else if (m.contains('lunch')) {
      icon = Icons.lunch_dining_outlined;
    } else if (m.contains('dinner')) {
      icon = Icons.dinner_dining_outlined;
    }

    return Container(
      width: 56.0,
      height: 56.0,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F3ED),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Icon(icon, color: AppColors.primary, size: 22.0),
    );
  }

  // 7. Complaints & Notices Section
  Widget _buildComplaintsSection(
    String roomNo,
    RecentComplaintModel? recentComplaint,
    LatestNoticeModel? latestNotice,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'My Complaints',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
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

        // 1. Complaint Card (or Data Not Available)
        if (recentComplaint == null)
          InkWell(
            onTap: () {
              Navigator.of(context).pushNamed(AppRoutes.myComplaints);
            },
            borderRadius: BorderRadius.circular(14.0),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10.0),
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14.0),
                border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38.0,
                    height: 38.0,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8F3ED),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_outline_rounded, color: AppColors.primary, size: 20.0),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recent Complaints',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.0,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          'Data not available',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.0,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          InkWell(
            onTap: () {
              _openComplaintDetails(recentComplaint, roomNo);
            },
            borderRadius: BorderRadius.circular(14.0),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10.0),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 34.0,
                        height: 34.0,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE8F3ED),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_getComplaintIcon(recentComplaint.title), color: AppColors.primary, size: 18.0),
                      ),
                      const SizedBox(width: 10.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              recentComplaint.ticketNo ?? '#CL-1024',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.0,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2.0),
                            Text(
                              recentComplaint.title ?? 'Complaint',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.0,
                                color: const Color(0xFF4B5563),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                        decoration: BoxDecoration(
                          color: _getStatusBgColor(recentComplaint.status),
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                        child: Text(
                          recentComplaint.status ?? 'Pending',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: _getStatusTextColor(recentComplaint.status),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6.0),
                  Padding(
                    padding: const EdgeInsets.only(left: 44.0),
                    child: Text(
                      recentComplaint.locationAndTime ?? 'Room ${recentComplaint.roomNo ?? roomNo}  •  ${recentComplaint.dateFormatted ?? 'Recently'}',
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

        // 2. Latest Notice Card (or Data Not Available)
        if (latestNotice == null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14.0),
              border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
            ),
            child: Row(
              children: [
                Container(
                  width: 38.0,
                  height: 38.0,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F3ED),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.notifications_none_rounded, color: AppColors.primary, size: 20.0),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Latest Notice',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.0,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        'Data not available',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.0,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          InkWell(
            onTap: () {
              if (latestNotice.id != null) {
                Navigator.of(context).pushNamed(
                  AppRoutes.noticeDetails,
                  arguments: latestNotice.id,
                );
              } else {
                Navigator.of(context).pushNamed(AppRoutes.notifications);
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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36.0,
                    height: 36.0,
                    decoration: BoxDecoration(
                      color: latestNotice.iconBg,
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Icon(
                      latestNotice.icon,
                      color: latestNotice.iconColor,
                      size: 19.0,
                    ),
                  ),
                  const SizedBox(width: 10.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Dynamic Category & Priority Badges
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: latestNotice.iconBg,
                                borderRadius: BorderRadius.circular(5.0),
                              ),
                              child: Text(
                                latestNotice.displayCategory,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.w700,
                                  color: latestNotice.iconColor,
                                ),
                              ),
                            ),
                            if (latestNotice.displayPriority.isNotEmpty) ...[
                              const SizedBox(width: 6.0),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: latestNotice.isHighPriority
                                      ? const Color(0xFFFEE2E2)
                                      : const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(5.0),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (latestNotice.isHighPriority) ...[
                                      const Icon(Icons.bolt_rounded, size: 11.0, color: Color(0xFFDC2626)),
                                      const SizedBox(width: 1.5),
                                    ],
                                    Text(
                                      latestNotice.displayPriority,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10.0,
                                        fontWeight: FontWeight.w700,
                                        color: latestNotice.isHighPriority
                                            ? const Color(0xFFDC2626)
                                            : const Color(0xFFD97706),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const Spacer(),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 10.0,
                              color: Color(0xFF9CA3AF),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5.0),

                        // Dynamic Title
                        Text(
                          latestNotice.title ?? 'Notice',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            height: 1.25,
                          ),
                        ),

                        // Dynamic Summary / Content
                        if ((latestNotice.summary ?? latestNotice.subtitle)?.isNotEmpty == true) ...[
                          const SizedBox(height: 2.5),
                          Text(
                            (latestNotice.summary ?? latestNotice.subtitle)!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.0,
                              color: const Color(0xFF6B7280),
                              height: 1.3,
                            ),
                          ),
                        ],

                        // Dynamic Date & Time
                        if ((latestNotice.dateTime ?? latestNotice.dateFormatted)?.isNotEmpty == true) ...[
                          const SizedBox(height: 5.0),
                          Row(
                            children: [
                              const Icon(Icons.schedule_rounded, size: 11.5, color: Color(0xFF9CA3AF)),
                              const SizedBox(width: 3.5),
                              Text(
                                (latestNotice.dateTime ?? latestNotice.dateFormatted)!,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF9CA3AF),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _openComplaintDetails(RecentComplaintModel recentComplaint, String defaultRoomNo) {
    // 1. Try to find the full ComplaintItemModel in cached complaints
    ComplaintItemModel? matchedComplaint;
    try {
      final prefService = di.sl<PreferencesService>();
      final list = prefService.getSavedComplaintsList();
      if (list != null && list.isNotEmpty) {
        for (final raw in list) {
          final item = ComplaintItemModel.fromJson(raw);
          if ((recentComplaint.id != null && item.id == recentComplaint.id) ||
              (recentComplaint.ticketNo != null &&
                  (item.complaintNumber == recentComplaint.ticketNo ||
                      item.displayId == recentComplaint.ticketNo ||
                      '#${item.complaintNumber}' == recentComplaint.ticketNo))) {
            matchedComplaint = item;
            break;
          }
        }
      }
    } catch (_) {}

    if (matchedComplaint != null) {
      Navigator.of(context).pushNamed(
        AppRoutes.complaintDetails,
        arguments: matchedComplaint,
      );
      return;
    }

    // 2. If recentComplaint has an ID, pass it or create a placeholder model
    final int? compId = recentComplaint.id;
    if (compId != null && compId > 0) {
      final placeholder = ComplaintItemModel(
        id: compId,
        complaintNumber: recentComplaint.ticketNo ?? '',
        title: recentComplaint.title ?? 'Complaint',
        description: '',
        status: recentComplaint.status ?? 'OPEN',
        location: ComplaintLocationInfo(roomNo: recentComplaint.roomNo ?? defaultRoomNo),
        createdAt: recentComplaint.dateFormatted ?? '',
        updatedAt: recentComplaint.dateFormatted ?? '',
      );

      Navigator.of(context).pushNamed(
        AppRoutes.complaintDetails,
        arguments: placeholder,
      );
      return;
    }

    // 3. Fallback to my complaints screen
    Navigator.of(context).pushNamed(AppRoutes.myComplaints);
  }

  IconData _getComplaintIcon(String? title) {
    final t = (title ?? '').toLowerCase();
    if (t.contains('wifi') || t.contains('internet')) return Icons.wifi_rounded;
    if (t.contains('water')) return Icons.water_drop_outlined;
    if (t.contains('clean') || t.contains('housekeep')) return Icons.cleaning_services_outlined;
    if (t.contains('ac') || t.contains('air')) return Icons.ac_unit_rounded;
    if (t.contains('electr') || t.contains('power')) return Icons.bolt_rounded;
    if (t.contains('plumb')) return Icons.plumbing_rounded;
    return Icons.report_problem_outlined;
  }

  Color _getStatusTextColor(String? status) {
    final s = (status ?? '').toLowerCase();
    if (s.contains('progress')) return const Color(0xFF4F46E5);
    if (s.contains('pending') || s.contains('open')) return const Color(0xFFD97706);
    if (s.contains('resolved') || s.contains('closed')) return const Color(0xFF059669);
    return const Color(0xFF4B5563);
  }

  Color _getStatusBgColor(String? status) {
    final s = (status ?? '').toLowerCase();
    if (s.contains('progress')) return const Color(0xFFEEF2FF);
    if (s.contains('pending') || s.contains('open')) return const Color(0xFFFEF3C7);
    if (s.contains('resolved') || s.contains('closed')) return const Color(0xFFD1FAE5);
    return const Color(0xFFF3F4F6);
  }
}

