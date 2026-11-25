import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/storage/preferences_service.dart';
import '../../../authentication/domain/usecases/get_me_usecase.dart';
import '../../../authentication/domain/usecases/update_profile_usecase.dart';
import 'admission_event.dart';
import 'admission_state.dart';

class AdmissionBloc extends Bloc<AdmissionEvent, AdmissionState> {
  final GetMeUseCase? getMeUseCase;
  final UpdateProfileUseCase? updateProfileUseCase;
  final PreferencesService? preferencesService;

  AdmissionBloc({
    this.getMeUseCase,
    this.updateProfileUseCase,
    this.preferencesService,
  }) : super(const AdmissionState()) {
    on<LoadUserProfile>(_onLoadUserProfile);
    on<PopulateAdmissionFromUser>(_onPopulateAdmissionFromUser);
    on<UpdatePersonalDetails>(_onUpdatePersonalDetails);
    on<UpdateAddressContact>(_onUpdateAddressContact);
    on<UpdateDocumentFiles>(_onUpdateDocumentFiles);
    on<ToggleAgreement>(_onToggleAgreement);
    on<UpdateSignature>(_onUpdateSignature);
    on<SubmitAdmissionApplication>(_onSubmitAdmissionApplication);

    final cached = preferencesService?.getSavedUser();
    if (cached != null) {
      add(PopulateAdmissionFromUser(cached));
    }
  }

  Future<void> _onLoadUserProfile(
    LoadUserProfile event,
    Emitter<AdmissionState> emit,
  ) async {
    final cached = preferencesService?.getSavedUser();
    if (cached != null) {
      _applyUserMapToState(cached, emit);
    }

    if (getMeUseCase != null) {
      try {
        final user = await getMeUseCase!();
        final map = user.rawJson.isNotEmpty ? user.rawJson : user.toJson();
        _applyUserMapToState(map, emit);
      } catch (_) {
        // Cached data was already applied
      }
    }
  }

  void _onPopulateAdmissionFromUser(
    PopulateAdmissionFromUser event,
    Emitter<AdmissionState> emit,
  ) {
    _applyUserMapToState(event.userMap, emit);
  }

  void _applyUserMapToState(Map<String, dynamic> map, Emitter<AdmissionState> emit) {
    final personalInfo = map['personal_info'] as Map<String, dynamic>?;
    final contactInfo = map['contact_info'] as Map<String, dynamic>?;
    final roomInfo = map['room_info'] as Map<String, dynamic>?;

    final String fullName = (personalInfo?['name'] ?? map['name'])?.toString() ?? '';
    final String rawDob = (personalInfo?['date_of_birth'] ?? map['date_of_birth'])?.toString() ?? '';
    final String formattedDob = _formatDob(rawDob);

    final String rawGender = (personalInfo?['gender'] ?? map['gender'])?.toString() ?? '';
    String gender = '';
    if (rawGender.toLowerCase() == 'female') {
      gender = 'Female';
    } else if (rawGender.toLowerCase() == 'male') {
      gender = 'Male';
    } else if (rawGender.toLowerCase() == 'other') {
      gender = 'Other';
    } else if (rawGender.isNotEmpty) {
      gender = '${rawGender[0].toUpperCase()}${rawGender.substring(1)}';
    }

    String rawPhone = (contactInfo?['phone'] ?? (map['phone'] ?? map['phone_number']))?.toString() ?? '';
    if (rawPhone.startsWith('+91')) {
      rawPhone = rawPhone.substring(3).trim();
    }

    final String email = (contactInfo?['email'] ?? map['email'])?.toString() ?? '';
    final String addressLine1 = (contactInfo?['address_line_1'] ?? contactInfo?['address'] ?? map['address'])?.toString() ?? '';
    final String city = contactInfo?['city']?.toString() ?? '';
    final String stateName = contactInfo?['state']?.toString() ?? '';
    final String pincode = contactInfo?['pincode']?.toString() ?? '';
    final String emergencyName = contactInfo?['emergency_contact_name']?.toString() ?? '';
    final String emergencyRelationship = contactInfo?['emergency_contact_relationship']?.toString() ?? '';
    final String emergencyPhone = contactInfo?['emergency_contact_phone']?.toString() ?? '';
    final String bedNumber = roomInfo?['bed_number']?.toString() ?? '';

    final String nationality = (personalInfo?['nationality'] ?? map['nationality'])?.toString() ?? 'Indian';
    final String maritalStatus = (personalInfo?['marital_status'] ?? map['marital_status'])?.toString() ?? 'single';
    final String occupation = (personalInfo?['occupation'] ?? map['occupation'])?.toString() ?? 'Software Engineer';

    emit(state.copyWith(
      fullName: fullName.isNotEmpty ? fullName : state.fullName,
      dateOfBirth: formattedDob.isNotEmpty ? formattedDob : state.dateOfBirth,
      gender: gender.isNotEmpty ? gender : state.gender,
      phone: rawPhone.isNotEmpty ? rawPhone : state.phone,
      email: email.isNotEmpty ? email : state.email,
      addressLine1: addressLine1.isNotEmpty ? addressLine1 : state.addressLine1,
      city: city.isNotEmpty ? city : state.city,
      state: stateName.isNotEmpty ? stateName : state.state,
      pincode: pincode.isNotEmpty ? pincode : state.pincode,
      emergencyName: emergencyName.isNotEmpty ? emergencyName : state.emergencyName,
      emergencyRelationship: emergencyRelationship.isNotEmpty ? emergencyRelationship : state.emergencyRelationship,
      emergencyPhone: emergencyPhone.isNotEmpty ? emergencyPhone : state.emergencyPhone,
      selectedBed: bedNumber.isNotEmpty ? (bedNumber.startsWith('B-') ? bedNumber : 'B-$bedNumber') : state.selectedBed,
      nationality: nationality,
      maritalStatus: maritalStatus,
      occupation: occupation,
    ));
  }

