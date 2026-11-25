import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/colors/app_colors.dart';

class ComplaintFeedbackPage extends StatefulWidget {
  const ComplaintFeedbackPage({super.key});

  @override
  State<ComplaintFeedbackPage> createState() => _ComplaintFeedbackPageState();
}

class _ComplaintFeedbackPageState extends State<ComplaintFeedbackPage> {
  int _rating = 4;
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
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
          'Feedback',
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
            const SizedBox(height: 10.0),

            // Top Thumbs Up + Stars Illustration Circle
            Center(
              child: Container(
                width: 88.0,
                height: 88.0,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F3ED),
                  shape: BoxShape.circle,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.thumb_up_rounded,
                      color: AppColors.primary,
                      size: 34.0,
                    ),
                    const SizedBox(height: 3.0),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (_) {
                        return const Icon(
                          Icons.star_rounded,
                          color: AppColors.primary,
                          size: 11.0,
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16.0),

            // Question Title & Subtitle
            Center(
              child: Text(
                'How was the resolution?',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 3.0),
            Center(
              child: Text(
                'Your feedback help us to improve.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.0,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ),
            const SizedBox(height: 20.0),

            // Complaint Preview Card
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14.0),
                border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
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
                  Container(
                    width: 38.0,
                    height: 38.0,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8F3ED),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.wifi_rounded,
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
                          'WiFi not working',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          '#CL-1024   •   05 march 2026',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18.0),

            // 5 Stars Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starValue = index + 1;
                final isSelected = starValue <= _rating;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _rating = starValue;
                    });
                  },
                  borderRadius: BorderRadius.circular(999.0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: Icon(
                      isSelected ? Icons.star_rounded : Icons.star_border_rounded,
                      color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFF9CA3AF),
                      size: 36.0,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 18.0),

            // Additional Comments Box
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14.0),
                border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextField(
                    controller: _commentController,
                    maxLines: 4,
                    maxLength: 300,
                    onChanged: (val) => setState(() {}),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.0,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Any additional comments',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        color: const Color(0xFF9CA3AF),
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      filled: false,
                      fillColor: Colors.transparent,
                      contentPadding: EdgeInsets.zero,
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    '${_commentController.text.length}/300',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.0,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24.0),

            // Submit Feedback Button
            InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Feedback submitted successfully! Thank you.')),
                );
                Navigator.of(context).popUntil((route) => route.isFirst);
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
                  'Submit Feedback',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12.0),

            // Skip for now
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Skip for now',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16.0),
          ],
        ),
      ),
    );
  }
}
