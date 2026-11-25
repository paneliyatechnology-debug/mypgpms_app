import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/colors/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/typography/app_text_styles.dart';
import '../../../../core/utils/app_validators.dart';
import '../../../../common/widgets/common_app_bar.dart';
import '../../../../common/widgets/common_phone_field.dart';
import '../../../../common/widgets/common_text_field.dart';
import '../bloc/admission_bloc.dart';
import '../bloc/admission_event.dart';
import '../bloc/admission_state.dart';
import '../widgets/admission_nav_buttons.dart';
import '../widgets/step_progress_header.dart';

class AddressContactPage extends StatefulWidget {
  const AddressContactPage({super.key});

  @override
  State<AddressContactPage> createState() => _AddressContactPageState();
}

class _AddressContactPageState extends State<AddressContactPage> {
  final _formKey = GlobalKey<FormState>();
  final _addressLineController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  String? _selectedState;
  String? _selectedRelationship;

  final List<String> _states = [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
    'Delhi',
    'Chandigarh',
    'Other',
  ];

  final List<String> _relationships = [
    'Mother',
    'Father',
    'Brother',
    'Sister',
    'Guardian',
    'Spouse',
    'Sibling',
    'Friend',
    'Relative',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    final state = context.read<AdmissionBloc>().state;
    _populateControllers(state);
  }

  void _populateControllers(AdmissionState state) {
    if (_addressLineController.text.isEmpty && state.addressLine1.isNotEmpty) {
      _addressLineController.text = state.addressLine1;
    }
    if (_cityController.text.isEmpty && state.city.isNotEmpty) {
      _cityController.text = state.city;
    }
    if (_pincodeController.text.isEmpty && state.pincode.isNotEmpty) {
      _pincodeController.text = state.pincode;
    }
    if (_emergencyNameController.text.isEmpty && state.emergencyName.isNotEmpty) {
      _emergencyNameController.text = state.emergencyName;
    }
    if (_emergencyPhoneController.text.isEmpty && state.emergencyPhone.isNotEmpty) {
      _emergencyPhoneController.text = state.emergencyPhone;
    }
    if (_selectedState == null && state.state.isNotEmpty) {
      _selectedState = state.state;
      if (!_states.contains(_selectedState)) {
        _states.add(_selectedState!);
      }
    }
    if (_selectedRelationship == null && state.emergencyRelationship.isNotEmpty) {
      _selectedRelationship = state.emergencyRelationship;
      if (!_relationships.contains(_selectedRelationship)) {
        _relationships.add(_selectedRelationship!);
      }
    }
  }

  @override
  void dispose() {
    _addressLineController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AdmissionBloc>().add(
            UpdateAddressContact(
              addressLine1: _addressLineController.text.trim(),
              city: _cityController.text.trim(),
              state: _selectedState ?? '',
              pincode: _pincodeController.text.trim(),
              emergencyName: _emergencyNameController.text.trim(),
              emergencyRelationship: _selectedRelationship ?? '',
              emergencyPhone: _emergencyPhoneController.text.trim(),
            ),
          );
      Navigator.of(context).pushNamed(AppRoutes.admissionDocuments);
    }
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required String hintText,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
  }) {
    final effectiveItems = items.toSet().toList();
    if (value != null && value.trim().isNotEmpty && !effectiveItems.contains(value.trim())) {
      effectiveItems.add(value.trim());
    }
    final effectiveValue = (value != null && effectiveItems.contains(value.trim())) ? value.trim() : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: AppColors.primary,
            fontSize: 14.0,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8.0),
        DropdownButtonFormField<String>(
          initialValue: effectiveValue,
          hint: Text(
            hintText,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.0,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF9CA3AF),
            ),
          ),
          items: effectiveItems.map((e) {
            return DropdownMenuItem(
              value: e,
              child: Text(e, style: AppTextStyles.input),
            );
          }).toList(),
          onChanged: onChanged,
          validator: validator,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.0),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.0),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.0),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.0),
              borderSide: const BorderSide(color: AppColors.error),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AdmissionBloc, AdmissionState>(
      listener: (context, state) {
        setState(() {
          _populateControllers(state);
        });
      },
      child: Scaffold(
      backgroundColor: const Color(0xFFF7F8F6),
      appBar: const CommonAppBar(
        title: 'Address and Emergency Contact',
        backgroundColor: Color(0xFFF7F8F6),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const StepProgressHeader(currentStep: 2),
                const SizedBox(height: 20.0),

                Text(
                  'Current Address',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18.0,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16.0),

                CommonTextField(
                  label: 'Address Line 1 *',
                  hintText: 'e.g. 45 Green park society',
                  controller: _addressLineController,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Address is required' : null,
                  borderRadius: 16.0,
                  fillColor: Colors.white,
                ),
                const SizedBox(height: 16.0),

                CommonTextField(
                  label: 'City *',
                  hintText: 'Rajkot',
                  controller: _cityController,
                  validator: (v) => v == null || v.trim().isEmpty ? 'City is required' : null,
                  borderRadius: 16.0,
                  fillColor: Colors.white,
                ),
                const SizedBox(height: 16.0),

                _buildDropdown(
                  label: 'State *',
                  value: _selectedState,
                  hintText: 'Gujarat',
                  items: _states,
                  validator: (v) => v == null || v.isEmpty ? 'Please select a state' : null,
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedState = val);
                  },
                ),
                const SizedBox(height: 16.0),

                CommonTextField(
                  label: 'Pincode *',
                  hintText: '465601',
                  controller: _pincodeController,
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.trim().length < 6 ? 'Enter valid 6-digit pincode' : null,
                  borderRadius: 16.0,
                  fillColor: Colors.white,
                ),
                const SizedBox(height: 28.0),

                Text(
                  'Emergency Contact',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18.0,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16.0),

                CommonTextField(
                  label: 'Name *',
                  hintText: 'Rupaliben Patel',
                  controller: _emergencyNameController,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Contact name is required' : null,
                  borderRadius: 16.0,
                  fillColor: Colors.white,
                ),
                const SizedBox(height: 16.0),

                _buildDropdown(
                  label: 'Relationship *',
                  value: _selectedRelationship,
                  hintText: 'Mother',
                  items: _relationships,
                  validator: (v) => v == null || v.isEmpty ? 'Please select relationship' : null,
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedRelationship = val);
                  },
                ),
                const SizedBox(height: 16.0),

                CommonPhoneField(
                  label: 'Phone number *',
                  controller: _emergencyPhoneController,
                  validator: AppValidators.validatePhoneNumber,
                ),
                const SizedBox(height: 36.0),

                AdmissionNavButtons(
                  onBack: () => Navigator.of(context).pop(),
                  onNext: _onNext,
                ),
                const SizedBox(height: 24.0),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
}
