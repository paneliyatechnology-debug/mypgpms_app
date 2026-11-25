import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_constants.dart';

/// Clean, reusable widget that displays the application version and version code.
class CommonVersionText extends StatelessWidget {
  final TextStyle? style;
  final bool showAppName;
  final bool isShortFormat;

  const CommonVersionText({
    super.key,
    this.style,
    this.showAppName = false,
    this.isShortFormat = false,
  });

  @override
  Widget build(BuildContext context) {
    final String text;
    if (isShortFormat) {
      text = showAppName
          ? '${AppConstants.appName} ${AppConstants.appVersionShort}'
          : AppConstants.appVersionShort;
    } else {
      text = showAppName
          ? '${AppConstants.appName} ${AppConstants.appVersionDisplay}'
          : AppConstants.appVersionDisplay;
    }

    return Text(
      text,
      textAlign: TextAlign.center,
      style: style ??
          GoogleFonts.plusJakartaSans(
            fontSize: 12.0,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF9CA3AF),
          ),
    );
  }
}
