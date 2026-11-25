import 'package:flutter/material.dart';

class ComplaintListResponseModel {
  final bool success;
  final String? message;
  final List<ComplaintItemModel> data;
  final ComplaintMetaModel? meta;

  ComplaintListResponseModel({
    required this.success,
    this.message,
    this.data = const [],
    this.meta,
  });

  factory ComplaintListResponseModel.fromJson(Map<String, dynamic> json) {
    List<ComplaintItemModel> list = [];
    if (json['data'] is List) {
      list = (json['data'] as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => ComplaintItemModel.fromJson(e))
          .toList();
    }
    return ComplaintListResponseModel(
      success: json['success'] as bool? ?? false,
      message: json['message']?.toString(),
      data: list,
      meta: json['meta'] is Map<String, dynamic>
          ? ComplaintMetaModel.fromJson(json['meta'] as Map<String, dynamic>)
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

class ComplaintItemModel {
  final int id;
  final String complaintNumber;
  final String title;
  final String description;
  final ComplaintCategoryInfo? category;
  final ComplaintLocationInfo? location;
  final ComplaintResidentInfo? resident;
  final String status;
  final bool isOverdue;
  final String? dueDate;
  final dynamic assignedTo;
  final String? resolutionNotes;
  final String? resolvedAt;
  final List<ComplaintAttachmentModel> attachments;
  final List<ComplaintTimelineModel> timeline;
  final String createdAt;
  final String updatedAt;

  ComplaintItemModel({
    required this.id,
    required this.complaintNumber,
    required this.title,
    required this.description,
    this.category,
    this.location,
    this.resident,
    required this.status,
    this.isOverdue = false,
    this.dueDate,
    this.assignedTo,
    this.resolutionNotes,
    this.resolvedAt,
    this.attachments = const [],
    this.timeline = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  String get displayId => complaintNumber.isNotEmpty ? '#$complaintNumber' : '#CL-$id';

  String get displayStatus {
    final s = status.toUpperCase();
    if (s == 'OPEN' || s == 'PENDING') return 'Pending';
    if (s == 'IN_PROGRESS' || s == 'INPROGRESS') return 'In Progress';
    if (s == 'RESOLVED') return 'Resolved';
    if (s == 'CLOSED') return 'Closed';
    return status;
  }

  Color get statusTextColor {
    final s = displayStatus.toLowerCase();
    if (s == 'in progress') return const Color(0xFF4F46E5);
    if (s == 'pending' || s == 'open') return const Color(0xFFD97706);
    if (s == 'resolved' || s == 'closed') return const Color(0xFF059669);
    return const Color(0xFF4B5563);
  }

  Color get statusBgColor {
    final s = displayStatus.toLowerCase();
    if (s == 'in progress') return const Color(0xFFEEF2FF);
    if (s == 'pending' || s == 'open') return const Color(0xFFFEF3C7);
    if (s == 'resolved' || s == 'closed') return const Color(0xFFD1FAE5);
    return const Color(0xFFF3F4F6);
  }

  String get displayLocation {
    final room = location?.roomNo ?? '101';
    final date = createdAt.isNotEmpty ? createdAt : 'Recent';
    return 'Room $room   •   $date';
  }

  IconData get categoryIcon {
    final name = category?.name.toLowerCase() ?? '';
    final key = category?.key?.toLowerCase() ?? '';
    final combined = '$name $key';

    if (combined.contains('clean') || combined.contains('housekeep')) return Icons.cleaning_services_outlined;
    if (name == 'ac' || combined.contains('air') || (combined.contains('ac') && !combined.contains('wash'))) return Icons.ac_unit_rounded;
    if (combined.contains('food') || combined.contains('mess') || combined.contains('meal') || combined.contains('dining')) return Icons.restaurant_outlined;
    if (combined.contains('furnit') || combined.contains('bed') || combined.contains('chair') || combined.contains('sofa')) return Icons.weekend_outlined;
    if (combined.contains('wifi') || combined.contains('internet')) return Icons.wifi_rounded;
    if (combined.contains('water')) return Icons.water_drop_outlined;
    if (combined.contains('electr') || combined.contains('power')) return Icons.bolt_rounded;
    if (combined.contains('plumb') || combined.contains('drain') || combined.contains('pipe')) return Icons.plumbing_rounded;
    if (combined.contains('wash') || combined.contains('laundry')) return Icons.local_laundry_service_outlined;
    if (combined.contains('applian') || combined.contains('fridge')) return Icons.kitchen_outlined;
    return Icons.report_problem_outlined;
  }

  factory ComplaintItemModel.fromJson(Map<String, dynamic> json) {
    List<ComplaintAttachmentModel> attachList = [];
    if (json['attachments'] is List) {
      attachList = (json['attachments'] as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => ComplaintAttachmentModel.fromJson(e))
          .toList();
    }

    List<ComplaintTimelineModel> timelineList = [];
    if (json['timeline'] is List) {
      timelineList = (json['timeline'] as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => ComplaintTimelineModel.fromJson(e))
          .toList();
    }

    return ComplaintItemModel(
      id: json['id'] as int? ?? 0,
      complaintNumber: json['complaint_number']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Complaint',
      description: json['description']?.toString() ?? '',
      category: json['category'] is Map<String, dynamic>
          ? ComplaintCategoryInfo.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      location: json['location'] is Map<String, dynamic>
          ? ComplaintLocationInfo.fromJson(json['location'] as Map<String, dynamic>)
          : null,
      resident: json['resident'] is Map<String, dynamic>
          ? ComplaintResidentInfo.fromJson(json['resident'] as Map<String, dynamic>)
          : null,
      status: json['status']?.toString() ?? 'OPEN',
      isOverdue: json['is_overdue'] as bool? ?? false,
      dueDate: json['due_date']?.toString(),
      assignedTo: json['assigned_to'],
      resolutionNotes: json['resolution_notes']?.toString(),
      resolvedAt: json['resolved_at']?.toString(),
      attachments: attachList,
      timeline: timelineList,
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'complaint_number': complaintNumber,
        'title': title,
        'description': description,
        if (category != null) 'category': category!.toJson(),
        if (location != null) 'location': location!.toJson(),
        if (resident != null) 'resident': resident!.toJson(),
        'status': status,
        'is_overdue': isOverdue,
        'due_date': dueDate,
        'assigned_to': assignedTo,
        'resolution_notes': resolutionNotes,
        'resolved_at': resolvedAt,
        'attachments': attachments.map((e) => e.toJson()).toList(),
        'timeline': timeline.map((e) => e.toJson()).toList(),
        'created_at': createdAt,
        'updated_at': updatedAt,
      };
}

class ComplaintCategoryInfo {
  final int id;
  final String name;
  final String? key;
  final String? icon;

  ComplaintCategoryInfo({
    required this.id,
    required this.name,
    this.key,
    this.icon,
  });

  factory ComplaintCategoryInfo.fromJson(Map<String, dynamic> json) {
    return ComplaintCategoryInfo(
      id: json['id'] as int? ?? 0,
      name: json['name']?.toString() ?? '',
      key: json['key']?.toString(),
      icon: json['icon']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'key': key,
        'icon': icon,
      };
}

class ComplaintLocationInfo {
  final int? roomId;
  final String? roomNo;
  final int? floorNumber;
  final String? buildingName;
  final String? branchName;

  ComplaintLocationInfo({
    this.roomId,
    this.roomNo,
    this.floorNumber,
    this.buildingName,
    this.branchName,
  });

  factory ComplaintLocationInfo.fromJson(Map<String, dynamic> json) {
    return ComplaintLocationInfo(
      roomId: json['room_id'] as int?,
      roomNo: json['room_no']?.toString(),
      floorNumber: json['floor_number'] as int?,
      buildingName: json['building_name']?.toString(),
      branchName: json['branch_name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'room_id': roomId,
        'room_no': roomNo,
        'floor_number': floorNumber,
        'building_name': buildingName,
        'branch_name': branchName,
      };
}

class ComplaintResidentInfo {
  final int id;
  final String name;
  final String? phone;

  ComplaintResidentInfo({
    required this.id,
    required this.name,
    this.phone,
  });

  factory ComplaintResidentInfo.fromJson(Map<String, dynamic> json) {
    return ComplaintResidentInfo(
      id: json['id'] as int? ?? 0,
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
      };
}

class ComplaintAttachmentModel {
  final int id;
  final String fileName;
  final String fileUrl;
  final String? fileType;
  final int? fileSize;
  final String? createdAt;

  ComplaintAttachmentModel({
    required this.id,
    required this.fileName,
    required this.fileUrl,
    this.fileType,
    this.fileSize,
    this.createdAt,
  });

  bool get isVideo {
    final type = fileType?.toLowerCase() ?? '';
    if (type.contains('video')) return true;
    final lowerName = fileName.toLowerCase();
    final lowerUrl = fileUrl.toLowerCase();
    return lowerName.endsWith('.mp4') ||
        lowerName.endsWith('.mov') ||
        lowerName.endsWith('.mkv') ||
        lowerName.endsWith('.avi') ||
        lowerName.endsWith('.webm') ||
        lowerName.endsWith('.3gp') ||
        lowerUrl.endsWith('.mp4') ||
        lowerUrl.endsWith('.mov') ||
        lowerUrl.endsWith('.mkv') ||
        lowerUrl.endsWith('.avi') ||
        lowerUrl.endsWith('.webm') ||
        lowerUrl.endsWith('.3gp') ||
        lowerUrl.contains('.mp4') ||
        lowerUrl.contains('.mov');
  }

  factory ComplaintAttachmentModel.fromJson(Map<String, dynamic> json) {
    return ComplaintAttachmentModel(
      id: json['id'] as int? ?? 0,
      fileName: json['file_name']?.toString() ?? '',
      fileUrl: json['file_url']?.toString() ?? '',
      fileType: json['file_type']?.toString(),
      fileSize: json['file_size'] as int?,
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'file_name': fileName,
        'file_url': fileUrl,
        if (fileType != null) 'file_type': fileType,
        if (fileSize != null) 'file_size': fileSize,
        if (createdAt != null) 'created_at': createdAt,
      };
}

class ComplaintTimelineModel {
  final int id;
  final String eventType;
  final String description;
  final String? oldValue;
  final String? newValue;
  final ComplaintPerformedBy? performedBy;
  final String createdAt;

  ComplaintTimelineModel({
    required this.id,
    required this.eventType,
    required this.description,
    this.oldValue,
    this.newValue,
    this.performedBy,
    required this.createdAt,
  });

  factory ComplaintTimelineModel.fromJson(Map<String, dynamic> json) {
    return ComplaintTimelineModel(
      id: json['id'] as int? ?? 0,
      eventType: json['event_type']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      oldValue: json['old_value']?.toString(),
      newValue: json['new_value']?.toString(),
      performedBy: json['performed_by'] is Map<String, dynamic>
          ? ComplaintPerformedBy.fromJson(json['performed_by'] as Map<String, dynamic>)
          : null,
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'event_type': eventType,
        'description': description,
        if (oldValue != null) 'old_value': oldValue,
        if (newValue != null) 'new_value': newValue,
        if (performedBy != null) 'performed_by': performedBy!.toJson(),
        'created_at': createdAt,
      };
}

class ComplaintPerformedBy {
  final int id;
  final String name;
  final String role;

  ComplaintPerformedBy({
    required this.id,
    required this.name,
    required this.role,
  });

  factory ComplaintPerformedBy.fromJson(Map<String, dynamic> json) {
    return ComplaintPerformedBy(
      id: json['id'] as int? ?? 0,
      name: json['name']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role,
      };
}

class ComplaintDetailsResponseModel {
  final bool success;
  final String? message;
  final ComplaintItemModel? data;

  ComplaintDetailsResponseModel({
    required this.success,
    this.message,
    this.data,
  });

  factory ComplaintDetailsResponseModel.fromJson(Map<String, dynamic> json) {
    return ComplaintDetailsResponseModel(
      success: json['success'] as bool? ?? false,
      message: json['message']?.toString(),
      data: json['data'] is Map<String, dynamic>
          ? ComplaintItemModel.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        if (data != null) 'data': data!.toJson(),
      };
}

class ComplaintMetaModel {
  final int page;
  final int limit;
  final int totalPages;
  final int total;

  ComplaintMetaModel({
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.total,
  });

  factory ComplaintMetaModel.fromJson(Map<String, dynamic> json) {
    return ComplaintMetaModel(
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
