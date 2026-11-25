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

class PersonalDetailsPage extends StatefulWidget {
  const PersonalDetailsPage({super.key});

  @override
  State<PersonalDetailsPage> createState() => _PersonalDetailsPageState();
}

class _PersonalDetailsPageState extends State<PersonalDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  String _selectedGender = 'Male';

  @override
  void initState() {
    super.initState();
    final bloc = context.read<AdmissionBloc>();
    _populateControllers(bloc.state);
    bloc.add(const LoadUserProfile());
  }

  void _populateControllers(AdmissionState state) {
    if (_fullNameController.text.isEmpty && state.fullName.isNotEmpty) {
      _fullNameController.text = state.fullName;
    }
    if (_dobController.text.isEmpty && state.dateOfBirth.isNotEmpty) {
      _dobController.text = state.dateOfBirth;
    }
    if (_phoneController.text.isEmpty && state.phone.isNotEmpty) {
      _phoneController.text = state.phone;
    }
    if (_emailController.text.isEmpty && state.email.isNotEmpty) {
      _emailController.text = state.email;
    }
    if (state.gender.isNotEmpty) {
      _selectedGender = state.gender;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2002, 5, 15),
      firstDate: DateTime(1970),
      lastDate: DateTime.now(),
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
        _dobController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  void _onNext() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AdmissionBloc>().add(
            UpdatePersonalDetails(
              fullName: _fullNameController.text.trim(),
              dateOfBirth: _dobController.text.trim(),
              gender: _selectedGender,
              phone: _phoneController.text.trim(),
              email: _emailController.text.trim(),
            ),
          );
      Navigator.of(context).pushNamed(AppRoutes.admissionAddress);
    }
  }

  Widget _buildGenderChip(String label, IconData icon) {
    final isSelected = _selectedGender == label;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedGender = label),
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          height: 48.0,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: isSelected ? AppColors.primary : const Color(0xFFE5E7EB),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18.0,
                color: isSelected ? Colors.white : AppColors.primary,
              ),
              const SizedBox(width: 8.0),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
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
        title: 'Personal Details',
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
                const StepProgressHeader(currentStep: 1),
                const SizedBox(height: 20.0),

                Text(
                  'Tell us about yourself',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20.0,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6.0),
                Text(
                  'Please fill in your personal details correctly as per your identity proof.',
                  style: AppTextStyles.welcomeSubtitle.copyWith(fontSize: 13.5),
                ),
                const SizedBox(height: 24.0),

                // Full name
                CommonTextField(
                  label: 'Full name *',
                  hintText: 'Enter your full name',
                  controller: _fullNameController,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Please enter your full name' : null,
                  borderRadius: 16.0,
                  fillColor: Colors.white,
                ),
                const SizedBox(height: 18.0),

                // Date of birth
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date of birth *',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.primary,
                        fontSize: 14.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    GestureDetector(
                      onTap: _selectDate,
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: _dobController,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Please select your date of birth'
                              : null,
                          style: AppTextStyles.input,
                          decoration: InputDecoration(
                            hintText: 'Select date',
                            hintStyle: AppTextStyles.hint,
                            suffixIcon: const Icon(
                              Icons.calendar_today_outlined,
                              color: AppColors.primary,
                              size: 20.0,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 16.0,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16.0),
                              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16.0),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 1.5,
                              ),
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
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18.0),

                // Gender
                Text(
                  'Gender *',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.primary,
                    fontSize: 14.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8.0),
                Row(
                  children: [
                    _buildGenderChip('Male', Icons.person_outline),
                    const SizedBox(width: 10.0),
                    _buildGenderChip('Female', Icons.person_outline),
                    const SizedBox(width: 10.0),
                    _buildGenderChip('Other', Icons.person_outline),
                  ],
                ),
                const SizedBox(height: 18.0),

                // Phone number
                CommonPhoneField(
                  label: 'Phone number *',
                  controller: _phoneController,
                  validator: AppValidators.validatePhoneNumber,
                ),
                const SizedBox(height: 18.0),

                // Email address
                CommonTextField(
                  label: 'Email address *',
                  hintText: 'you@domain.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: AppValidators.validateEmail,
                  borderRadius: 16.0,
                  fillColor: Colors.white,
                ),
                const SizedBox(height: 36.0),

                AdmissionNavButtons(
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