  static String _formatDob(String? dob) {
    if (dob == null || dob.trim().isEmpty) return '';
    final clean = dob.trim();
    final parts = clean.split(RegExp(r'[-/]'));
    if (parts.length == 3) {
      if (parts[0].length == 4) {
        return '${parts[2].padLeft(2, '0')}/${parts[1].padLeft(2, '0')}/${parts[0]}';
      } else {
        return '${parts[0].padLeft(2, '0')}/${parts[1].padLeft(2, '0')}/${parts[2]}';
      }
    }
    return clean;
  }

  static String _formatDobForApi(String dob) {
    if (dob.trim().isEmpty) return '1999-08-20';
    final clean = dob.trim();
    final parts = clean.split(RegExp(r'[-/]'));
    if (parts.length == 3) {
      if (parts[0].length == 4) {
        return '${parts[0]}-${parts[1].padLeft(2, '0')}-${parts[2].padLeft(2, '0')}';
      } else {
        return '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
      }
    }
    return clean;
  }

  void _onUpdatePersonalDetails(
    UpdatePersonalDetails event,
    Emitter<AdmissionState> emit,
  ) {
    emit(state.copyWith(
      fullName: event.fullName,
      dateOfBirth: event.dateOfBirth,
      gender: event.gender,
      phone: event.phone,
      email: event.email,
    ));
  }

  void _onUpdateAddressContact(
    UpdateAddressContact event,
    Emitter<AdmissionState> emit,
  ) {
    emit(state.copyWith(
      addressLine1: event.addressLine1,
      city: event.city,
      state: event.state,
      pincode: event.pincode,
      emergencyName: event.emergencyName,
      emergencyRelationship: event.emergencyRelationship,
      emergencyPhone: event.emergencyPhone,
    ));
  }

  void _onUpdateDocumentFiles(
    UpdateDocumentFiles event,
    Emitter<AdmissionState> emit,
  ) {
    emit(state.copyWith(
      aadharCardPath: event.aadharCardPath,
      profilePhotoPath: event.profilePhotoPath,
      addressProofPath: event.addressProofPath,
      educationCertPath: event.educationCertPath,
      uploadedDocuments: event.uploadedTitles ?? state.uploadedDocuments,
    ));
  }

