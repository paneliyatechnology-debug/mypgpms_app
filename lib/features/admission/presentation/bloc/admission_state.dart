import 'package:equatable/equatable.dart';

enum AdmissionStatus { initial, inProgress, submitting, success, failure }

class AdmissionState extends Equatable {
  final AdmissionStatus status;
  final String fullName;
  final String dateOfBirth;
  final String gender;
  final String phone;
  final String email;

  final String addressLine1;
  final String city;
  final String state;
  final String pincode;

  final String emergencyName;
  final String emergencyRelationship;
  final String emergencyPhone;

  final List<String> uploadedDocuments;
  final String? aadharCardPath;
  final String? profilePhotoPath;
  final String? addressProofPath;
  final String? educationCertPath;
  final String? signaturePath;

  final String nationality;
  final String maritalStatus;
  final String occupation;

  final String selectedBed;
  final bool agreementAccepted;
  final bool hasSignature;
  final String applicationId;
  final String errorMessage;

  const AdmissionState({
    this.status = AdmissionStatus.initial,
    this.fullName = '',
    this.dateOfBirth = '',
    this.gender = '',
    this.phone = '',
    this.email = '',
    this.addressLine1 = '',
    this.city = '',
    this.state = '',
    this.pincode = '',
    this.emergencyName = '',
    this.emergencyRelationship = '',
    this.emergencyPhone = '',
    this.uploadedDocuments = const [],
    this.aadharCardPath,
    this.profilePhotoPath,
    this.addressProofPath,
    this.educationCertPath,
    this.signaturePath,
    this.nationality = 'Indian',
    this.maritalStatus = 'single',
    this.occupation = 'Software Engineer',
    this.selectedBed = 'B-2',
    this.agreementAccepted = false,
    this.hasSignature = false,
    this.applicationId = 'CLV-2026-00123',
    this.errorMessage = '',
  });

  AdmissionState copyWith({
    AdmissionStatus? status,
    String? fullName,
    String? dateOfBirth,
    String? gender,
    String? phone,
    String? email,
    String? addressLine1,
    String? city,
    String? state,
    String? pincode,
    String? emergencyName,
    String? emergencyRelationship,
    String? emergencyPhone,
    List<String>? uploadedDocuments,
    String? aadharCardPath,
    String? profilePhotoPath,
    String? addressProofPath,
    String? educationCertPath,
    String? signaturePath,
    String? nationality,
    String? maritalStatus,
    String? occupation,
    String? selectedBed,
    bool? agreementAccepted,
    bool? hasSignature,
    String? applicationId,
    String? errorMessage,
  }) {
    return AdmissionState(
      status: status ?? this.status,
      fullName: fullName ?? this.fullName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      addressLine1: addressLine1 ?? this.addressLine1,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      emergencyName: emergencyName ?? this.emergencyName,
      emergencyRelationship: emergencyRelationship ?? this.emergencyRelationship,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
      uploadedDocuments: uploadedDocuments ?? this.uploadedDocuments,
      aadharCardPath: aadharCardPath ?? this.aadharCardPath,
      profilePhotoPath: profilePhotoPath ?? this.profilePhotoPath,
      addressProofPath: addressProofPath ?? this.addressProofPath,
      educationCertPath: educationCertPath ?? this.educationCertPath,
      signaturePath: signaturePath ?? this.signaturePath,
      nationality: nationality ?? this.nationality,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      occupation: occupation ?? this.occupation,
      selectedBed: selectedBed ?? this.selectedBed,
      agreementAccepted: agreementAccepted ?? this.agreementAccepted,
      hasSignature: hasSignature ?? this.hasSignature,
      applicationId: applicationId ?? this.applicationId,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        fullName,
        dateOfBirth,
        gender,
        phone,
        email,
        addressLine1,
        city,
        state,
        pincode,
        emergencyName,
        emergencyRelationship,
        emergencyPhone,
        uploadedDocuments,
        aadharCardPath,
        profilePhotoPath,
        addressProofPath,
        educationCertPath,
        signaturePath,
        nationality,
        maritalStatus,
        occupation,
        selectedBed,
        agreementAccepted,
        hasSignature,
        applicationId,
        errorMessage,
      ];
}
