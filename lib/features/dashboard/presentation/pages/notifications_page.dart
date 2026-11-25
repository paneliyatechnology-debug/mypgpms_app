import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../common/widgets/common_bottom_nav_bar.dart';
import '../../../../core/colors/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../injection_container.dart' as di;
import '../../data/datasources/notices_remote_data_source.dart';
import '../../data/models/notice_model.dart';

class _FilterItem {
  final String label;
  final String query;

  const _FilterItem({
    required this.label,
    required this.query,
  });
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> with SingleTickerProviderStateMixin {
  int _selectedFilterIndex = 0;

  final List<_FilterItem> _filters = const [
    _FilterItem(label: 'All', query: 'all'),
    _FilterItem(label: 'Maintenance', query: 'maintenance'),
    _FilterItem(label: 'Safety', query: 'safety'),
    _FilterItem(label: 'Event', query: 'event'),
    _FilterItem(label: 'General', query: 'general'),
    _FilterItem(label: 'Important', query: 'important'),
  ];

  List<NoticeItemModel> _notices = [];
  NoticesMetaModel? _meta;
  bool _isLoading = true;
  String? _errorMessage;

  late AnimationController _animController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.4, end: 0.9).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
    _fetchNotices();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String get _currentCategoryQuery => _filters[_selectedFilterIndex].query;

  Future<void> _fetchNotices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dataSource = di.sl<NoticesRemoteDataSource>();
      final response = await dataSource.getNotices(
        category: _currentCategoryQuery,
        page: 1,
        limit: 20,
      );

