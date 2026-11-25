import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/colors/app_colors.dart';
import '../../core/routes/app_routes.dart';

/// Reusable Bottom Navigation Bar for MYPGPMS application.
/// Provides consistent 5-tab layout (Home, Payments, Services, Visitors, Profile)
/// with pixel-perfect brand styling and smooth navigation.
class CommonBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const CommonBottomNavBar({
    super.key,
    required this.currentIndex,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB), width: 1.0)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            children: [
              Expanded(child: _buildNavItem(context, 0, Icons.home_rounded, 'Home')),
              Expanded(child: _buildNavItem(context, 1, Icons.receipt_long_outlined, 'Payments')),
              Expanded(child: _buildNavItem(context, 2, Icons.build_outlined, 'Services')),
              Expanded(child: _buildNavItem(context, 3, Icons.group_outlined, 'Visitors')),
              Expanded(child: _buildNavItem(context, 4, Icons.person_outline_rounded, 'Profile')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon, String label) {
    final isSelected = currentIndex == index;
    final color = isSelected ? AppColors.primary : const Color(0xFF9CA3AF);

    return InkWell(
      onTap: () {
        if (onTap != null) {
          onTap!(index);
          return;
        }

        if (index == currentIndex && index == 0) return;

        switch (index) {
          case 0:
            if (currentIndex != 0) {
              Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.dashboard, (route) => false);
            }
            break;
          case 1:
            if (currentIndex != 1) {
              Navigator.of(context).pushNamed(AppRoutes.payments);
            }
            break;
          case 2:
            if (currentIndex != 2) {
              Navigator.of(context).pushNamed(AppRoutes.services);
            }
            break;
          case 3:
            if (currentIndex != 3) {
              Navigator.of(context).pushNamed(AppRoutes.visitors);
            }
            break;
          case 4:
            if (currentIndex != 4) {
              Navigator.of(context).pushNamed(AppRoutes.profile);
            }
            break;
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22.0),
            const SizedBox(height: 2.0),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.0,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
