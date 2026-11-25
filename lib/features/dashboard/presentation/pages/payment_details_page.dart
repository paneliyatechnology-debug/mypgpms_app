import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/colors/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../injection_container.dart' as di;
import '../../data/datasources/payments_remote_data_source.dart';
import '../../data/models/payment_item_model.dart';

class PaymentDetailsPage extends StatefulWidget {
  final dynamic paymentId;

  const PaymentDetailsPage({super.key, required this.paymentId});

  @override
  State<PaymentDetailsPage> createState() => _PaymentDetailsPageState();
}

class _PaymentDetailsPageState extends State<PaymentDetailsPage> {
  PaymentDetailsDataModel? _details;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.paymentId is PaymentRecordModel) {
      _details = PaymentDetailsDataModel.fromPaymentRecord(widget.paymentId as PaymentRecordModel);
      _isLoading = false;
    } else if (widget.paymentId is PaymentDetailsDataModel) {
      _details = widget.paymentId as PaymentDetailsDataModel;
      _isLoading = false;
    }
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    if (_details == null) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final dataSource = di.sl<PaymentsRemoteDataSource>();
      final id = widget.paymentId is PaymentRecordModel
          ? (widget.paymentId as PaymentRecordModel).id ?? 1
          : (widget.paymentId is PaymentDetailsDataModel
              ? (widget.paymentId as PaymentDetailsDataModel).id ?? 1
              : (widget.paymentId ?? 1));

      final response = await dataSource.getPaymentDetails(id);
      if (mounted && response.data != null) {
        setState(() {
          _details = response.data;
          _isLoading = false;
        });
      } else if (mounted && _details != null) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (_details == null) {
            _errorMessage = e.toString().replaceAll('Exception: ', '').replaceAll('ServerException: ', '');
          }
        });
      }
    }
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
              maxScale: 4.0,
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

    final data = _details;
    final breakdown = data?.breakdown;
    final billing = data?.billingPeriod;

    final String cardTitle = data?.title ?? 'Onboarding Due (Rent, Deposit, Maintenance) - November 2026';
    final num totalAmount = data?.amount ?? breakdown?.total ?? 1;
    final String? rawDueDate = data?.dueDate;
    final String dueDateText = rawDueDate != null && rawDueDate.isNotEmpty
        ? (rawDueDate.toLowerCase().contains('due') ? rawDueDate : 'Due on $rawDueDate')
        : 'Due on 25-11-2026 00:00';
    final String rawStatus = data?.status ?? 'Pending';
    final String displayStatusText = data?.displayStatus ??
        (rawStatus.toLowerCase() == 'in_review'
            ? 'In Review'
            : (rawStatus.toLowerCase() == 'paid' ? 'Paid' : 'Pending'));
    final bool isPaid = data?.isPaid ?? (rawStatus.toLowerCase() == 'paid');
    final bool isInReview = data?.isInReview ?? (rawStatus.toLowerCase() == 'in_review');
    final bool isPending = data?.isPending ?? (rawStatus.toLowerCase() == 'pending');

    final Color statusBg = data?.statusBgColor ??
        (isInReview
            ? const Color(0xFFDBEAFE)
            : (isPaid ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7)));
    final Color statusTextColor = data?.statusTextColor ??
        (isInReview
            ? const Color(0xFF2563EB)
            : (isPaid ? const Color(0xFF059669) : const Color(0xFFD97706)));

    String billingPeriodText = 'November 2026 (01-11-2026 - 30-11-2026)';
    if (billing != null && billing.start != null && billing.end != null) {
      final startStr = billing.start!.contains(' ') ? billing.start!.split(' ').first : billing.start!;
      final endStr = billing.end!.contains(' ') ? billing.end!.split(' ').first : billing.end!;
      billingPeriodText = 'November 2026 ($startStr - $endStr)';
    }

    final List<Map<String, String>> breakdownList = [];
    if (breakdown != null) {
      breakdownList.add({'label': 'Rent', 'amount': _formatCurrency(breakdown.rent)});
      if (breakdown.deposit > 0 || breakdown.securityDeposit > 0) {
        final depositVal = breakdown.deposit > 0 ? breakdown.deposit : breakdown.securityDeposit;
        breakdownList.add({'label': 'Deposit', 'amount': _formatCurrency(depositVal)});
      }
      breakdownList.add({'label': 'Maintenance', 'amount': _formatCurrency(breakdown.maintenance)});
      breakdownList.add({'label': 'Electricity', 'amount': _formatCurrency(breakdown.electricity)});
      breakdownList.add({'label': 'Other', 'amount': _formatCurrency(breakdown.other)});
    } else {
      breakdownList.addAll([
        {'label': 'Rent', 'amount': '₹1'},
        {'label': 'Maintenance', 'amount': '₹0'},
        {'label': 'Electricity', 'amount': '₹0'},
        {'label': 'Other', 'amount': '₹0'},
      ]);
    }

    final String? notesText = data?.notes;

    String? proofImageUrl = data?.imageUrl;
    if ((proofImageUrl == null || proofImageUrl.isEmpty) && data?.image != null && data!.image!.isNotEmpty) {
      final img = data.image!;
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
        child: _isLoading && _details == null
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
              )
            : _errorMessage != null && _details == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 36.0),
                          const SizedBox(height: 12.0),
                          Text(
                            _errorMessage ?? 'Failed to load payment details',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.0,
                              color: const Color(0xFF4B5563),
                            ),
                          ),
                          const SizedBox(height: 16.0),
                          ElevatedButton(
                            onPressed: _fetchDetails,
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                            child: const Text('Retry', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _fetchDetails,
                          color: AppColors.primary,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 10.0),
                            children: [
                              // 1. Monthly Rent Top Card
                              Container(
                                padding: const EdgeInsets.all(14.0),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F3ED),
                                  borderRadius: BorderRadius.circular(16.0),
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
                                    const SizedBox(height: 6.0),
                                    Text(
                                      _formatCurrency(totalAmount),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 24.0,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 4.0),
                                    Text(
                                      dueDateText,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12.0,
                                        color: const Color(0xFF6B7280),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14.0),

                              // 2. Billing Period Section
                              Text(
                                'Billing Period',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                billingPeriodText,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                              const SizedBox(height: 10.0),

                              // 3. Breakdown Card Table
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16.0),
                                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
                                ),
                                child: Column(
                                  children: List.generate(breakdownList.length, (index) {
                                    final item = breakdownList[index];
                                    final isLast = index == breakdownList.length - 1;
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                                      decoration: BoxDecoration(
                                        border: isLast
                                            ? null
                                            : const Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            item['label']!,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 13.0,
                                              color: const Color(0xFF4B5563),
                                            ),
                                          ),
                                          Text(
                                            item['amount']!,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ),
                              ),
                              const SizedBox(height: 12.0),

                              // 4. Total Card
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F3ED),
                                  borderRadius: BorderRadius.circular(14.0),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Total',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
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
                              const SizedBox(height: 12.0),

                              // 5. Late Fine Notice Card / Dynamic Notes
                              Container(
                                padding: const EdgeInsets.all(12.0),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F3ED).withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(14.0),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 26.0,
                                      height: 26.0,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFD1FAE5),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 16.0),
                                    ),
                                    const SizedBox(width: 10.0),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            notesText != null && notesText.trim().isNotEmpty
                                                ? notesText
                                                : 'Rent is due by 25th of every month.',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12.0,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF4B5563),
                                            ),
                                          ),
                                          if (notesText == null || notesText.trim().isEmpty) ...[
                                            const SizedBox(height: 2.0),
                                            Text(
                                              'Late payment may attract a fine.',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 11.5,
                                                color: const Color(0xFF6B7280),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // 6. Payment Screenshot Card (if available)
                              if (proofImageUrl != null && proofImageUrl.isNotEmpty) ...[
                                const SizedBox(height: 14.0),
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
                                    if (data?.upiRefNo != null && data!.upiRefNo!.isNotEmpty)
                                      Text(
                                        'UTR: ${data.upiRefNo}',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF6B7280),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8.0),
                                GestureDetector(
                                  onTap: () => _openImagePreview(context, proofImageUrl!),
                                  child: Container(
                                    width: double.infinity,
                                    height: 190.0,
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

                              // Payment Receipt Card (When Paid)
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
                                    if (data?.receiptNo != null && data!.receiptNo!.isNotEmpty)
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
                                        'paymentId': data?.id ??
                                            (widget.paymentId is PaymentRecordModel
                                                ? (widget.paymentId as PaymentRecordModel).id
                                                : widget.paymentId) ??
                                            2,
                                        'receiptNo': data?.receiptNo,
                                        'residentName': data?.resident?.name,
                                        'amount': data?.amount,
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
                                                data?.receiptNo ?? 'Official Receipt',
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
                                arguments: data?.id ??
                                    (widget.paymentId is PaymentRecordModel
                                        ? (widget.paymentId as PaymentRecordModel).id
                                        : widget.paymentId) ??
                                    1,
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
                                  'paymentId': data?.id ??
                                      (widget.paymentId is PaymentRecordModel
                                          ? (widget.paymentId as PaymentRecordModel).id
                                          : widget.paymentId) ??
                                      2,
                                  'receiptNo': data?.receiptNo,
                                  'residentName': data?.resident?.name,
                                  'amount': data?.amount,
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
