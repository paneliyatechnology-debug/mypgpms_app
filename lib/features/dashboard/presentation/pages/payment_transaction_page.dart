import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/colors/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../injection_container.dart' as di;
import '../../data/datasources/payments_remote_data_source.dart';

class PaymentTransactionPage extends StatefulWidget {
  final dynamic arguments;

  const PaymentTransactionPage({super.key, this.arguments});

  @override
  State<PaymentTransactionPage> createState() => _PaymentTransactionPageState();
}

class _PaymentTransactionPageState extends State<PaymentTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _transactionIdController = TextEditingController();
  final _notesController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  final String _selectedPaymentMethod = 'UPI';
  File? _paymentScreenshot;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _transactionIdController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  dynamic get _paymentId {
    if (widget.arguments is Map) {
      final val = (widget.arguments as Map)['paymentId'];
      if (val != null) return val;
    } else if (widget.arguments != null) {
      return widget.arguments;
    }
    return 1;
  }

  num get _amount {
    if (widget.arguments is Map) {
      final val = (widget.arguments as Map)['amount'];
      if (val is num) return val;
      if (val is String) {
        final parsed = num.tryParse(val.replaceAll(RegExp(r'[^\d.]'), ''));
        if (parsed != null) return parsed;
      }
    }
    return 17000;
  }

  String get _payeeName {
    if (widget.arguments is Map) {
      return (widget.arguments as Map)['payeeName']?.toString() ?? 'Jasmin Patel';
    }
    return 'Jasmin Patel';
  }

  String _formatCurrency(num amount) {
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

  String _formatCurrentDateTime() {
    final dt = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final day = dt.day.toString().padLeft(2, '0');
    final month = months[dt.month - 1];
    final year = dt.year;

    final hour24 = dt.hour;
    final hour12 = hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24);
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = hour24 >= 12 ? 'PM' : 'AM';

    return '$day $month $year, $hour12:$minute $ampm';
  }

  Future<void> _pickScreenshot([FormFieldState<File>? formFieldState]) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _paymentScreenshot = File(picked.path);
        });
        formFieldState?.didChange(_paymentScreenshot);
      }
    } catch (e) {
      debugPrint('Error picking screenshot: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not access gallery. Please grant photo permissions.',
              style: GoogleFonts.plusJakartaSans(fontSize: 12.0),
            ),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  Future<void> _submitTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    if (_paymentScreenshot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please upload payment screenshot from gallery',
            style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFFD97706),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final dataSource = di.sl<PaymentsRemoteDataSource>();
      final paymentId = _paymentId;
      final upiRef = _transactionIdController.text.trim();
      final noteText = _notesController.text.trim();

      final response = await dataSource.payPayment(
        paymentId: paymentId,
        paymentMethod: 'upi',
        upiRefNo: upiRef,
        note: noteText.isNotEmpty ? noteText : 'Paid via Google Pay UPI',
        imagePath: _paymentScreenshot?.path,
      );

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      final successMsg = response['message']?.toString() ?? 'Payment recorded successfully!';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            successMsg,
            style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Navigate to Payment Success page with the entered details
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.paymentSuccess,
        arguments: {
          'amount': _formatCurrency(_amount),
          'transactionId': upiRef,
          'paymentMethod': _selectedPaymentMethod,
          'dateTime': _formatCurrentDateTime(),
          'payeeName': _payeeName,
          'screenshotPath': _paymentScreenshot?.path,
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });

      final errMsg = e.toString().replaceAll('Exception: ', '').replaceAll('ServerException: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errMsg.isNotEmpty ? errMsg : 'Failed to submit payment. Please try again.',
            style: GoogleFonts.plusJakartaSans(fontSize: 12.5),
          ),
          backgroundColor: const Color(0xFFDC2626),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary, size: 20.0),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Confirm Payment',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18.0,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 12.0),
                  children: [
                    // Amount Paid Card
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F3ED),
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(color: const Color(0xFFD1E7DD)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Amount Paid',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF4B5563),
                                ),
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                _formatCurrency(_amount),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 24.0,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20.0),
                              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.verified_outlined, size: 14.0, color: Color(0xFF059669)),
                                const SizedBox(width: 4.0),
                                Text(
                                  'To Verify',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.0,
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
                    const SizedBox(height: 18.0),

                    // 1. Payment Method Field (Static UPI)
                    Text(
                      'Payment Method',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14.0),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.qr_code_scanner_rounded,
                            size: 20.0,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 10.0),
                          Text(
                            'UPI (GPay, PhonePe, Paytm)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18.0),

                    // 2. Transaction ID / UTR Field
                    Text(
                      'Transaction ID / UTR Number *',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    TextFormField(
                      controller: _transactionIdController,
                      maxLength: 12,
                      keyboardType: TextInputType.text,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(12),
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                      ],
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: 'e.g. 405612348901 or UPI Ref ID',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 13.0,
                          color: const Color(0xFF9CA3AF),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
                        prefixIcon: const Icon(Icons.tag_rounded, color: AppColors.primary, size: 20.0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14.0),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14.0),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14.0),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14.0),
                          borderSide: const BorderSide(color: Color(0xFFDC2626)),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14.0),
                          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
                        ),
                      ),
                      validator: (value) {
                        final val = value?.trim() ?? '';
                        if (val.isEmpty) {
                          return 'Please enter 12-character Transaction ID / UTR';
                        }
                        if (val.length != 12) {
                          return 'Transaction ID / UTR must be exactly 12 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18.0),

                    // 3. Payment Screenshot from Gallery (Replaces Payment Date & Time)
                    Text(
                      'Payment Screenshot *',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    FormField<File>(
                      initialValue: _paymentScreenshot,
                      validator: (val) {
                        if (_paymentScreenshot == null) {
                          return 'Payment screenshot is required';
                        }
                        return null;
                      },
                      builder: (formFieldState) {
                        final hasError = formFieldState.hasError;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_paymentScreenshot != null)
                              Container(
                                padding: const EdgeInsets.all(12.0),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14.0),
                                  border: Border.all(color: const Color(0xFFE5E7EB)),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x04000000),
                                      blurRadius: 6.0,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10.0),
                                      child: Image.file(
                                        _paymentScreenshot!,
                                        width: 64.0,
                                        height: 64.0,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(width: 14.0),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Screenshot Attached',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 4.0),
                                          Text(
                                            'Tap to change screenshot',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11.5,
                                              color: const Color(0xFF6B7280),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20.0),
                                      tooltip: 'Change screenshot',
                                      onPressed: () => _pickScreenshot(formFieldState),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 20.0),
                                      tooltip: 'Remove',
                                      onPressed: () {
                                        setState(() {
                                          _paymentScreenshot = null;
                                        });
                                        formFieldState.didChange(null);
                                      },
                                    ),
                                  ],
                                ),
                              )
                            else
                              InkWell(
                                onTap: () => _pickScreenshot(formFieldState),
                                borderRadius: BorderRadius.circular(14.0),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 22.0, horizontal: 16.0),
                                  decoration: BoxDecoration(
                                    color: hasError ? const Color(0xFFFEF2F2) : Colors.white,
                                    borderRadius: BorderRadius.circular(14.0),
                                    border: Border.all(
                                      color: hasError ? const Color(0xFFDC2626) : const Color(0xFFCBD5E1),
                                      width: hasError ? 1.5 : 1.2,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 48.0,
                                        height: 48.0,
                                        decoration: BoxDecoration(
                                          color: hasError ? const Color(0xFFFEE2E2) : const Color(0xFFE8F3ED),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.add_photo_alternate_outlined,
                                          color: hasError ? const Color(0xFFDC2626) : AppColors.primary,
                                          size: 24.0,
                                        ),
                                      ),
                                      const SizedBox(height: 10.0),
                                      Text(
                                        'Upload Payment Screenshot',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: hasError ? const Color(0xFFDC2626) : AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4.0),
                                      Text(
                                        'Select from phone gallery (JPG, PNG)',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11.5,
                                          color: const Color(0xFF6B7280),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (hasError) ...[
                              const SizedBox(height: 6.0),
                              Padding(
                                padding: const EdgeInsets.only(left: 4.0),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 14.0),
                                    const SizedBox(width: 4.0),
                                    Text(
                                      formFieldState.errorText ?? 'Payment screenshot is required',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12.0,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFFDC2626),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 18.0),

                    // 4. Additional Note Field (Optional)
                    Text(
                      'Notes / Remarks (Optional)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g. Paid via PhonePe from Jasmin Patel account',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          color: const Color(0xFF9CA3AF),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.all(14.0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14.0),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14.0),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14.0),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20.0),

                    // Helper Card
                    Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded, color: Color(0xFF4B5563), size: 18.0),
                          const SizedBox(width: 8.0),
                          Expanded(
                            child: Text(
                              'Please enter the exact Transaction ID or UTR number shown in your payment app. Once verified, your rent receipt will be generated automatically.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                color: const Color(0xFF4B5563),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24.0),
                  ],
                ),
              ),

              // Bottom Submit Button
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 12.0),
                child: InkWell(
                  onTap: _isSubmitting ? null : _submitTransaction,
                  borderRadius: BorderRadius.circular(999.0),
                  child: Container(
                    width: double.infinity,
                    height: 48.0,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(999.0),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22.0,
                            height: 22.0,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.2,
                            ),
                          )
                        : Text(
                            'Submit Payment',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.0,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
