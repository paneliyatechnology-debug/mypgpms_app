import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/colors/app_colors.dart';
import '../../../../core/network/socket_service.dart';
import '../../../../core/storage/preferences_service.dart';
import '../../../../injection_container.dart' as di;
import '../../data/datasources/room_shift_remote_data_source.dart';
import '../../data/models/room_model.dart';
import '../../data/models/room_shift_model.dart';

class RequestRoomShiftPage extends StatefulWidget {
  final String? initialRoom;

  const RequestRoomShiftPage({super.key, this.initialRoom});

  @override
  State<RequestRoomShiftPage> createState() => _RequestRoomShiftPageState();
}

class _RequestRoomShiftPageState extends State<RequestRoomShiftPage> {
  String _selectedRoomType = 'Double Sharing';
  String? _selectedRoomNumber;
  int? _selectedRoomId;
  String? _selectedReason;
  DateTime? _expectedMoveDate;
  final TextEditingController _notesController = TextEditingController();
  final int _maxChars = 500;
  int _charCount = 0;
  bool _isSubmitting = false;
  bool _isLoadingRooms = false;
  List<RoomItemModel> _apiRooms = [];

  final List<String> _roomTypes = [
    'Single Sharing',
    'Double Sharing',
    'Triple Sharing',
    'Four Sharing',
  ];

  List<String> _availableRoomNumbers = [
    'A-102 (Double Sharing)',
    'A-202 (Double Sharing)',
    'A-302 (Triple Sharing)',
    'B-104 (Double Sharing)',
    'B-201 (Four Sharing)',
    'Any Available Room',
  ];

  final List<String> _reasons = [
    'Better view',
    'Need quiet study environment',
    'Moving with friend/colleague',
    'Want different sharing option',
    'Floor or ventilation preference',
    'Maintenance or room issue',
    'Other reason',
  ];

