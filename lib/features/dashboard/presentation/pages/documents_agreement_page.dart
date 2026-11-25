import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/colors/app_colors.dart';
import '../../../../core/storage/preferences_service.dart';
import '../../../../injection_container.dart' as di;
import '../../../authentication/data/datasources/auth_remote_data_source.dart';

class _DocumentItemData {
  final String title;
  final String subtitle;
  final String status;
  final String imageUrl;

  const _DocumentItemData({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.imageUrl,
  });
}

class DocumentsAgreementPage extends StatefulWidget {
  const DocumentsAgreementPage({super.key});

  @override
  State<DocumentsAgreementPage> createState() => _DocumentsAgreementPageState();
}

class _DocumentsAgreementPageState extends State<DocumentsAgreementPage> {
  int _selectedTabIndex = 0; // 0: My Documents, 1: Agreement
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

  /// Resolves document URL. Returns null if missing or empty.
  String? _resolveDocUrl(dynamic raw) {
    if (raw == null) return null;
    final str = raw.toString().trim();
    if (str.isEmpty || str.toLowerCase() == 'null') return null;
    if (str.startsWith('http://') || str.startsWith('https://')) return str;
    if (str.startsWith('/')) return 'https://api.mypgpms.com$str';
    return 'https://api.mypgpms.com/uploads/documents/$str';
  }

