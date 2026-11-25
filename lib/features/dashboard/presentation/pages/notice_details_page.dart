import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/colors/app_colors.dart';
import '../../../../injection_container.dart' as di;
import '../../data/datasources/notices_remote_data_source.dart';
import '../../data/models/notice_model.dart';

class NoticeDetailsPage extends StatefulWidget {
  final dynamic arguments;

  const NoticeDetailsPage({super.key, this.arguments});

  @override
  State<NoticeDetailsPage> createState() => _NoticeDetailsPageState();
}

class _NoticeDetailsPageState extends State<NoticeDetailsPage> {
  int? _noticeId;
  NoticeItemModel? _notice;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _parseArguments();
  }

  void _parseArguments() {
    final args = widget.arguments;
    if (args is NoticeItemModel) {
      _noticeId = args.id;
      _notice = args;
      _isLoading = false;
      _fetchDetails(); // Still fetch fresh details in background
    } else if (args is Map) {
      final idRaw = args['id'] ?? args['noticeId'];
      _noticeId = idRaw is int ? idRaw : int.tryParse(idRaw?.toString() ?? '');
      _fetchDetails();
    } else if (args is int) {
      _noticeId = args;
      _fetchDetails();
    } else if (args is String) {
      _noticeId = int.tryParse(args);
      _fetchDetails();
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Invalid notice parameters provided';
      });
    }
  }

  Future<void> _fetchDetails() async {
    if (_noticeId == null) return;

    if (_notice == null) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final dataSource = di.sl<NoticesRemoteDataSource>();
      final response = await dataSource.getNoticeDetails(_noticeId!);

      if (mounted) {
        if (response.data != null) {
          setState(() {
            _notice = response.data;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
            if (_notice == null) {
              _errorMessage = response.message ?? 'Notice details not found';
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (_notice == null) {
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

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1.0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary, size: 18.0),
          onPressed: () => Navigator.of(context).pop(_notice),
        ),
        title: Text(
          'Notice Details',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary, size: 20.0),
            onPressed: _fetchDetails,
          ),
        ],
      ),
      body: _buildBody(horizontalPadding),
    );
  }

  Widget _buildBody(double horizontalPadding) {
    if (_isLoading && _notice == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.8),
      );
    }

    if (_errorMessage != null && _notice == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 52.0, color: Color(0xFF9CA3AF)),
              const SizedBox(height: 12.0),
              Text(
                'Notice Not Available',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6.0),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFF6B7280)),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton.icon(
                onPressed: _fetchDetails,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999.0)),
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                ),
                icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 16.0),
                label: const Text('Try Again', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    final item = _notice!;
    final dateTimeStr = item.dateTime ?? item.sentAt ?? 'Recent';
    final hasPriority = item.priority != null && item.priority!.isNotEmpty;
    final isPriorityHigh = (item.priority ?? '').toLowerCase() == 'high' || (item.priority ?? '').toLowerCase() == 'urgent';

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _fetchDetails,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Main Notice Header Card
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18.0),
                border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x05000000),
                    blurRadius: 10.0,
                    offset: Offset(0, 2.0),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges Row
                  Row(
                    children: [
                      Container(
                        width: 44.0,
                        height: 44.0,
                        decoration: BoxDecoration(
                          color: item.iconBg,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(item.icon, color: item.iconColor, size: 22.0),
                      ),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: Wrap(
                          spacing: 8.0,
                          runSpacing: 4.0,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                              decoration: BoxDecoration(
                                color: item.iconBg,
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Text(
                                item.displayCategory,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w700,
                                  color: item.tagColor,
                                ),
                              ),
                            ),
                            if (hasPriority)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                                decoration: BoxDecoration(
                                  color: isPriorityHigh ? const Color(0xFFFEE2E2) : const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isPriorityHigh ? Icons.priority_high_rounded : Icons.info_outline_rounded,
                                      size: 13.0,
                                      color: isPriorityHigh ? const Color(0xFFDC2626) : const Color(0xFF4B5563),
                                    ),
                                    const SizedBox(width: 4.0),
                                    Text(
                                      '${item.priority!.toUpperCase()} PRIORITY',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11.0,
                                        fontWeight: FontWeight.w700,
                                        color: isPriorityHigh ? const Color(0xFFDC2626) : const Color(0xFF4B5563),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),

                  // Notice Title
                  Text(
                    item.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10.0),

                  // Date & Sent Info Row
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(color: const Color(0xFFF3F4F6)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 15.0, color: Color(0xFF9CA3AF)),
                        const SizedBox(width: 6.0),
                        Expanded(
                          child: Text(
                            dateTimeStr,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.0,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.done_all_rounded, size: 13.0, color: Color(0xFF059669)),
                              const SizedBox(width: 4.0),
                              Text(
                                'Read',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF059669),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16.0),

            // Content Section Card
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18.0),
                border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x05000000),
                    blurRadius: 10.0,
                    offset: Offset(0, 2.0),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.notes_rounded, size: 18.0, color: AppColors.primary),
                      const SizedBox(width: 8.0),
                      Text(
                        'Notice Message',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12.0),
                  const Divider(color: Color(0xFFF3F4F6), height: 1.0),
                  const SizedBox(height: 14.0),

                  // Detailed text
                  Text(
                    (item.content != null && item.content!.isNotEmpty)
                        ? item.content!
                        : (item.summary ?? 'No additional details provided.'),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.0,
                      color: const Color(0xFF374151),
                      height: 1.6,
                    ),
                  ),

                  // If summary was distinct from content
                  if (item.summary != null &&
                      item.summary!.isNotEmpty &&
                      item.content != null &&
                      item.content!.isNotEmpty &&
                      item.summary != item.content) ...[
                    const SizedBox(height: 16.0),
                    Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(color: const Color(0xFFF3F4F6)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Summary',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            item.summary!,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              color: const Color(0xFF4B5563),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Attachment Section if available
            if (item.hasAttachment && item.attachment != null) ...[
              const SizedBox(height: 16.0),
              Container(
                padding: const EdgeInsets.all(18.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18.0),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x05000000),
                      blurRadius: 10.0,
                      offset: Offset(0, 2.0),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.attachment_rounded, size: 18.0, color: AppColors.primary),
                        const SizedBox(width: 8.0),
                        Text(
                          'Attachment',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14.0),

                    // If attachment is an image, display preview
                    if (item.attachment!.isImage) ...[
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            barrierColor: Colors.black87,
                            builder: (ctx) => Dialog(
                              backgroundColor: Colors.transparent,
                              insetPadding: const EdgeInsets.all(16.0),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  InteractiveViewer(
                                    minScale: 0.5,
                                    maxScale: 4.0,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12.0),
                                      child: Image.network(
                                        item.attachment!.fileUrl,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, _, _) => Container(
                                          padding: const EdgeInsets.all(24.0),
                                          color: Colors.white,
                                          child: const Text('Unable to load image preview'),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 8.0,
                                    right: 8.0,
                                    child: IconButton(
                                      style: IconButton.styleFrom(backgroundColor: Colors.black54),
                                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                                      onPressed: () => Navigator.of(ctx).pop(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: Container(
                          height: 180.0,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                            color: const Color(0xFFF9FAFB),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Image.network(
                                item.attachment!.fileUrl,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const Icon(
                                  Icons.broken_image_rounded,
                                  color: Colors.grey,
                                  size: 40.0,
                                ),
                              ),
                              Positioned(
                                right: 8.0,
                                bottom: 8.0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                  decoration: BoxDecoration(
                                    color: const Color(0xBF000000),
                                    borderRadius: BorderRadius.circular(6.0),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 14.0),
                                      const SizedBox(width: 4.0),
                                      Text(
                                        'Tap to zoom',
                                        style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      // File info row (for non-image attachments)
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38.0,
                              height: 38.0,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                item.attachment!.isPdf ? Icons.picture_as_pdf_rounded : Icons.attach_file_rounded,
                                color: AppColors.primary,
                                size: 20.0,
                              ),
                            ),
                            const SizedBox(width: 12.0),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.attachment!.fileName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13.0,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  if (item.attachment!.fileSize != null) ...[
                                    const SizedBox(height: 2.0),
                                    Text(
                                      item.attachment!.fileSize!,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11.0,
                                        color: const Color(0xFF9CA3AF),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24.0),
          ],
        ),
      ),
    );
  }
}
