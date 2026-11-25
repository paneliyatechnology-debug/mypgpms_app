import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  final Map<String, dynamic> rawJson;

  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.phoneNumber,
    super.profileImageUrl,
    super.role,
    super.gender,
    super.address,
    super.pgName,
    super.pgAddress,
    super.isCompleteProfile = false,
    super.buildingName,
    super.floorName,
    super.roomNo,
    super.bedNumber,
    super.roomType,
    super.dueAmount,
    super.dueDate,
    super.dateOfBirth,
    super.dobDisplay,
    super.occupation,
    super.city,
    super.state,
    super.pincode,
    super.addressLine1,
    super.emergencyContactName,
    super.emergencyContactRelationship,
    super.emergencyContactPhone,
    this.rawJson = const {},
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final pg = json['pg'] is Map<String, dynamic> ? json['pg'] as Map<String, dynamic> : null;
    final personalInfo = json['personal_info'] is Map<String, dynamic> ? json['personal_info'] as Map<String, dynamic> : null;
    final contactInfo = json['contact_info'] is Map<String, dynamic> ? json['contact_info'] as Map<String, dynamic> : null;
    final roomInfo = json['room_info'] is Map<String, dynamic> ? json['room_info'] as Map<String, dynamic> : null;
    final paymentInfo = json['payment_info'] is Map<String, dynamic> ? json['payment_info'] as Map<String, dynamic> : null;

    final String name = (personalInfo?['name'] ?? json['name']) as String? ?? '';
    final String email = (contactInfo?['email'] ?? json['email']) as String? ?? '';
    final String phone = (contactInfo?['phone'] ?? (json['phone'] ?? json['phone_number']))?.toString() ?? '';
    final String? pgName = (roomInfo?['pg_name'] ?? pg?['name'])?.toString();
    final String? pgAddress = (roomInfo?['branch_name'] ?? pg?['address'])?.toString();
    final bool isComplete = json['is_complete_profile'] as bool? ?? false;
    final String? buildingName = roomInfo?['building_name']?.toString();
    final String? floorName = (roomInfo?['floor_name'] ?? (roomInfo?['floor_number'] != null ? 'Floor ${roomInfo!['floor_number']}' : null))?.toString();
    final String? roomNo = roomInfo?['room_no']?.toString();
    final String? bedNumber = roomInfo?['bed_number']?.toString();
    final String? roomType = roomInfo?['room_type']?.toString();
    final int? dueAmount = (json['due_amount'] ?? paymentInfo?['due_amount']) as int?;
    final String? dueDate = paymentInfo?['due_date']?.toString();

    final String? dateOfBirth = personalInfo?['date_of_birth']?.toString();
    final String? dobDisplay = personalInfo?['dob_display']?.toString();
    final String? occupation = personalInfo?['occupation']?.toString();
    final String? city = contactInfo?['city']?.toString();
    final String? state = contactInfo?['state']?.toString();
    final String? pincode = contactInfo?['pincode']?.toString();
    final String? addressLine1 = (contactInfo?['address_line_1'] ?? contactInfo?['address'] ?? json['address'])?.toString();
    final String? emergencyContactName = contactInfo?['emergency_contact_name']?.toString();
    final String? emergencyContactRelationship = contactInfo?['emergency_contact_relationship']?.toString();
    final String? emergencyContactPhone = contactInfo?['emergency_contact_phone']?.toString();

    return UserModel(
      id: json['id']?.toString() ?? '',
      name: name,
      email: email,
      phoneNumber: phone,
      profileImageUrl: (json['profile_photo_url'] ?? json['profile_image_url']) as String?,
      role: json['role'] as String?,
      gender: (personalInfo?['gender'] ?? json['gender']) as String?,
      address: addressLine1,
      pgName: pgName,
      pgAddress: pgAddress,
      isCompleteProfile: isComplete,
      buildingName: buildingName,
      floorName: floorName,
      roomNo: roomNo,
      bedNumber: bedNumber,
      roomType: roomType,
      dueAmount: dueAmount,
      dueDate: dueDate,
      dateOfBirth: dateOfBirth,
      dobDisplay: dobDisplay,
      occupation: occupation,
      city: city,
      state: state,
      pincode: pincode,
      addressLine1: addressLine1,
      emergencyContactName: emergencyContactName,
      emergencyContactRelationship: emergencyContactRelationship,
      emergencyContactPhone: emergencyContactPhone,
      rawJson: json,
    );
  }

  Map<String, dynamic> toJson() {
    if (rawJson.isNotEmpty) {
      return Map<String, dynamic>.from(rawJson);
    }
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phoneNumber,
      'profile_photo_url': profileImageUrl,
      'role': role,
      'gender': gender,
      'address': address,
      'is_complete_profile': isCompleteProfile,
      'building_name': buildingName,
      'floor_name': floorName,
      'room_no': roomNo,
      'bed_number': bedNumber,
      'room_type': roomType,
      'due_amount': dueAmount,
      'due_date': dueDate,
      'date_of_birth': dateOfBirth,
      'dob_display': dobDisplay,
      'occupation': occupation,
      'city': city,
      'state': state,
      'pincode': pincode,
      'address_line_1': addressLine1,
      'emergency_contact_name': emergencyContactName,
      'emergency_contact_relationship': emergencyContactRelationship,
      'emergency_contact_phone': emergencyContactPhone,
      if (pgName != null || pgAddress != null)
        'pg': {
          if (pgName != null) 'name': pgName,
          if (pgAddress != null) 'address': pgAddress,
        },
    };
  }
}

class LoginResultModel {
  final bool success;
  final String message;
  final UserModel? user;
  final String? accessToken;
  final String? refreshToken;
  final Map<String, dynamic> rawJson;

  LoginResultModel({
    required this.success,
    required this.message,
    this.user,
    this.accessToken,
    this.refreshToken,
    required this.rawJson,
  });

  factory LoginResultModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : null;
    final userJson = data?['user'] is Map<String, dynamic> ? data!['user'] as Map<String, dynamic> : null;

    return LoginResultModel(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      user: userJson != null ? UserModel.fromJson(userJson) : null,
      accessToken: data?['access_token'] as String?,
      refreshToken: data?['refresh_token'] as String?,
      rawJson: json,
    );
  }
}
