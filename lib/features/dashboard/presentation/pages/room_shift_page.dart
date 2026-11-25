import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/colors/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/storage/preferences_service.dart';
import '../../../../injection_container.dart' as di;
import '../../data/datasources/room_shift_remote_data_source.dart';

class RoomShiftPage extends StatefulWidget {
  const RoomShiftPage({super.key});

  @override
  State<RoomShiftPage> createState() => _RoomShiftPageState();
}

class _RoomShiftPageState extends State<RoomShiftPage> {
  int _selectedTabIndex = 0; // 0: My Room, 1: Shift Request
  bool _isLoadingShifts = false;

  // Shift requests list
  List<Map<String, dynamic>> _shiftRequests = [];

  List<Map<String, String>> _availableRooms = [
    {
      'room': 'A-102',
      'sharing': 'Double Sharing',
      'status': 'Available',
    },
    {
      'room': 'A-302',
      'sharing': 'Triple Sharing',
      'status': 'Available',
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchShiftsFromApi();
    _fetchRoomsFromApi();
  }

  Future<void> _fetchRoomsFromApi() async {
    try {
      final dataSource = di.sl<RoomShiftRemoteDataSource>();
      final rooms = await dataSource.getRooms();
      if (rooms.isNotEmpty && mounted) {
        setState(() {
          _availableRooms = rooms.map((r) {
            return {
              'id': r.id.toString(),
              'room': 'Room ${r.roomNo}',
              'sharing': r.sharingLabel,
              'status': r.isAvailable ? 'Available' : 'Occupied',
              'image': r.imageUrl ?? '',
              'beds': '${r.availableBeds ?? 1} beds available',
            };
          }).toList();
        });
      }
    } catch (_) {}
  }

  String _formatDateString(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return 'Recent';
    try {
      final clean = rawDate.split(' ')[0];
      if (clean.contains('-')) {
        final parts = clean.split('-');
        if (parts.length == 3) {
          const months = [
            'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
            'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
          ];
          if (parts[0].length == 4) {
            // YYYY-MM-DD
            final month = int.tryParse(parts[1]) ?? 1;
            final day = parts[2];
            final year = parts[0];
            return '$day ${months[(month - 1).clamp(0, 11)]} $year';
          } else {
            // DD-MM-YYYY
            final day = parts[0];
            final month = int.tryParse(parts[1]) ?? 1;
            final year = parts[2];
            return '$day ${months[(month - 1).clamp(0, 11)]} $year';
          }
        }
      }
      return rawDate;
    } catch (_) {
      return rawDate;
    }
  }

  String _formatTargetDisplay(String targetRoom, String sharing) {
    final cleanTarget = targetRoom.trim();
    final cleanSharing = sharing.trim();
    if (cleanTarget.isEmpty) {
      return cleanSharing.isNotEmpty ? cleanSharing : 'Any Available Room';
    }
    if (cleanSharing.isEmpty || cleanTarget.toLowerCase().contains(cleanSharing.toLowerCase())) {
      return cleanTarget;
    }
    return '$cleanTarget ($cleanSharing)';
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  Future<void> _fetchShiftsFromApi() async {
    setState(() {
      _isLoadingShifts = true;
    });
    try {
      final prefService = di.sl<PreferencesService>();
      final dashboard = prefService.getSavedDashboard();
      final user = prefService.getSavedUser();
      int branchId = 1;
      if (dashboard?['stay_details'] is Map && dashboard!['stay_details']['branch_id'] != null) {
        branchId = int.tryParse(dashboard['stay_details']['branch_id'].toString()) ?? 1;
      } else if (user?['branch_id'] != null) {
        branchId = int.tryParse(user!['branch_id'].toString()) ?? 1;
      }

      final dataSource = di.sl<RoomShiftRemoteDataSource>();
      final list = await dataSource.getRoomShifts(
        branchId: branchId,
        status: 'all',
        page: 1,
        limit: 10,
      );
      if (mounted) {
        setState(() {
          _isLoadingShifts = false;
          _shiftRequests = list.map((item) {
            final sharing = item.preferredRoomType ??
                (item.requestedRoomType != null ? '${item.requestedRoomType} Sharing' : 'Double Sharing');
            final targetRoom = item.targetRoom ??
                (item.requestedRoomNo != null ? 'Room ${item.requestedRoomNo}' : 'Any Available Room');
            final dateDisplay = _formatDateString(item.createdAt ?? item.expectedMoveDate);
            final status = (item.status.isNotEmpty) ? item.status : 'Pending';

            return {
              'id': 'RSR-${item.id ?? 1024}',
              'target_room': targetRoom,
              'sharing': sharing,
              'date': dateDisplay,
              'status': status,
              'reason': item.reason ?? '',
            };
          }).toList();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingShifts = false;
        });
      }
    }
  }

  Future<void> _navigateToRequestPage([String? preselectedRoom]) async {
    final result = await Navigator.of(context).pushNamed(
      AppRoutes.requestRoomShift,
      arguments: preselectedRoom,
    );
    if (result != null && mounted) {
      setState(() {
        _selectedTabIndex = 1; // switch to Shift Request tab
      });
      await _fetchShiftsFromApi();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth > 600 ? (screenWidth - 460) / 2 : 16.0;

    // Load saved data dynamically
    Map<String, dynamic>? savedDashboard;
    Map<String, dynamic>? savedUser;
    try {
      final prefService = di.sl<PreferencesService>();
      savedDashboard = prefService.getSavedDashboard();
      savedUser = prefService.getSavedUser();
    } catch (_) {}

    final stay = savedDashboard?['stay'] as Map<String, dynamic>?;
    final roomInfo = savedUser?['room_info'] as Map<String, dynamic>?;

    final String roomNo = stay?['room_no']?.toString() ??
        roomInfo?['room_no']?.toString() ??
        'A-204';

    final String bedNo = stay?['bed_number']?.toString() ??
        roomInfo?['bed_no']?.toString() ??
        'B-2';

    final String rawRoomSharing = roomInfo?['room_sharing']?.toString() ??
        (roomInfo?['room_type'] != null ? '${roomInfo!['room_type']} Sharing' : 'Triple Sharing');
    final String roomSharing = _capitalize(rawRoomSharing);

    // Resolve current room image if matched
    String? currentRoomImageUrl;
    if (_availableRooms.isNotEmpty) {
      try {
        final matched = _availableRooms.firstWhere(
          (r) => (r['room'] ?? '').contains(roomNo) || (r['id'] ?? '') == roomNo,
        );
        if (matched['image'] != null && matched['image']!.isNotEmpty) {
          currentRoomImageUrl = matched['image'];
        }
      } catch (_) {}
    }

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
          'Room Shift',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18.0,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 10.0),
          children: [
            // Segmented Tab Pills: My Room & Shift Request
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24.0),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() => _selectedTabIndex = 0);
                      },
                      borderRadius: BorderRadius.circular(24.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 11.0),
                        decoration: BoxDecoration(
                          color: _selectedTabIndex == 0 ? AppColors.primary : const Color(0xFFE8F3ED),
                          borderRadius: BorderRadius.circular(24.0),
                        ),
                        child: Text(
                          'My Room',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.0,
                            fontWeight: FontWeight.w700,
                            color: _selectedTabIndex == 0 ? Colors.white : AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() => _selectedTabIndex = 1);
                      },
                      borderRadius: BorderRadius.circular(24.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 11.0),
                        decoration: BoxDecoration(
                          color: _selectedTabIndex == 1 ? AppColors.primary : const Color(0xFFE8F3ED),
                          borderRadius: BorderRadius.circular(24.0),
                        ),
                        child: Text(
                          'Shift Request',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.0,
                            fontWeight: FontWeight.w700,
                            color: _selectedTabIndex == 1 ? Colors.white : AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20.0),