  /// Opens document link in external browser/downloader
  Future<void> _downloadOrOpenDocument(String url, String title) async {
    try {
      final uri = Uri.parse(url);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (mounted) {
        if (launched) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening $title download link in browser...'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.primary,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open download link for $title'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  /// Opens full-screen interactive preview
  void _openImagePreview(BuildContext context, String title, String imageUrl) {
    showDialog(
      context: context,
      useSafeArea: false,
      barrierColor: Colors.black.withValues(alpha: 0.95),
      builder: (ctx) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24.0),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            title: Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16.0,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.file_download_outlined, color: Colors.white, size: 24.0),
                tooltip: 'Download Document',
                onPressed: () => _downloadOrOpenDocument(imageUrl, title),
              ),
            ],
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 5.0,
              child: imageUrl.startsWith('http')
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.broken_image_rounded, color: Colors.white70, size: 54.0),
                          const SizedBox(height: 10.0),
                          Text(
                            'Failed to load document preview',
                            style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 13.0),
                          ),
                        ],
                      ),
                    )
                  : Image.file(
                      File(imageUrl),
                      fit: BoxFit.contain,
                    ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: SizedBox(
                width: double.infinity,
                height: 48.0,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.download_rounded, size: 20.0),
                  label: Text(
                    'Download Document',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: () => _downloadOrOpenDocument(imageUrl, title),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth > 600 ? (screenWidth - 460) / 2 : 16.0;

    final docInfo = _savedUser?['documents'] as Map<String, dynamic>?;

    // Resolve available URLs strictly (null if not provided by backend)
    final String? aadharUrl = _resolveDocUrl(
      docInfo?['aadhar_card_url'] ?? docInfo?['aadhar_card'] ?? _savedUser?['aadhar_card_url'] ?? _savedUser?['aadhar_card'],
    );

    final String? addressProofUrl = _resolveDocUrl(
      docInfo?['address_proof_url'] ?? docInfo?['address_proof'] ?? _savedUser?['address_proof_url'] ?? _savedUser?['address_proof'],
    );

    final String? educationUrl = _resolveDocUrl(
      docInfo?['education_certificate_url'] ?? docInfo?['education_certificate'] ?? _savedUser?['education_certificate_url'] ?? _savedUser?['education_certificate'],
    );

    final String? signatureUrl = _resolveDocUrl(
      docInfo?['signature_url'] ?? docInfo?['signature'] ?? _savedUser?['signature_url'] ?? _savedUser?['signature'],
    );

    final String? agreementUrl = _resolveDocUrl(
      docInfo?['agreement_file_url'] ?? docInfo?['agreement_file'] ?? _savedUser?['agreement_file_url'] ?? _savedUser?['agreement_file'],
    );

    final String? policyUrl = _resolveDocUrl(
      docInfo?['policy_document_url'] ?? docInfo?['policy_document'] ?? _savedUser?['policy_document_url'] ?? _savedUser?['policy_document'],
    );

    final String? termsAcceptedAt = docInfo?['terms_accepted_at']?.toString() ?? _savedUser?['terms_accepted_at']?.toString();

    // Populate only available documents
    final List<_DocumentItemData> myDocs = [];
    if (aadharUrl != null) {
      myDocs.add(_DocumentItemData(
        title: 'ID Proof',
        subtitle: 'Aadhar card',
        status: 'Verified',
        imageUrl: aadharUrl,
      ));
    }
    if (addressProofUrl != null) {
      myDocs.add(_DocumentItemData(
        title: 'Address Proof',
        subtitle: 'Rental agreement',
        status: 'Verified',
        imageUrl: addressProofUrl,
      ));
    }
    if (educationUrl != null) {
      myDocs.add(_DocumentItemData(
        title: 'Other Documents',
        subtitle: 'Educational Certificate',
        status: 'Verified',
        imageUrl: educationUrl,
      ));
    }

    final List<_DocumentItemData> agreementDocs = [];
    if (agreementUrl != null) {
      agreementDocs.add(_DocumentItemData(
        title: 'Rental Agreement',
        subtitle: 'Signed Agreement • 11 months validity',
        status: 'Verified',
        imageUrl: agreementUrl,
      ));
    }
    if (policyUrl != null) {
      agreementDocs.add(_DocumentItemData(
        title: 'PG Policy & Terms',
        subtitle: 'Resident guidelines v2.1',
        status: 'Verified',
        imageUrl: policyUrl,
      ));
    }

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
          'Documents & Agreement',
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
              // Top Toggle Tabs
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedTabIndex = 0;
                        });
                      },
                      borderRadius: BorderRadius.circular(999.0),
                      child: Container(
                        height: 42.0,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _selectedTabIndex == 0 ? AppColors.primary : const Color(0xFFE8F3ED),
                          borderRadius: BorderRadius.circular(999.0),
                        ),
                        child: Text(
                          'My Documents',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.0,
                            fontWeight: FontWeight.w700,
                            color: _selectedTabIndex == 0 ? Colors.white : AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10.0),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedTabIndex = 1;
                        });
                      },
                      borderRadius: BorderRadius.circular(999.0),
                      child: Container(
                        height: 42.0,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _selectedTabIndex == 1 ? AppColors.primary : const Color(0xFFE8F3ED),
                          borderRadius: BorderRadius.circular(999.0),
                        ),
                        child: Text(
                          'Agreement',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.0,
                            fontWeight: FontWeight.w700,
                            color: _selectedTabIndex == 1 ? Colors.white : AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),

              // Tab 0: My Documents
              if (_selectedTabIndex == 0) ...[
                if (myDocs.isEmpty && signatureUrl == null) ...[
                  _buildEmptyState(
                    icon: Icons.folder_open_outlined,
                    title: 'No Documents Available',
                    description: 'Your uploaded identity proofs will appear here once submitted.',
                  ),
                ] else ...[
                  for (int i = 0; i < myDocs.length; i++) ...[
                    _buildDocumentCard(
                      title: myDocs[i].title,
                      subtitle: myDocs[i].subtitle,
                      status: myDocs[i].status,
                      imageUrl: myDocs[i].imageUrl,
                    ),
                    const SizedBox(height: 12.0),
                  ],

                  // Resident Signature Section Below Documents
                  if (signatureUrl != null) ...[
                    _buildSignatureCard(
                      signatureUrl: signatureUrl,
                      acceptedAt: termsAcceptedAt,
                    ),
                    const SizedBox(height: 12.0),
                  ],
                ],
              ]
              // Tab 1: Agreement
              else ...[
                if (agreementDocs.isEmpty) ...[
                  _buildEmptyState(
                    icon: Icons.assignment_outlined,
                    title: 'No Agreement Available',
                    description: 'Rental agreement document has not been uploaded yet.',
                  ),
                  const SizedBox(height: 12.0),
                  // If signature exists, show signature here as well
                  if (signatureUrl != null) ...[
                    _buildSignatureCard(
                      signatureUrl: signatureUrl,
                      acceptedAt: termsAcceptedAt,
                    ),
                    const SizedBox(height: 12.0),
                  ],
                ] else ...[
                  for (int i = 0; i < agreementDocs.length; i++) ...[
                    _buildDocumentCard(
                      title: agreementDocs[i].title,
                      subtitle: agreementDocs[i].subtitle,
                      status: agreementDocs[i].status,
                      imageUrl: agreementDocs[i].imageUrl,
                    ),
                    const SizedBox(height: 12.0),
                  ],
                  if (signatureUrl != null) ...[
                    _buildSignatureCard(
                      signatureUrl: signatureUrl,
                      acceptedAt: termsAcceptedAt,
                    ),
                    const SizedBox(height: 12.0),
                  ],
                ],
              ],

              const SizedBox(height: 4.0),

              // Bottom Notice Box
              Container(
                padding: const EdgeInsets.all(14.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F3ED),
                  borderRadius: BorderRadius.circular(14.0),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32.0,
                      height: 32.0,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified_user_outlined,
                        color: AppColors.primary,
                        size: 18.0,
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Text(
                        'All documents are securely stored and verified by MYPGPMS.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.0,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                          height: 1.4,
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
      ),
    );
  }

  /// Builds a single document card with thumbnail, preview button, and functional download button
  Widget _buildDocumentCard({
    required String title,
    required String subtitle,
    required String status,
    required String imageUrl,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 6.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.0),
          onTap: () => _openImagePreview(context, title, imageUrl),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Document Image Thumbnail
                GestureDetector(
                  onTap: () => _openImagePreview(context, title, imageUrl),
                  child: Container(
                    width: 58.0,
                    height: 58.0,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F3ED),
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        imageUrl.startsWith('http')
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const Center(
                                    child: SizedBox(
                                      width: 18.0,
                                      height: 18.0,
                                      child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.0),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: const Color(0xFFE8F3ED),
                                  child: const Center(
                                    child: Icon(Icons.description_outlined, color: AppColors.primary, size: 24.0),
                                  ),
                                ),
                              )
                            : Image.file(
                                File(imageUrl),
                                fit: BoxFit.cover,
                              ),
                        // Zoom icon badge overlay
                        Positioned(
                          right: 3.0,
                          bottom: 3.0,
                          child: Container(
                            padding: const EdgeInsets.all(2.5),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 10.0),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12.0),

                // Title, Subtitle & Status Badge
                Expanded(
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
                      const SizedBox(height: 2.0),
                      Text(
                        subtitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.0,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 6.0),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 11.0,
                              color: Color(0xFF059669),
                            ),
                            const SizedBox(width: 3.5),
                            Text(
                              status,
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
                ),

                // Preview & Download Action Buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Preview Button
                    IconButton(
                      icon: const Icon(
                        Icons.visibility_outlined,
                        color: AppColors.primary,
                        size: 20.0,
                      ),
                      tooltip: 'Preview Document',
                      onPressed: () => _openImagePreview(context, title, imageUrl),
                    ),
                    // Functional Download Button
                    IconButton(
                      icon: const Icon(
                        Icons.file_download_outlined,
                        color: AppColors.primary,
                        size: 21.0,
                      ),
                      tooltip: 'Download Document',
                      onPressed: () => _downloadOrOpenDocument(imageUrl, title),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a dedicated Resident Signature Card below the documents
  Widget _buildSignatureCard({
    required String signatureUrl,
    String? acceptedAt,
  }) {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 6.0,
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
                padding: const EdgeInsets.all(7.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F3ED),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Icon(Icons.draw_rounded, color: AppColors.primary, size: 18.0),
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resident Signature',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (acceptedAt != null && acceptedAt.isNotEmpty)
                      Text(
                        'Terms accepted on $acceptedAt',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 11.0, color: Color(0xFF059669)),
                    const SizedBox(width: 3.5),
                    Text(
                      'Verified',
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
          const SizedBox(height: 12.0),

          // Signature Image Container
          InkWell(
            onTap: () => _openImagePreview(context, 'Resident Signature', signatureUrl),
            borderRadius: BorderRadius.circular(12.0),
            child: Container(
              width: double.infinity,
              height: 90.0,
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.network(
                    signatureUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: SizedBox(
                          width: 20.0,
                          height: 20.0,
                          child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.0),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(Icons.draw_outlined, color: Colors.grey, size: 28.0),
                    ),
                  ),
                  Positioned(
                    right: 4.0,
                    bottom: 4.0,
                    child: Container(
                      padding: const EdgeInsets.all(3.0),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 12.0),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10.0),

          // Actions Row (Preview & Download)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _openImagePreview(context, 'Resident Signature', signatureUrl),
                icon: const Icon(Icons.visibility_outlined, size: 16.0, color: AppColors.primary),
                label: Text(
                  'Preview',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 8.0),
              TextButton.icon(
                onPressed: () => _downloadOrOpenDocument(signatureUrl, 'Resident Signature'),
                icon: const Icon(Icons.file_download_outlined, size: 16.0, color: AppColors.primary),
                label: Text(
                  'Download',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Empty state widget when no documents are uploaded yet
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36.0, horizontal: 20.0),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14.0),
            decoration: const BoxDecoration(
              color: Color(0xFFE8F3ED),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 32.0),
          ),
          const SizedBox(height: 12.0),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15.0,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            description,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              color: const Color(0xFF6B7280),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
