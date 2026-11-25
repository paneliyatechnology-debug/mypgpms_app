import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../common/widgets/common_bottom_nav_bar.dart';
import '../../../../core/colors/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/storage/preferences_service.dart';
import '../../../../injection_container.dart' as di;
import '../../data/datasources/payments_remote_data_source.dart';
import '../../data/models/payment_item_model.dart';
import '../../data/models/payments_overview_model.dart';

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key});

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  bool _isLoading = false;
  String? _errorMessage;
  PaymentsOverviewDataModel? _paymentsData;
  List<PaymentRecordModel> _transactions = [];
  bool _isLoadingTransactions = false;

  @override
  void initState() {
    super.initState();
    _loadLocalCachedData();
    _fetchPaymentsOverview();
    _fetchPaymentsList();
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
      final cachedList = prefService.getSavedPaymentsList();
      if (cachedList != null && cachedList.isNotEmpty) {
        final list = cachedList.map((e) => PaymentRecordModel.fromJson(e)).toList();
        if (list.isNotEmpty) {
          setState(() {
            _transactions = list;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _onRefreshAll() async {
    await Future.wait([
      _fetchPaymentsList(),
      _fetchPaymentsOverview(),
    ]);
  }

  Future<void> _fetchPaymentsOverview() async {
    if (_paymentsData == null) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final dataSource = di.sl<PaymentsRemoteDataSource>();
      final response = await dataSource.getPaymentsOverview();
      if (mounted) {
        setState(() {
          _paymentsData = response.data;
          _isLoading = false;
          _errorMessage = null;
        });

        if (response.data != null) {
          final prefService = di.sl<PreferencesService>();
          await prefService.savePaymentsOverview(response.data!.toJson());
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (_paymentsData == null && _transactions.isEmpty) {
            _errorMessage = e.toString();
          }
        });
      }
    }
  }

  Future<void> _fetchPaymentsList() async {
    setState(() {
      _isLoadingTransactions = true;
    });

    try {
      final dataSource = di.sl<PaymentsRemoteDataSource>();
      final response = await dataSource.getPayments(status: 'all', page: 1, limit: 10, tab: '');
      if (mounted) {
        setState(() {
          _transactions = response.data;
          _isLoadingTransactions = false;
        });

        if (response.data.isNotEmpty) {
          final prefService = di.sl<PreferencesService>();
          await prefService.savePaymentsList(response.data.map((e) => e.toJson()).toList());
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingTransactions = false;
        });
      }
    }
  }

  String _formatDueDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return 'No pending dues';
    try {
      final datePart = rawDate.split(' ').first;
      final parts = datePart.split('-');
      if (parts.length == 3) {
        final day = parts[0];
        final monthNum = int.tryParse(parts[1]) ?? 1;
        final year = parts[2];
        const months = [
          'January',
          'February',
          'March',
          'April',
          'May',
          'June',
          'July',
          'August',
          'September',
          'October',
          'November',
          'December'
        ];
        final monthName = (monthNum >= 1 && monthNum <= 12) ? months[monthNum - 1] : parts[1];
        return 'Due on $day $monthName $year';
      }
      return 'Due on $datePart';
    } catch (_) {
      return 'Due on $rawDate';
    }
  }

  String _formatTransactionDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return '';
    try {
      if (rawDate.contains(' ')) {
        return rawDate.split(' ').first;
      }
      return rawDate;
    } catch (_) {
      return rawDate;
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

  IconData _getTransactionIcon(String? paymentType) {
    final type = paymentType?.toLowerCase() ?? '';
    if (type.contains('rent')) return Icons.apartment_rounded;
    if (type.contains('maintenance')) return Icons.build_rounded;
    if (type.contains('deposit')) return Icons.shield_outlined;
    if (type.contains('electricity')) return Icons.bolt_rounded;
    return Icons.receipt_long_rounded;
  }

  Color _getStatusBgColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'paid':
      case 'completed':
      case 'success':
        return const Color(0xFFD1FAE5);
      case 'in_review':
      case 'in review':
      case 'under_review':
        return const Color(0xFFDBEAFE);
      case 'pending':
      case 'due':
        return const Color(0xFFFEF3C7);
      case 'failed':
      case 'rejected':
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'paid':
      case 'completed':
      case 'success':
        return const Color(0xFF059669);
      case 'in_review':
      case 'in review':
      case 'under_review':
        return const Color(0xFF2563EB);
      case 'pending':
      case 'due':
        return const Color(0xFFD97706);
      case 'failed':
      case 'rejected':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth > 600 ? (screenWidth - 460) / 2 : 16.0;
    final recentTransactions = _paymentsData?.recentTransactions ?? [];

    final pendingTx = _transactions.cast<PaymentRecordModel?>().firstWhere(
          (e) => e != null && (e.isPending || e.status.toLowerCase() == 'pending'),
          orElse: () => null,
        );

    final inReviewTx = _transactions.cast<PaymentRecordModel?>().firstWhere(
          (e) => e != null && e.isInReview,
          orElse: () => null,
        );

    final bool hasPending = pendingTx != null;
    final bool hasInReview = inReviewTx != null;

    final num outstandingAmount = hasPending
        ? pendingTx.amount
        : (hasInReview
            ? inReviewTx.amount
            : (_transactions.isNotEmpty
                ? 0
                : (_paymentsData?.outstanding?.amount ?? 0)));

    final String outstandingStatus = hasPending
        ? 'pending'
        : (hasInReview
            ? 'in_review'
            : (_transactions.isNotEmpty
                ? 'paid'
                : ((_paymentsData?.outstanding?.status ?? 'paid').toLowerCase())));

    final bool isPending = outstandingStatus == 'pending';
    final bool isInReview = outstandingStatus == 'in_review';

    final String dueDateText = hasPending
        ? _formatDueDate(pendingTx.dueDate)
        : (hasInReview
            ? 'Payment verification in progress'
            : (_transactions.isNotEmpty
                ? 'No pending dues'
                : (_paymentsData?.outstanding?.dueDateText ?? 'No pending dues')));

    final effectiveBreakdown = pendingTx?.breakdown ??
        (_transactions.isNotEmpty ? _transactions.first.breakdown : null) ??
        _paymentsData?.breakdown;

    // Build breakdown items dynamically from API response
    final List<Map<String, dynamic>> breakdownItems = [];
    if (effectiveBreakdown != null) {
      breakdownItems.add({'label': 'Rent', 'amount': _formatCurrency(effectiveBreakdown.rent)});
      if (effectiveBreakdown.deposit > 0) {
        breakdownItems.add({'label': 'Deposit', 'amount': _formatCurrency(effectiveBreakdown.deposit)});
      }
      breakdownItems.add({'label': 'Maintenance', 'amount': _formatCurrency(effectiveBreakdown.maintenance)});
      breakdownItems.add({'label': 'Electricity', 'amount': _formatCurrency(effectiveBreakdown.electricity)});
      breakdownItems.add({'label': 'Other', 'amount': _formatCurrency(effectiveBreakdown.other)});
    } else {
      breakdownItems.addAll([
        {'label': 'Rent', 'amount': '₹0'},
        {'label': 'Maintenance', 'amount': '₹0'},
        {'label': 'Electricity', 'amount': '₹0'},
        {'label': 'Other', 'amount': '₹0'},
      ]);
    }

    // Security deposit details
    final depositAmount = pendingTx?.breakdown?.securityDeposit ??
        (_transactions.isNotEmpty ? (_transactions.first.breakdown?.securityDeposit ?? 0) : null) ??
        _paymentsData?.securityDeposit?.amount ??
        _paymentsData?.breakdown?.securityDeposit ??
        0;
    final depositTag = _paymentsData?.securityDeposit?.tag ?? 'Refundable';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8F6),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary, size: 20.0),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.dashboard, (route) => false);
            }
          },
        ),
        title: Text(
          'Payments',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18.0,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _onRefreshAll,
          color: AppColors.primary,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8.0),
            children: [
              if (_isLoading && _paymentsData == null) ...[
                const SizedBox(height: 60.0),
                const Center(
                  child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
                ),
                const SizedBox(height: 60.0),
              ] else if (_errorMessage != null && _paymentsData == null) ...[
                _buildErrorState(),
              ] else ...[
                // 1. Outstanding Amount Top Card
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF0F4734),
                        Color(0xFF165A42),
                        Color(0xFF1F6F52),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16.0),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x2E0F4734),
                        blurRadius: 16.0,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Outstanding amount',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9.0, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: isInReview
                                  ? const Color(0xFF2563EB)
                                  : (isPending ? const Color(0xFFD97706) : const Color(0xFF059669)),
                              borderRadius: BorderRadius.circular(6.0),
                            ),
                            child: Text(
                              isInReview ? 'In Review' : (isPending ? 'Pending' : 'Paid'),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.0,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        _formatCurrency(outstandingAmount),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24.0,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            dueDateText,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.0,
                              color: const Color(0xFFB7E4C7),
                            ),
                          ),
                          if (isPending || isInReview)
                            InkWell(
                              onTap: () {
                                final targetTx = pendingTx ?? (_transactions.isNotEmpty ? _transactions.first : null);
                                Navigator.of(context).pushNamed(
                                  AppRoutes.rentDetails,
                                  arguments: targetTx,
                                );
                              },
                              borderRadius: BorderRadius.circular(999.0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 7.0),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(999.0),
                                ),
                                child: Text(
                                  isPending ? 'Pay Now' : 'In Review',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14.0),

                // 2. Breakdown Section
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
                    borderRadius: BorderRadius.circular(14.0),
                    border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
                  ),
                  child: Column(
                    children: List.generate(breakdownItems.length, (index) {
                      final item = breakdownItems[index];
                      final isLast = index == breakdownItems.length - 1;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 11.0),
                        decoration: BoxDecoration(
                          border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item['label'] as String,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF4B5563),
                              ),
                            ),
                            Text(
                              item['amount'] as String,
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

                // 3. Security Deposit Card
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14.0),
                    border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38.0,
                        height: 38.0,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFEF3C7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.shield_outlined,
                          color: Color(0xFFD97706),
                          size: 20.0,
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Security Deposit',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.0,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF4B5563),
                              ),
                            ),
                            const SizedBox(height: 2.0),
                            Text(
                              _formatCurrency(depositAmount),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15.0,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9.0, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        child: Text(
                          depositTag,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.0,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF059669),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14.0),

                // 4. Recent Transaction Section
                Text(
                  'Recent Transaction',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8.0),

                if (_isLoadingTransactions && _transactions.isEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14.0),
                      border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
                    ),
                    child: const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.0),
                  ),
                ] else if (_transactions.isNotEmpty) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14.0),
                      border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
                    ),
                    child: Column(
                      children: List.generate(_transactions.length, (index) {
                        final tx = _transactions[index];
                        final isLast = index == _transactions.length - 1;
                        final txDate = _formatTransactionDate(tx.paidAt ?? tx.createdAt ?? tx.dueDate);
                        final txMethod = tx.paymentMethod ?? (tx.status.toLowerCase() == 'pending' ? 'Pending Payment' : 'Online');
                        final subtitle = txDate.isNotEmpty ? '$txDate   •   $txMethod' : txMethod;
                        final statusText = tx.displayStatus;

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14.0),
                            onTap: () {
                              if (tx.status.toLowerCase() == 'pending') {
                                Navigator.of(context).pushNamed(
                                  AppRoutes.rentDetails,
                                  arguments: tx,
                                );
                              } else {
                                Navigator.of(context).pushNamed(
                                  AppRoutes.paymentDetails,
                                  arguments: tx,
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                              decoration: BoxDecoration(
                                border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36.0,
                                    height: 36.0,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFE8F3ED),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _getTransactionIcon(tx.paymentType),
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
                                          tx.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13.0,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 3.0),
                                        Text(
                                          subtitle,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11.0,
                                            color: const Color(0xFF6B7280),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8.0),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        _formatCurrency(tx.amount),
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 3.0),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 2.0),
                                        decoration: BoxDecoration(
                                          color: _getStatusBgColor(tx.status),
                                          borderRadius: BorderRadius.circular(4.0),
                                        ),
                                        child: Text(
                                          statusText,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 10.0,
                                            fontWeight: FontWeight.w700,
                                            color: _getStatusTextColor(tx.status),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ] else if (recentTransactions.isNotEmpty) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14.0),
                      border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
                    ),
                    child: Column(
                      children: List.generate(recentTransactions.length, (index) {
                        final tx = recentTransactions[index];
                        final isLast = index == recentTransactions.length - 1;
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14.0),
                            onTap: () {
                              if (tx.status.toLowerCase() == 'pending') {
                                Navigator.of(context).pushNamed(
                                  AppRoutes.rentDetails,
                                  arguments: tx,
                                );
                              } else {
                                Navigator.of(context).pushNamed(
                                  AppRoutes.paymentDetails,
                                  arguments: tx,
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                              decoration: BoxDecoration(
                                border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36.0,
                                    height: 36.0,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFE8F3ED),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.apartment_rounded,
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
                                          tx.title,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13.0,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 3.0),
                                        Text(
                                          '${tx.date}   •   ${tx.method}',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11.0,
                                            color: const Color(0xFF6B7280),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        _formatCurrency(tx.amount),
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 3.0),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 2.0),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFD1FAE5),
                                          borderRadius: BorderRadius.circular(4.0),
                                        ),
                                        child: Text(
                                          tx.status,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 10.0,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF059669),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14.0),
                      border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36.0,
                          height: 36.0,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE8F3ED),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.receipt_long_rounded,
                            color: AppColors.primary,
                            size: 18.0,
                          ),
                        ),
                        const SizedBox(width: 12.0),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recent Transaction',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.0,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2.0),
                            Text(
                              'Data not available',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20.0),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CommonBottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36.0, horizontal: 20.0),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, color: Color(0xFF9CA3AF), size: 48.0),
          const SizedBox(height: 12.0),
          Text(
            'Unable to load payments data',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6.0),
          Text(
            _errorMessage ?? 'Please check your connection and try again',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(fontSize: 12.0, color: const Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16.0),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999.0)),
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
            ),
            onPressed: _fetchPaymentsOverview,
            child: Text(
              'Retry',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13.0),
            ),
          ),
        ],
      ),
    );
  }
}