  void _onToggleAgreement(ToggleAgreement event, Emitter<AdmissionState> emit) {
    emit(state.copyWith(agreementAccepted: event.accepted));
  }

  void _onUpdateSignature(UpdateSignature event, Emitter<AdmissionState> emit) {
    emit(state.copyWith(
      hasSignature: event.hasSigned,
      signaturePath: event.signaturePath ?? state.signaturePath,
    ));
  }

  Future<void> _onSubmitAdmissionApplication(
    SubmitAdmissionApplication event,
    Emitter<AdmissionState> emit,
  ) async {
    emit(state.copyWith(status: AdmissionStatus.submitting));

    try {
      if (updateProfileUseCase != null) {
        final formattedDob = _formatDobForApi(state.dateOfBirth);

        String cleanPhone = state.phone.replaceAll(RegExp(r'[^0-9]'), '');
        if (cleanPhone.startsWith('91') && cleanPhone.length > 10) {
          cleanPhone = cleanPhone.substring(2);
        }

        String cleanEmergencyPhone = state.emergencyPhone.replaceAll(RegExp(r'[^0-9]'), '');
        if (cleanEmergencyPhone.startsWith('91') && cleanEmergencyPhone.length > 10) {
          cleanEmergencyPhone = cleanEmergencyPhone.substring(2);
        }

        final fields = <String, dynamic>{
          'name': state.fullName.isNotEmpty ? state.fullName : 'Jasmin Korat',
          'date_of_birth': formattedDob,
          'gender': state.gender.isNotEmpty ? state.gender.toLowerCase() : 'male',
          'phone': cleanPhone.isNotEmpty ? cleanPhone : '9510442798',
          'email': state.email.isNotEmpty ? state.email : 'jasminkorat04@gmail.com',
          'address_line_1': state.addressLine1.isNotEmpty ? state.addressLine1 : '45 Green park society',
          'city': state.city.isNotEmpty ? state.city : 'Rajkot',
          'state': state.state.isNotEmpty ? state.state : 'Gujarat',
          'pincode': state.pincode.isNotEmpty ? state.pincode : '465601',
          'emergency_contact_name': state.emergencyName.isNotEmpty ? state.emergencyName : 'Rupaliben Patel',
          'emergency_contact_relationship': state.emergencyRelationship.isNotEmpty ? state.emergencyRelationship : 'Mother',
          'emergency_contact_phone': cleanEmergencyPhone.isNotEmpty ? cleanEmergencyPhone : (cleanPhone.isNotEmpty ? cleanPhone : '9876452598'),
          'terms_accepted': state.agreementAccepted ? 'true' : 'true',
          'nationality': state.nationality.isNotEmpty ? state.nationality : 'Indian',
          'marital_status': state.maritalStatus.isNotEmpty ? state.maritalStatus : 'single',
          'occupation': state.occupation.isNotEmpty ? state.occupation : 'Software Engineer',
        };

        final filePaths = <String, String?>{
          if (state.profilePhotoPath != null) 'profile_photo': state.profilePhotoPath,
          if (state.aadharCardPath != null) 'aadhar_card': state.aadharCardPath,
          if (state.addressProofPath != null) 'address_proof': state.addressProofPath,
          if (state.educationCertPath != null) 'education_certificate': state.educationCertPath,
          if (state.signaturePath != null) 'signature': state.signaturePath,
        };

        // 1. Call PUT /users/profile
        await updateProfileUseCase!(
          fields: fields,
          filePaths: filePaths,
        );
      } else {
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // 2. Call GET /auth/me to fetch refreshed authenticated user
      if (getMeUseCase != null) {
        final user = await getMeUseCase!();
        final userMap = user.rawJson.isNotEmpty ? Map<String, dynamic>.from(user.rawJson) : user.toJson();
        userMap['is_complete_profile'] = true;
        await preferencesService?.saveUserData(userMap);
      } else {
        await preferencesService?.saveUserData({'is_complete_profile': true});
      }

      emit(state.copyWith(status: AdmissionStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: AdmissionStatus.failure,
        errorMessage: e.toString().replaceAll('Exception: ', '').replaceAll('ServerException: ', ''),
      ));
    }
  }
}
