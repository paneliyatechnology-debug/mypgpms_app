import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/colors/app_colors.dart';
import '../../../../core/network/socket_service.dart';
import '../../../../core/storage/preferences_service.dart';
import '../../../../injection_container.dart' as di;
import '../../data/datasources/complaints_remote_data_source.dart';
import '../../data/models/complaint_category_model.dart';

class CreateComplaintPage extends StatefulWidget {
  final String? initialCategory;

  const CreateComplaintPage({super.key, this.initialCategory});

  @override
  State<CreateComplaintPage> createState() => _CreateComplaintPageState();
}

class _CreateComplaintPageState extends State<CreateComplaintPage> {
  late String _selectedCategory;
  String _selectedLocation = 'Room A-204';
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final List<XFile> _selectedFiles = [];
  final ImagePicker _imagePicker = ImagePicker();
  bool _isSubmitting = false;
  List<ComplaintCategoryModel> _categoryModels = [];

  List<String> _categories = [
    'Cleaning',
    'AC',
    'WiFi',
    'Water',
    'Food',
    'Electricity',
    'Furniture',
    'Plumbing',
    'Appliances',
    'Washing Machine',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  void _loadCategories() {
    try {
      final prefService = di.sl<PreferencesService>();
      final cached = prefService.getSavedComplaintCategories();
      if (cached != null && cached.isNotEmpty) {
        final parsed = cached.map((e) => ComplaintCategoryModel.fromJson(e)).toList();
        _categoryModels = parsed;
        final names = parsed.map((e) => e.name).toList();
        if (names.isNotEmpty) {
          _categories = names;
          if (!_categories.contains('Washing Machine')) {
            _categories.insert(_categories.length > 1 ? _categories.length - 1 : _categories.length, 'Washing Machine');
          }
        }
      }

      // Load user profile assigned room
      final savedDashboard = prefService.getSavedDashboard();
      final savedUser = prefService.getSavedUser();
      final stay = savedDashboard?['stay'] as Map<String, dynamic>?;
      final roomInfo = savedUser?['room_info'] as Map<String, dynamic>?;

      final String roomNo = stay?['room_no']?.toString() ??
          roomInfo?['room_no']?.toString() ??
          'A-204';

      _selectedLocation = roomNo.toLowerCase().startsWith('room') ? roomNo : 'Room $roomNo';
    } catch (_) {}

    _selectedCategory = widget.initialCategory ?? 'Cleaning';
    if (!_categories.contains(_selectedCategory)) {
      _selectedCategory = _categories.isNotEmpty ? _categories.first : 'Cleaning';
    }

    _titleController.text = '$_selectedCategory Request';
    _descriptionController.text = '$_selectedCategory issue reported.';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool _isVideoFile(String path) {
    final ext = path.toLowerCase();
    return ext.endsWith('.mp4') ||
        ext.endsWith('.mov') ||
        ext.endsWith('.avi') ||
        ext.endsWith('.mkv') ||
        ext.endsWith('.webm') ||
        ext.endsWith('.3gp');
  }

  Future<void> _showImageSourcePicker() async {
    if (_selectedFiles.length >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 2 files (photos or videos) allowed.')),
      );
      return;
    }

    final String? selectedAction = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22.0)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 14.0, 20.0, 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42.0,
                    height: 4.0,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1D5DB),
                      borderRadius: BorderRadius.circular(2.0),
                    ),
                  ),
                ),
                const SizedBox(height: 14.0),
                Text(
                  'Upload photo or video',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3.0),
                Text(
                  'Attach photos or videos (Max 2 files, ${_selectedFiles.length}/2 added)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.0,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 14.0),

                // Option 1: Take Photo
                _buildPickerOptionTile(
                  icon: Icons.camera_alt_rounded,
                  title: 'Take Photo',
                  subtitle: 'Capture a picture with camera',
                  onTap: () => Navigator.of(ctx).pop('camera_photo'),
                ),
                const SizedBox(height: 8.0),

                // Option 2: Choose Photo
                _buildPickerOptionTile(
                  icon: Icons.photo_library_rounded,
                  title: 'Choose Photo',
                  subtitle: 'Select picture from gallery',
                  onTap: () => Navigator.of(ctx).pop('gallery_photo'),
                ),
                const SizedBox(height: 8.0),

                // Option 3: Record Video
                _buildPickerOptionTile(
                  icon: Icons.videocam_rounded,
                  title: 'Record Video',
                  subtitle: 'Record a video with camera',
                  onTap: () => Navigator.of(ctx).pop('camera_video'),
                ),
                const SizedBox(height: 8.0),

                // Option 4: Choose Video
                _buildPickerOptionTile(
                  icon: Icons.video_library_rounded,
                  title: 'Choose Video',
                  subtitle: 'Select video from gallery',
                  onTap: () => Navigator.of(ctx).pop('gallery_video'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selectedAction == null) return;
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;

    try {
      if (selectedAction == 'camera_photo') {
        final XFile? photo = await _imagePicker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
        );
        if (photo != null && mounted) {
          setState(() {
            if (_selectedFiles.length < 2) {
              _selectedFiles.add(photo);
            }
          });
        }
      } else if (selectedAction == 'gallery_photo') {
        final remaining = 2 - _selectedFiles.length;
        if (remaining <= 0) return;

        final List<XFile> pickedList = await _imagePicker.pickMultiImage(
          imageQuality: 85,
          limit: remaining,
        );

        if (pickedList.isNotEmpty && mounted) {
          setState(() {
            for (final img in pickedList) {
              if (_selectedFiles.length < 2) {
                _selectedFiles.add(img);
              }
            }
          });
        }
      } else if (selectedAction == 'camera_video') {
        final XFile? video = await _imagePicker.pickVideo(
          source: ImageSource.camera,
          maxDuration: const Duration(minutes: 3),
        );
        if (video != null && mounted) {
          setState(() {
            if (_selectedFiles.length < 2) {
              _selectedFiles.add(video);
            }
          });
        }
      } else if (selectedAction == 'gallery_video') {
        final XFile? video = await _imagePicker.pickVideo(
          source: ImageSource.gallery,
        );
        if (video != null && mounted) {
          setState(() {
            if (_selectedFiles.length < 2) {
              _selectedFiles.add(video);
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not attach file: $e')),
        );
      }
    }
  }

  Widget _buildPickerOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: const Color(0xFFE5E7EB)),
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
              child: Icon(icon, color: AppColors.primary, size: 20.0),
            ),
            const SizedBox(width: 12.0),
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
                  const SizedBox(height: 1.0),
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
            const Icon(Icons.arrow_forward_ios_rounded, size: 12.0, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }

  int _getCategoryId() {
    final matched = _categoryModels.where(
      (c) => c.name.toLowerCase() == _selectedCategory.toLowerCase(),
    ).firstOrNull;
    if (matched != null) return matched.id;

    switch (_selectedCategory.toLowerCase()) {
      case 'cleaning':
        return 1;
      case 'ac':
        return 2;
      case 'wifi':
        return 3;
      case 'water':
        return 4;
      case 'food':
        return 5;
      case 'electricity':
        return 6;
      case 'furniture':
        return 7;
      case 'plumbing':
        return 8;
      case 'appliances':
      case 'washing machine':
        return 9;
      case 'other':
      default:
        return 10;
    }
  }

  int _getLocationId() {
    try {
      final prefService = di.sl<PreferencesService>();
      final savedUser = prefService.getSavedUser();
      final savedDashboard = prefService.getSavedDashboard();
      final roomInfo = savedUser?['room_info'] as Map<String, dynamic>?;
      final stay = savedDashboard?['stay'] as Map<String, dynamic>?;

      if (roomInfo?['room_id'] != null) {
        return int.tryParse(roomInfo!['room_id'].toString()) ?? 1;
      }
      if (stay?['room_id'] != null) {
        return int.tryParse(stay!['room_id'].toString()) ?? 1;
      }
    } catch (_) {}
    return 1;
  }

  Future<void> _submitComplaint() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a complaint title.')),
      );
      return;
    }

    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter description of the issue.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final dataSource = di.sl<ComplaintsRemoteDataSource>();
      final categoryId = _getCategoryId();
      final locationId = _getLocationId();
      final attachmentPaths = _selectedFiles.map((e) => e.path).toList();

      final response = await dataSource.createComplaint(
        categoryId: categoryId,
        title: title,
        description: description,
        locationId: locationId,
        attachmentPaths: attachmentPaths,
      );

      if (mounted) {
        try {
          di.sl<SocketService>().notifyComplaintCreated(response);
        } catch (_) {}
        final message = response['message']?.toString() ?? 'Complaint registered successfully';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message,
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit complaint: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
          ),
        );
      }
    }
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
          'Create complaint',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18.0,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 6.0),
                children: [
                  Text(
                    'Issue Details',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8.0),

                  // 1. Category *
                  _buildFieldLabel('Category *'),
                  const SizedBox(height: 4.0),
                  Container(
                    height: 42.0,
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary, size: 20.0),
                        isExpanded: true,
                        items: _categories.map((cat) {
                          return DropdownMenuItem(
                            value: cat,
                            child: Text(
                              cat,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.0,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedCategory = val;
                              _titleController.text = '$_selectedCategory Request';
                              _descriptionController.text = '$_selectedCategory issue reported.';
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 9.0),

                  // 2. Title *
                  _buildFieldLabel('Title *'),
                  const SizedBox(height: 4.0),
                  Container(
                    height: 42.0,
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
                    ),
                    child: TextField(
                      controller: _titleController,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.0,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter title (e.g. Cleaning Request)',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          color: const Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w400,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        filled: false,
                        fillColor: Colors.transparent,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const SizedBox(height: 9.0),

                  // 3. Description *
                  _buildFieldLabel('Description *'),
                  const SizedBox(height: 4.0),
                  Container(
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        TextField(
                          controller: _descriptionController,
                          maxLines: 3,
                          maxLength: 500,
                          onChanged: (val) => setState(() {}),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            color: AppColors.textPrimary,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Describe your issue in detail...',
                            hintStyle: TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF9CA3AF),
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
                          '${_descriptionController.text.length}/500',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.0,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 9.0),

                  // 3. Location *
                  _buildFieldLabel('Location *'),
                  const SizedBox(height: 4.0),
                  Container(
                    height: 42.0,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
                    ),
                    child: Text(
                      _selectedLocation,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.0,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 9.0),

                  // 4. Upload photo or video (optional)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildFieldLabel('Upload photo or video (optional)'),
                      Text(
                        '${_selectedFiles.length}/2',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: _selectedFiles.isNotEmpty ? AppColors.primary : const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4.0),
                  if (_selectedFiles.isEmpty)
                    InkWell(
                      onTap: _showImageSourcePicker,
                      borderRadius: BorderRadius.circular(12.0),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 12.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(
                            color: const Color(0xFF9CA3AF).withValues(alpha: 0.5),
                            width: 1.0,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 36.0,
                              height: 36.0,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE8F3ED),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add_photo_alternate_outlined,
                                color: AppColors.primary,
                                size: 18.0,
                              ),
                            ),
                            const SizedBox(height: 6.0),
                            Text(
                              'Tap to upload photo or video',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF4B5563),
                              ),
                            ),
                            const SizedBox(height: 2.0),
                            Text(
                              'Camera, Gallery or Video   •   Max 2 files',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.0,
                                color: const Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: 80.0,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _selectedFiles.length + (_selectedFiles.length < 2 ? 1 : 0),
                        separatorBuilder: (context, index) => const SizedBox(width: 8.0),
                        itemBuilder: (context, index) {
                          if (index == _selectedFiles.length) {
                            return InkWell(
                              onTap: _showImageSourcePicker,
                              borderRadius: BorderRadius.circular(10.0),
                              child: Container(
                                width: 76.0,
                                height: 76.0,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10.0),
                                  border: Border.all(
                                    color: AppColors.primary.withValues(alpha: 0.5),
                                    width: 1.0,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 28.0,
                                      height: 28.0,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFE8F3ED),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.add_circle_outline_rounded,
                                        size: 16.0,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 4.0),
                                    Text(
                                      'Add more',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          final file = _selectedFiles[index];
                          final isVideo = _isVideoFile(file.path);
                          return Stack(
                            children: [
                              Container(
                                width: 76.0,
                                height: 76.0,
                                decoration: BoxDecoration(
                                  color: isVideo ? const Color(0xFF1F2937) : Colors.white,
                                  borderRadius: BorderRadius.circular(10.0),
                                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(9.0),
                                  child: isVideo
                                      ? Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            const Icon(
                                              Icons.videocam_rounded,
                                              color: Colors.white70,
                                              size: 32.0,
                                            ),
                                            Positioned(
                                              bottom: 4.0,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 1.0),
                                                decoration: BoxDecoration(
                                                  color: Colors.black54,
                                                  borderRadius: BorderRadius.circular(3.0),
                                                ),
                                                child: Text(
                                                  'VIDEO',
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 8.0,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      : Image.file(
                                          File(file.path),
                                          fit: BoxFit.cover,
                                          width: 76.0,
                                          height: 76.0,
                                          errorBuilder: (ctx, err, stack) => const Center(
                                            child: Icon(Icons.broken_image_rounded, color: Colors.grey, size: 20.0),
                                          ),
                                        ),
                                ),
                              ),
                              Positioned(
                                top: 3.0,
                                right: 3.0,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedFiles.removeAt(index);
                                    });
                                  },
                                  child: Container(
                                    width: 20.0,
                                    height: 20.0,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.65),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close_rounded,
                                      size: 12.0,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 10.0),
                ],
              ),
            ),

            // Submit Complaint Button
            Padding(
              padding: EdgeInsets.fromLTRB(horizontalPadding, 4.0, horizontalPadding, 10.0),
              child: InkWell(
                onTap: _isSubmitting ? null : _submitComplaint,
                borderRadius: BorderRadius.circular(999.0),
                child: Container(
                  width: double.infinity,
                  height: 46.0,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _isSubmitting ? AppColors.primary.withValues(alpha: 0.7) : AppColors.primary,
                    borderRadius: BorderRadius.circular(999.0),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20.0,
                          height: 20.0,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Submit Complaint',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.0,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13.0,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
      ),
    );
  }
}
