import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/colors/app_colors.dart';
import '../../../../core/network/socket_service.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/storage/preferences_service.dart';
import '../../../../injection_container.dart' as di;
import '../../data/datasources/visitors_remote_data_source.dart';
import '../../data/models/visitor_model.dart';
import '../../../../common/widgets/common_bottom_nav_bar.dart';
import '../../../../common/widgets/common_filter_pills.dart';
import '../../../../common/widgets/common_status_badge.dart';

class VisitorsPage extends StatefulWidget {
  const VisitorsPage({super.key});

  @override
  State<VisitorsPage> createState() => _VisitorsPageState();
}

class _VisitorsPageState extends State<VisitorsPage> {
  int _selectedFilterIndex = 0; // 0: All, 1: Approved, 2: Pending
  bool _isLoading = false;
  String? _errorMessage;
  List<VisitorItemModel> _visitors = [];
  Timer? _autoSyncTimer;

  @override
  void initState() {
    super.initState();
    _loadCachedVisitors();
    _fetchVisitors();
    _setupSocketListeners();
    // Background polling fallback to guarantee 100% sync even if socket disconnects
    _autoSyncTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (mounted) {
        _fetchVisitors(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _autoSyncTimer?.cancel();
    _teardownSocketListeners();
    super.dispose();
  }

  void _setupSocketListeners() {
    try {
      final socket = di.sl<SocketService>();
      socket.connect();
      socket.on(SocketEvents.visitorNew, _onSocketVisitorRefresh);
      socket.on(SocketEvents.visitorStatusUpdated, _onSocketVisitorStatusUpdated);
      socket.on(SocketEvents.visitorEntry, _onSocketVisitorEntry);
      socket.on(SocketEvents.visitorStatsUpdated, _onSocketVisitorRefresh);
      socket.on(SocketEvents.dashboardStatsUpdated, _onSocketVisitorRefresh);
      // Catch-all: If ANY event has "visitor" in its name or is "dashboard:stats_updated", refresh!
      socket.onAny(_onSocketAnyEvent);
    } catch (e) {
      debugPrint('[VisitorsPage] Error setting up socket listeners: $e');
    }
  }

  void _teardownSocketListeners() {
    try {
      final socket = di.sl<SocketService>();
      socket.off(SocketEvents.visitorNew, _onSocketVisitorRefresh);
      socket.off(SocketEvents.visitorStatusUpdated, _onSocketVisitorStatusUpdated);
      socket.off(SocketEvents.visitorEntry, _onSocketVisitorEntry);
      socket.off(SocketEvents.visitorStatsUpdated, _onSocketVisitorRefresh);
      socket.off(SocketEvents.dashboardStatsUpdated, _onSocketVisitorRefresh);
      socket.offAny(_onSocketAnyEvent);
    } catch (_) {}
  }

  void _onSocketVisitorRefresh(dynamic data) {
    if (!mounted) return;
    debugPrint('[VisitorsPage] Socket visitor refresh event received.');
    _fetchVisitors(silent: true);
  }

  void _onSocketAnyEvent(String event, dynamic data) {
    if (!mounted) return;
    final lower = event.toLowerCase();
    if (lower.contains('visitor') || lower == 'dashboard:stats_updated') {
      debugPrint('[VisitorsPage] Catch-all socket triggered refresh on event: "$event"');
      _fetchVisitors(silent: true);
    }
  }

  void _onSocketVisitorStatusUpdated(dynamic data) {
    if (!mounted) return;
    _fetchVisitors(silent: true);
    if (data is Map) {
      final name = data['visitor_name']?.toString() ?? 'Visitor';
      final status = data['status']?.toString() ?? '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Visitor pass for $name is now $status',
            style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          backgroundColor: status.toLowerCase() == 'approved' ? const Color(0xFF059669) : AppColors.primary,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _onSocketVisitorEntry(dynamic data) {
    if (!mounted) return;
    _fetchVisitors(silent: true);
    if (data is Map) {
      final name = data['visitor_name']?.toString() ?? 'Visitor';
      final action = data['action']?.toString() ?? 'ENTRY';
      final gate = data['gate_name']?.toString() ?? 'Main Gate';
      final logTime = data['log_time']?.toString() ?? '';
      final actionText = action.toUpperCase() == 'ENTRY' ? 'entered' : 'exited';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Visitor $name $actionText at $gate${logTime.isNotEmpty ? ' ($logTime)' : ''}',
            style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _loadCachedVisitors() {
    try {
      final prefService = di.sl<PreferencesService>();
      final cached = prefService.getSavedVisitorsList();
      if (cached != null && cached.isNotEmpty) {
        setState(() {
          _visitors = cached.map((e) => VisitorItemModel.fromJson(e)).toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchVisitors({bool silent = false}) async {
    if (!silent || _visitors.isEmpty) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final prefService = di.sl<PreferencesService>();
      final savedUser = prefService.getSavedUser();
      int? residentId;
      if (savedUser?['resident_id'] != null) {
        residentId = int.tryParse(savedUser!['resident_id'].toString());
      } else if (savedUser?['id'] != null) {
        residentId = int.tryParse(savedUser!['id'].toString());
      }

      final dataSource = di.sl<VisitorsRemoteDataSource>();
      final result = await dataSource.getVisitors(
        status: 'all',
        purpose: 'all',
        page: 1,
        limit: 20,
        residentId: residentId,
      );

      if (mounted) {
        setState(() {
          _visitors = result;
          _isLoading = false;
          _errorMessage = null;
        });

        try {
          await prefService.saveVisitorsList(result.map((e) => e.toJson()).toList());
        } catch (_) {}
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (_visitors.isEmpty) {
            _errorMessage = e.toString().replaceAll('Exception: ', '').replaceAll('ServerException: ', '');
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth > 600 ? (screenWidth - 460) / 2 : 16.0;

    final approvedVisitors = _visitors
        .where((v) => v.isApproved)
        .toList();
    final pendingVisitors = _visitors.where((v) => v.isPending).toList();

    final filters = [
      'All (${_visitors.length})',
      'Approved (${approvedVisitors.length})',
      'Pending (${pendingVisitors.length})',
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8F6),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary, size: 18.0),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Visitors',
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
          onRefresh: _fetchVisitors,
          color: AppColors.primary,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 6.0),
            children: [
              // Filter Pills Row (0: All, 1: Approved, 2: Pending)
              CommonFilterPills(
                labels: filters,
                selectedIndex: _selectedFilterIndex,
                onSelected: (index) {
                  setState(() {
                    _selectedFilterIndex = index;
                  });
                },
              ),
              const SizedBox(height: 14.0),

              if (_isLoading && _visitors.isEmpty) ...[
                const SizedBox(height: 60.0),
                const Center(
                  child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
                ),
                const SizedBox(height: 60.0),
              ] else if (_errorMessage != null && _visitors.isEmpty) ...[
                _buildErrorState(),
              ] else ...[
                // Tab 0: All Visitors
                if (_selectedFilterIndex == 0) ...[
                  if (_visitors.isNotEmpty) ...[
                    ..._visitors.map((v) => Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: _buildVisitorTile(v),
                        )),
                    const SizedBox(height: 4.0),
                  ] else ...[
                    _buildEmptyStateCard('No visitors found.'),
                    const SizedBox(height: 16.0),
                  ],
                ]
                // Tab 1: Approved Visitors
                else if (_selectedFilterIndex == 1) ...[
                  if (approvedVisitors.isNotEmpty) ...[
                    ...approvedVisitors.map((v) => Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: _buildVisitorTile(v),
                        )),
                    const SizedBox(height: 4.0),
                  ] else ...[
                    _buildEmptyStateCard('No approved visitors found.'),
                    const SizedBox(height: 16.0),
                  ],
                ]
                // Tab 2: Pending Visitors
                else ...[
                  if (pendingVisitors.isNotEmpty) ...[
                    ...pendingVisitors.map((v) => Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: _buildVisitorTile(v),
                        )),
                    const SizedBox(height: 4.0),
                  ] else ...[
                    _buildEmptyStateCard('No pending visitor requests.'),
                    const SizedBox(height: 16.0),
                  ],
                ],
              ],

              // Add Visitor Button
              InkWell(
                onTap: () async {
                  final added = await Navigator.of(context).pushNamed(AppRoutes.addVisitor);
                  if (added == true && mounted) {
                    _fetchVisitors();
                  }
                },
                borderRadius: BorderRadius.circular(999.0),
                child: Container(
                  width: double.infinity,
                  height: 48.0,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(999.0),
                  ),
                  child: Text(
                    'Add Visitor',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24.0),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CommonBottomNavBar(currentIndex: 3),
    );
  }

  Widget _buildVisitorTile(VisitorItemModel v) {
    final statusText = v.displayStatus;
    final statusBgColor = v.statusBgColor;
    final statusTextColor = v.statusTextColor;

    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 22.0,
            backgroundColor: const Color(0xFFE8F3ED),
            child: Text(
              v.initials,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  v.visitorName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  v.visitorPhone,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.0,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  v.formattedVisitInfo.isNotEmpty ? v.formattedVisitInfo : (v.visitDate),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              CommonStatusBadge(
                label: statusText,
                backgroundColor: statusBgColor,
                textColor: statusTextColor,
              ),
              if (v.isPending) ...[
                const SizedBox(height: 8.0),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => _openEditVisitor(v),
                      borderRadius: BorderRadius.circular(6.0),
                      child: Container(
                        padding: const EdgeInsets.all(5.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        child: const Icon(
                          Icons.edit_outlined,
                          size: 16.0,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    InkWell(
                      onTap: () => _confirmDeleteVisitor(v),
                      borderRadius: BorderRadius.circular(6.0),
                      child: Container(
                        padding: const EdgeInsets.all(5.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          size: 16.0,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openEditVisitor(VisitorItemModel v) async {
    final updated = await Navigator.of(context).pushNamed(
      AppRoutes.addVisitor,
      arguments: v,
    );
    if (updated == true && mounted) {
      _fetchVisitors();
    }
  }

  Future<void> _confirmDeleteVisitor(VisitorItemModel v) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        backgroundColor: Colors.white,
        title: Text(
          'Delete Visitor Request',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 17.0,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to delete the visitor request for "${v.visitorName}"?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5,
            color: const Color(0xFF4B5563),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6B7280),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      _deleteVisitor(v.id);
    }
  }

  Future<void> _deleteVisitor(int visitorId) async {
    try {
      final dataSource = di.sl<VisitorsRemoteDataSource>();
      final response = await dataSource.deleteVisitor(visitorId);

      if (mounted) {
        try {
          di.sl<SocketService>().notifyVisitorUpdated({'id': visitorId, 'action': 'deleted'});
        } catch (_) {}
        final msg = response['message']?.toString() ?? 'Visitor request deleted successfully';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              msg,
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: Colors.white),
            ),
            backgroundColor: AppColors.primary,
          ),
        );
        _fetchVisitors();
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceAll('Exception: ', '').replaceAll('ServerException: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMsg,
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: Colors.white),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildEmptyStateCard(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
      ),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.person_outline_rounded, size: 36.0, color: Colors.grey.shade400),
          const SizedBox(height: 8.0),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.0,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, size: 40.0, color: AppColors.error),
          const SizedBox(height: 10.0),
          Text(
            _errorMessage ?? 'Failed to load visitors',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12.0),
          ElevatedButton(
            onPressed: _fetchVisitors,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
            ),
            child: const Text('Try Again', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
