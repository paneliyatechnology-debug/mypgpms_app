import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/colors/app_colors.dart';
import '../../../../core/routes/app_routes.dart';

class PaymentSuccessPage extends StatefulWidget {
  final dynamic arguments;

  const PaymentSuccessPage({super.key, this.arguments});

  @override
  State<PaymentSuccessPage> createState() => _PaymentSuccessPageState();
}

class _PaymentSuccessPageState extends State<PaymentSuccessPage> {
  Timer? _countdownTimer;
  int _secondsRemaining = 3;

  @override
  void initState() {
    super.initState();
    _startAutoRedirectTimer();
  }

  void _startAutoRedirectTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining > 1) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
        _returnToApp();
      }
    });
  }

  void _returnToApp() {
    _countdownTimer?.cancel();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.dashboard,
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  dynamic get _paymentId {
    if (widget.arguments is Map) {
      return (widget.arguments as Map)['paymentId'] ?? (widget.arguments as Map)['id'];
    }
    return widget.arguments;
  }

  String get _amount {
    if (widget.arguments is Map) {
      return (widget.arguments as Map)['amount']?.toString() ?? '₹17,000';
    }
    return '₹17,000';
  }

  String get _transactionId {
    if (widget.arguments is Map) {
      final id = (widget.arguments as Map)['transactionId']?.toString();
      if (id != null && id.isNotEmpty) return id;
    }
    return '1234567890123';
  }

  String get _paymentMethod {
    if (widget.arguments is Map) {
      return (widget.arguments as Map)['paymentMethod']?.toString() ?? 'UPI';
    }
    return 'UPI';
  }

  String get _dateTime {
    if (widget.arguments is Map) {
      final dt = (widget.arguments as Map)['dateTime']?.toString();
      if (dt != null && dt.isNotEmpty) return dt;
    }
    return '20 Nov 2026, 01:36 PM';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth > 600 ? (screenWidth - 460) / 2 : 16.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8F6),
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: AppColors.primary, size: 22.0),
            onPressed: _returnToApp,
          ),
          const SizedBox(width: 8.0),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 10.0),
          child: Column(
            children: [
              const SizedBox(height: 6.0),
              // Green Checkmark Badge
              Center(
                child: Container(
                  width: 76.0,
                  height: 76.0,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F3ED),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 50.0,
                      height: 50.0,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 30.0,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18.0),

              // Title & Subtitle
              Text(
                'Payment Successful!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20.0,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                '$_amount paid successfully',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.0,
                  color: const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 20.0),

              // Transaction Info Card
              Container(
                padding: const EdgeInsets.all(14.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x06000000),
                      blurRadius: 10.0,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildDetailRow('Transaction ID', _transactionId),
                    const SizedBox(height: 12.0),
                    _buildDetailRow('Date & Time', _dateTime),
                    const SizedBox(height: 12.0),
                    _buildDetailRow('Payment Method', _paymentMethod),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),

              // Auto-redirect pill indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F3ED),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 14.0,
                      height: 14.0,
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2.0,
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Text(
                      'Returning to dashboard in ${_secondsRemaining}s...',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // View Receipt Button
              InkWell(
                onTap: () {
                  _countdownTimer?.cancel();
                  Navigator.of(context).pushNamed(
                    AppRoutes.paymentReceipt,
                    arguments: {
                      'paymentId': _paymentId ?? 2,
                      'amount': _amount,
                    },
                  );
                },
                borderRadius: BorderRadius.circular(999.0),
                child: Container(
                  width: double.infinity,
                  height: 48.0,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999.0),
                    border: Border.all(color: AppColors.primary, width: 1.4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary, size: 18.0),
                      const SizedBox(width: 8.0),
                      Text(
                        'View & Download Receipt',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10.0),

              // Go to Dashboard Button
              InkWell(
                onTap: _returnToApp,
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
                    'Go to Dashboard',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5,
            color: const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(width: 12.0),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
