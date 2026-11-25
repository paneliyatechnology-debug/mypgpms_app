import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../common/widgets/common_bottom_nav_bar.dart';
import '../../../../core/colors/app_colors.dart';
import '../../../../core/network/socket_service.dart';
import '../../../../core/storage/preferences_service.dart';
import '../../../../injection_container.dart' as di;
import '../../data/datasources/visitors_remote_data_source.dart';
import '../../data/models/visitor_model.dart';

class AddVisitorPage extends StatefulWidget {
  final VisitorItemModel? initialVisitor;

  const AddVisitorPage({super.key, this.initialVisitor});

  @override
  State<AddVisitorPage> createState() => _AddVisitorPageState();
}

class _AddVisitorPageState extends State<AddVisitorPage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _purposeController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isSubmitting = false;

  String? _selectedRelation;
  final List<String> _relations = ['Family', 'Friend', 'Colleague', 'Delivery', 'Other'];

  // Field validation error messages shown directly below each textfield
  String? _nameError;
  String? _phoneError;
  String? _dateError;
  String? _timeError;
  String? _relationError;
  String? _purposeError;

  @override
  void initState() {
    super.initState();

    _nameController.addListener(() {
      if (_nameError != null && _nameController.text.trim().isNotEmpty) {
        setState(() => _nameError = null);
      }
    });

    _phoneController.addListener(() {
      if (_phoneError != null && _phoneController.text.trim().isNotEmpty) {
        setState(() => _phoneError = null);
      }
    });

    _dateController.addListener(() {
      if (_dateError != null && _dateController.text.trim().isNotEmpty) {
        setState(() => _dateError = null);
      }
    });

    _timeController.addListener(() {
      if (_timeError != null && _timeController.text.trim().isNotEmpty) {
        setState(() => _timeError = null);
      }
    });

    _purposeController.addListener(() {
      if (_purposeError != null && _purposeController.text.trim().isNotEmpty) {
        setState(() => _purposeError = null);
      }
    });
    if (widget.initialVisitor != null) {
      final v = widget.initialVisitor!;
      _nameController.text = v.visitorName;
      final cleanPhone = v.visitorPhone.replaceAll('+91', '').trim();
      _phoneController.text = cleanPhone;

      if (v.validUntil.isNotEmpty) {
        final d = v.validUntil.split(' ').first;
        _dateController.text = d;
        try {
          _selectedDate = DateTime.tryParse(d);
        } catch (_) {}
      } else if (v.visitDate.isNotEmpty) {
        final d = v.visitDate.split(' ').first;
        _dateController.text = d;
        try {
          _selectedDate = DateTime.tryParse(d);
        } catch (_) {}
      }

      _timeController.text = v.entryTime;
      _purposeController.text = v.purpose;

      for (final rel in _relations) {
        if (rel.toLowerCase() == v.purpose.toLowerCase()) {
          _selectedRelation = rel;
          break;
        }
      }
      _selectedRelation ??= _relations.first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
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
        _selectedDate = picked;
        _dateError = null;
        _dateController.text =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
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
        _selectedTime = picked;
        _timeError = null;
        final hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
        final minute = picked.minute.toString().padLeft(2, '0');
        final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
        _timeController.text = '${hour.toString().padLeft(2, '0')}:$minute $period';
      });
    }
  }

  Future<void> _submitVisitor() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final date = _dateController.text.trim();
    final time = _timeController.text.trim();
    final relation = _selectedRelation;
    final purpose = _purposeController.text.trim();

    String? nameErr;
    String? phoneErr;
    String? dateErr;
    String? timeErr;
    String? relationErr;
    String? purposeErr;

    if (name.isEmpty) {
      nameErr = 'Please enter visitor name';
    }

    if (phone.isEmpty) {
      phoneErr = 'Please enter phone number';
    } else if (phone.replaceAll(RegExp(r'\D'), '').length < 10) {
      phoneErr = 'Please enter a valid 10-digit phone number';
    }

    if (date.isEmpty) {
      dateErr = 'Please select visit date';
    }

    if (time.isEmpty) {
      timeErr = 'Please select visit time';
    }

    if (relation == null || relation.isEmpty) {
      relationErr = 'Please select relation';
    }

    if (purpose.isEmpty) {
      purposeErr = 'Please enter purpose of visit';
    }

    if (nameErr != null ||
        phoneErr != null ||
        dateErr != null ||
        timeErr != null ||
        relationErr != null ||
        purposeErr != null) {
      setState(() {
        _nameError = nameErr;
        _phoneError = phoneErr;
        _dateError = dateErr;
        _timeError = timeErr;
        _relationError = relationErr;
        _purposeError = purposeErr;
      });
      return;
    }

    setState(() {
      _nameError = null;
      _phoneError = null;
      _dateError = null;
      _timeError = null;
      _relationError = null;
      _purposeError = null;
      _isSubmitting = true;
    });

    try {
      final prefService = di.sl<PreferencesService>();
      final savedUser = prefService.getSavedUser();
      final savedDashboard = prefService.getSavedDashboard();

      int residentId = 1;
      if (savedUser?['resident_id'] != null) {
        residentId = int.tryParse(savedUser!['resident_id'].toString()) ?? 1;
      } else if (savedUser?['id'] != null) {
        residentId = int.tryParse(savedUser!['id'].toString()) ?? 1;
      }

      int pgId = 1;
      if (savedUser?['pg_id'] != null) {
        pgId = int.tryParse(savedUser!['pg_id'].toString()) ?? 1;
      } else if (savedDashboard?['stay']?['pg_id'] != null) {
        pgId = int.tryParse(savedDashboard!['stay']['pg_id'].toString()) ?? 1;
      }

      int branchId = 1;
      if (savedDashboard?['stay']?['branch_id'] != null) {
        branchId = int.tryParse(savedDashboard!['stay']['branch_id'].toString()) ?? 1;
      } else if (savedUser?['branch_id'] != null) {
        branchId = int.tryParse(savedUser!['branch_id'].toString()) ?? 1;
      } else if (savedUser?['pg_id'] != null) {
        branchId = int.tryParse(savedUser!['pg_id'].toString()) ?? 1;
      }

      final fullPhone = phone.startsWith('+') ? phone : '+91 $phone';

      final dataSource = di.sl<VisitorsRemoteDataSource>();

      if (widget.initialVisitor != null) {
        final response = await dataSource.updateVisitor(
          visitorId: widget.initialVisitor!.id,
          visitorName: name,
          visitorPhone: fullPhone,
          purpose: purpose,
          visitDate: date,
          validUntil: date,
          entryTime: time,
          branchId: branchId,
          adminNotes: 'Pass updated by resident',
        );

        if (mounted) {
          try {
            di.sl<SocketService>().notifyVisitorUpdated(response);
          } catch (_) {}
          final message = response['message']?.toString() ?? 'Visitor request updated successfully!';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                message,
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: Colors.white),
              ),
              backgroundColor: AppColors.primary,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        final response = await dataSource.addVisitor(
          visitorName: name,
          visitorPhone: fullPhone,
          purpose: purpose,
          visitDate: date,
          validUntil: date,
          entryTime: time,
          residentId: residentId,
          pgId: pgId,
          branchId: branchId,
          relation: relation,
          adminNotes: 'Visitor request created by resident',
          status: 'pending',
        );

        if (mounted) {
          try {
            di.sl<SocketService>().notifyVisitorCreated(response);
          } catch (_) {}
          final message = response['message']?.toString() ?? 'Visitor request sent successfully!';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                message,
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: Colors.white),
              ),
              backgroundColor: AppColors.primary,
            ),
          );
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceAll('Exception: ', '').replaceAll('ServerException: ', '');
        _showSnackbar(errorMsg, isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500, color: Colors.white),
        ),
        backgroundColor: isError ? AppColors.error : AppColors.primary,
      ),
    );
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary, size: 18.0),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.initialVisitor != null ? 'Edit Visitor' : 'Add Visitor',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18.0,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8.0),
          children: [
            // Visitor Name
            _buildFieldLabel('Visitor Name *'),
            const SizedBox(height: 6.0),
            _buildTextInput(
              controller: _nameController,
              hint: 'Name',
              hasError: _nameError != null,
            ),
            _buildErrorText(_nameError),
            const SizedBox(height: 12.0),

            // Phone Number
            _buildFieldLabel('Phone Number *'),
            const SizedBox(height: 6.0),
            Container(
              height: 46.0,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: _phoneError != null ? const Color(0xFFEF4444) : const Color(0xFFE5E7EB),
                  width: _phoneError != null ? 1.2 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12.0),
                  Text(
                    '+91',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4.0),
                  const Icon(Icons.arrow_drop_down, color: Color(0xFF6B7280)),
                  const SizedBox(width: 4.0),
                  Container(width: 1.0, height: 22.0, color: const Color(0xFFE5E7EB)),
                  const SizedBox(width: 10.0),
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Phone number',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 13.0,
                          color: const Color(0xFF9CA3AF),
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
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _buildErrorText(_phoneError),
            const SizedBox(height: 12.0),

            // Visit Date
            _buildFieldLabel('Visit Date *'),
            const SizedBox(height: 6.0),
            InkWell(
              onTap: _selectDate,
              borderRadius: BorderRadius.circular(12.0),
              child: IgnorePointer(
                child: _buildTextInput(
                  controller: _dateController,
                  hint: 'Select date',
                  suffixIcon: Icons.calendar_today_outlined,
                  hasError: _dateError != null,
                ),
              ),
            ),
            _buildErrorText(_dateError),
            const SizedBox(height: 12.0),

            // Visit Time
            _buildFieldLabel('Visit Time *'),
            const SizedBox(height: 6.0),
            InkWell(
              onTap: _selectTime,
              borderRadius: BorderRadius.circular(12.0),
              child: IgnorePointer(
                child: _buildTextInput(
                  controller: _timeController,
                  hint: 'Select time',
                  suffixIcon: Icons.access_time_rounded,
                  hasError: _timeError != null,
                ),
              ),
            ),
            _buildErrorText(_timeError),
            const SizedBox(height: 12.0),

            // Relation
            _buildFieldLabel('Relation *'),
            const SizedBox(height: 6.0),
            Container(
              height: 46.0,
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: _relationError != null ? const Color(0xFFEF4444) : const Color(0xFFE5E7EB),
                  width: _relationError != null ? 1.2 : 1.0,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedRelation,
                  hint: Text(
                    'Select relation',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.0,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary, size: 20.0),
                  isExpanded: true,
                  items: _relations.map((rel) {
                    return DropdownMenuItem(
                      value: rel,
                      child: Text(
                        rel,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13.0, color: AppColors.textPrimary),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedRelation = val;
                      _relationError = null;
                    });
                  },
                ),
              ),
            ),
            _buildErrorText(_relationError),
            const SizedBox(height: 12.0),

            // Purpose of visit
            _buildFieldLabel('Purpose of visit *'),
            const SizedBox(height: 6.0),
            _buildTextInput(
              controller: _purposeController,
              hint: 'e.g. family visiting',
              hasError: _purposeError != null,
            ),
            _buildErrorText(_purposeError),
            const SizedBox(height: 20.0),

            // Send Request Button
            InkWell(
              onTap: _isSubmitting ? null : _submitVisitor,
              borderRadius: BorderRadius.circular(999.0),
              child: Container(
                width: double.infinity,
                height: 48.0,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _isSubmitting ? AppColors.primary.withValues(alpha: 0.7) : AppColors.primary,
                  borderRadius: BorderRadius.circular(999.0),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22.0,
                        height: 22.0,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                      )
                    : Text(
                        widget.initialVisitor != null ? 'Update Request' : 'Send Request',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16.0),
          ],
        ),
      ),
      bottomNavigationBar: const CommonBottomNavBar(currentIndex: 3),
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

  Widget _buildErrorText(String? error) {
    if (error == null || error.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 4.0, left: 2.0),
      child: Text(
        error,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
          color: const Color(0xFFEF4444),
        ),
      ),
    );
  }

  Widget _buildTextInput({
    required TextEditingController controller,
    required String hint,
    IconData? suffixIcon,
    bool hasError = false,
  }) {
    return Container(
      height: 46.0,
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: hasError ? const Color(0xFFEF4444) : const Color(0xFFE5E7EB),
          width: hasError ? 1.2 : 1.0,
        ),
      ),
      alignment: Alignment.center,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13.0,
                  color: const Color(0xFF9CA3AF),
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
                isDense: true,
              ),
            ),
          ),
          if (suffixIcon != null)
            Icon(
              suffixIcon,
              color: hasError ? const Color(0xFFEF4444) : AppColors.primary,
              size: 18.0,
            ),
        ],
      ),
    );
  }
}
