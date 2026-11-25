import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/colors/app_colors.dart';
import '../../../../core/routes/app_routes.dart';

class UpiPaymentPage extends StatelessWidget {
  const UpiPaymentPage({super.key});

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
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 10.0),
          children: [
            // Main QR Code Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
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
                  Text(
                    '₹12,000',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24.0,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16.0),

                  // QR Code with UPI/GPay overlay
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 175.0,
                        height: 175.0,
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14.0),
                          border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
                        ),
                        child: const Icon(
                          Icons.qr_code_2_rounded,
                          size: 160.0,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      Container(
                        width: 38.0,
                        height: 38.0,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.0),
                          boxShadow: const [
                            BoxShadow(color: Color(0x20000000), blurRadius: 6.0),
                          ],
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Color(0xFF4285F4),
                          size: 22.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14.0),

                  Text(
                    'Scan this QR code with any UPI app',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.0,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),

            // OR Divider
            Row(
              children: [
                const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    'OR',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ),
                const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
              ],
            ),
            const SizedBox(height: 16.0),

            // Open UPI App Button
            InkWell(
              onTap: () {
                Navigator.of(context).pushNamed(AppRoutes.paymentSuccess);
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
                child: Text(
                  'Open UPI App',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16.0),

            // Notice Box
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F3ED),
                borderRadius: BorderRadius.circular(14.0),
              ),
              child: Row(
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
                    child: Text(
                      'Make sure your UPI app is updated for a smooth payment experience.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.0,
                        color: const Color(0xFF4B5563),
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
    );
  }
}
