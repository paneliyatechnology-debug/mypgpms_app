import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/colors/app_colors.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _pushEnabled = true;
  bool _paymentsEnabled = true;
  bool _communityEnabled = true;
  bool _maintenanceEnabled = true;

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
          'Notification Settings',
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
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8.0),
          children: [
            // Push Notifications Header
            _buildSectionHeader('Push Notifications'),
            const SizedBox(height: 8.0),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Enable notifications',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          'Receive push notifications on this device',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _pushEnabled,
                    activeThumbColor: AppColors.primary,
                    activeTrackColor: const Color(0xFFE8F3ED),
                    onChanged: (val) {
                      setState(() {
                        _pushEnabled = val;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18.0),

            // Notification Categories Header
            _buildSectionHeader('Notification Categories'),
            const SizedBox(height: 8.0),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
              ),
              child: Column(
                children: [
                  _buildCategoryRow(
                    title: 'Payments & Billing',
                    subtitle: 'Payment reminders, invoices',
                    value: _paymentsEnabled,
                    onChanged: (val) => setState(() => _paymentsEnabled = val),
                  ),
                  const Divider(height: 1.0, color: Color(0xFFF3F4F6)),
                  _buildCategoryRow(
                    title: 'Community',
                    subtitle: 'Events, announcements',
                    value: _communityEnabled,
                    onChanged: (val) => setState(() => _communityEnabled = val),
                  ),
                  const Divider(height: 1.0, color: Color(0xFFF3F4F6)),
                  _buildCategoryRow(
                    title: 'Maintenance',
                    subtitle: 'Service Updates, issues',
                    value: _maintenanceEnabled,
                    onChanged: (val) => setState(() => _maintenanceEnabled = val),
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

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14.5,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildCategoryRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: AppColors.primary,
            activeTrackColor: const Color(0xFFE8F3ED),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
