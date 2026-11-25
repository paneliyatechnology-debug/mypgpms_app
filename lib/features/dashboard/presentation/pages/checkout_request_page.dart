import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/colors/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../data/models/checkout_model.dart';

class CheckoutRequestPage extends StatefulWidget {
  const CheckoutRequestPage({super.key});

  @override
  State<CheckoutRequestPage> createState() => _CheckoutRequestPageState();
}

class _CheckoutRequestPageState extends State<CheckoutRequestPage> {
  final _dateController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime? _selectedDepartureDate;

  String? _selectedReason;
  final List<String> _reasons = [
    'Job Relocation',
    'Job transfer / Relocation',
    'Graduation / Course completed',
    'Found another place',
    'Personal reasons',
    'Other',
  ];

  @override
  void dispose() {
    _dateController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDepartureDate ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      setState(() {
        _selectedDepartureDate = picked;
        _dateController.text = '${picked.day.toString().padLeft(2, '0')} ${months[picked.month - 1]} ${picked.year}';
      });
    }
  }

  void _onNext() {
    if (_selectedDepartureDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select your departure date',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13.0),
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        ),
      );
      return;
    }

    if (_selectedReason == null || _selectedReason!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select a reason for checkout',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13.0),
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        ),
      );
      return;
    }

    final dateStr =
        '${_selectedDepartureDate!.year}-${_selectedDepartureDate!.month.toString().padLeft(2, '0')}-${_selectedDepartureDate!.day.toString().padLeft(2, '0')}';

    final payload = CheckoutRequestPayload(
      departureDate: dateStr,
      reason: _selectedReason!,
      additionalNotes: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
    );

    Navigator.of(context).pushNamed(
      AppRoutes.checkoutReviewNoc,
      arguments: payload,
    );
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
          'Checkout Request',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18.0,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8.0),
                children: [
                  // Select Departure Date
                  _buildLabel('Select your departure date *'),
                  const SizedBox(height: 6.0),
                  InkWell(
                    onTap: _selectDate,
                    borderRadius: BorderRadius.circular(12.0),
                    child: Container(
                      height: 48.0,
                      padding: const EdgeInsets.symmetric(horizontal: 14.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _dateController.text.isNotEmpty ? _dateController.text : 'Select date',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.0,
                                color: _dateController.text.isNotEmpty ? AppColors.textPrimary : const Color(0xFF9CA3AF),
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 18.0,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14.0),

                  // Reason for checkout
                  _buildLabel('Reason for checkout *'),
                  const SizedBox(height: 6.0),
                  Container(
                    height: 48.0,
                    padding: const EdgeInsets.symmetric(horizontal: 14.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedReason,
                        hint: Text(
                          'Select reason',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.0,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary, size: 22.0),
                        isExpanded: true,
                        items: _reasons.map((r) {
                          return DropdownMenuItem(
                            value: r,
                            child: Text(
                              r,
                              style: GoogleFonts.plusJakartaSans(fontSize: 13.0, color: AppColors.textPrimary),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedReason = val;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14.0),

                  // Additional note
                  _buildLabel('Additional note'),
                  const SizedBox(height: 6.0),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
                    ),
                    child: TextField(
                      controller: _noteController,
                      maxLines: 4,
                      style: GoogleFonts.plusJakartaSans(fontSize: 13.0, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Any additional feedback or reason...',
                        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13.0, color: const Color(0xFF9CA3AF)),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        filled: false,
                        fillColor: Colors.transparent,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),

                  // Warning Notice
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFD97706),
                          size: 18.0,
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Text(
                            'Please complete all dues and clear your room before the final approval!',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.0,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF92400E),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20.0),
                ],
              ),
            ),

            // Bottom Next Button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 12.0),
              child: InkWell(
                onTap: _onNext,
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
                    'Next',
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
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13.0,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
      ),
    );
  }
}
