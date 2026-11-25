import 'package:flutter/material.dart';

class VisitorItemModel {
  final int id;
  final String passCode;
  final String visitorName;
  final String visitorPhone;
  final String? visitorPhoto;
  final String? visitorPhotoUrl;
  final String purpose;
  final String visitDate;
  final String validUntil;
  final String entryTime;
  final String? exitTime;
  final String? lastEntryTime;
  final String? lastExitTime;
  final String status;
  final bool isOnSite;
  final int totalEntries;
  final String? qrCode;
  final String? adminNotes;
  final String? hostResident;
  final String? roomNo;
  final String? roomType;
  final String? pgName;
  final String? branchName;
  final String? createdAt;
  final String? updatedAt;

  VisitorItemModel({
    required this.id,
    required this.passCode,
    required this.visitorName,
    required this.visitorPhone,
    this.visitorPhoto,
    this.visitorPhotoUrl,
    required this.purpose,
    required this.visitDate,
    required this.validUntil,
    required this.entryTime,
    this.exitTime,
    this.lastEntryTime,
    this.lastExitTime,
    required this.status,
    required this.isOnSite,
    required this.totalEntries,
    this.qrCode,
    this.adminNotes,
    this.hostResident,
    this.roomNo,
    this.roomType,
    this.pgName,
    this.branchName,
    this.createdAt,
    this.updatedAt,
  });

  factory VisitorItemModel.fromJson(Map<String, dynamic> json) {
    final room = json['room'] as Map<String, dynamic>?;
    final pg = json['pg'] as Map<String, dynamic>?;
    final branch = json['branch'] as Map<String, dynamic>?;

    return VisitorItemModel(
      id: json['id'] is num ? (json['id'] as num).toInt() : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      passCode: json['pass_code']?.toString() ?? '',
      visitorName: json['visitor_name']?.toString() ?? 'Visitor',
      visitorPhone: json['visitor_phone']?.toString() ?? '',
      visitorPhoto: json['visitor_photo']?.toString(),
      visitorPhotoUrl: json['visitor_photo_url']?.toString(),
      purpose: json['purpose']?.toString() ?? '',
      visitDate: json['visit_date']?.toString() ?? '',
      validUntil: json['valid_until']?.toString() ?? '',
      entryTime: json['entry_time']?.toString() ?? '',
      exitTime: json['exit_time']?.toString(),
      lastEntryTime: json['last_entry_time']?.toString(),
      lastExitTime: json['last_exit_time']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      isOnSite: json['is_on_site'] == true || json['is_on_site'] == 1,
      totalEntries: json['total_entries'] is num ? (json['total_entries'] as num).toInt() : 0,
      qrCode: json['qr_code']?.toString(),
      adminNotes: json['admin_notes']?.toString(),
      hostResident: json['host_resident']?.toString(),
      roomNo: room?['room_no']?.toString(),
      roomType: room?['room_type']?.toString(),
      pgName: pg?['name']?.toString(),
      branchName: branch?['name']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pass_code': passCode,
      'visitor_name': visitorName,
      'visitor_phone': visitorPhone,
      'visitor_photo': visitorPhoto,
      'visitor_photo_url': visitorPhotoUrl,
      'purpose': purpose,
      'visit_date': visitDate,
      'valid_until': validUntil,
      'entry_time': entryTime,
      'exit_time': exitTime,
      'last_entry_time': lastEntryTime,
      'last_exit_time': lastExitTime,
      'status': status,
      'is_on_site': isOnSite,
      'total_entries': totalEntries,
      'qr_code': qrCode,
      'admin_notes': adminNotes,
      'host_resident': hostResident,
      'room': {
        'room_no': roomNo,
        'room_type': roomType,
      },
      'pg': {
        'name': pgName,
      },
      'branch': {
        'name': branchName,
      },
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  String get initials {
    final trimmed = visitorName.trim();
    if (trimmed.isEmpty) return 'V';
    final parts = trimmed.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  String get displayStatus {
    if (status.isEmpty) return 'Pending';
    final s = status.toLowerCase();
    if (s == 'active' || s == 'approved') return 'Approved';
    final clean = status.replaceAll('-', '_');
    return clean.split('_').where((w) => w.isNotEmpty).map((w) {
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');
  }

  bool get isPending => status.toLowerCase() == 'pending';

  bool get isApproved =>
      status.toLowerCase() == 'approved' ||
      status.toLowerCase() == 'active';

  bool get isInOffice =>
      status.toLowerCase() == 'in_office' ||
      status.toLowerCase() == 'in-office' ||
      status.toLowerCase() == 'inoffice';

  bool get isRejected => status.toLowerCase() == 'rejected';

  bool get isCancelled => status.toLowerCase() == 'cancelled';

  bool get isCompleted =>
      status.toLowerCase() == 'completed' ||
      status.toLowerCase() == 'checked_out';

  /// Active covers visitors who are currently approved, in office, on site, or active
  bool get isActive =>
      !isPending &&
      !isRejected &&
      !isCancelled &&
      (isApproved ||
          isInOffice ||
          isOnSite ||
          status.toLowerCase() == 'active' ||
          status.toLowerCase() == 'checked_in');

  Color get statusBgColor {
    switch (status.toLowerCase()) {
      case 'in_office':
      case 'in-office':
      case 'inoffice':
      case 'checked_in':
        return const Color(0xFFE0F2FE);
      case 'active':
      case 'approved':
        return const Color(0xFFD1FAE5);
      case 'pending':
        return const Color(0xFFFEF3C7);
      case 'completed':
      case 'checked_out':
        return const Color(0xFFF3F4F6);
      case 'rejected':
      case 'cancelled':
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFE0F2FE);
    }
  }

  Color get statusTextColor {
    switch (status.toLowerCase()) {
      case 'in_office':
      case 'in-office':
      case 'inoffice':
      case 'checked_in':
        return const Color(0xFF0284C7);
      case 'active':
      case 'approved':
        return const Color(0xFF059669);
      case 'pending':
        return const Color(0xFFD97706);
      case 'completed':
      case 'checked_out':
        return const Color(0xFF4B5563);
      case 'rejected':
      case 'cancelled':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF0284C7);
    }
  }

  String get formattedVisitInfo {
    final datePart = visitDate.isNotEmpty ? visitDate.split(' ').first : '';
    final timePart = entryTime.isNotEmpty ? entryTime : '';
    if (datePart.isNotEmpty && timePart.isNotEmpty) {
      return '$datePart, $timePart';
    }
    return datePart.isNotEmpty ? datePart : timePart;
  }
}