            // Tab View Content
            if (_selectedTabIndex == 0) ...[
              // 1. Current room section
              Text(
                'Current room',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15.0,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12.0),

              // Current Room Card
              Container(
                padding: const EdgeInsets.all(12.0),
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
                child: Row(
                  children: [
                    // Room Thumbnail Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: SizedBox(
                        width: 80.0,
                        height: 58.0,
                        child: currentRoomImageUrl != null && currentRoomImageUrl.isNotEmpty
                            ? Image.network(
                                currentRoomImageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: const Color(0xFFE8F3ED),
                                  child: const Center(
                                    child: Icon(Icons.bed_rounded, color: AppColors.primary, size: 28.0),
                                  ),
                                ),
                              )
                            : Image.network(
                                'https://images.unsplash.com/photo-1598928506311-c55ded91a20c?w=400&q=80',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: const Color(0xFFE8F3ED),
                                  child: const Center(
                                    child: Icon(Icons.bed_rounded, color: AppColors.primary, size: 28.0),
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 14.0),

                    // Room Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            roomNo,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16.0,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3.0),
                          Text(
                            'Bed No. : $bedNo',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.0,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Double Sharing Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD2EBE0),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        roomSharing,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),

              // 2. Request Room Shift Card
              Container(
                padding: const EdgeInsets.all(16.0),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44.0,
                          height: 44.0,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE8F3ED),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.bed_rounded,
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
                                'Request Room Shift',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3.0),
                              Text(
                                'Want to change your room?\nSubmit a request and we\'ll check availability.',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.0,
                                  color: const Color(0xFF6B7280),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    SizedBox(
                      width: double.infinity,
                      height: 46.0,
                      child: ElevatedButton(
                        onPressed: () => _navigateToRequestPage(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24.0),
                          ),
                        ),
                        child: Text(
                          'Request Room Shift',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.0,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20.0),

              // 3. Available options (If any)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Available options (If any)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15.0,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (_availableRooms.isNotEmpty)
                    Text(
                      '${_availableRooms.length} available',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12.0),

              if (_availableRooms.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
                  ),
                  child: Center(
                    child: Text(
                      'No alternative rooms currently available',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.0,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _availableRooms.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12.0,
                    mainAxisSpacing: 12.0,
                    mainAxisExtent: 146.0,
                  ),
                  itemBuilder: (context, index) {
                    final opt = _availableRooms[index];
                    final isAvailable = (opt['status'] ?? '').toLowerCase() == 'available';

                    return InkWell(
                      onTap: () => _navigateToRequestPage(opt['room']),
                      borderRadius: BorderRadius.circular(16.0),
                      child: Container(
                        padding: const EdgeInsets.all(14.0),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  width: 32.0,
                                  height: 32.0,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F3ED),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: const Icon(
                                    Icons.meeting_room_outlined,
                                    color: AppColors.primary,
                                    size: 18.0,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.5),
                                  decoration: BoxDecoration(
                                    color: isAvailable
                                        ? const Color(0xFFD2EBE0)
                                        : const Color(0xFFFEE2E2),
                                    borderRadius: BorderRadius.circular(6.0),
                                  ),
                                  child: Text(
                                    opt['status'] ?? 'Available',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: isAvailable
                                        ? AppColors.primary
                                        : const Color(0xFFDC2626),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6.0),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  opt['room'] ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2.0),
                                Text(
                                  opt['sharing'] ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.0,
                                    color: const Color(0xFF6B7280),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            if (opt['beds'] != null && opt['beds']!.isNotEmpty)
                              Row(
                                children: [
                                  const Icon(
                                    Icons.bed_outlined,
                                    size: 13.0,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 4.0),
                                  Expanded(
                                    child: Text(
                                      opt['beds']!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11.0,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ] else ...[
              // Shift Request Tab View
              if (_isLoadingShifts)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.0),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (_shiftRequests.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 56.0,
                        height: 56.0,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE8F3ED),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.history_rounded, color: AppColors.primary, size: 28.0),
                      ),
                      const SizedBox(height: 14.0),
                      Text(
                        'No Shift Requests',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15.0,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        'You haven\'t submitted any room shift requests yet.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      ElevatedButton(
                        onPressed: () => _navigateToRequestPage(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
                        ),
                        child: Text(
                          'New Request',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.0,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ..._shiftRequests.map((req) {
                  final statusStr = req['status'] as String? ?? 'Pending';
                  final statusLower = statusStr.toLowerCase();
                  final Color badgeBg;
                  final Color badgeText;
                  final String footerStatus;
                  final Color footerColor;

                  if (statusLower == 'approved') {
                    badgeBg = const Color(0xFFDCFCE7);
                    badgeText = const Color(0xFF166534);
                    footerStatus = 'Approved';
                    footerColor = const Color(0xFF166534);
                  } else if (statusLower == 'rejected') {
                    badgeBg = const Color(0xFFFEE2E2);
                    badgeText = const Color(0xFFDC2626);
                    footerStatus = 'Rejected';
                    footerColor = const Color(0xFFDC2626);
                  } else {
                    badgeBg = const Color(0xFFFEF3C7);
                    badgeText = const Color(0xFFD97706);
                    footerStatus = 'Under Review';
                    footerColor = AppColors.primary;
                  }

                  final displayStatus = statusLower.isEmpty
                      ? 'Pending'
                      : '${statusLower[0].toUpperCase()}${statusLower.substring(1)}';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12.0),
                    padding: const EdgeInsets.all(16.0),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Request #${req['id']}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                              decoration: BoxDecoration(
                                color: badgeBg,
                                borderRadius: BorderRadius.circular(6.0),
                              ),
                              child: Text(
                                displayStatus,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.w700,
                                  color: badgeText,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10.0),
                        Row(
                          children: [
                            const Icon(Icons.meeting_room_outlined, size: 16.0, color: Color(0xFF6B7280)),
                            const SizedBox(width: 6.0),
                            Expanded(
                              child: Text(
                                'Target: ${_formatTargetDisplay(req['target_room']?.toString() ?? '', req['sharing']?.toString() ?? '')}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.0,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6.0),
                        Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, size: 16.0, color: Color(0xFF6B7280)),
                            const SizedBox(width: 6.0),
                            Expanded(
                              child: Text(
                                req['reason'] as String? ?? '',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.0,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20.0, color: Color(0xFFF3F4F6)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Submitted on ${req['date']}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                color: const Color(0xFF9CA3AF),
                              ),
                            ),
                            Text(
                              footerStatus,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.0,
                                fontWeight: FontWeight.w600,
                                color: footerColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
            ],
            const SizedBox(height: 24.0),
          ],
        ),
      ),
    );
  }
}
