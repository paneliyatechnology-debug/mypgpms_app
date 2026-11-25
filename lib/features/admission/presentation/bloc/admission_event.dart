import 'package:equatable/equatable.dart';

abstract class AdmissionEvent extends Equatable {
  const AdmissionEvent();

  @override
  List<Object?> get props => [];
}

class LoadUserProfile extends AdmissionEvent {
  const LoadUserProfile();
}

class PopulateAdmissionFromUser extends AdmissionEvent {
  final Map<String, dynamic> userMap;
  const PopulateAdmissionFromUser(this.userMap);

  @override
  List<Object?> get props => [userMap];
}

class UpdatePersonalDetails extends AdmissionEvent {
  final String fullName;
  final String dateOfBirth;
  final String gender;
  final String phone;
  final String email;

  const UpdatePersonalDetails({
    required this.fullName,
    required this.dateOfBirth,
    required this.gender,
    required this.phone,
    required this.email,
  });

  @override
  List<Object?> get props => [fullName, dateOfBirth, gender, phone, email];
}

class UpdateAddressContact extends AdmissionEvent {
  final String addressLine1;
  final String city;
  final String state;
  final String pincode;
  final String emergencyName;
  final String emergencyRelationship;
  final String emergencyPhone;

  const UpdateAddressContact({
    required this.addressLine1,
    required this.city,
    required this.state,
    required this.pincode,
    required this.emergencyName,
    required this.emergencyRelationship,
    required this.emergencyPhone,
  });

  @override
  List<Object?> get props => [
        addressLine1,
        city,
        state,
        pincode,
        emergencyName,
        emergencyRelationship,
        emergencyPhone,
      ];
}

class UpdateDocumentFiles extends AdmissionEvent {
  final String? aadharCardPath;
  final String? profilePhotoPath;
  final String? addressProofPath;
  final String? educationCertPath;
  final List<String>? uploadedTitles;

  const UpdateDocumentFiles({
    this.aadharCardPath,
    this.profilePhotoPath,
    this.addressProofPath,
    this.educationCertPath,
    this.uploadedTitles,
  });

  @override
  List<Object?> get props => [
        aadharCardPath,
        profilePhotoPath,
        addressProofPath,
        educationCertPath,
        uploadedTitles,
      ];
}

class ToggleAgreement extends AdmissionEvent {
  final bool accepted;

  const ToggleAgreement(this.accepted);

  @override
  List<Object?> get props => [accepted];
}

class UpdateSignature extends AdmissionEvent {
  final bool hasSigned;
  final String? signaturePath;

  const UpdateSignature(this.hasSigned, {this.signaturePath});

  @override
  List<Object?> get props => [hasSigned, signaturePath];
}

class SubmitAdmissionApplication extends AdmissionEvent {
  const SubmitAdmissionApplication();
}

