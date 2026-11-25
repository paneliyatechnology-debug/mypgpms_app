import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/colors/app_colors.dart';
import '../../../../injection_container.dart' as di;
import '../../data/datasources/complaints_remote_data_source.dart';
import '../../data/models/complaint_model.dart';
import '../widgets/app_video_player_widget.dart';

class ComplaintDetailsPage extends StatefulWidget {
  final ComplaintItemModel? complaint;
  final int? complaintId;

  const ComplaintDetailsPage({
    super.key,
    this.complaint,
    this.complaintId,
  });

  @override
  State<ComplaintDetailsPage> createState() => _ComplaintDetailsPageState();
}

class _ComplaintDetailsPageState extends State<ComplaintDetailsPage> {
  ComplaintItemModel? _complaint;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _complaint = widget.complaint;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initAndFetch();
    });
  }

  void _initAndFetch() {
    if (_complaint == null) {
      final routeArg = ModalRoute.of(context)?.settings.arguments;
      if (routeArg is ComplaintItemModel) {
        setState(() {
          _complaint = routeArg;
        });
      }
    }

    final int? id = _complaint?.id != null && _complaint!.id > 0
        ? _complaint!.id
        : widget.complaintId;

    if (id != null && id > 0) {
      _fetchComplaintDetails(id);
    }
  }

  Future<void> _fetchComplaintDetails([int? targetId]) async {
    final int? id = targetId ?? _complaint?.id ?? widget.complaintId;
    if (id == null || id <= 0) return;

    if (_complaint == null) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final dataSource = di.sl<ComplaintsRemoteDataSource>();
      final fresh = await dataSource.getComplaintDetails(id);
      if (mounted) {
        setState(() {
          _complaint = fresh;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (_complaint == null) {
            _errorMessage = e.toString().replaceFirst('Exception: ', '');
          }
        });
      }
    }
  }

  void _openImagePreview(BuildContext context, int initialIndex) {
    final attachments = _complaint?.attachments ?? [];
    if (attachments.isEmpty) return;

    showDialog(
      context: context,
      useSafeArea: false,
      barrierColor: Colors.black.withValues(alpha: 0.95),
      builder: (ctx) {
        int currentIndex = initialIndex;
        final pageController = PageController(initialPage: initialIndex);

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Scaffold(
              backgroundColor: Colors.transparent,
              body: Stack(
                children: [
                  // Full-screen zoomable PageView (Images + in-app Video Player)
                  PageView.builder(
                    controller: pageController,
                    itemCount: attachments.length,
                    onPageChanged: (idx) {
                      setModalState(() {
                        currentIndex = idx;
                      });
                    },
                    itemBuilder: (context, i) {
                      final item = attachments[i];

                      if (item.isVideo) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14.0),
                            child: AppVideoPlayerWidget(
                              videoUrl: item.fileUrl,
                              autoPlay: true,
                            ),
                          ),
                        );
                      }

                      return Center(
                        child: InteractiveViewer(
                          minScale: 0.8,
                          maxScale: 4.0,
                          clipBehavior: Clip.none,
                          child: Image.network(
                            item.fileUrl,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) => Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.broken_image_rounded,
                                    color: Colors.white70, size: 54.0),
                                const SizedBox(height: 10.0),
                                Text(
                                  'Unable to load image',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white70,
                                    fontSize: 13.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // Top Header Bar
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.75),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: Container(
                                padding: const EdgeInsets.all(6.0),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white,
                                  size: 20.0,
                                ),
                              ),
                            ),
                            if (attachments.length > 1)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 5.0),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(20.0),
                                ),
                                child: Text(
                                  '${currentIndex + 1} / ${attachments.length}',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontSize: 13.0,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )
                            else
                              const SizedBox(width: 40.0),
                            const SizedBox(width: 40.0),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Bottom Filename overlay
                  if (attachments[currentIndex].fileName.isNotEmpty)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: SafeArea(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                          color: Colors.black.withValues(alpha: 0.55),
                          child: Text(
                            attachments[currentIndex].fileName,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white70,
                              fontSize: 12.0,
                            ),
                          ),
                        ),
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

  Widget _buildPhotoThumbnail(ComplaintAttachmentModel att, int index) {
    final isVideo = att.isVideo;

    return GestureDetector(
      onTap: () => _openImagePreview(context, index),
      child: Container(
        width: 76.0,
        height: 76.0,
        decoration: BoxDecoration(
          color: isVideo ? const Color(0xFF1E293B) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 4.0,
              offset: Offset(0, 1),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: isVideo
            ? Stack(
                alignment: Alignment.center,
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF0F172A), Color(0xFF334155)],
                      ),
                    ),
                  ),
                  const Center(
                    child: Icon(
                      Icons.play_circle_fill_rounded,
                      color: Colors.white,
                      size: 34.0,
                    ),
                  ),
                  Positioned(
                    bottom: 4.0,
                    left: 4.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Text(
                        'VIDEO',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    att.fileUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: SizedBox(
                          width: 18.0,
                          height: 18.0,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            color: AppColors.primary,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(Icons.broken_image_rounded, color: Colors.grey, size: 24.0),
                    ),
                  ),
                  Positioned(
                    bottom: 4.0,
                    right: 4.0,
                    child: Container(
                      padding: const EdgeInsets.all(3.5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      child: const Icon(
                        Icons.fullscreen_rounded,
                        color: Colors.white,
                        size: 13.0,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth > 600 ? (screenWidth - 460) / 2 : 16.0;

    final ComplaintItemModel? item = _complaint;

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
          'Complaint Details',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18.0,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: _isLoading && item == null
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : _errorMessage != null && item == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 48.0, color: Colors.redAccent),
                          const SizedBox(height: 12.0),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.0,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16.0),
                          ElevatedButton(
                            onPressed: () => _fetchComplaintDetails(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                            ),
                            child: const Text('Retry', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  )
                : _buildContent(item, horizontalPadding),
      ),
    );
  }

  Widget _buildContent(ComplaintItemModel? item, double horizontalPadding) {
    final String displayId = item?.displayId ?? '#CL-1024';
    final String title = item?.title ?? 'Complaint';
    final String category = item?.category?.name ?? 'General';
    final String description = item?.description ?? '';
    final String status = item?.displayStatus ?? 'In Progress';
    final Color statusTextColor = item?.statusTextColor ?? const Color(0xFF4F46E5);
    final Color statusBgColor = item?.statusBgColor ?? const Color(0xFFEEF2FF);
    final String locationDate = item?.displayLocation ?? 'Room 101';
    final IconData categoryIcon = item?.categoryIcon ?? Icons.cleaning_services_outlined;
    final attachments = item?.attachments ?? [];

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        await _fetchComplaintDetails();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 10.0),
        children: [
          // 1. Top Complaint Status Card
                Container(
                  padding: const EdgeInsets.all(14.0),
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
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44.0,
                        height: 44.0,
                        decoration: const BoxDecoration(
                          color: Color(0xFF0F4734),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(categoryIcon, color: Colors.white, size: 22.0),
                      ),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  displayId,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.0,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9.0, vertical: 3.5),
                                  decoration: BoxDecoration(
                                    color: statusBgColor,
                                    borderRadius: BorderRadius.circular(6.0),
                                  ),
                                  child: Text(
                                    status,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11.0,
                                      fontWeight: FontWeight.w700,
                                      color: statusTextColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3.0),
                            Text(
                              title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3.0),
                            Text(
                              locationDate,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                color: const Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18.0),

                // 2. Details Section
                Text(
                  'Details',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10.0),
                Text(
                  'Category',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.0,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  category,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12.0),

                Text(
                  'Description',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.0,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  description,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 14.0),

                // Attachments / Photos Section
                if (attachments.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        attachments.any((a) => a.isVideo)
                            ? 'Attachments (${attachments.length})'
                            : 'Photos (${attachments.length})',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      Text(
                        'Tap to preview',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.0,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  SizedBox(
                    height: 76.0,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: attachments.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 10.0),
                      itemBuilder: (ctx, i) {
                        return _buildPhotoThumbnail(attachments[i], i);
                      },
                    ),
                  ),
                  const SizedBox(height: 22.0),
                ] else ...[
                  const SizedBox(height: 8.0),
                ],

                // 3. Timeline Section
                Text(
                  'Timeline',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12.0),

                _buildStatusTimeline(item),
                const SizedBox(height: 24.0),
              ],
            ),
    );
  }

  Widget _buildStatusTimeline(ComplaintItemModel? item) {
    final status = (item?.status ?? 'OPEN').toUpperCase();
    final timeline = item?.timeline ?? [];

    // 1. Pending (Submitted) step data
    ComplaintTimelineModel? createdEvent;
    for (final e in timeline) {
      final t = e.eventType.toUpperCase();
      if (t == 'CREATED' || t == 'OPEN') {
        createdEvent = e;
        break;
      }
    }
    final String step1Date = createdEvent?.createdAt.isNotEmpty == true
        ? createdEvent!.createdAt
        : (item?.createdAt.isNotEmpty == true ? item!.createdAt : 'Recent');
    final String step1Desc = createdEvent?.description.isNotEmpty == true
        ? createdEvent!.description
        : 'Complaint created by ${item?.resident?.name ?? 'Resident'}';
    final String step1Subtitle = '$step1Date   •   $step1Desc';

    // 2. In Progress step data
    ComplaintTimelineModel? progressEvent;
    for (final e in timeline) {
      final t = e.eventType.toUpperCase();
      final n = (e.newValue ?? '').toUpperCase();
      if (t == 'ASSIGNED' || t == 'IN_PROGRESS' || t == 'INPROGRESS' || n == 'IN_PROGRESS' || n == 'INPROGRESS') {
        progressEvent = e;
        break;
      }
    }

    final bool isResolved = status == 'RESOLVED' || status == 'CLOSED';
    final bool isProgressCurrent = (status == 'IN_PROGRESS' || status == 'INPROGRESS') && !isResolved;
    final bool isProgressOrBeyond = isProgressCurrent || isResolved || progressEvent != null;

    String step2Subtitle;
    if (progressEvent != null) {
      step2Subtitle = '${progressEvent.createdAt}   •   ${progressEvent.description}';
    } else if (isResolved) {
      step2Subtitle = 'Work completed by maintenance team';
    } else if (isProgressCurrent) {
      step2Subtitle = 'Work is currently in progress';
    } else {
      step2Subtitle = 'Waiting for staff assignment';
    }

    // 3. Resolved step data
    ComplaintTimelineModel? resolvedEvent;
    for (final e in timeline) {
      final t = e.eventType.toUpperCase();
      final n = (e.newValue ?? '').toUpperCase();
      if (t == 'RESOLVED' || t == 'CLOSED' || n == 'RESOLVED' || n == 'CLOSED') {
        resolvedEvent = e;
        break;
      }
    }

    String step3Subtitle;
    if (resolvedEvent != null) {
      final desc = item?.resolutionNotes?.isNotEmpty == true
          ? item!.resolutionNotes!
          : (resolvedEvent.description.isNotEmpty ? resolvedEvent.description : 'Issue has been resolved');
      step3Subtitle = '${resolvedEvent.createdAt}   •   $desc';
    } else if (isResolved) {
      final date = item?.resolvedAt?.isNotEmpty == true ? item!.resolvedAt! : (item?.updatedAt ?? 'Recently');
      final notes = item?.resolutionNotes?.isNotEmpty == true ? item!.resolutionNotes! : 'Issue resolved successfully';
      step3Subtitle = '$date   •   $notes';
    } else {
      step3Subtitle = 'Pending final resolution';
    }

    return Column(
      children: [
        _buildTimelineItem(
          isFirst: true,
          isCompleted: true,
          isActive: false,
          hasActiveNext: isProgressOrBeyond,
          title: 'Pending',
          subtitle: step1Subtitle,
        ),
        _buildTimelineItem(
          isCompleted: isResolved,
          isActive: isProgressCurrent,
          hasActiveNext: isResolved,
          title: 'In Progress',
          subtitle: step2Subtitle,
        ),
        _buildTimelineItem(
          isLast: true,
          isCompleted: isResolved,
          isActive: false,
          hasActiveNext: false,
          title: 'Resolved',
          subtitle: step3Subtitle,
        ),
      ],
    );
  }

  Widget _buildTimelineItem({
    bool isFirst = false,
    bool isLast = false,
    required bool isCompleted,
    bool isActive = false,
    bool hasActiveNext = false,
    required String title,
    required String subtitle,
  }) {
    Color circleColor;
    Widget iconWidget;
    Color titleColor;
    FontWeight titleWeight;

    if (isCompleted) {
      circleColor = AppColors.primary;
      iconWidget = const Icon(Icons.check_rounded, color: Colors.white, size: 14.0);
      titleColor = AppColors.primary;
      titleWeight = FontWeight.w700;
    } else if (isActive) {
      circleColor = const Color(0xFF4F46E5);
      iconWidget = const Icon(Icons.sync_rounded, color: Colors.white, size: 14.0);
      titleColor = const Color(0xFF4F46E5);
      titleWeight = FontWeight.w700;
    } else {
      circleColor = const Color(0xFFE5E7EB);
      iconWidget = Container(
        width: 8.0,
        height: 8.0,
        decoration: const BoxDecoration(
          color: Color(0xFF9CA3AF),
          shape: BoxShape.circle,
        ),
      );
      titleColor = const Color(0xFF9CA3AF);
      titleWeight = FontWeight.w600;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Indicator Circle & Vertical Line
          Column(
            children: [
              Container(
                width: 24.0,
                height: 24.0,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: circleColor,
                  shape: BoxShape.circle,
                ),
                child: iconWidget,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2.0,
                    color: hasActiveNext ? AppColors.primary : const Color(0xFFE5E7EB),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14.0),

          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 4.0 : 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: titleWeight,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.0,
                      color: isCompleted || isActive
                          ? const Color(0xFF6B7280)
                          : const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
