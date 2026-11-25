import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/colors/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/storage/preferences_service.dart';
import '../../../../injection_container.dart' as di;
import '../../data/datasources/payments_remote_data_source.dart';
import '../../data/models/payment_item_model.dart';
import '../../data/models/payments_overview_model.dart';

class RentDetailsPage extends StatefulWidget {
  final dynamic payment;

  const RentDetailsPage({super.key, this.payment});

  @override
  State<RentDetailsPage> createState() => _RentDetailsPageState();
}

class _RentDetailsPageState extends State<RentDetailsPage> {
  PaymentsOverviewDataModel? _paymentsData;
  List<PaymentRecordModel> _transactions = [];
  PaymentRecordModel? _record;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    int? targetId;
    if (widget.payment is PaymentRecordModel) {
      _record = widget.payment as PaymentRecordModel;
      targetId = _record?.id;
    } else if (widget.payment is PaymentDetailsDataModel) {
      _record = PaymentRecordModel.fromDetails(widget.payment as PaymentDetailsDataModel);
      targetId = _record?.id;
    } else if (widget.payment is Map<String, dynamic>) {
      _record = PaymentRecordModel.fromJson(widget.payment as Map<String, dynamic>);
      targetId = _record?.id;
    } else if (widget.payment is int) {
      targetId = widget.payment as int;
    } else if (widget.payment is String) {
      targetId = int.tryParse(widget.payment as String);
    }

    _loadLocalCachedData();
    _fetchPaymentsOverview();
    _fetchPaymentsList();

