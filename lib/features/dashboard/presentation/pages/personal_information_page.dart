import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/colors/app_colors.dart';
import '../../../../core/storage/preferences_service.dart';
import '../../../../injection_container.dart' as di;
import '../../../authentication/data/datasources/auth_remote_data_source.dart';

class PersonalInformationPage extends StatefulWidget {
  const PersonalInformationPage({super.key});

  @override
  State<PersonalInformationPage> createState() => _PersonalInformationPageState();
}

class _PersonalInformationPageState extends State<PersonalInformationPage> {
  Map<String, dynamic>? _savedUser;
  Map<String, dynamic>? _savedDashboard;

  @override
  void initState() {
    super.initState();
    _loadLocalData();
    _fetchFreshData();
  }

  void _loadLocalData() {
    try {
      final prefService = di.sl<PreferencesService>();
      setState(() {
        _savedUser = prefService.getSavedUser();
        _savedDashboard = prefService.getSavedDashboard();
      });
    } catch (_) {}
  }

  Future<void> _fetchFreshData() async {
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
    } catch (_) {}
  }

  String _cleanDob(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'Not provided';
    // Remove awkward '(0 Years)' or '(0 Year)' from raw string
    final cleaned = raw.replaceAll(RegExp(r'\s*\(\s*0\s*Years?\s*\)', caseSensitive: false), '').trim();
    return cleaned.isNotEmpty ? cleaned : raw;
  }

  String _capitalize(String? text) {
    if (text == null || text.trim().isEmpty) return 'Not specified';
    final trimmed = text.trim();
    return '${trimmed[0].toUpperCase()}${trimmed.substring(1).toLowerCase()}';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth > 600 ? (screenWidth - 460) / 2 : 16.0;

    final greeting = _savedDashboard?['greeting'] as Map<String, dynamic>?;
    final personalInfo = _savedUser?['personal_info'] as Map<String, dynamic>?;
    final contactInfo = _savedUser?['contact_info'] as Map<String, dynamic>?;

    final String fullName = greeting?['resident_name']?.toString() ??
        _savedUser?['name']?.toString() ??
        personalInfo?['name']?.toString() ??
        'Jasmin Korat';

    final String rawDob = personalInfo?['dob_display']?.toString() ??
        personalInfo?['date_of_birth']?.toString() ??
        _savedUser?['date_of_birth']?.toString() ??
        '18 November 2026';
    final String cleanDob = _cleanDob(rawDob);

    final String rawGender = personalInfo?['gender']?.toString() ??
        _savedUser?['gender']?.toString() ??
        'Male';
    final String gender = _capitalize(rawGender);

    final String phone = contactInfo?['phone']?.toString() ??
        _savedUser?['phone']?.toString() ??
        _savedUser?['phone_number']?.toString() ??
        '9510442798';

    final String email = contactInfo?['email']?.toString() ??
        _savedUser?['email']?.toString() ??
        'jasminkorat04@gmail.com';

    final String rawMaritalStatus = personalInfo?['marital_status']?.toString() ??
        _savedUser?['marital_status']?.toString() ??
        'Single';
    final String maritalStatus = _capitalize(rawMaritalStatus);

    final String occupation = personalInfo?['occupation']?.toString() ??
        _savedUser?['occupation']?.toString() ??
        '';

    final String addressLine = contactInfo?['address_line_1']?.toString() ??
        contactInfo?['address']?.toString() ??
        _savedUser?['address']?.toString() ??
        'Nikol';

    final String city = contactInfo?['city']?.toString() ?? _savedUser?['city']?.toString() ?? '';
    final String state = contactInfo?['state']?.toString() ?? _savedUser?['state']?.toString() ?? '';
    final String pincode = contactInfo?['pincode']?.toString() ?? _savedUser?['pincode']?.toString() ?? '';

    final List<String> cityStateParts = [
      if (city.isNotEmpty) city,
      if (state.isNotEmpty) state,
      if (pincode.isNotEmpty) pincode,
    ];
    final String cityStateZip = cityStateParts.join(', ');

    final String residentId = _savedUser?['resident_id']?.toString() ??
        (_savedUser?['id'] != null ? 'CLV - ${_savedUser!['id']}' : 'CLV - 104');

    final String? photoUrl = greeting?['photo_url']?.toString() ??
        _savedUser?['profile_photo_url']?.toString() ??
        _savedUser?['profile_image_url']?.toString();

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
          'Personal Information',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18.0,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchFreshData,
          color: AppColors.primary,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 10.0),
            children: [
              // 1. Profile Avatar & Identity Card
              Container(
                padding: const EdgeInsets.all(16.0),
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
                child: Row(
                  children: [
                    Container(
                      width: 56.0,
                      height: 56.0,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F3ED),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15), width: 2.0),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: photoUrl != null && photoUrl.isNotEmpty
                          ? Image.network(
                              photoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Center(
                                child: Text(
                                  fullName.isNotEmpty ? fullName[0].toUpperCase() : 'J',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 22.0,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                fullName.isNotEmpty ? fullName[0].toUpperCase() : 'J',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 22.0,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(width: 14.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16.0,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 5.0),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F3ED),
                                  borderRadius: BorderRadius.circular(6.0),
                                ),
                                child: Text(
                                  residentId,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.0,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8.0),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD1FAE5),
                                  borderRadius: BorderRadius.circular(6.0),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.verified_rounded, color: Color(0xFF059669), size: 12.0),
                                    const SizedBox(width: 3.0),
                                    Text(
                                      'Active Resident',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF059669),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14.0),

              // 2. Basic Details Card
              Container(
                padding: const EdgeInsets.all(16.0),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 28.0,
                          height: 28.0,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE8F3ED),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.badge_outlined, color: AppColors.primary, size: 15.0),
                        ),
                        const SizedBox(width: 10.0),
                        Text(
                          'Basic Details',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14.0),
                    _buildDetailRow(
                      icon: Icons.person_outline_rounded,
                      label: 'Full name',
                      value: fullName,
                    ),
                    _buildDivider(),
                    _buildDetailRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Date of Birth',
                      value: cleanDob,
                    ),
                    _buildDivider(),
                    _buildDetailRow(
                      icon: Icons.wc_rounded,
                      label: 'Gender',
                      value: gender,
                    ),
                    _buildDivider(),
                    _buildDetailRow(
                      icon: Icons.phone_outlined,
                      label: 'Phone Number',
                      value: phone,
                    ),
                    _buildDivider(),
                    _buildDetailRow(
                      icon: Icons.email_outlined,
                      label: 'Email ID',
                      value: email,
                    ),
                    _buildDivider(),
                    _buildDetailRow(
                      icon: Icons.favorite_outline_rounded,
                      label: 'Marital status',
                      value: maritalStatus,
                    ),
                    if (occupation.isNotEmpty) ...[
                      _buildDivider(),
                      _buildDetailRow(
                        icon: Icons.work_outline_rounded,
                        label: 'Occupation',
                        value: occupation,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14.0),

              // 3. Current Address Card
              Container(
                padding: const EdgeInsets.all(16.0),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 28.0,
                          height: 28.0,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE8F3ED),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 16.0),
                        ),
                        const SizedBox(width: 10.0),
                        Text(
                          'Current Address',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14.0),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(color: const Color(0xFFF3F4F6)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.pin_drop_rounded, color: AppColors.primary, size: 18.0),
                          const SizedBox(width: 10.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  addressLine,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                    height: 1.4,
                                  ),
                                ),
                                if (cityStateZip.isNotEmpty) ...[
                                  const SizedBox(height: 4.0),
                                  Text(
                                    cityStateZip,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12.0,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 9.0),
      child: Divider(color: Color(0xFFF3F4F6), height: 1.0, thickness: 1.0),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 26.0,
          height: 26.0,
          decoration: const BoxDecoration(
            color: Color(0xFFF9FAFB),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF6B7280), size: 14.0),
        ),
        const SizedBox(width: 10.0),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            color: const Color(0xFF6B7280),
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.0,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
