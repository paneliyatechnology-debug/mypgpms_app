import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/colors/app_colors.dart';
import '../../../../core/storage/preferences_service.dart';
import '../../../../injection_container.dart' as di;
import '../../../authentication/data/datasources/auth_remote_data_source.dart';
import '../../data/datasources/dashboard_remote_data_source.dart';
import '../../data/models/dashboard_response_model.dart';

class RoomPropertyDetailsPage extends StatefulWidget {
  const RoomPropertyDetailsPage({super.key});

  @override
  State<RoomPropertyDetailsPage> createState() => _RoomPropertyDetailsPageState();
}

class _RoomPropertyDetailsPageState extends State<RoomPropertyDetailsPage> {
  Map<String, dynamic>? _savedUser;
  Map<String, dynamic>? _savedDashboard;
  DashboardDataModel? _dashboardData;

  @override
  void initState() {
    super.initState();
    _loadLocalData();
    _fetchFreshData();
  }

  void _loadLocalData() {
    try {
      final prefService = di.sl<PreferencesService>();
      final cachedDash = prefService.getSavedDashboard();
      setState(() {
        _savedUser = prefService.getSavedUser();
        _savedDashboard = cachedDash;
        if (cachedDash != null) {
          _dashboardData = DashboardDataModel.fromJson(cachedDash);
        }
      });
    } catch (_) {}
  }

  Future<void> _fetchFreshData() async {
    try {
      final prefService = di.sl<PreferencesService>();
      final dashboardDataSource = di.sl<DashboardRemoteDataSource>();
      final authDataSource = di.sl<AuthRemoteDataSource>();

      try {
        final dashRes = await dashboardDataSource.getDashboardData();
        if (dashRes.data != null) {
          _dashboardData = dashRes.data;
          await prefService.saveDashboardData(dashRes.data!.toJson());
        }
      } catch (_) {}

      try {
        final freshUser = await authDataSource.getMe();
        final userMap = freshUser.rawJson.isNotEmpty ? Map<String, dynamic>.from(freshUser.rawJson) : freshUser.toJson();
        await prefService.saveUserData(userMap);
      } catch (_) {}

      if (mounted) {
        setState(() {
          _savedUser = prefService.getSavedUser();
          _savedDashboard = prefService.getSavedDashboard();
        });
      }
    } catch (_) {}
  }

  Future<void> _onRefresh() async {
    await _fetchFreshData();
  }

  String _formatValue(dynamic val) {
    if (val == null) return 'Data not available';
    final str = val.toString().trim();
    if (str.isEmpty || str.toLowerCase() == 'null') return 'Data not available';
    return str;
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return 'Data not available';
    if (amount is num) {
      final str = amount.round().toString();
      if (str.length <= 3) return '₹$str';
      final lastThree = str.substring(str.length - 3);
      final otherNumbers = str.substring(0, str.length - 3);
      final formatted = otherNumbers.replaceAllMapped(
        RegExp(r'\B(?=(\d{2})+(?!\d))'),
        (match) => ',',
      );
      return '₹$formatted,$lastThree';
    }
    final strVal = amount.toString().trim();
    if (strVal.isEmpty || strVal.toLowerCase() == 'null') return 'Data not available';
    if (strVal.startsWith('₹')) return strVal;
    final parsed = num.tryParse(strVal.replaceAll(RegExp(r'[^\d.]'), ''));
    if (parsed != null) return _formatCurrency(parsed);
    return strVal;
  }

  String? _resolveImageUrl(dynamic raw) {
    if (raw == null) return null;
    final str = raw.toString().trim();
    if (str.isEmpty || str.toLowerCase() == 'null') return null;
    if (str.startsWith('http://') || str.startsWith('https://')) return str;
    if (str.startsWith('/')) return 'https://api.mypgpms.com$str';
    return 'https://api.mypgpms.com/uploads/$str';
  }