  int? _resolveRequestedRoomId() {
    if (_selectedRoomId != null) return _selectedRoomId;
    if (_selectedRoomNumber == null) return 2;
    if (_selectedRoomNumber!.contains('102')) return 2;
    if (_selectedRoomNumber!.contains('101')) return 1;
    if (_selectedRoomNumber!.contains('302')) return 3;
    if (_selectedRoomNumber!.contains('104')) return 4;
    if (_selectedRoomNumber!.contains('201')) return 5;
    return 2;
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialRoom != null) {
      final match = _availableRoomNumbers.firstWhere(
        (r) => r.startsWith(widget.initialRoom!),
        orElse: () => widget.initialRoom!,
      );
      _selectedRoomNumber = match;
    }
    _notesController.addListener(() {
      setState(() {
        _charCount = _notesController.text.length;
      });
    });
    _fetchRoomsFromApi();
  }

  Future<void> _fetchRoomsFromApi() async {
    setState(() => _isLoadingRooms = true);
    try {
      final dataSource = di.sl<RoomShiftRemoteDataSource>();
      final rooms = await dataSource.getRooms();
      if (rooms.isNotEmpty && mounted) {
        setState(() {
          _apiRooms = rooms;
          _availableRoomNumbers = [
            ...rooms.map((r) => r.displayLabel),
            'Any Available Room',
          ];
          if (widget.initialRoom != null) {
            final match = _availableRoomNumbers.firstWhere(
              (r) => r.toLowerCase().contains(widget.initialRoom!.toLowerCase()),
              orElse: () => _availableRoomNumbers.first,
            );
            _onRoomSelected(match);
          } else if (_selectedRoomNumber != null) {
            final match = _availableRoomNumbers.firstWhere(
              (r) => r == _selectedRoomNumber || r.contains(_selectedRoomNumber!),
              orElse: () => _availableRoomNumbers.first,
            );
            _onRoomSelected(match);
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching rooms: $e');
    } finally {
      if (mounted) setState(() => _isLoadingRooms = false);
    }
  }

  void _onRoomSelected(String? roomLabel) {
    setState(() {
      _selectedRoomNumber = roomLabel;
      if (roomLabel != null) {
        try {
          final matched = _apiRooms.firstWhere(
            (r) => r.displayLabel == roomLabel,
          );
          _selectedRoomId = matched.id;
          if (_roomTypes.any((t) => t.toLowerCase() == matched.sharingLabel.toLowerCase())) {
            _selectedRoomType = _roomTypes.firstWhere((t) => t.toLowerCase() == matched.sharingLabel.toLowerCase());
          } else if (matched.sharingLabel.isNotEmpty) {
            _selectedRoomType = matched.sharingLabel;
          }
        } catch (_) {
          _selectedRoomId = _resolveRequestedRoomId();
        }
      }
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expectedMoveDate ?? now.add(const Duration(days: 3)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 120)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _expectedMoveDate = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  String _formatDateFull(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _submitRequest() async {
    if (_isSubmitting) return;

    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select a reason for the shift',
            style: GoogleFonts.plusJakartaSans(fontSize: 13.0, fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        ),
      );
      return;
    }

    if (_expectedMoveDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select your expected move date',
            style: GoogleFonts.plusJakartaSans(fontSize: 13.0, fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final prefService = di.sl<PreferencesService>();
      final savedUser = prefService.getSavedUser();
      final residentId = (savedUser?['id'] as int?) ??
          (savedUser?['resident_id'] as int?) ??
          3;

      final dateStr =
          '${_expectedMoveDate!.year}-${_expectedMoveDate!.month.toString().padLeft(2, '0')}-${_expectedMoveDate!.day.toString().padLeft(2, '0')}';

      final payload = RoomShiftRequestPayload(
        residentId: residentId,
        reason: _selectedReason!,
        preferredRoomType: _selectedRoomType,
        requestedRoomId: _resolveRequestedRoomId(),
        expectedMoveDate: dateStr,
        additionalNotes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        status: 'pending',
      );

      final dataSource = di.sl<RoomShiftRemoteDataSource>();
      final response = await dataSource.submitRoomShiftRequest(payload);

      try {
        di.sl<SocketService>().notifyRoomShiftCreated(response);
      } catch (_) {}

      if (!mounted) return;

      final message = response['message']?.toString() ??
          'Room shift request submitted successfully!';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: GoogleFonts.plusJakartaSans(fontSize: 13.0, fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        ),
      );

      Navigator.of(context).pop({
        'id': 'RSR-${DateTime.now().millisecondsSinceEpoch % 10000}',
        'target_room': _selectedRoomNumber ?? _selectedRoomType,
        'sharing': _selectedRoomType,
        'reason': _selectedReason,
        'move_date': _formatDate(_expectedMoveDate!),
        'notes': _notesController.text.trim(),
        'status': 'Pending',
      });
    } catch (e) {
      if (!mounted) return;
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMsg,
            style: GoogleFonts.plusJakartaSans(fontSize: 13.0, fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  Widget _buildFieldLabel(String title, {bool isRequired = false, String? optionalText}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          if (isRequired)
            Text(
              ' *',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFEF4444),
              ),
            ),
          if (optionalText != null)
            Text(
              ' $optionalText',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.0,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF9CA3AF),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDropdownContainer({required Widget child}) {
    return Container(
      height: 50.0,
      padding: const EdgeInsets.symmetric(horizontal: 14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 4.0,
            offset: Offset(0, 1),
          ),
        ],
      ),
      alignment: Alignment.centerLeft,
      child: child,
    );
  }

  Widget _buildRoomTypeCard(String type, IconData icon) {
    final isSelected = _selectedRoomType.toLowerCase() == type.toLowerCase();
    return InkWell(
      onTap: () {
        setState(() {
          _selectedRoomType = type;
        });
      },
      borderRadius: BorderRadius.circular(14.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE5E7EB),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  const BoxShadow(
                    color: Color(0x2E0F4734),
                    blurRadius: 8.0,
                    offset: Offset(0, 3),
                  ),
                ]
              : [
                  const BoxShadow(
                    color: Color(0x04000000),
                    blurRadius: 4.0,
                    offset: Offset(0, 1),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18.0,
              color: isSelected ? Colors.white : const Color(0xFF6B7280),
            ),
            const SizedBox(width: 8.0),
            Flexible(
              child: Text(
                type,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth > 600 ? (screenWidth - 460) / 2 : 16.0;

    // Load saved current room dynamically
    Map<String, dynamic>? savedDashboard;
    Map<String, dynamic>? savedUser;
    try {
      final prefService = di.sl<PreferencesService>();
      savedDashboard = prefService.getSavedDashboard();
      savedUser = prefService.getSavedUser();
    } catch (_) {}

    final stay = savedDashboard?['stay'] as Map<String, dynamic>?;
    final roomInfo = savedUser?['room_info'] as Map<String, dynamic>?;

    final String roomNo = stay?['room_no']?.toString() ??
        roomInfo?['room_no']?.toString() ??
        '101';

    final String bedNo = stay?['bed_number']?.toString() ??
        roomInfo?['bed_no']?.toString() ??
        '1';

    final String rawRoomSharing = roomInfo?['room_sharing']?.toString() ??
        (roomInfo?['room_type'] != null ? '${roomInfo!['room_type']} Sharing' : 'Triple Sharing');
    final String roomSharing = _capitalize(rawRoomSharing);

    // Resolve current room image if matched
    String? currentRoomImageUrl;
    if (_apiRooms.isNotEmpty) {
      try {
        final matched = _apiRooms.firstWhere((r) => r.roomNo == roomNo || roomNo.contains(r.roomNo));
        currentRoomImageUrl = matched.imageUrl;
      } catch (_) {}
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
          'Request Room Shift',
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
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8.0),
                children: [
                  // 1. Top Mint Banner Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F3ED),
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(color: const Color(0xFFD2EBE0), width: 1.0),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 44.0,
                          height: 44.0,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD2EBE0),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: const Icon(
                            Icons.swap_horiz_rounded,
                            color: AppColors.primary,
                            size: 26.0,
                          ),
                        ),
                        const SizedBox(width: 14.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Request Room Shift',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3.0),
                              Text(
                                'Change your room easily\n(For availability and approval).',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.0,
                                  color: const Color(0xFF6B7280),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20.0),

                  // 2. Current room section
                  _buildFieldLabel('Current room'),
                  Container(
                    padding: const EdgeInsets.all(12.0),
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
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10.0),
                          child: SizedBox(
                            width: 80.0,
                            height: 60.0,
                            child: currentRoomImageUrl != null && currentRoomImageUrl.isNotEmpty
                                ? Image.network(
                                    currentRoomImageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: const Color(0xFFE8F3ED),
                                      child: const Center(
                                        child: Icon(Icons.bed_rounded, color: AppColors.primary, size: 28.0),
                                      ),
                                    ),
                                  )
                                : Image.network(
                                    'https://images.unsplash.com/photo-1598928506311-c55ded91a20c?w=400&q=80',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: const Color(0xFFE8F3ED),
                                      child: const Center(
                                        child: Icon(Icons.bed_rounded, color: AppColors.primary, size: 28.0),
                                      ),
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
                                roomNo,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3.0),
                              Text(
                                'Bed No. : $bedNo',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.0,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD2EBE0),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Text(
                            roomSharing,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20.0),

                  // 3. Preferred room type * (2x2 Grid Layout)
                  _buildFieldLabel('Preferred room type', isRequired: true),
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildRoomTypeCard('Single Sharing', Icons.person_outline_rounded)),
                          const SizedBox(width: 10.0),
                          Expanded(child: _buildRoomTypeCard('Double Sharing', Icons.people_outline_rounded)),
                        ],
                      ),
                      const SizedBox(height: 10.0),
                      Row(
                        children: [
                          Expanded(child: _buildRoomTypeCard('Triple Sharing', Icons.groups_outlined)),
                          const SizedBox(width: 10.0),
                          Expanded(child: _buildRoomTypeCard('Four Sharing', Icons.domain_rounded)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20.0),

                  // 4. Preferred room (Optional)
                  _buildFieldLabel('Preferred room', optionalText: '(Optional)'),
                  _buildDropdownContainer(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedRoomNumber,
                        hint: Row(
                          children: [
                            const Icon(Icons.meeting_room_outlined, size: 18.0, color: Color(0xFF9CA3AF)),
                            const SizedBox(width: 8.0),
                            Text(
                              'Select room number',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.0,
                                color: const Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                        isExpanded: true,
                        icon: _isLoadingRooms
                            ? const SizedBox(
                                width: 16.0,
                                height: 16.0,
                                child: CircularProgressIndicator(strokeWidth: 2.0, color: AppColors.primary),
                              )
                            : const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary, size: 22.0),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.0,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        items: _availableRoomNumbers.map((room) {
                          return DropdownMenuItem(
                            value: room,
                            child: Row(
                              children: [
                                const Icon(Icons.meeting_room_outlined, size: 16.0, color: Color(0xFF6B7280)),
                                const SizedBox(width: 8.0),
                                Expanded(
                                  child: Text(
                                    room,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13.0,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          _onRoomSelected(val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20.0),

                  // 5. Reason for shift *
                  _buildFieldLabel('Reason for shift', isRequired: true),
                  _buildDropdownContainer(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedReason,
                        hint: Row(
                          children: [
                            const Icon(Icons.help_outline_rounded, size: 18.0, color: Color(0xFF9CA3AF)),
                            const SizedBox(width: 8.0),
                            Text(
                              'Select reason',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.0,
                                color: const Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary, size: 22.0),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.0,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        items: _reasons.map((reason) {
                          return DropdownMenuItem(
                            value: reason,
                            child: Row(
                              children: [
                                const Icon(Icons.swap_horiz_rounded, size: 16.0, color: Color(0xFF6B7280)),
                                const SizedBox(width: 8.0),
                                Expanded(
                                  child: Text(
                                    reason,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13.0,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedReason = val;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20.0),

                  // 6. Additional Notes (Optional)
                  _buildFieldLabel('Additional Notes', optionalText: '(Optional)'),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14.0),
                      border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x04000000),
                          blurRadius: 4.0,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                    child: TextField(
                      controller: _notesController,
                      maxLines: 4,
                      maxLength: _maxChars,
                      buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                      style: GoogleFonts.plusJakartaSans(fontSize: 13.0, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: false,
                        fillColor: Colors.transparent,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        hintText: 'Any additional information...',
                        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13.0, color: const Color(0xFF9CA3AF)),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '$_charCount/$_maxChars',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11.0, color: const Color(0xFF9CA3AF)),
                    ),
                  ),
                  const SizedBox(height: 14.0),

                  // 7. Expected move date *
                  _buildFieldLabel('Expected move date', isRequired: true),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(14.0),
                    child: Container(
                      height: 50.0,
                      padding: const EdgeInsets.symmetric(horizontal: 14.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14.0),
                        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x04000000),
                            blurRadius: 4.0,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 18.0,
                            color: _expectedMoveDate != null ? AppColors.primary : const Color(0xFF9CA3AF),
                          ),
                          const SizedBox(width: 10.0),
                          Expanded(
                            child: Text(
                              _expectedMoveDate != null
                                  ? _formatDateFull(_expectedMoveDate!)
                                  : 'Select date',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.0,
                                color: _expectedMoveDate != null ? AppColors.textPrimary : const Color(0xFF9CA3AF),
                                fontWeight: _expectedMoveDate != null ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 22.0,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20.0),

                  // 8. Info Notification Banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F3ED),
                      borderRadius: BorderRadius.circular(14.0),
                      border: Border.all(color: const Color(0xFFD2EBE0), width: 1.0),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2.0),
                          child: Icon(Icons.info_outline_rounded, size: 18.0, color: AppColors.primary),
                        ),
                        const SizedBox(width: 10.0),
                        Expanded(
                          child: Text(
                            'Your request will be reviewed by the administration team. You will be notified once a decision is made.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.0,
                              color: const Color(0xFF374151),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24.0),
                ],
              ),
            ),

            // Bottom Sticky Submit Button with clean elevated container
            Container(
              padding: EdgeInsets.fromLTRB(horizontalPadding, 12.0, horizontalPadding, 16.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 10.0,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 50.0,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25.0),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22.0,
                            height: 22.0,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.2,
                            ),
                          )
                        : Text(
                            'Submit Request',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
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
}
