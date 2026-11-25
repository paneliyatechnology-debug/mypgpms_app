import 'package:flutter/material.dart';

class DashboardResponseModel {
  final bool success;
  final String? message;
  final DashboardDataModel? data;

  DashboardResponseModel({
    required this.success,
    this.message,
    this.data,
  });

  factory DashboardResponseModel.fromJson(Map<String, dynamic> json) {
    return DashboardResponseModel(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      data: json['data'] != null && json['data'] is Map<String, dynamic>
          ? DashboardDataModel.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        'data': data?.toJson(),
      };
}

class DashboardDataModel {
  final String? role;
  final GreetingModel? greeting;
  final StayModel? stay;
  final RentDueModel? rentDue;
  final NextEventModel? nextEvent;
  final GatePassModel? gatePass;
  final List<QuickActionModel>? quickActions;
  final List<TodayMenuModel> todayMenu;
  final RecentComplaintModel? recentComplaint;
  final LatestNoticeModel? latestNotice;
  final int unreadNotificationsCount;

  TodayMenuModel? get todayMenuSingle => todayMenu.isNotEmpty ? todayMenu.first : null;

  DashboardDataModel({
    this.role,
    this.greeting,
    this.stay,
    this.rentDue,
    this.nextEvent,
    this.gatePass,
    this.quickActions,
    this.todayMenu = const [],
    this.recentComplaint,
    this.latestNotice,
    this.unreadNotificationsCount = 0,
  });

  factory DashboardDataModel.fromJson(Map<String, dynamic> json) {
    List<QuickActionModel>? actions;
    if (json['quick_actions'] is List) {
      actions = (json['quick_actions'] as List)
          .whereType<Map<String, dynamic>>()
          .map((item) => QuickActionModel.fromJson(item))
          .toList();
    }

    List<TodayMenuModel> menuList = [];
    if (json['today_menu'] is List) {
      menuList = (json['today_menu'] as List)
          .whereType<Map<String, dynamic>>()
          .map((item) => TodayMenuModel.fromJson(item))
          .toList();
    } else if (json['today_menu'] is Map<String, dynamic>) {
      menuList.add(TodayMenuModel.fromJson(json['today_menu'] as Map<String, dynamic>));
    }

    return DashboardDataModel(
      role: json['role']?.toString(),
      greeting: json['greeting'] is Map<String, dynamic>
          ? GreetingModel.fromJson(json['greeting'] as Map<String, dynamic>)
          : null,
      stay: json['stay'] is Map<String, dynamic>
          ? StayModel.fromJson(json['stay'] as Map<String, dynamic>)
          : null,
      rentDue: json['rent_due'] is Map<String, dynamic>
          ? RentDueModel.fromJson(json['rent_due'] as Map<String, dynamic>)
          : null,
      nextEvent: json['next_event'] is Map<String, dynamic>
          ? NextEventModel.fromJson(json['next_event'] as Map<String, dynamic>)
          : null,
      gatePass: json['gate_pass'] is Map<String, dynamic>
          ? GatePassModel.fromJson(json['gate_pass'] as Map<String, dynamic>)
          : null,
      quickActions: actions,
      todayMenu: menuList,
      recentComplaint: json['recent_complaint'] is Map<String, dynamic>
          ? RecentComplaintModel.fromJson(json['recent_complaint'] as Map<String, dynamic>)
          : null,
      latestNotice: json['latest_notice'] is Map<String, dynamic>
          ? LatestNoticeModel.fromJson(json['latest_notice'] as Map<String, dynamic>)
          : null,
      unreadNotificationsCount: json['unread_notifications_count'] is num
          ? (json['unread_notifications_count'] as num).toInt()
          : (int.tryParse(json['unread_notifications_count']?.toString() ?? '0') ?? 0),
    );
  }

  Map<String, dynamic> toJson() => {
        'role': role,
        'greeting': greeting?.toJson(),
        'stay': stay?.toJson(),
        'rent_due': rentDue?.toJson(),
        'next_event': nextEvent?.toJson(),
        'gate_pass': gatePass?.toJson(),
        'quick_actions': quickActions?.map((e) => e.toJson()).toList(),
        'today_menu': todayMenu.map((e) => e.toJson()).toList(),
        'recent_complaint': recentComplaint?.toJson(),
        'latest_notice': latestNotice?.toJson(),
        'unread_notifications_count': unreadNotificationsCount,
      };
}

class GreetingModel {
  final String? salutation;
  final String? residentName;
  final String? subtitle;
  final String? photoUrl;

