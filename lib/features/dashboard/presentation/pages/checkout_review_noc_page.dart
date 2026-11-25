import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/colors/app_colors.dart';
import '../../../../core/network/socket_service.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/storage/preferences_service.dart';
import '../../../../injection_container.dart' as di;
import '../../data/datasources/checkout_remote_data_source.dart';
import '../../data/datasources/payments_remote_data_source.dart';
import '../../data/models/checkout_model.dart';
import '../../data/models/payments_overview_model.dart';

class CheckoutReviewNocPage extends StatefulWidget {
  final CheckoutRequestPayload? payload;

  const CheckoutReviewNocPage({super.key, this.payload});

  @override
  State<CheckoutReviewNocPage> createState() => _CheckoutReviewNocPageState();
}

class _CheckoutReviewNocPageState extends State<CheckoutReviewNocPage> {
  bool _roomInspection = true;
  bool _returnKey = true;
  bool _noPendingDues = true;
  bool _isSubmitting = false;
  bool _isLoadingPayments = true;
  PaymentsOverviewDataModel? _paymentsData;

  @override
  void initState() {
    super.initState();
    _loadCachedPayments();
    _fetchPaymentsOverview();
  }

  void _loadCachedPayments() {
    try {
      final prefService = di.sl<PreferencesService>();
      final cached = prefService.getSavedPaymentsOverview();
      if (cached != null) {
        setState(() {
          _paymentsData = PaymentsOverviewDataModel.fromJson(cached);
          _isLoadingPayments = false;
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchPaymentsOverview() async {
    try {
      final dataSource = di.sl<PaymentsRemoteDataSource>();
      final response = await dataSource.getPaymentsOverview();
      if (mounted && response.data != null) {
        setState(() {
          _paymentsData = response.data;
          _isLoadingPayments = false;
        });
        final prefService = di.sl<PreferencesService>();
        await prefService.savePaymentsOverview(response.data!.toJson());
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingPayments = false;
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

  String _getBillingMonth(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'November 2026';
    try {
      final parts = dateStr.split(' ')[0].split('-');
      if (parts.length == 3) {
        const months = [
          'January', 'February', 'March', 'April', 'May', 'June',
          'July', 'August', 'September', 'October', 'November', 'December'
        ];
        if (parts[0].length == 4) {
          final m = int.tryParse(parts[1]) ?? 1;
          return '${months[(m - 1).clamp(0, 11)]} ${parts[0]}';
        } else {
          final m = int.tryParse(parts[1]) ?? 1;
          return '${months[(m - 1).clamp(0, 11)]} ${parts[2]}';
        }
      }
    } catch (_) {}
    return 'November 2026';
  }

  String _formatDepartureDate(String? raw) {
    if (raw == null || raw.isEmpty) return '30 December 2026';
    try {
      if (raw.contains('-')) {
        final parts = raw.split(' ')[0].split('-');
        if (parts.length == 3) {
          const months = [
            'January', 'February', 'March', 'April', 'May', 'June',
            'July', 'August', 'September', 'October', 'November', 'December'
          ];
          if (parts[0].length == 4) {
            // YYYY-MM-DD
            final month = int.tryParse(parts[1]) ?? 1;
            final day = parts[2];
            final year = parts[0];
            return '$day ${months[(month - 1).clamp(0, 11)]} $year';
          } else {
            // DD-MM-YYYY
            final day = parts[0];
            final month = int.tryParse(parts[1]) ?? 1;
            final year = parts[2];
            return '$day ${months[(month - 1).clamp(0, 11)]} $year';
          }
        }
      }
      return raw;
    } catch (_) {
      return raw;
    }
  }

  Future<void> _submitCheckoutRequest() async {
    if (_isSubmitting) return;

    if (!_roomInspection || !_returnKey || !_noPendingDues) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please verify and confirm all items in the clearance checklist',
            style: GoogleFonts.plusJakartaSans(fontSize: 13.0, fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final payload = widget.payload ??
          CheckoutRequestPayload(
            departureDate: '2026-03-31',
            reason: 'Job Relocation',
          );

      final dataSource = di.sl<CheckoutRemoteDataSource>();
      final response = await dataSource.submitCheckoutRequest(payload);

      try {
        di.sl<SocketService>().notifyCheckoutCreated(response);
      } catch (_) {}

      if (!mounted) return;

      final message = response['message']?.toString() ??
          'Checkout request submitted successfully!';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: GoogleFonts.plusJakartaSans(fontSize: 13.0, fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        ),
      );

      Navigator.of(context).pushReplacementNamed(AppRoutes.checkoutStatus);
    } catch (e) {
      if (!mounted) return;
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMsg,
            style: GoogleFonts.plusJakartaSans(fontSize: 13.0, fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth > 600 ? (screenWidth - 460) / 2 : 16.0;

    // Load saved current room dynamically
    Map<String, dynamic>? savedDashboard;
    Map<String, dynamic>? savedUser;
    try {
      final prefService = di.sl<PreferencesService>();
      savedDashboard = prefService.getSavedDashboard();
      savedUser = prefService.getSavedUser();
    } catch (_) {}

    final stay = savedDashboard?['stay'] as Map<String, dynamic>?;
    final roomInfo = savedUser?['room_info'] as Map<String, dynamic>?;

    final String roomNo = stay?['room_no']?.toString() ??
        roomInfo?['room_no']?.toString() ??
        '101';

    final String bedNo = stay?['bed_number']?.toString() ??
        roomInfo?['bed_no']?.toString() ??
        '1';

    final String checkOutDate = _formatDepartureDate(widget.payload?.departureDate);

    // Compute dynamic payments overview data
    final breakdown = _paymentsData?.breakdown;
    final outstanding = _paymentsData?.outstanding;
    final secDeposit = _paymentsData?.securityDeposit;

    final num rentAmount = breakdown?.rent ?? 0;
    final num maintenanceAmount = breakdown?.maintenance ?? 0;
    final num electricityAmount = breakdown?.electricity ?? 0;
    final num otherAmount = breakdown?.other ?? 0;
    final num depositInBreakdown = breakdown?.deposit ?? 0;
    final num totalDue = outstanding?.amount ?? breakdown?.total ?? 0;

    final num originalDeposit = (secDeposit != null && secDeposit.amount > 0)
        ? secDeposit.amount
        : ((breakdown != null && breakdown.securityDeposit > 0)
            ? breakdown.securityDeposit
            : (depositInBreakdown > 0 ? depositInBreakdown : 0));

    final num estimatedRefund = (originalDeposit > totalDue) ? (originalDeposit - totalDue) : 0;
    final String rentMonthYear = _getBillingMonth(_paymentsData?.billingPeriod?.start ?? outstanding?.dueDate);

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
          'Checkout Review & NOC',
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
                  // Card 1: Room & Stay Details
                  _buildCard(
                    title: 'Room & Stay Details',
                    children: [
                      _buildRow('Room No.', roomNo),
                      _buildRow('Bed No.', bedNo),
                      _buildRow('Check-out date', checkOutDate, isLast: true),
                    ],
                  ),
                  const SizedBox(height: 12.0),

                  // Card 2: Pending Dues (Dynamic)
                  _buildCard(
                    title: 'Pending Dues',
                    children: [
                      if (_isLoadingPayments && _paymentsData == null)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            child: SizedBox(
                              width: 24.0,
                              height: 24.0,
                              child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.primary),
                            ),
                          ),
                        )
                      else ...[
                        if (rentAmount > 0)
                          _buildRow('Rent ($rentMonthYear)', _formatCurrency(rentAmount)),
                        if (depositInBreakdown > 0)
                          _buildRow('Deposit', _formatCurrency(depositInBreakdown)),
                        if (maintenanceAmount > 0)
                          _buildRow('Maintenance', _formatCurrency(maintenanceAmount)),
                        if (electricityAmount > 0)
                          _buildRow('Electricity', _formatCurrency(electricityAmount)),
                        if (otherAmount > 0)
                          _buildRow('Other', _formatCurrency(otherAmount)),
                        if (rentAmount == 0 && depositInBreakdown == 0 && maintenanceAmount == 0 && electricityAmount == 0 && totalDue == 0)
                          _buildRow('No Pending Dues', '₹0'),
                        const Divider(height: 16.0, color: Color(0xFFF3F4F6)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Due',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.0,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              _formatCurrency(totalDue),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.0,
                                fontWeight: FontWeight.w800,
                                color: totalDue > 0 ? AppColors.primary : const Color(0xFF059669),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12.0),

                  // Card 3: Security Deposit (Dynamic)
                  _buildCard(
                    title: 'Security Deposit',
                    children: [
                      if (_isLoadingPayments && _paymentsData == null)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            child: SizedBox(
                              width: 24.0,
                              height: 24.0,
                              child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.primary),
                            ),
                          ),
                        )
                      else ...[
                        _buildRow('Original Deposit', _formatCurrency(originalDeposit)),
                        const SizedBox(height: 4.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Estimated Refund',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.0,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              _formatCurrency(estimatedRefund),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12.0),

                  // Card 4: Clearance checklist
                  _buildCard(
                    title: 'Clearance checklist',
                    children: [
                      _buildCheckItem(
                        label: 'Room inspection',
                        checked: _roomInspection,
                        onChanged: (val) => setState(() => _roomInspection = val ?? false),
                      ),
                      _buildCheckItem(
                        label: 'Return room key',
                        checked: _returnKey,
                        onChanged: (val) => setState(() => _returnKey = val ?? false),
                      ),
                      _buildCheckItem(
                        label: 'No pending dues',
                        checked: _noPendingDues,
                        onChanged: (val) => setState(() => _noPendingDues = val ?? false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20.0),
                ],
              ),
            ),

            // Bottom Submit Button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 12.0),
              child: InkWell(
                onTap: _isSubmitting ? null : _submitCheckoutRequest,
                borderRadius: BorderRadius.circular(999.0),
                child: Container(
                  width: double.infinity,
                  height: 48.0,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _isSubmitting ? AppColors.primary.withAlpha(180) : AppColors.primary,
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
                          'Proceed to submit',
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

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.0,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10.0),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0.0 : 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              color: const Color(0xFF6B7280),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.0,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem({
    required String label,
    required bool checked,
    required ValueChanged<bool?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: InkWell(
        onTap: () => onChanged(!checked),
        child: Row(
          children: [
            SizedBox(
              width: 24.0,
              height: 24.0,
              child: Checkbox(
                value: checked,
                activeColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
                onChanged: onChanged,
              ),
            ),
            const SizedBox(width: 8.0),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
