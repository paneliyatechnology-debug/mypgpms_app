import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/colors/app_colors.dart';
import '../../../../core/network/socket_service.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/storage/preferences_service.dart';
import '../../../../injection_container.dart' as di;
import '../../data/datasources/complaints_remote_data_source.dart';
import '../../data/models/complaint_model.dart';

class MyComplaintsPage extends StatefulWidget {
  const MyComplaintsPage({super.key});

  @override
  State<MyComplaintsPage> createState() => _MyComplaintsPageState();
}

class _MyComplaintsPageState extends State<MyComplaintsPage> {
  String _selectedFilter = 'All';
  bool _isLoading = true;
  String? _errorMessage;
  List<ComplaintItemModel> _complaints = [];
  Timer? _complaintAutoSyncTimer;

  final List<String> _filters = ['All', 'Pending', 'In Progress', 'Resolved', 'Closed'];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _setupSocketListeners();
    _complaintAutoSyncTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) _fetchComplaints(silent: true);
    });
  }

  @override
  void dispose() {
    _complaintAutoSyncTimer?.cancel();
    _teardownSocketListeners();
    super.dispose();
  }

  void _setupSocketListeners() {
    try {
      final socket = di.sl<SocketService>();
      socket.connect();
      socket.on(SocketEvents.complaintNew, _onSocketComplaintEvent);
      socket.on(SocketEvents.complaintStatusUpdated, _onSocketComplaintStatusUpdated);
      socket.on(SocketEvents.complaintActivity, _onSocketComplaintEvent);
      socket.on(SocketEvents.complaintStatsUpdated, _onSocketComplaintEvent);
      socket.on(SocketEvents.dashboardStatsUpdated, _onSocketComplaintEvent);
      socket.onAny(_onSocketAnyEvent);
    } catch (_) {}
  }

  void _teardownSocketListeners() {
    try {
      final socket = di.sl<SocketService>();
      socket.off(SocketEvents.complaintNew, _onSocketComplaintEvent);
      socket.off(SocketEvents.complaintStatusUpdated, _onSocketComplaintStatusUpdated);
      socket.off(SocketEvents.complaintActivity, _onSocketComplaintEvent);
      socket.off(SocketEvents.complaintStatsUpdated, _onSocketComplaintEvent);
      socket.off(SocketEvents.dashboardStatsUpdated, _onSocketComplaintEvent);
      socket.offAny(_onSocketAnyEvent);
    } catch (_) {}
  }

  void _onSocketComplaintEvent(dynamic data) {
    if (!mounted) return;
    _fetchComplaints(silent: true);
  }

  void _onSocketAnyEvent(String event, dynamic data) {
    if (!mounted) return;
    final lower = event.toLowerCase();
    if (lower.contains('complaint') || lower == 'dashboard:stats_updated') {
      debugPrint('[MyComplaintsPage] Real-time event "$event" triggered complaint refresh.');
      _fetchComplaints(silent: true);
    }
  }

  void _onSocketComplaintStatusUpdated(dynamic data) {
    if (!mounted) return;
    _fetchComplaints(silent: true);
    if (data is Map) {
      final num = data['complaint_number']?.toString() ?? '';
      final status = data['status']?.toString() ?? '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Complaint $num status updated to $status',
            style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _loadInitialData() {
    // 1. Load cached complaints for instant display
    try {
      final prefService = di.sl<PreferencesService>();
      final cached = prefService.getSavedComplaintsList();
      if (cached != null && cached.isNotEmpty) {
        final parsed = cached.map((e) => ComplaintItemModel.fromJson(e)).toList();
        if (parsed.isNotEmpty) {
          _complaints = parsed;
          _isLoading = false;
        }
      }
    } catch (_) {}

    // 2. Fetch fresh complaints from API
    _fetchComplaints();
  }

  Future<void> _fetchComplaints({bool silent = false}) async {
    if (!silent || _complaints.isEmpty) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final dataSource = di.sl<ComplaintsRemoteDataSource>();
      final result = await dataSource.getComplaints(
        status: 'all',
        page: 1,
        limit: 30,
      );

      if (mounted) {
        setState(() {
          _complaints = result;
          _isLoading = false;
          _errorMessage = null;
        });

        // Save fresh list to cache
        try {
          final prefService = di.sl<PreferencesService>();
          await prefService.saveComplaintsList(result.map((e) => e.toJson()).toList());
        } catch (_) {}
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (_complaints.isEmpty) {
            _errorMessage = e.toString();
          }
        });
      }
    }
  }

  List<ComplaintItemModel> _getFilteredComplaints() {
    if (_selectedFilter == 'All') {
      return _complaints;
    }
    return _complaints.where((c) {
      final status = c.displayStatus.toLowerCase();
      final filter = _selectedFilter.toLowerCase();
      if (filter == 'pending') {
        return status == 'pending' || status == 'open';
      }
      return status == filter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth > 600 ? (screenWidth - 460) / 2 : 16.0;

    final filteredComplaints = _getFilteredComplaints();

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
          'My Complaints',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18.0,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 24.0),
            tooltip: 'New Complaint',
            onPressed: () async {
              final result = await Navigator.of(context).pushNamed(AppRoutes.reportIssue);
              if (result == true || mounted) {
                _fetchComplaints();
              }
            },
          ),
          const SizedBox(width: 8.0),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchComplaints,
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
                  children: _filters.map((filter) {
                    final isSelected = _selectedFilter.toLowerCase() == filter.toLowerCase();
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedFilter = filter;
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
                            filter,
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
              if (_isLoading && _complaints.isEmpty) ...[
                const SizedBox(height: 60.0),
                const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                const SizedBox(height: 60.0),
              ]
              // Error State
              else if (_errorMessage != null && _complaints.isEmpty) ...[
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
                        'Unable to load complaints',
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
                        style: GoogleFonts.plusJakartaSans(fontSize: 12.0, color: const Color(0xFF6B7280)),
                      ),
                      const SizedBox(height: 16.0),
                      ElevatedButton(
                        onPressed: _fetchComplaints,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                        ),
                        child: Text(
                          'Retry',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ]
              // Empty State (Clean, centered, without the report an issue button)
              else if (filteredComplaints.isEmpty) ...[
                const SizedBox(height: 80.0),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64.0,
                        height: 64.0,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE8F3ED),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.inbox_outlined,
                          size: 32.0,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      Text(
                        'No complaints found',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6.0),
                      Text(
                        _selectedFilter == 'All'
                            ? 'You have not submitted any complaints yet.'
                            : 'No complaints under $_selectedFilter.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.0,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 80.0),
              ]
              // Complaints List
              else
                ...filteredComplaints.map((item) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12.0),
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          AppRoutes.complaintDetails,
                          arguments: item,
                        );
                      },
                      borderRadius: BorderRadius.circular(14.0),
                      child: Container(
                        padding: const EdgeInsets.all(14.0),
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
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 42.0,
                              height: 42.0,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE8F3ED),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                item.categoryIcon,
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
                                    item.displayId,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12.0,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2.0),
                                  Text(
                                    item.title,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1F2937),
                                    ),
                                  ),
                                  const SizedBox(height: 3.0),
                                  Text(
                                    item.displayLocation,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11.0,
                                      color: const Color(0xFF9CA3AF),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9.0, vertical: 4.0),
                              decoration: BoxDecoration(
                                color: item.statusBgColor,
                                borderRadius: BorderRadius.circular(6.0),
                              ),
                              child: Text(
                                item.displayStatus,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.w700,
                                  color: item.statusTextColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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