  GreetingModel({
    this.salutation,
    this.residentName,
    this.subtitle,
    this.photoUrl,
  });

  factory GreetingModel.fromJson(Map<String, dynamic> json) {
    return GreetingModel(
      salutation: json['salutation']?.toString(),
      residentName: json['resident_name']?.toString(),
      subtitle: json['subtitle']?.toString(),
      photoUrl: json['photo_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'salutation': salutation,
        'resident_name': residentName,
        'subtitle': subtitle,
        'photo_url': photoUrl,
      };
}

class StayModel {
  final String? pgName;
  final String? roomNo;
  final String? bedNumber;
  final String? branchName;
  final String? bannerImage;

  StayModel({
    this.pgName,
    this.roomNo,
    this.bedNumber,
    this.branchName,
    this.bannerImage,
  });

  factory StayModel.fromJson(Map<String, dynamic> json) {
    return StayModel(
      pgName: json['pg_name']?.toString(),
      roomNo: json['room_no']?.toString(),
      bedNumber: json['bed_number']?.toString(),
      branchName: json['branch_name']?.toString(),
      bannerImage: json['banner_image']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'pg_name': pgName,
        'room_no': roomNo,
        'bed_number': bedNumber,
        'branch_name': branchName,
        'banner_image': bannerImage,
      };
}

class RentDueModel {
  final int? paymentId;
  final int? amount;
  final String? formatted;
  final String? dueDate;
  final String? dueDateFormatted;
  final String? status;

  RentDueModel({
    this.paymentId,
    this.amount,
    this.formatted,
    this.dueDate,
    this.dueDateFormatted,
    this.status,
  });

  factory RentDueModel.fromJson(Map<String, dynamic> json) {
    return RentDueModel(
      paymentId: json['payment_id'] is num ? (json['payment_id'] as num).toInt() : null,
      amount: json['amount'] is num ? (json['amount'] as num).toInt() : null,
      formatted: json['formatted']?.toString(),
      dueDate: json['due_date']?.toString(),
      dueDateFormatted: json['due_date_formatted']?.toString(),
      status: json['status']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'payment_id': paymentId,
        'amount': amount,
        'formatted': formatted,
        'due_date': dueDate,
        'due_date_formatted': dueDateFormatted,
        'status': status,
      };

  String get displayStatus {
    final s = (status ?? '').trim().toLowerCase();
    switch (s) {
      case 'in_review':
      case 'in review':
      case 'under_review':
        return 'In Review';
      case 'paid':
      case 'completed':
      case 'success':
        return 'Paid';
      case 'pending':
      case 'due':
        return 'Pending';
      case 'failed':
      case 'rejected':
        return 'Failed';
      default:
        if (s.isEmpty) return 'Pending';
        return s.replaceAll('_', ' ').split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
    }
  }

  Color get statusBgColor {
    final s = (status ?? '').trim().toLowerCase();
    switch (s) {
      case 'paid':
      case 'completed':
      case 'success':
        return const Color(0xFFD1FAE5);
      case 'in_review':
      case 'in review':
      case 'under_review':
        return const Color(0xFFDBEAFE);
      case 'pending':
      case 'due':
        return const Color(0xFFFEF3C7);
      case 'failed':
      case 'rejected':
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  Color get statusTextColor {
    final s = (status ?? '').trim().toLowerCase();
    switch (s) {
      case 'paid':
      case 'completed':
      case 'success':
        return const Color(0xFF059669);
      case 'in_review':
      case 'in review':
      case 'under_review':
        return const Color(0xFF2563EB);
      case 'pending':
      case 'due':
        return const Color(0xFFD97706);
      case 'failed':
      case 'rejected':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF6B7280);
    }
  }

  bool get isPending {
    final s = (status ?? '').trim().toLowerCase();
    return s == 'pending' || s == 'due';
  }

  bool get isInReview {
    final s = (status ?? '').trim().toLowerCase();
    return s == 'in_review' || s == 'in review' || s == 'under_review';
  }

  bool get isPaid {
    final s = (status ?? '').trim().toLowerCase();
    return s == 'paid' || s == 'completed' || s == 'success';
  }
}

class NextEventModel {
  final int? id;
  final String? title;
  final String? dateFormatted;
  final String? image;

  NextEventModel({
    this.id,
    this.title,
    this.dateFormatted,
    this.image,
  });

  factory NextEventModel.fromJson(Map<String, dynamic> json) {
    return NextEventModel(
      id: json['id'] is num ? (json['id'] as num).toInt() : null,
      title: json['title']?.toString(),
      dateFormatted: json['date_formatted']?.toString(),
      image: json['image']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'date_formatted': dateFormatted,
        'image': image,
      };
}

class GatePassModel {
  final String? qrCode;
  final String? status;

  GatePassModel({this.qrCode, this.status});

  factory GatePassModel.fromJson(Map<String, dynamic> json) {
    return GatePassModel(
      qrCode: json['qr_code']?.toString(),
      status: json['status']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'qr_code': qrCode,
        'status': status,
      };
}

class QuickActionModel {
  final String key;
  final String label;
  final String? icon;

  QuickActionModel({
    required this.key,
    required this.label,
    this.icon,
  });

  factory QuickActionModel.fromJson(Map<String, dynamic> json) {
    return QuickActionModel(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      icon: json['icon']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'label': label,
        'icon': icon,
      };
}

class TodayMenuModel {
  final int? id;
  final int? branchId;
  final String? mealType;
  final String? rawMealType;
  final String? foodName;
  final String? name;
  final String? description;
  final String? items;
  final String? includedItems;
  final String? startTime;
  final String? endTime;
  final String? timings;
  final String? image;
  final String? imageUrl;
  final String? dayOfWeek;
  final String? menuDate;
  final bool isActive;

  TodayMenuModel({
    this.id,
    this.branchId,
    this.mealType,
    this.rawMealType,
    this.foodName,
    this.name,
    this.description,
    this.items,
    this.includedItems,
    this.startTime,
    this.endTime,
    this.timings,
    this.image,
    this.imageUrl,
    this.dayOfWeek,
    this.menuDate,
    this.isActive = true,
  });

  factory TodayMenuModel.fromJson(Map<String, dynamic> json) {
    return TodayMenuModel(
      id: json['id'] as int? ?? int.tryParse(json['id']?.toString() ?? ''),
      branchId: json['branch_id'] as int? ?? int.tryParse(json['branch_id']?.toString() ?? ''),
      mealType: (json['meal_type'] ?? json['type'] ?? json['title'])?.toString(),
      rawMealType: json['raw_meal_type']?.toString(),
      foodName: json['food_name']?.toString(),
      name: (json['name'] ?? json['food_name'])?.toString(),
      description: json['description']?.toString(),
      items: (json['items'] ?? json['menu'] ?? json['food'])?.toString(),
      includedItems: json['included_items']?.toString(),
      startTime: json['start_time']?.toString(),
      endTime: json['end_time']?.toString(),
      timings: (json['timings'] ??
          (json['start_time'] != null && json['end_time'] != null
              ? '${json['start_time']} - ${json['end_time']}'
              : json['time']))?.toString(),
      image: json['image']?.toString(),
      imageUrl: (json['image_url'] ?? json['image'])?.toString(),
      dayOfWeek: json['day_of_week']?.toString(),
      menuDate: json['menu_date']?.toString(),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (branchId != null) 'branch_id': branchId,
        'meal_type': mealType,
        'raw_meal_type': rawMealType,
        'food_name': foodName,
        'name': name,
        'description': description,
        'items': items,
        'included_items': includedItems,
        'start_time': startTime,
        'end_time': endTime,
        'timings': timings,
        'image': image,
        'image_url': imageUrl,
        'day_of_week': dayOfWeek,
        'menu_date': menuDate,
        'is_active': isActive,
      };
}

class RecentComplaintModel {
  final int? id;
  final String? ticketNo;
  final String? title;
  final String? status;
  final String? dateFormatted;
  final String? roomNo;
  final String? locationAndTime;

  RecentComplaintModel({
    this.id,
    this.ticketNo,
    this.title,
    this.status,
    this.dateFormatted,
    this.roomNo,
    this.locationAndTime,
  });

  factory RecentComplaintModel.fromJson(Map<String, dynamic> json) {
    return RecentComplaintModel(
      id: json['id'] as int? ?? int.tryParse(json['id']?.toString() ?? ''),
      ticketNo: (json['ticket_no'] ?? json['ticket_number'] ?? json['complaint_id'])?.toString(),
      title: json['title']?.toString(),
      status: json['status']?.toString(),
      dateFormatted: (json['date_formatted'] ?? json['created_at'])?.toString(),
      roomNo: json['room_no']?.toString(),
      locationAndTime: json['location_and_time']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'ticket_no': ticketNo,
        'title': title,
        'status': status,
        'date_formatted': dateFormatted,
        'room_no': roomNo,
        if (locationAndTime != null) 'location_and_time': locationAndTime,
      };
}

class LatestNoticeModel {
  final int? id;
  final String? category;
  final String? priority;
  final String? title;
  final String? summary;
  final String? dateTime;
  final String? tag;
  final String? subtitle;
  final String? dateFormatted;

  LatestNoticeModel({
    this.id,
    this.category,
    this.priority,
    this.title,
    this.summary,
    this.dateTime,
    this.tag,
    this.subtitle,
    this.dateFormatted,
  });

  factory LatestNoticeModel.fromJson(Map<String, dynamic> json) {
    final cat = (json['category'] ?? json['tag'])?.toString();
    final pri = json['priority']?.toString();
    final tit = json['title']?.toString();
    final sum = (json['summary'] ?? json['subtitle'] ?? json['description'] ?? json['content'])?.toString();
    final dt = (json['date_time'] ?? json['date_formatted'] ?? json['created_at'])?.toString();

    return LatestNoticeModel(
      id: json['id'] is num ? (json['id'] as num).toInt() : int.tryParse(json['id']?.toString() ?? ''),
      category: cat,
      priority: pri,
      title: tit,
      summary: sum,
      dateTime: dt,
      tag: cat,
      subtitle: sum,
      dateFormatted: dt,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (category != null) 'category': category,
        if (priority != null) 'priority': priority,
        if (title != null) 'title': title,
        if (summary != null) 'summary': summary,
        if (dateTime != null) 'date_time': dateTime,
        if (tag != null) 'tag': tag,
        if (subtitle != null) 'subtitle': subtitle,
        if (dateFormatted != null) 'date_formatted': dateFormatted,
      };

  String get displayCategory {
    if (category != null && category!.trim().isNotEmpty) {
      return category!.trim();
    }
    return 'Notice';
  }

  String get displayPriority {
    final p = (priority ?? '').trim().toLowerCase();
    if (p == 'high' || p == 'urgent') return 'High';
    if (p == 'medium') return 'Medium';
    if (p == 'low') return 'Low';
    return '';
  }

  bool get isHighPriority {
    final p = (priority ?? '').trim().toLowerCase();
    return p == 'high' || p == 'urgent';
  }

  IconData get icon {
    final c = (category ?? '').toLowerCase();
    final p = (priority ?? '').toLowerCase();
    if (c.contains('safety') || c.contains('security')) {
      return Icons.shield_outlined;
    }
    if (p == 'high' || p == 'urgent' || c == 'important') {
      return Icons.notifications_active_outlined;
    }
    if (c.contains('event')) {
      return Icons.event_outlined;
    }
    if (c.contains('maintenance')) {
      return Icons.build_outlined;
    }
    return Icons.campaign_outlined;
  }

  Color get iconBg {
    final c = (category ?? '').toLowerCase();
    final p = (priority ?? '').toLowerCase();
    if (c.contains('safety') || c.contains('security')) {
      return const Color(0xFFFFEDD5);
    }
    if (p == 'high' || p == 'urgent' || c == 'important') {
      return const Color(0xFFFEE2E2);
    }
    if (c.contains('event')) {
      return const Color(0xFFE0E7FF);
    }
    if (c.contains('maintenance')) {
      return const Color(0xFFFEF3C7);
    }
    return const Color(0xFFE8F3ED);
  }

  Color get iconColor {
    final c = (category ?? '').toLowerCase();
    final p = (priority ?? '').toLowerCase();
    if (c.contains('safety') || c.contains('security')) {
      return const Color(0xFFEA580C);
    }
    if (p == 'high' || p == 'urgent' || c == 'important') {
      return const Color(0xFFDC2626);
    }
    if (c.contains('event')) {
      return const Color(0xFF3B82F6);
    }
    if (c.contains('maintenance')) {
      return const Color(0xFFD97706);
    }
    return const Color(0xFF146A4F);
  }
}