    if (targetId != null) {
      _fetchPaymentDetails(targetId);
    }
  }

  void _loadLocalCachedData() {
    try {
      final prefService = di.sl<PreferencesService>();
      final cachedJson = prefService.getSavedPaymentsOverview();
      if (cachedJson != null) {
        setState(() {
          _paymentsData = PaymentsOverviewDataModel.fromJson(cachedJson);
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchPaymentDetails(int id) async {
    try {
      final dataSource = di.sl<PaymentsRemoteDataSource>();
      final response = await dataSource.getPaymentDetails(id);
      if (mounted && response.data != null) {
        setState(() {
          _record = PaymentRecordModel.fromDetails(response.data!);
          _isLoading = false;
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchPaymentsOverview() async {
    if (_paymentsData == null && _record == null) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final dataSource = di.sl<PaymentsRemoteDataSource>();
      final response = await dataSource.getPaymentsOverview();
      if (mounted && response.data != null) {
        setState(() {
          _paymentsData = response.data;
          _isLoading = false;
        });
        final prefService = di.sl<PreferencesService>();
        await prefService.savePaymentsOverview(response.data!.toJson());

        if (_record == null && response.data?.outstanding?.paymentId != null) {
          _fetchPaymentDetails(response.data!.outstanding!.paymentId!);
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchPaymentsList() async {
    try {
      final dataSource = di.sl<PaymentsRemoteDataSource>();
      final response = await dataSource.getPayments(status: 'all', page: 1, limit: 10, tab: '');
      if (mounted) {
        setState(() {
          _transactions = response.data;

          if (widget.payment != null) {
            final match = _transactions.cast<PaymentRecordModel?>().firstWhere(
                  (e) => e?.id.toString() == widget.payment.toString(),
                  orElse: () => null,
                );
            if (match != null) {
              _record = match;
            }
          }

          if (_record == null && _transactions.isNotEmpty) {
            _record = _transactions.cast<PaymentRecordModel?>().firstWhere(
                  (e) => e != null && (e.isPending || e.isInReview),
                  orElse: () => _transactions.first,
                );
          }
        });

        final targetId = _record?.id ??
            _paymentsData?.outstanding?.paymentId ??
            (widget.payment is int ? widget.payment as int : null);
        if (targetId != null) {
          _fetchPaymentDetails(targetId);
        }
      }
    } catch (_) {}
  }

  Future<void> _onRefresh() async {
    final targetId = _record?.id ??
        _paymentsData?.outstanding?.paymentId ??
        (widget.payment is int ? widget.payment as int : null);
    await Future.wait([
      _fetchPaymentsOverview(),
      _fetchPaymentsList(),
      if (targetId != null) _fetchPaymentDetails(targetId),
    ]);
  }

  void _openImagePreview(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      useSafeArea: false,
      barrierColor: Colors.black.withValues(alpha: 0.95),
      builder: (ctx) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24.0),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            title: Text(
              'Payment Screenshot',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16.0,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 5.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.broken_image_rounded, color: Colors.white70, size: 54.0),
                    const SizedBox(height: 10.0),
                    Text(
                      'Failed to load image',
                      style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 13.0),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatCurrency(num? amount) {
    if (amount == null) return '₹0';
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth > 600 ? (screenWidth - 460) / 2 : 16.0;

    final outstanding = _paymentsData?.outstanding;
    final record = _record;

    final breakdown = record?.breakdown ?? _paymentsData?.breakdown;
    final billing = record?.billingPeriod ?? _paymentsData?.billingPeriod;

    final String cardTitle = record?.title ?? 'Onboarding Due (Rent, Deposit, Maintenance) - November 2026';
    final num totalAmount = record?.amount ?? outstanding?.amount ?? breakdown?.total ?? 1;

    final String rawStatus = record?.status ?? outstanding?.status ?? 'Pending';
    final String displayStatusText = record?.displayStatus ??
        (rawStatus.toLowerCase() == 'in_review'
            ? 'In Review'
            : (rawStatus.toLowerCase() == 'paid' ? 'Paid' : 'Pending'));
    final bool isPaid = record?.isPaid ?? (rawStatus.toLowerCase() == 'paid');
    final bool isInReview = record?.isInReview ?? (rawStatus.toLowerCase() == 'in_review');
    final bool isPending = record?.isPending ?? (rawStatus.toLowerCase() == 'pending');

    final Color statusBg = record?.statusBgColor ??
        (isInReview
            ? const Color(0xFFDBEAFE)
            : (isPaid ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7)));
    final Color statusTextColor = record?.statusTextColor ??
        (isInReview
            ? const Color(0xFF2563EB)
            : (isPaid ? const Color(0xFF059669) : const Color(0xFFD97706)));

    // Contextual date text
    String dateSubtitle;
    if (isPaid) {
      final paidAt = record?.paidAt ?? record?.updatedAt;
      dateSubtitle = paidAt != null && paidAt.isNotEmpty
          ? 'Paid on $paidAt'
          : 'Payment Completed';
    } else if (isInReview) {
      final subAt = record?.updatedAt ?? record?.createdAt;
      dateSubtitle = subAt != null && subAt.isNotEmpty
          ? 'Submitted on $subAt • Verification pending'
          : 'Payment proof submitted • Under review';
    } else {
      final rawDueDate = record?.dueDate ?? outstanding?.dueDate ?? outstanding?.dueDateText;
      dateSubtitle = rawDueDate != null && rawDueDate.isNotEmpty
          ? (rawDueDate.toLowerCase().contains('due') ? rawDueDate : 'Due on $rawDueDate')
          : 'Due on 25-11-2026 00:00';
    }

    // Billing period formatted
    String billingPeriodText = 'November 2026 (01-11-2026 - 30-11-2026)';
    if (billing != null && billing.start != null && billing.end != null) {
      final startStr = billing.start!.contains(' ') ? billing.start!.split(' ').first : billing.start!;
      final endStr = billing.end!.contains(' ') ? billing.end!.split(' ').first : billing.end!;
      billingPeriodText = 'November 2026 ($startStr - $endStr)';
    }

    // Breakdown Items
    final List<Map<String, dynamic>> breakdownList = [];
    if (breakdown != null) {
      breakdownList.add({
        'label': 'Rent',
        'subtitle': 'Room rent charges',
        'amount': _formatCurrency(breakdown.rent),
        'icon': Icons.apartment_rounded,
        'bgColor': const Color(0xFFE8F3ED),
        'iconColor': AppColors.primary,
      });
      if (breakdown.deposit > 0 || breakdown.securityDeposit > 0) {
        final depositVal = breakdown.deposit > 0 ? breakdown.deposit : breakdown.securityDeposit;
        breakdownList.add({
          'label': 'Security Deposit',
          'subtitle': 'Refundable deposit',
          'amount': _formatCurrency(depositVal),
          'icon': Icons.shield_outlined,
          'bgColor': const Color(0xFFFEF3C7),
          'iconColor': const Color(0xFFD97706),
        });
      }
      breakdownList.add({
        'label': 'Maintenance',
        'subtitle': 'Premises maintenance',
        'amount': _formatCurrency(breakdown.maintenance),
        'icon': Icons.handyman_outlined,
        'bgColor': const Color(0xFFEFF6FF),
        'iconColor': const Color(0xFF2563EB),
      });
      breakdownList.add({
        'label': 'Electricity',
        'subtitle': 'Meter consumption',
        'amount': _formatCurrency(breakdown.electricity),
        'icon': Icons.bolt_rounded,
        'bgColor': const Color(0xFFFEF3C7),
        'iconColor': const Color(0xFFD97706),
      });
      breakdownList.add({
        'label': 'Other',
        'subtitle': 'Additional utilities',
        'amount': _formatCurrency(breakdown.other),
        'icon': Icons.miscellaneous_services_outlined,
        'bgColor': const Color(0xFFF3E8FF),
        'iconColor': const Color(0xFF7C3AED),
      });
    } else {
      breakdownList.addAll([
        {
          'label': 'Rent',
          'subtitle': 'Room rent charges',
          'amount': '₹1',
          'icon': Icons.apartment_rounded,
          'bgColor': const Color(0xFFE8F3ED),
          'iconColor': AppColors.primary,
        },
        {
          'label': 'Maintenance',
          'subtitle': 'Premises maintenance',
          'amount': '₹0',
          'icon': Icons.handyman_outlined,
          'bgColor': const Color(0xFFEFF6FF),
          'iconColor': const Color(0xFF2563EB),
        },
        {
          'label': 'Electricity',
          'subtitle': 'Meter consumption',
          'amount': '₹0',
          'icon': Icons.bolt_rounded,
          'bgColor': const Color(0xFFFEF3C7),
          'iconColor': const Color(0xFFD97706),
        },
        {
          'label': 'Other',
          'subtitle': 'Additional utilities',
          'amount': '₹0',
          'icon': Icons.miscellaneous_services_outlined,
          'bgColor': const Color(0xFFF3E8FF),
          'iconColor': const Color(0xFF7C3AED),
        },
      ]);
    }

    final String? notesText = record?.notes ?? outstanding?.notes;

    String? proofImageUrl = record?.imageUrl;
    if ((proofImageUrl == null || proofImageUrl.isEmpty) && record?.image != null && record!.image!.isNotEmpty) {
      final img = record.image!;
      proofImageUrl = img.startsWith('http') ? img : 'https://api.mypgpms.com/uploads/payments/$img';
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
          'Rent Details',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18.0,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: _isLoading && _paymentsData == null && _record == null
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
              )
            : Column(
                children: [
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _onRefresh,
                      color: AppColors.primary,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8.0),
                        children: [
                          // 1. Hero Due / Paid Status Card
                          Container(
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F3ED),
                              borderRadius: BorderRadius.circular(18.0),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.15), width: 1.0),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        cardTitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13.0,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF4B5563),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8.0),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 9.0, vertical: 3.5),
                                      decoration: BoxDecoration(
                                        color: statusBg,
                                        borderRadius: BorderRadius.circular(6.0),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (isPaid) ...[
                                            const Icon(Icons.check_rounded, color: Color(0xFF059669), size: 12.0),
                                            const SizedBox(width: 3.0),
                                          ] else if (isInReview) ...[
                                            const Icon(Icons.schedule_rounded, color: Color(0xFF2563EB), size: 12.0),
                                            const SizedBox(width: 3.0),
                                          ],
                                          Text(
                                            displayStatusText,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11.0,
                                              fontWeight: FontWeight.w700,
                                              color: statusTextColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8.0),
                                Text(
                                  _formatCurrency(totalAmount),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 28.0,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 6.0),
                                Row(
                                  children: [
                                    Icon(
                                      isPaid ? Icons.check_circle_outline_rounded : Icons.schedule_rounded,
                                      size: 14.0,
                                      color: isPaid ? const Color(0xFF059669) : const Color(0xFF6B7280),
                                    ),
                                    const SizedBox(width: 5.0),
                                    Expanded(
                                      child: Text(
                                        dateSubtitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12.0,
                                          fontWeight: FontWeight.w500,
                                          color: isPaid ? const Color(0xFF059669) : const Color(0xFF6B7280),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16.0),

                          // 2. Billing Period Card
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14.0),
                              border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7.0),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFE8F3ED),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.calendar_month_outlined,
                                    color: AppColors.primary,
                                    size: 18.0,
                                  ),
                                ),
                                const SizedBox(width: 12.0),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Billing Period',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF6B7280),
                                        ),
                                      ),
                                      const SizedBox(height: 1.0),
                                      Text(
                                        billingPeriodText,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13.0,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16.0),

                          // 3. Unified Breakdown & Total Card
                          Text(
                            'Breakdown',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8.0),

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
                            child: Column(
                              children: [
                                for (int i = 0; i < breakdownList.length; i++) ...[
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 11.0),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 34.0,
                                          height: 34.0,
                                          decoration: BoxDecoration(
                                            color: breakdownList[i]['bgColor'] as Color,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            breakdownList[i]['icon'] as IconData,
                                            color: breakdownList[i]['iconColor'] as Color,
                                            size: 17.0,
                                          ),
                                        ),
                                        const SizedBox(width: 12.0),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                breakdownList[i]['label'] as String,
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                              Text(
                                                breakdownList[i]['subtitle'] as String,
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 11.0,
                                                  color: const Color(0xFF9CA3AF),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          breakdownList[i]['amount'] as String,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (i < breakdownList.length - 1)
                                    const Divider(height: 1.0, color: Color(0xFFF3F4F6), indent: 60.0),
                                ],

                                // Integrated Total Row
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF9FAFB),
                                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(15.0)),
                                    border: Border(top: BorderSide(color: Color(0xFFF3F4F6), width: 1.0)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Total',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF374151),
                                        ),
                                      ),
                                      Text(
                                        _formatCurrency(totalAmount),
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14.0),

                          // 4. Remarks / Notes Box
                          if (notesText != null && notesText.trim().isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(12.0),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F3ED),
                                borderRadius: BorderRadius.circular(14.0),
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.12), width: 1.0),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4.0),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.info_outline_rounded,
                                      color: AppColors.primary,
                                      size: 16.0,
                                    ),
                                  ),
                                  const SizedBox(width: 10.0),
                                  Expanded(
                                    child: Text(
                                      notesText,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12.0,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.primary,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14.0),
                          ],

                          // 5. Payment Screenshot Card
                          if (proofImageUrl != null && proofImageUrl.isNotEmpty) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Payment Screenshot',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                if (record?.upiRefNo != null && record!.upiRefNo!.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F3ED),
                                      borderRadius: BorderRadius.circular(6.0),
                                    ),
                                    child: Text(
                                      'UTR: ${record.upiRefNo}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11.0,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8.0),

                            GestureDetector(
                              onTap: () => _openImagePreview(context, proofImageUrl!),
                              child: Container(
                                width: double.infinity,
                                height: 210.0,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16.0),
                                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x06000000),
                                      blurRadius: 8.0,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(15.0),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.network(
                                        proofImageUrl,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return const Center(
                                            child: CircularProgressIndicator(
                                              color: AppColors.primary,
                                              strokeWidth: 2.5,
                                            ),
                                          );
                                        },
                                        errorBuilder: (context, error, stackTrace) {
                                          return Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                const Icon(Icons.broken_image_outlined, color: Color(0xFF9CA3AF), size: 36.0),
                                                const SizedBox(height: 6.0),
                                                Text(
                                                  'Unable to preview screenshot',
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 12.0,
                                                    color: const Color(0xFF6B7280),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                      Positioned(
                                        right: 10.0,
                                        bottom: 10.0,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.65),
                                            borderRadius: BorderRadius.circular(20.0),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 14.0),
                                              const SizedBox(width: 4.0),
                                              Text(
                                                'View Screenshot',
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 11.0,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],

                          // 6. Payment Receipt Card (When Paid)
                          if (isPaid) ...[
                            const SizedBox(height: 20.0),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Payment Receipt',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                if (record?.receiptNo != null && record!.receiptNo!.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFECFDF5),
                                      borderRadius: BorderRadius.circular(6.0),
                                    ),
                                    child: Text(
                                      'VERIFIED',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF059669),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10.0),
                            InkWell(
                              onTap: () {
                                Navigator.of(context).pushNamed(
                                  AppRoutes.paymentReceipt,
                                  arguments: {
                                    'paymentId': record?.id ?? (widget.payment is int ? widget.payment as int : 2),
                                    'receiptNo': record?.receiptNo,
                                    'residentName': record?.resident?.name,
                                    'amount': record?.amount,
                                  },
                                );
                              },
                              borderRadius: BorderRadius.circular(16.0),
                              child: Container(
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
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44.0,
                                      height: 44.0,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFE8F3ED),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.picture_as_pdf_rounded,
                                        color: Color(0xFF0F4734),
                                        size: 22.0,
                                      ),
                                    ),
                                    const SizedBox(width: 14.0),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            record?.receiptNo ?? 'Official Receipt',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 14.0,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 2.0),
                                          Text(
                                            'Official PDF Receipt Ready',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12.0,
                                              color: const Color(0xFF6B7280),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      color: Color(0xFF9CA3AF),
                                      size: 14.0,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 24.0),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Button (Pay Now if pending, In Review container if in_review)
                  if (isPending)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 12.0),
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            AppRoutes.paymentMethod,
                            arguments: record?.id ?? outstanding?.paymentId ?? 1,
                          );
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
                            'Pay Now',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.0,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    )
                  else if (isInReview)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 12.0),
                      child: Container(
                        width: double.infinity,
                        height: 48.0,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(999.0),
                          border: Border.all(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.schedule_rounded, color: Color(0xFF2563EB), size: 18.0),
                            const SizedBox(width: 8.0),
                            Text(
                              'Payment Under Review',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.0,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF2563EB),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (isPaid)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 12.0),
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            AppRoutes.paymentReceipt,
                            arguments: {
                              'paymentId': record?.id ?? (widget.payment is int ? widget.payment as int : 2),
                              'receiptNo': record?.receiptNo,
                              'residentName': record?.resident?.name,
                              'amount': record?.amount,
                            },
                          );
                        },
                        borderRadius: BorderRadius.circular(999.0),
                        child: Container(
                          width: double.infinity,
                          height: 48.0,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F4734),
                            borderRadius: BorderRadius.circular(999.0),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x18000000),
                                blurRadius: 8.0,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 20.0),
                              const SizedBox(width: 8.0),
                              Text(
                                'View Receipt (PDF)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
