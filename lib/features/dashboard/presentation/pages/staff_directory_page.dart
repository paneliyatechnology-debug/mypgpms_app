import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/colors/app_colors.dart';
import '../../../../core/storage/preferences_service.dart';
import '../../../../injection_container.dart' as di;
import '../../data/datasources/staff_remote_data_source.dart';
import '../../data/models/staff_model.dart';

class StaffDirectoryPage extends StatefulWidget {
  const StaffDirectoryPage({super.key});

  @override
  State<StaffDirectoryPage> createState() => _StaffDirectoryPageState();
}

class _StaffDirectoryPageState extends State<StaffDirectoryPage> {
  String _selectedCategory = 'All';
  bool _isLoading = true;
  String? _errorMessage;
  List<StaffMemberModel> _staffList = [];

  final List<String> _baseCategories = [
    'All',
    'Manager',
    'Security',
    'Cleaning',
    'Maintenance',
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    // 1. Try to load cached staff from storage for instant display
    try {
      final prefService = di.sl<PreferencesService>();
      final cached = prefService.getSavedStaffList();
      if (cached != null && cached.isNotEmpty) {
        final parsed = cached.map((e) => StaffMemberModel.fromJson(e)).toList();
        if (parsed.isNotEmpty) {
          _staffList = parsed;
          _isLoading = false;
        }
      }
    } catch (_) {}

    // 2. Fetch fresh staff list from API
    _fetchStaffList();
  }

  Future<void> _fetchStaffList() async {
    if (_staffList.isEmpty) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final prefService = di.sl<PreferencesService>();
      final savedUser = prefService.getSavedUser();
      final savedDashboard = prefService.getSavedDashboard();

      // Retrieve resident branch_id or pg_id
      int branchId = 1;
      if (savedDashboard?['stay']?['branch_id'] != null) {
        branchId = int.tryParse(savedDashboard!['stay']['branch_id'].toString()) ?? 1;
      } else if (savedUser?['branch_id'] != null) {
        branchId = int.tryParse(savedUser!['branch_id'].toString()) ?? 1;
      } else if (savedUser?['pg_id'] != null) {
        branchId = int.tryParse(savedUser!['pg_id'].toString()) ?? 1;
      }

      final dataSource = di.sl<StaffRemoteDataSource>();
      final result = await dataSource.getStaffList(
        branchId: branchId,
        staffRole: 'all',
        status: 'all',
        page: 1,
        limit: 20,
      );

      if (mounted) {
        setState(() {
          _staffList = result;
          _isLoading = false;
          _errorMessage = null;
        });

        // Cache the retrieved staff list
        try {
          await prefService.saveStaffList(result.map((e) => e.toJson()).toList());
        } catch (_) {}
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (_staffList.isEmpty) {
            _errorMessage = e.toString();
          }
        });
      }
    }
  }

  List<String> _getAvailableCategories() {
    final Set<String> categories = {..._baseCategories};
    for (final staff in _staffList) {
      categories.add(staff.categoryFilter);
    }
    // Return ordered list starting with 'All'
    final list = categories.toList();
    list.remove('All');
    return ['All', ...list];
  }

  List<StaffMemberModel> _getFilteredStaff() {
    if (_selectedCategory == 'All') {
      return _staffList;
    }
    return _staffList.where((s) {
      return s.categoryFilter.toLowerCase() == _selectedCategory.toLowerCase();
    }).toList();
  }

  Future<void> _makeCall(StaffMemberModel staff) async {
    final cleanPhone = staff.phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanPhone.isEmpty) {
      _showActionSnackBar('Phone number not available');
      return;
    }

    final Uri phoneUri = Uri(scheme: 'tel', path: cleanPhone);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(phoneUri);
      }
    } catch (_) {
      try {
        await launchUrl(Uri.parse('tel:$cleanPhone'));
      } catch (e) {
        if (!mounted) return;
        _showActionSnackBar('Could not launch phone dialer: $e');
      }
    }
  }

  void _showActionSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.plusJakartaSans(fontSize: 13.0, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth > 600 ? (screenWidth - 460) / 2 : 16.0;

    final categories = _getAvailableCategories();
    final filteredStaff = _getFilteredStaff();

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
          'Staff Directory',
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
          onRefresh: _fetchStaffList,
          color: AppColors.primary,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 10.0),
            children: [
              // Filter Pills Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: categories.map((cat) {
                    final isSelected = _selectedCategory.toLowerCase() == cat.toLowerCase();
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedCategory = cat;
                          });
                        },
                        borderRadius: BorderRadius.circular(24.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : const Color(0xFFE8F3ED),
                            borderRadius: BorderRadius.circular(24.0),
                          ),
                          child: Text(
                            cat,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                              color: isSelected ? Colors.white : AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14.0),

              // Loading State
              if (_isLoading && _staffList.isEmpty) ...[
                const SizedBox(height: 40.0),
                const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                const SizedBox(height: 40.0),
              ]
              // Error State
              else if (_errorMessage != null && _staffList.isEmpty) ...[
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 20.0),
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.cloud_off_rounded, size: 48.0, color: Color(0xFF9CA3AF)),
                      const SizedBox(height: 12.0),
                      Text(
                        'Unable to load staff directory',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6.0),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      ElevatedButton(
                        onPressed: _fetchStaffList,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                        ),
                        child: Text(
                          'Retry',
                          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ]
              // Empty State
              else if (filteredStaff.isEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(32.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.people_outline_rounded, size: 48.0, color: Color(0xFF9CA3AF)),
                      const SizedBox(height: 12.0),
                      Text(
                        'No staff found in this category',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ]
              // Staff Cards
              else
                ...filteredStaff.map((staff) {
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
                      children: [
                        // Avatar + Details
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(29.0),
                              child: Container(
                                width: 58.0,
                                height: 58.0,
                                color: const Color(0xFFE8F3ED),
                                child: staff.displayPhoto.isNotEmpty
                                    ? Image.network(
                                        staff.displayPhoto,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => const Center(
                                          child: Icon(
                                            Icons.person_rounded,
                                            color: AppColors.primary,
                                            size: 30.0,
                                          ),
                                        ),
                                      )
                                    : const Center(
                                        child: Icon(
                                          Icons.person_rounded,
                                          color: AppColors.primary,
                                          size: 30.0,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 14.0),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    staff.name,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15.0,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 3.0),
                                  Text(
                                    staff.formattedRole,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13.0,
                                      color: const Color(0xFF6B7280),
                                    ),
                                  ),
                                  const SizedBox(height: 3.0),
                                  Text(
                                    staff.phone.startsWith('+91')
                                        ? staff.phone
                                        : staff.phone.isNotEmpty
                                            ? '+91 ${staff.phone}'
                                            : '',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13.0,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF4B5563),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14.0),

                        // Call Action Button (Direct call dialer redirect)
                        SizedBox(
                          width: double.infinity,
                          height: 38.0,
                          child: OutlinedButton(
                            onPressed: () => _makeCall(staff),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.primary, width: 1.2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.call_rounded, size: 16.0, color: AppColors.primary),
                                const SizedBox(width: 8.0),
                                Text(
                                  'Call',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 20.0),
            ],
          ),
        ),
      ),
    );
  }
}
