class StaffListResponseModel {
  final bool success;
  final String? message;
  final List<StaffMemberModel> data;
  final StaffMetaModel? meta;

  StaffListResponseModel({
    required this.success,
    this.message,
    this.data = const [],
    this.meta,
  });

  factory StaffListResponseModel.fromJson(Map<String, dynamic> json) {
    List<StaffMemberModel> list = [];
    if (json['data'] is List) {
      list = (json['data'] as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => StaffMemberModel.fromJson(e))
          .toList();
    }
    return StaffListResponseModel(
      success: json['success'] as bool? ?? false,
      message: json['message']?.toString(),
      data: list,
      meta: json['meta'] is Map<String, dynamic>
          ? StaffMetaModel.fromJson(json['meta'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        'data': data.map((e) => e.toJson()).toList(),
        if (meta != null) 'meta': meta!.toJson(),
      };
}

class StaffMemberModel {
  final int id;
  final String name;
  final String role;
  final String staffRole;
  final String? email;
  final String phone;
  final String? status;
  final String? profilePhotoUrl;
  final String? photoUrl;
  final String? branchName;
  final String? callAction;
  final String? messageAction;

  StaffMemberModel({
    required this.id,
    required this.name,
    required this.role,
    required this.staffRole,
    this.email,
    required this.phone,
    this.status,
    this.profilePhotoUrl,
    this.photoUrl,
    this.branchName,
    this.callAction,
    this.messageAction,
  });

  String get displayPhoto => photoUrl ?? profilePhotoUrl ?? '';

  String get formattedRole {
    if (role.isEmpty) return 'Staff';
    final lower = role.toLowerCase();
    if (lower == 'maintenance') return 'Maintenance staff';
    if (lower == 'manager') return 'Resident Manager';
    if (lower == 'security') return 'Security Guard';
    if (lower == 'housekeeping' || lower == 'cleaning') return 'Housekeeping staff';
    return role
        .split('_')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}' : '')
        .join(' ');
  }

  String get categoryFilter {
    final lower = staffRole.isNotEmpty ? staffRole.toLowerCase() : role.toLowerCase();
    if (lower.contains('manager')) return 'Manager';
    if (lower.contains('security')) return 'Security';
    if (lower.contains('clean') || lower.contains('housekeep')) return 'Cleaning';
    if (lower.contains('maintenance')) return 'Maintenance';
    return 'Other';
  }

  factory StaffMemberModel.fromJson(Map<String, dynamic> json) {
    return StaffMemberModel(
      id: json['id'] as int? ?? 0,
      name: json['name']?.toString() ?? 'Staff Member',
      role: json['role']?.toString() ?? 'Staff',
      staffRole: json['staff_role']?.toString() ?? json['role']?.toString() ?? 'Staff',
      email: json['email']?.toString(),
      phone: json['phone']?.toString() ?? '',
      status: json['status']?.toString() ?? 'active',
      profilePhotoUrl: json['profile_photo_url']?.toString(),
      photoUrl: json['photo_url']?.toString(),
      branchName: json['branch_name']?.toString(),
      callAction: json['call_action']?.toString(),
      messageAction: json['message_action']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role,
        'staff_role': staffRole,
        'email': email,
        'phone': phone,
        'status': status,
        'profile_photo_url': profilePhotoUrl,
        'photo_url': photoUrl,
        'branch_name': branchName,
        'call_action': callAction,
        'message_action': messageAction,
      };
}

class StaffMetaModel {
  final int page;
  final int limit;
  final int totalPages;
  final int total;

  StaffMetaModel({
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.total,
  });

  factory StaffMetaModel.fromJson(Map<String, dynamic> json) {
    return StaffMetaModel(
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 10,
      totalPages: json['total_pages'] as int? ?? 1,
      total: json['total'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'page': page,
        'limit': limit,
        'total_pages': totalPages,
        'total': total,
      };
}
