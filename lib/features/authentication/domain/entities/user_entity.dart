import 'package:equatable/equatable.dart';

/// Domain entity representing an authenticated user.
class UserEntity extends Equatable {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String? profileImageUrl;
  final String? role;
  final String? gender;
  final String? address;
  final String? pgName;
  final String? pgAddress;
  final bool isCompleteProfile;
  final String? buildingName;
  final String? floorName;
  final String? roomNo;
  final String? bedNumber;
  final String? roomType;
  final int? dueAmount;
  final String? dueDate;
  final String? dateOfBirth;
  final String? dobDisplay;
  final String? occupation;
  final String? city;
  final String? state;
  final String? pincode;
  final String? addressLine1;
  final String? emergencyContactName;
  final String? emergencyContactRelationship;
  final String? emergencyContactPhone;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    this.profileImageUrl,
    this.role,
    this.gender,
    this.address,
    this.pgName,
    this.pgAddress,
    this.isCompleteProfile = false,
    this.buildingName,
    this.floorName,
    this.roomNo,
    this.bedNumber,
    this.roomType,
    this.dueAmount,
    this.dueDate,
    this.dateOfBirth,
    this.dobDisplay,
    this.occupation,
    this.city,
    this.state,
    this.pincode,
    this.addressLine1,
    this.emergencyContactName,
    this.emergencyContactRelationship,
    this.emergencyContactPhone,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        phoneNumber,
        profileImageUrl,
        role,
        gender,
        address,
        pgName,
        pgAddress,
        isCompleteProfile,
        buildingName,
        floorName,
        roomNo,
        bedNumber,
        roomType,
        dueAmount,
        dueDate,
        dateOfBirth,
        dobDisplay,
        occupation,
        city,
        state,
        pincode,
        addressLine1,
        emergencyContactName,
        emergencyContactRelationship,
        emergencyContactPhone,
      ];
}
