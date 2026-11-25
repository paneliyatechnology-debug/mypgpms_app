import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/colors/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../injection_container.dart' as di;
import '../../data/datasources/payments_remote_data_source.dart';
import '../../data/models/payment_item_model.dart';

class PaymentMethodPage extends StatefulWidget {
  final dynamic paymentId;

  const PaymentMethodPage({super.key, this.paymentId});

  @override
  State<PaymentMethodPage> createState() => _PaymentMethodPageState();
}

class _PaymentMethodPageState extends State<PaymentMethodPage> {
  bool _isLoading = true;
  String? _errorMessage;
  InitiateUpiDataModel? _upiData;
  bool _isPaymentCompleted = false;

  @override
  void initState() {
    super.initState();
    _initiateUpi();
  }

  Future<void> _initiateUpi() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dataSource = di.sl<PaymentsRemoteDataSource>();
      final id = widget.paymentId is PaymentRecordModel
          ? (widget.paymentId as PaymentRecordModel).id ?? 1
          : (widget.paymentId ?? 1);
      final response = await dataSource.initiateUpi(id);
      if (mounted) {
        setState(() {
          _upiData = response.data;
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

  void _copyUpiId(String upiId) {
    Clipboard.setData(ClipboardData(text: upiId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'UPI ID copied to clipboard',
          style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth > 600 ? (screenWidth - 460) / 2 : 16.0;

    final amount = _upiData?.amount ?? (widget.paymentId is PaymentRecordModel ? (widget.paymentId as PaymentRecordModel).amount : 1);
    final payeeName = _upiData != null && _upiData!.payeeName.isNotEmpty ? _upiData!.payeeName : 'Jasmin Patel';
    final payeeUpi = _upiData != null && _upiData!.payeeUpi.isNotEmpty ? _upiData!.payeeUpi : 'jasminkorat204@oksbi';
    final qrCodeUrl = _upiData?.qrCodeUrl;

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
          'Payment Method',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18.0,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: _isLoading && _upiData == null
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
              )
            : _errorMessage != null && _upiData == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 36.0),
                          const SizedBox(height: 12.0),
                          Text(
                            _errorMessage ?? 'Failed to initiate UPI checkout',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.0,
                              color: const Color(0xFF4B5563),
                            ),
                          ),
                          const SizedBox(height: 16.0),
                          ElevatedButton(
                            onPressed: _initiateUpi,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                            ),
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
                          onRefresh: _initiateUpi,
                          color: AppColors.primary,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 4.0),
                            children: [
                              // Scan QR Code Card
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16.0),
                                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x06000000),
                                      blurRadius: 8.0,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'Scan QR Code to Pay',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2.0),
                                    Text(
                                      'Scan with any UPI app on your phone',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11.0,
                                        color: const Color(0xFF6B7280),
                                      ),
                                    ),
                                    const SizedBox(height: 8.0),

                                    // Real API QR Code Image
                                    Container(
                                      width: 140.0,
                                      height: 140.0,
                                      padding: const EdgeInsets.all(5.0),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12.0),
                                        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
                                      ),
                                      child: qrCodeUrl != null && qrCodeUrl.isNotEmpty
                                          ? Image.network(
                                              qrCodeUrl,
                                              fit: BoxFit.contain,
                                              loadingBuilder: (context, child, progress) {
                                                if (progress == null) return child;
                                                return const Center(
                                                  child: CircularProgressIndicator(
                                                    color: AppColors.primary,
                                                    strokeWidth: 2.0,
                                                  ),
                                                );
                                              },
                                              errorBuilder: (context, error, stackTrace) {
                                                return const Icon(
                                                  Icons.qr_code_2_rounded,
                                                  size: 125.0,
                                                  color: Color(0xFF1F2937),
                                                );
                                              },
                                            )
                                          : const Icon(
                                              Icons.qr_code_2_rounded,
                                              size: 125.0,
                                              color: Color(0xFF1F2937),
                                            ),
                                    ),
                                    const SizedBox(height: 6.0),

                                    // Amount below QR code
                                    Text(
                                      _formatCurrency(amount),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 22.0,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 6.0),

                                    // Payee Name & UPI ID
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF9FAFB),
                                        borderRadius: BorderRadius.circular(10.0),
                                        border: Border.all(color: const Color(0xFFE5E7EB)),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  payeeName,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 12.0,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.textPrimary,
                                                  ),
                                                ),
                                                const SizedBox(height: 1.0),
                                                Text(
                                                  payeeUpi,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 10.5,
                                                    color: const Color(0xFF6B7280),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.copy_rounded, size: 16.0, color: AppColors.primary),
                                            tooltip: 'Copy UPI ID',
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () => _copyUpiId(payeeUpi),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14.0),

                              // Payment Completed Interactive Confirmation Card
                              Container(
                                decoration: BoxDecoration(
                                  color: _isPaymentCompleted ? const Color(0xFFE8F3ED) : Colors.white,
                                  borderRadius: BorderRadius.circular(14.0),
                                  border: Border.all(
                                    color: _isPaymentCompleted ? AppColors.primary : const Color(0xFFE5E7EB),
                                    width: _isPaymentCompleted ? 1.4 : 1.0,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x04000000),
                                      blurRadius: 6.0,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        _isPaymentCompleted = !_isPaymentCompleted;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(14.0),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                                      child: Row(
                                        children: [
                                          AnimatedContainer(
                                            duration: const Duration(milliseconds: 200),
                                            width: 22.0,
                                            height: 22.0,
                                            decoration: BoxDecoration(
                                              color: _isPaymentCompleted ? AppColors.primary : Colors.white,
                                              borderRadius: BorderRadius.circular(6.0),
                                              border: Border.all(
                                                color: _isPaymentCompleted ? AppColors.primary : const Color(0xFF9CA3AF),
                                                width: 1.6,
                                              ),
                                            ),
                                            child: _isPaymentCompleted
                                                ? const Icon(Icons.check_rounded, size: 15.0, color: Colors.white)
                                                : null,
                                          ),
                                          const SizedBox(width: 10.0),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'I have completed the payment',
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 12.5,
                                                    fontWeight: FontWeight.w700,
                                                    color: _isPaymentCompleted
                                                        ? AppColors.primary
                                                        : AppColors.textPrimary,
                                                  ),
                                                ),
                                                const SizedBox(height: 1.0),
                                                Text(
                                                  'Check this box to confirm and enter transaction ID',
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 10.5,
                                                    color: const Color(0xFF6B7280),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6.0),
                            ],
                          ),
                        ),
                      ),

                      // 5. Bottom Continue to Transaction ID Button
                      Padding(
                        padding: EdgeInsets.fromLTRB(horizontalPadding, 6.0, horizontalPadding, 16.0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: double.infinity,
                          height: 46.0,
                          decoration: BoxDecoration(
                            color: _isPaymentCompleted ? AppColors.primary : const Color(0xFFD1D5DB),
                            borderRadius: BorderRadius.circular(999.0),
                            boxShadow: _isPaymentCompleted
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.28),
                                      blurRadius: 8.0,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _isPaymentCompleted
                                  ? () {
                                      Navigator.of(context).pushNamed(
                                        AppRoutes.paymentTransaction,
                                        arguments: {
                                          'paymentId': widget.paymentId,
                                          'amount': amount,
                                          'payeeName': payeeName,
                                          'payeeUpi': payeeUpi,
                                        },
                                      );
                                    }
                                  : null,
                              borderRadius: BorderRadius.circular(999.0),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Continue to Enter Transaction ID',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.w700,
                                        color: _isPaymentCompleted ? Colors.white : const Color(0xFF6B7280),
                                      ),
                                    ),
                                    if (_isPaymentCompleted) ...[
                                      const SizedBox(width: 8.0),
                                      const Icon(
                                        Icons.arrow_forward_rounded,
                                        color: Colors.white,
                                        size: 16.0,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
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
