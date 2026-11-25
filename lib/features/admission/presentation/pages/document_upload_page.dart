import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/colors/app_colors.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../common/widgets/common_app_bar.dart';
import '../bloc/admission_bloc.dart';
import '../bloc/admission_event.dart';
import '../widgets/admission_nav_buttons.dart';
import '../widgets/step_progress_header.dart';

class DocumentUploadPage extends StatefulWidget {
  const DocumentUploadPage({super.key});

  @override
  State<DocumentUploadPage> createState() => _DocumentUploadPageState();
}

class _DocItem {
  final String id;
  final String title;
  final bool isRequired;
  bool isUploaded;
  String? fileName;
  String? fileSize;
  String? filePath;

  _DocItem({
    required this.id,
    required this.title,
    required this.isRequired,
    this.isUploaded = false,
    this.fileName,
    this.fileSize,
  });
}

class _DocumentUploadPageState extends State<DocumentUploadPage> {
  final List<_DocItem> _documents = [
    _DocItem(
      id: 'aadhar',
      title: 'Aadhar card',
      isRequired: true,
      isUploaded: false,
      fileName: 'name_aadhar.pdf',
      fileSize: '2.3 MB',
    ),
    _DocItem(
      id: 'photo',
      title: 'Passport size photo',
      isRequired: true,
      isUploaded: false,
      fileName: 'photo.jpg',
      fileSize: '1.8 MB',
    ),
    _DocItem(
      id: 'address',
      title: 'Address proof',
      isRequired: true,
      isUploaded: false,
      fileName: 'address_proof.pdf',
      fileSize: '2.0 MB',
    ),
    _DocItem(
      id: 'education',
      title: 'Previous education certificate',
      isRequired: false,
      isUploaded: false,
      fileName: 'degree_cert.pdf',
      fileSize: '1.5 MB',
    ),
  ];