      if (mounted) {
        setState(() {
          _notices = response.data;
          _meta = response.meta;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '').replaceAll('ServerException: ', '');
        });
      }
    }
  }

  Future<void> _onNoticeTap(NoticeItemModel item) async {
    // If unread, mark as read immediately in local state and call PATCH API
    if (!item.isRead) {
      setState(() {
        final index = _notices.indexWhere((n) => n.id == item.id);
        if (index != -1) {
          _notices[index] = NoticeItemModel(
            id: item.id,
            title: item.title,
            category: item.category,
            priority: item.priority,
            summary: item.summary,
            content: item.content,
            dateTime: item.dateTime,
            sentAt: item.sentAt,
            isRead: true,
            readAt: DateTime.now().toIso8601String(),
            hasAttachment: item.hasAttachment,
            attachment: item.attachment,
          );
        }
        if (_meta != null && _meta!.unreadCount > 0) {
          _meta = NoticesMetaModel(
            page: _meta!.page,
            limit: _meta!.limit,
            totalRecords: _meta!.totalRecords,
            totalPages: _meta!.totalPages,
            hasNext: _meta!.hasNext,
            hasPrev: _meta!.hasPrev,
            unreadCount: _meta!.unreadCount - 1,
          );
        }
      });
      try {
        await di.sl<NoticesRemoteDataSource>().markNoticeAsRead(item.id);
      } catch (_) {}
    }

    if (!mounted) return;
    final updatedNotice = await Navigator.of(context).pushNamed(
      AppRoutes.noticeDetails,
      arguments: item,
    );
    if (updatedNotice is NoticeItemModel && mounted) {
      setState(() {
        final index = _notices.indexWhere((n) => n.id == updatedNotice.id);
        if (index != -1) {
          _notices[index] = updatedNotice;
        }
      });
    }
  }

  Future<void> _markAllAsRead() async {
    setState(() {
      _notices = _notices.map((n) {
        return NoticeItemModel(
          id: n.id,
          title: n.title,
          category: n.category,
          priority: n.priority,
          summary: n.summary,
          content: n.content,
          dateTime: n.dateTime,
          sentAt: n.sentAt,
          isRead: true,
          readAt: DateTime.now().toIso8601String(),
          hasAttachment: n.hasAttachment,
          attachment: n.attachment,
        );
      }).toList();

      if (_meta != null) {
        _meta = NoticesMetaModel(
          page: _meta!.page,
          limit: _meta!.limit,
          totalRecords: _meta!.totalRecords,
          totalPages: _meta!.totalPages,
          hasNext: _meta!.hasNext,
          hasPrev: _meta!.hasPrev,
          unreadCount: 0,
        );
      }
    });

    try {
      await di.sl<NoticesRemoteDataSource>().markAllNoticesAsRead();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
            content: Text(
              'All notifications marked as read',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 13.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }
    } catch (_) {}
  }

  String _formatNoticeDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    final cleaned = raw.trim();
    return cleaned
        .replaceAll(' • ', ', ')
        .replaceAll('January', 'Jan')
        .replaceAll('February', 'Feb')
        .replaceAll('March', 'Mar')
        .replaceAll('April', 'Apr')
        .replaceAll('May', 'May')
        .replaceAll('June', 'Jun')
        .replaceAll('July', 'Jul')
        .replaceAll('August', 'Aug')
        .replaceAll('September', 'Sep')
        .replaceAll('October', 'Oct')
        .replaceAll('November', 'Nov')
        .replaceAll('December', 'Dec');
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth > 600 ? (screenWidth - 460) / 2 : 16.0;
    final int unreadCount = _meta?.unreadCount ?? _notices.where((n) => !n.isRead).length;

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
          'Notifications',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18.0,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        centerTitle: false,
        actions: [
          if (unreadCount > 0 || _notices.any((n) => !n.isRead))
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                'Mark all read',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 4.0),

            // Clean Filter Pills Row
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: List.generate(_filters.length, (index) {
                    final item = _filters[index];
                    final isSelected = _selectedFilterIndex == index;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
                      child: InkWell(
                        onTap: () {
                          if (_selectedFilterIndex != index) {
                            setState(() {
                              _selectedFilterIndex = index;
                            });
                            _fetchNotices();
                          }
                        },
                        borderRadius: BorderRadius.circular(999.0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 7.0),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : const Color(0xFFE8F3ED),
                            borderRadius: BorderRadius.circular(999.0),
                          ),
                          child: Text(
                            item.label,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                              color: isSelected ? Colors.white : AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 6.0),

            // Notification List
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: Colors.white,
                onRefresh: _fetchNotices,
                child: _buildListContent(horizontalPadding),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CommonBottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildListContent(double horizontalPadding) {
    if (_isLoading) {
      return _buildSkeletonLoader(horizontalPadding);
    }

    if (_errorMessage != null) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50.0,
                  height: 50.0,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.cloud_off_rounded, size: 24.0, color: Color(0xFFDC2626)),
                ),
                const SizedBox(height: 14.0),
                Text(
                  'Unable to load notifications',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15.0,
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
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: _fetchNotices,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                  ),
                  child: Text(
                    'Try Again',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13.0, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_notices.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.18),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
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
                      Icons.notifications_none_rounded,
                      size: 30.0,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    'No notifications',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  Text(
                    'You\'re all caught up with announcements and notices.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.0,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 4.0),
      itemCount: _notices.length,
      separatorBuilder: (context, index) => const SizedBox(height: 6.0),
      itemBuilder: (context, index) {
        final notif = _notices[index];
        return _buildNoticeCard(notif);
      },
    );
  }

  Widget _buildNoticeCard(NoticeItemModel notif) {
    final String desc = (notif.summary != null && notif.summary!.isNotEmpty)
        ? notif.summary!
        : (notif.content ?? '');
    final String dateText = _formatNoticeDate(notif.dateTime ?? notif.sentAt);
    final bool isUnread = !notif.isRead;
    final String priority = (notif.priority ?? '').toLowerCase();
    final bool isHighPriority = priority == 'high' || priority == 'urgent';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isUnread ? AppColors.primary.withValues(alpha: 0.3) : const Color(0xFFE5E7EB),
          width: 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onNoticeTap(notif),
          borderRadius: BorderRadius.circular(12.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 9.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Compact circular leading icon
                Container(
                  width: 36.0,
                  height: 36.0,
                  decoration: BoxDecoration(
                    color: isUnread ? const Color(0xFFE8F3ED) : const Color(0xFFF3F4F6),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      notif.icon,
                      color: isUnread ? AppColors.primary : const Color(0xFF6B7280),
                      size: 18.0,
                    ),
                  ),
                ),
                const SizedBox(width: 10.0),

                // Notice Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Top Row: Title & Date
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              notif.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6.0),
                          Text(
                            dateText,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.0,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),

                      // Description
                      if (desc.isNotEmpty) ...[
                        const SizedBox(height: 2.0),
                        Text(
                          desc,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.0,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF6B7280),
                            height: 1.3,
                          ),
                        ),
                      ],

                      // Attachment Preview (if any)
                      if (notif.hasAttachment && notif.attachment != null) ...[
                        const SizedBox(height: 4.0),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.attach_file_rounded,
                              size: 12.0,
                              color: Color(0xFF6B7280),
                            ),
                            const SizedBox(width: 3.0),
                            Flexible(
                              child: Text(
                                notif.attachment!.fileName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 5.0),

                      // Bottom Metadata: Category Tag & Unread Badge
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: Text(
                              notif.displayCategory,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF4B5563),
                              ),
                            ),
                          ),
                          if (isHighPriority) ...[
                            const SizedBox(width: 4.0),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                              child: Text(
                                'High',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.0,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFDC2626),
                                ),
                              ),
                            ),
                          ],
                          const Spacer(),
                          if (isUnread)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 5.5,
                                  height: 5.5,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 3.5),
                                Text(
                                  'New',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader(double horizontalPadding) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final opacity = _pulseAnimation.value;
        return ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 4.0),
          itemCount: 4,
          separatorBuilder: (context, index) => const SizedBox(height: 6.0),
          itemBuilder: (context, index) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 9.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36.0,
                    height: 36.0,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB).withValues(alpha: opacity),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 110.0,
                              height: 13.0,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE5E7EB).withValues(alpha: opacity),
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                            ),
                            Container(
                              width: 45.0,
                              height: 10.0,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE5E7EB).withValues(alpha: opacity),
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5.0),
                        Container(
                          width: double.infinity,
                          height: 11.0,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5E7EB).withValues(alpha: opacity),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                        ),
                        const SizedBox(height: 7.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 50.0,
                              height: 15.0,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE5E7EB).withValues(alpha: opacity),
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                            ),
                            Container(
                              width: 28.0,
                              height: 10.0,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE5E7EB).withValues(alpha: opacity),
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