  IconData _getAmenityIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('wifi') || lower.contains('internet')) return Icons.wifi_rounded;
    if (lower.contains('ac') || lower.contains('air')) return Icons.ac_unit_rounded;
    if (lower.contains('water') || lower.contains('ro')) return Icons.water_drop_outlined;
    if (lower.contains('laundry') || lower.contains('washing')) return Icons.local_laundry_service_outlined;
    if (lower.contains('common') || lower.contains('hall') || lower.contains('room')) return Icons.meeting_room_outlined;
    if (lower.contains('security') || lower.contains('cctv') || lower.contains('guard')) return Icons.shield_outlined;
    if (lower.contains('parking')) return Icons.local_parking_rounded;
    if (lower.contains('garden') || lower.contains('lawn')) return Icons.park_outlined;
    if (lower.contains('gym') || lower.contains('fitness')) return Icons.fitness_center_rounded;
    if (lower.contains('food') || lower.contains('mess') || lower.contains('dining')) return Icons.restaurant_rounded;
    if (lower.contains('tv')) return Icons.tv_rounded;
    if (lower.contains('clean') || lower.contains('housekeeping')) return Icons.cleaning_services_rounded;
    return Icons.check_circle_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth > 600 ? (screenWidth - 460) / 2 : 16.0;

    final stayModel = _dashboardData?.stay;
    final rentDueModel = _dashboardData?.rentDue;

    final stayMap = _savedDashboard?['stay'] as Map<String, dynamic>?;
    final rentDueMap = _savedDashboard?['rent_due'] as Map<String, dynamic>?;
    final roomInfo = _savedUser?['room_info'] as Map<String, dynamic>?;
    final paymentInfo = _savedUser?['payment_info'] as Map<String, dynamic>?;
    final pgMap = _savedUser?['pg'] as Map<String, dynamic>?;

    // 1. Dynamic Room No.
    final dynamic rawRoomNo = stayModel?.roomNo ?? stayMap?['room_no'] ?? roomInfo?['room_no'] ?? _savedUser?['room_no'];
    final String roomNoDisplay = _formatValue(rawRoomNo);
    final bool hasValidRoomNo = roomNoDisplay != 'Data not available';

    // 2. Dynamic Building Name
    final dynamic rawBuilding = roomInfo?['building_name'] ??
        _savedUser?['building_name'] ??
        stayModel?.branchName ??
        stayMap?['branch_name'] ??
        stayModel?.pgName ??
        pgMap?['name'];
    final String buildingDisplay = _formatValue(rawBuilding);

    // 3. Dynamic Room Type
    final dynamic rawRoomType = roomInfo?['room_type'] ?? _savedUser?['room_type'] ?? stayMap?['room_type'];
    final String roomTypeDisplay = _formatValue(rawRoomType);

    // 4. Dynamic Monthly Rent
    final dynamic rawRent = rentDueModel?.formatted ??
        (rentDueModel?.amount != null ? '₹${rentDueModel!.amount}' : null) ??
        rentDueMap?['formatted'] ??
        (rentDueMap?['amount'] != null ? '₹${rentDueMap!['amount']}' : null) ??
        paymentInfo?['rent'] ??
        roomInfo?['rent'];
    final String rentDisplay = _formatCurrency(rawRent);

    // 5. Dynamic Deposit
    final dynamic rawDeposit = roomInfo?['deposit'] ??
        roomInfo?['security_deposit'] ??
        paymentInfo?['deposit'] ??
        paymentInfo?['security_deposit'] ??
        _savedUser?['deposit'];
    final String depositDisplay = _formatCurrency(rawDeposit);

    // 6. Dynamic Moving-in Date
    final dynamic rawMovingInDate = roomInfo?['moving_in_date'] ??
        roomInfo?['join_date'] ??
        stayMap?['moving_in_date'] ??
        _savedUser?['moving_in_date'] ??
        _savedUser?['joining_date'];
    final String movingInDateDisplay = _formatValue(rawMovingInDate);

    // 7. Dynamic Room Sharing
    final dynamic rawRoomSharing = roomInfo?['room_sharing'] ??
        roomInfo?['sharing_type'] ??
        (rawRoomType != null ? '$rawRoomType Sharing' : null) ??
        (stayModel?.bedNumber != null ? 'Bed ${stayModel!.bedNumber}' : null);
    final String roomSharingDisplay = _formatValue(rawRoomSharing);

    // 8. Dynamic Banner Image
    final dynamic rawImage = stayModel?.bannerImage ??
        stayMap?['banner_image'] ??
        stayMap?['image'] ??
        roomInfo?['image_url'] ??
        roomInfo?['image'] ??
        roomInfo?['banner_image'] ??
        roomInfo?['photo_url'] ??
        pgMap?['banner_image'] ??
        pgMap?['image'];
    final String? dynamicImageUrl = _resolveImageUrl(rawImage);

    // 9. Dynamic Amenities
    List<Map<String, dynamic>> dynamicAmenities = [];
    final dynamic rawAmenities = roomInfo?['amenities'] ?? pgMap?['amenities'] ?? stayMap?['amenities'];
    if (rawAmenities is List && rawAmenities.isNotEmpty) {
      for (final item in rawAmenities) {
        if (item is Map) {
          final name = item['name']?.toString() ?? item['title']?.toString() ?? '';
          if (name.isNotEmpty) {
            dynamicAmenities.add({
              'name': name,
              'icon': _getAmenityIcon(name),
            });
          }
        } else if (item is String && item.isNotEmpty) {
          dynamicAmenities.add({
            'name': item,
            'icon': _getAmenityIcon(item),
          });
        }
      }
    }

    // Default fallback amenities if PG list is completely unconfigured
    if (dynamicAmenities.isEmpty) {
      dynamicAmenities = [
        {'name': 'WiFi', 'icon': Icons.wifi_rounded},
        {'name': 'AC', 'icon': Icons.ac_unit_rounded},
        {'name': 'Water', 'icon': Icons.water_drop_outlined},
        {'name': 'Laundry', 'icon': Icons.local_laundry_service_outlined},
        {'name': 'Common Room', 'icon': Icons.meeting_room_outlined},
        {'name': 'Security', 'icon': Icons.shield_outlined},
        {'name': 'Parking', 'icon': Icons.local_parking_rounded},
        {'name': 'Garden', 'icon': Icons.park_outlined},
      ];
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
          'Room & Property Details',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18.0,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppColors.primary,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8.0),
            children: [
              // Top Room Details Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x04000000),
                      blurRadius: 8.0,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    // Dynamic Banner Image with Badge Overlay
                    Stack(
                      children: [
                        SizedBox(
                          height: 175.0,
                          width: double.infinity,
                          child: dynamicImageUrl != null && dynamicImageUrl.isNotEmpty
                              ? Image.network(
                                  dynamicImageUrl,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      color: const Color(0xFFF3F4F6),
                                      child: const Center(
                                        child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) => _buildImageUnavailableWidget(),
                                )
                              : _buildImageUnavailableWidget(),
                        ),

                        // Dynamic Room Badge Overlay
                        if (hasValidRoomNo)
                          Positioned(
                            top: 12.0,
                            right: 12.0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F3ED).withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(8.0),
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                              ),
                              child: Text(
                                'Room $roomNoDisplay',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),

                    // Table of dynamic details
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildRow('Room No.', roomNoDisplay),
                          _buildRow('Building', buildingDisplay),
                          _buildRow('Room Type', roomTypeDisplay),
                          _buildRow('Rent (monthly)', rentDisplay),
                          _buildRow('Deposit', depositDisplay),
                          _buildRow('Moving in date', movingInDateDisplay),
                          _buildRow('Room Sharing', roomSharingDisplay, isLast: true),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14.0),

              // Property Amenities Card
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x04000000),
                      blurRadius: 8.0,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Property Amenities',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 14.0),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 12.0,
                        crossAxisSpacing: 10.0,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: dynamicAmenities.length,
                      itemBuilder: (context, index) {
                        final item = dynamicAmenities[index];
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 48.0,
                              height: 48.0,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F3ED),
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: Icon(
                                item['icon'] as IconData,
                                color: AppColors.primary,
                                size: 24.0,
                              ),
                            ),
                            const SizedBox(height: 6.0),
                            Text(
                              item['name'] as String,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        );
                      },
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

  Widget _buildImageUnavailableWidget() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF3F4F6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 46.0,
            height: 46.0,
            decoration: const BoxDecoration(
              color: Color(0xFFE5E7EB),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.image_not_supported_outlined, color: Color(0xFF9CA3AF), size: 24.0),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Data not available',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.0,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isLast = false}) {
    final bool isUnavailable = value.trim().toLowerCase() == 'data not available';

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0.0 : 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(width: 8.0),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.0,
                fontWeight: isUnavailable ? FontWeight.w500 : FontWeight.w600,
                color: isUnavailable ? const Color(0xFF9CA3AF) : AppColors.textPrimary,
                fontStyle: isUnavailable ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