  Future<void> _openImagePickerSheet(_DocItem item) async {
    final ImageSource? selectedSource = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 14.0, 20.0, 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44.0,
                    height: 4.0,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1D5DB),
                      borderRadius: BorderRadius.circular(2.0),
                    ),
                  ),
                ),
                const SizedBox(height: 18.0),
                Text(
                  'Upload ${item.title}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18.0,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  'Choose Camera or Gallery to upload your document',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.0,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 20.0),

                // Option 1: Camera
                InkWell(
                  onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
                  borderRadius: BorderRadius.circular(16.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44.0,
                          height: 44.0,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE8F3ED),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary, size: 22.0),
                        ),
                        const SizedBox(width: 14.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Camera',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15.0,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2.0),
                              Text(
                                'Take a photo using your camera',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 16.0, color: Color(0xFF9CA3AF)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12.0),

                // Option 2: Gallery
                InkWell(
                  onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
                  borderRadius: BorderRadius.circular(16.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44.0,
                          height: 44.0,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE8F3ED),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.photo_library_rounded, color: AppColors.primary, size: 22.0),
                        ),
                        const SizedBox(width: 14.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Gallery',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15.0,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2.0),
                              Text(
                                'Choose an image from your gallery',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 16.0, color: Color(0xFF9CA3AF)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selectedSource != null) {
      // Brief pause to allow bottom sheet dismissal animation to finish
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      await _pickDocument(item, selectedSource);
    }
  }

  Future<void> _pickDocument(_DocItem item, ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (picked != null) {
        final File file = File(picked.path);
        int bytes = 0;
        try {
          if (await file.exists()) {
            bytes = await file.length();
          }
        } catch (_) {}

        final String sizeString = bytes > (1024 * 1024)
            ? '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB'
            : bytes > 0
                ? '${(bytes / 1024).toStringAsFixed(0)} KB'
                : '1.2 MB';

        setState(() {
          item.isUploaded = true;
          item.filePath = picked.path;
          item.fileName = picked.name.isNotEmpty ? picked.name : '${item.id}.jpg';
          item.fileSize = sizeString;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${item.title} uploaded successfully!'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.primary,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking document: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open ${source == ImageSource.camera ? "Camera" : "Gallery"}: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showImagePreviewDialog(_DocItem item) {
    showDialog(
      context: context,
      builder: (ctx) {
        final bool hasLocalFile = item.filePath != null && File(item.filePath!).existsSync();

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 520.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16.0,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (item.fileName != null)
                              Text(
                                '${item.fileName} • ${item.fileSize ?? ""}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.0,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1.0, color: Color(0xFFE5E7EB)),

                // Image Preview with interactive pinch-to-zoom
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.0),
                      child: InteractiveViewer(
                        child: hasLocalFile
                            ? Image.file(
                                File(item.filePath!),
                                fit: BoxFit.contain,
                              )
                            : Image.asset(
                                AppAssets.admissionRoom,
                                fit: BoxFit.contain,
                              ),
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1.0, color: Color(0xFFE5E7EB)),

                // Actions: Change Photo & Delete
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            _openImagePickerSheet(item);
                          },
                          icon: const Icon(Icons.replay_rounded, size: 16.0),
                          label: const Text('Change'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999.0),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              item.isUploaded = false;
                              item.filePath = null;
                            });
                            Navigator.of(ctx).pop();
                          },
                          icon: const Icon(Icons.delete_outline_rounded, size: 16.0, color: AppColors.error),
                          label: const Text('Remove', style: TextStyle(color: AppColors.error)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999.0),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFallbackIcon() {
    return Container(
      width: 44.0,
      height: 44.0,
      decoration: const BoxDecoration(
        color: Color(0xFFE8F3ED),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Icon(
          Icons.picture_as_pdf_rounded,
          color: Color(0xFF146A4F),
          size: 22.0,
        ),
      ),
    );
  }

  Widget _buildDocCard(_DocItem item) {
    final bool hasFilePreview = item.isUploaded && item.filePath != null && File(item.filePath!).existsSync();

    return Container(
      margin: const EdgeInsets.only(bottom: 14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(16.0),
          onTap: () {
            if (item.isUploaded) {
              _showImagePreviewDialog(item);
            } else {
              _openImagePickerSheet(item);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left: Image Preview thumbnail (if uploaded) OR Document Icon
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    if (hasFilePreview)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10.0),
                        child: Image.file(
                          File(item.filePath!),
                          width: 44.0,
                          height: 44.0,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(),
                        ),
                      )
                    else
                      _buildFallbackIcon(),
                    if (item.isUploaded)
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          padding: const EdgeInsets.all(2.5),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.visibility_rounded,
                            color: Colors.white,
                            size: 10.0,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14.0),

                // Middle: File Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text.rich(
                        TextSpan(
                          text: item.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          children: [
                            if (item.isRequired)
                              const TextSpan(
                                text: ' *',
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (item.isUploaded && item.fileName != null) ...[
                        const SizedBox(height: 3.0),
                        Text(
                          item.fileName!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.0,
                            color: const Color(0xFF6B7280),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          item.fileSize ?? '',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8.0),

                // Right: Uploaded Badge OR Upload File Button
                if (item.isUploaded)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 7.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD6EAE0),
                      borderRadius: BorderRadius.circular(999.0),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 14.0,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4.0),
                        Text(
                          'Uploaded',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.0,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(999.0),
                      border: Border.all(color: AppColors.primary, width: 1.2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.cloud_upload_outlined,
                          size: 16.0,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6.0),
                        Text(
                          'Upload File',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.0,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onNext() {
    String? aadharPath;
    String? photoPath;
    String? addressPath;
    String? educationPath;
    final List<String> uploadedTitles = [];

    for (final doc in _documents) {
      if (doc.isUploaded) {
        uploadedTitles.add(doc.title);
        if (doc.id == 'aadhar') aadharPath = doc.filePath;
        if (doc.id == 'photo') photoPath = doc.filePath;
        if (doc.id == 'address') addressPath = doc.filePath;
        if (doc.id == 'education') educationPath = doc.filePath;
      }
    }

    context.read<AdmissionBloc>().add(
      UpdateDocumentFiles(
        aadharCardPath: aadharPath,
        profilePhotoPath: photoPath,
        addressProofPath: addressPath,
        educationCertPath: educationPath,
        uploadedTitles: uploadedTitles,
      ),
    );

    Navigator.of(context).pushNamed(AppRoutes.admissionAgreement);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F6),
      appBar: const CommonAppBar(
        title: 'Document Upload',
        backgroundColor: Color(0xFFF7F8F6),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StepProgressHeader(currentStep: 3),
              const SizedBox(height: 20.0),

              Text(
                'Upload Documents',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20.0,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6.0),
              Text(
                'Please upload the required documents in clear view (PDF, JPG & PNG).',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  color: const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 24.0),

              ..._documents.map(_buildDocCard),

              const SizedBox(height: 28.0),

              AdmissionNavButtons(
                onBack: () => Navigator.of(context).pop(),
                onNext: _onNext,
              ),
              const SizedBox(height: 24.0),
            ],
          ),
        ),
      ),
    );
  }
}
