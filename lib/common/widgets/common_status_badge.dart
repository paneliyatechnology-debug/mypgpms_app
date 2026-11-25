import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Reusable status badge pill component for MYPGPMS.
/// Displays clean status labels with soft tinted background and bold colored text.
class CommonStatusBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final double fontSize;
  final EdgeInsetsGeometry padding;
  final Widget? leading;

  const CommonStatusBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.fontSize = 11.5,
    this.padding = const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
    this.leading,
  });

  /// Factory for green/success status (e.g. Approved, Paid, Resolved)
  factory CommonStatusBadge.success({
    Key? key,
    required String label,
    double fontSize = 11.5,
    Widget? leading,
  }) {
    return CommonStatusBadge(
      key: key,
      label: label,
      backgroundColor: const Color(0xFFD1FAE5),
      textColor: const Color(0xFF059669),
      fontSize: fontSize,
      leading: leading,
    );
  }

  /// Factory for amber/warning status (e.g. Pending, In Office, In Progress)
  factory CommonStatusBadge.warning({
    Key? key,
    required String label,
    double fontSize = 11.5,
    Widget? leading,
  }) {
    return CommonStatusBadge(
      key: key,
      label: label,
      backgroundColor: const Color(0xFFFEF3C7),
      textColor: const Color(0xFFD97706),
      fontSize: fontSize,
      leading: leading,
    );
  }

  /// Factory for red/error status (e.g. Rejected, Overdue, Cancelled)
  factory CommonStatusBadge.error({
    Key? key,
    required String label,
    double fontSize = 11.5,
    Widget? leading,
  }) {
    return CommonStatusBadge(
      key: key,
      label: label,
      backgroundColor: const Color(0xFFFEE2E2),
      textColor: const Color(0xFFDC2626),
      fontSize: fontSize,
      leading: leading,
    );
  }

  /// Factory for neutral/gray status (e.g. Closed, Draft, Completed)
  factory CommonStatusBadge.neutral({
    Key? key,
    required String label,
    double fontSize = 11.5,
    Widget? leading,
  }) {
    return CommonStatusBadge(
      key: key,
      label: label,
      backgroundColor: const Color(0xFFF3F4F6),
      textColor: const Color(0xFF4B5563),
      fontSize: fontSize,
      leading: leading,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 4.0),
          ],
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
