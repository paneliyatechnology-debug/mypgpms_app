import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/colors/app_colors.dart';
import '../../../../core/storage/preferences_service.dart';
import '../../../../injection_container.dart' as di;
import '../../../authentication/data/datasources/auth_remote_data_source.dart';

class EmergencyContactPage extends StatefulWidget {
  const EmergencyContactPage({super.key});

  @override
  State<EmergencyContactPage> createState() => _EmergencyContactPageState();
}

class _EmergencyContactPageState extends State<EmergencyContactPage> {
  Map<String, dynamic>? _savedUser;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLocalData();
    _fetchFreshUserData();
  }

  void _loadLocalData() {
    try {
      final prefService = di.sl<PreferencesService>();
      setState(() {
        _savedUser = prefService.getSavedUser();
      });
    } catch (_) {}
  }

  Future<void> _fetchFreshUserData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final authDataSource = di.sl<AuthRemoteDataSource>();
      final prefService = di.sl<PreferencesService>();
      final user = await authDataSource.getMe();
      final userMap = user.rawJson.isNotEmpty ? Map<String, dynamic>.from(user.rawJson) : user.toJson();
      await prefService.saveUserData(userMap);
      if (mounted) {
        setState(() {
          _savedUser = userMap;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatPhone(String raw) {
    final clean = raw.replaceAll(RegExp(r'\D'), '');
    if (clean.length == 10) {
      return '+91 ${clean.substring(0, 5)} ${clean.substring(5)}';
    }
    return raw;
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return 'EC';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.trim().substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth > 600 ? (screenWidth - 460) / 2 : 16.0;

    final contactInfo = _savedUser?['contact_info'] as Map<String, dynamic>?;

    // Primary Contact Dynamic Data
    final String? primaryNameRaw = contactInfo?['emergency_contact_name']?.toString() ??
        _savedUser?['emergency_contact_name']?.toString();
    final String primaryName = (primaryNameRaw != null && primaryNameRaw.trim().isNotEmpty && primaryNameRaw != 'null')
        ? primaryNameRaw.trim()
        : 'Niraj Patel';

    final String? primaryPhoneRaw = contactInfo?['emergency_contact_phone']?.toString() ??
        _savedUser?['emergency_contact_phone']?.toString();
    final String primaryPhone = (primaryPhoneRaw != null && primaryPhoneRaw.trim().isNotEmpty && primaryPhoneRaw != 'null')
        ? primaryPhoneRaw.trim()
        : '9426886960';

    final String? primaryRelationRaw = contactInfo?['emergency_contact_relationship']?.toString() ??
        _savedUser?['emergency_contact_relationship']?.toString();
    final String primaryRelation = (primaryRelationRaw != null && primaryRelationRaw.trim().isNotEmpty && primaryRelationRaw != 'null')
        ? primaryRelationRaw.trim()
        : 'Other';

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
          'Emergency Contact',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18.0,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        centerTitle: false,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(
                child: SizedBox(
                  width: 18.0,
                  height: 18.0,
                  child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.0),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchFreshUserData,
          color: AppColors.primary,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8.0),
            children: [
              // Top Safety Protocol Banner
              Container(
                padding: const EdgeInsets.all(14.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F3ED),
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.15), width: 1.0),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.health_and_safety_rounded,
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
                            'Your Safety is Our Priority',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.0,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 3.0),
                          Text(
                            'In case of any urgent situation or emergency, our PG warden and administration will reach out to this verified contact immediately.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary.withValues(alpha: 0.85),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),

              // Primary Contact Card
              _buildContactCard(
                name: primaryName,
                phone: primaryPhone,
                relation: primaryRelation,
              ),
              const SizedBox(height: 20.0),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the single primary contact card
  Widget _buildContactCard({
    required String name,
    required String phone,
    required String relation,
  }) {
    final initials = _getInitials(name);
    final formattedPhone = _formatPhone(phone);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Avatar + Name & Subtitle
            Row(
              children: [
                // Initials Circle
                Container(
                  width: 44.0,
                  height: 44.0,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F3ED),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12.0),

                // Name and Primary Contact Label
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Primary Contact',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.0,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14.0),
            const Divider(height: 1.0, color: Color(0xFFF3F4F6)),
            const SizedBox(height: 12.0),

            // Detail 1: Person Name
            _buildDetailRow(
              icon: Icons.person_outline_rounded,
              label: 'Person name',
              value: name,
            ),
            const SizedBox(height: 10.0),

            // Detail 2: Phone Number
            _buildDetailRow(
              icon: Icons.phone_outlined,
              label: 'Phone number',
              value: formattedPhone,
            ),
            const SizedBox(height: 10.0),

            // Detail 3: Relation
            _buildDetailRow(
              icon: Icons.people_outline_rounded,
              label: 'Relation',
              value: relation,
              isChip: true,
            ),
          ],
        ),
      ),
    );
  }

  /// Single detail row with icon, label, and formatted value
  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    bool isChip = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16.0, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 8.0),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            color: const Color(0xFF6B7280),
          ),
        ),
        const Spacer(),
        if (isChip)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F3ED),
              borderRadius: BorderRadius.circular(6.0),
            ),
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.0,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          )
        else
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.0,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
      ],
    );
  }
}
