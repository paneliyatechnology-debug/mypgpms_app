import 'package:flutter/material.dart';

class NoticesResponseModel {
  final bool success;
  final String? message;
  final List<NoticeItemModel> data;
  final NoticesMetaModel? meta;

  NoticesResponseModel({
    required this.success,
    this.message,
    this.data = const [],
    this.meta,
  });

  factory NoticesResponseModel.fromJson(Map<String, dynamic> json) {
    List<NoticeItemModel> items = [];
    if (json['data'] is List) {
      for (final raw in (json['data'] as List)) {
        if (raw is Map) {
          try {
            items.add(NoticeItemModel.fromJson(Map<String, dynamic>.from(raw)));
          } catch (_) {}
        }
      }
    }

    return NoticesResponseModel(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      data: items,
      meta: json['meta'] is Map
          ? NoticesMetaModel.fromJson(Map<String, dynamic>.from(json['meta'] as Map))
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        'data': data.map((e) => e.toJson()).toList(),
        'meta': meta?.toJson(),
      };
}

class NoticeDetailsResponseModel {
  final bool success;
  final String? message;
  final NoticeItemModel? data;

  NoticeDetailsResponseModel({
    required this.success,
    this.message,
    this.data,
  });

  factory NoticeDetailsResponseModel.fromJson(Map<String, dynamic> json) {
    return NoticeDetailsResponseModel(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      data: json['data'] is Map ? NoticeItemModel.fromJson(Map<String, dynamic>.from(json['data'] as Map)) : null,
    );
  }
}

class NoticeAttachmentModel {
  final String fileName;
  final String? rawFileName;
  final String fileUrl;
  final String? fileSize;
  final String? fileMime;

  NoticeAttachmentModel({
    required this.fileName,
    this.rawFileName,
    required this.fileUrl,
    this.fileSize,
    this.fileMime,
  });

  factory NoticeAttachmentModel.fromJson(Map<String, dynamic> json) {
    return NoticeAttachmentModel(
      fileName: json['file_name']?.toString() ?? json['filename']?.toString() ?? 'Attachment',
      rawFileName: json['raw_file_name']?.toString(),
      fileUrl: json['file_url']?.toString() ?? '',
      fileSize: json['file_size']?.toString(),
      fileMime: json['file_mime']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'file_name': fileName,
        'raw_file_name': rawFileName,
        'file_url': fileUrl,
        'file_size': fileSize,
        'file_mime': fileMime,
      };

  bool get isImage {
    final mime = (fileMime ?? '').toLowerCase();
    final url = fileUrl.toLowerCase();
    final name = fileName.toLowerCase();
    return mime.startsWith('image/') ||
        url.endsWith('.png') ||
        url.endsWith('.jpg') ||
        url.endsWith('.jpeg') ||
        url.endsWith('.webp') ||
        name.endsWith('.png') ||
        name.endsWith('.jpg') ||
        name.endsWith('.jpeg');
  }

  bool get isPdf {
    final mime = (fileMime ?? '').toLowerCase();
    final url = fileUrl.toLowerCase();
    final name = fileName.toLowerCase();
    return mime.contains('pdf') || url.endsWith('.pdf') || name.endsWith('.pdf');
  }
}

class NoticeItemModel {
  final int id;
  final String title;
  final String category;
  final String? priority;
  final String? summary;
  final String? content;
  final String? dateTime;
  final String? sentAt;
  final bool isRead;
  final String? readAt;
  final bool hasAttachment;
  final NoticeAttachmentModel? attachment;

  NoticeItemModel({
    required this.id,
    required this.title,
    required this.category,
    this.priority,
    this.summary,
    this.content,
    this.dateTime,
    this.sentAt,
    this.isRead = false,
    this.readAt,
    this.hasAttachment = false,
    this.attachment,
  });

  factory NoticeItemModel.fromJson(Map<String, dynamic> json) {
    NoticeAttachmentModel? attachmentObj;
    if (json['attachment'] is Map) {
      try {
        attachmentObj = NoticeAttachmentModel.fromJson(Map<String, dynamic>.from(json['attachment'] as Map));
      } catch (_) {}
    } else if (json['attachment'] is String && (json['attachment'] as String).isNotEmpty) {
      attachmentObj = NoticeAttachmentModel(
        fileName: (json['attachment'] as String).split('/').last,
        fileUrl: json['attachment'] as String,
      );
    }

    return NoticeItemModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      category: json['category']?.toString() ?? 'General',
      priority: json['priority']?.toString(),
      summary: json['summary']?.toString(),
      content: json['content']?.toString(),
      dateTime: json['date_time']?.toString(),
      sentAt: json['sent_at']?.toString(),
      isRead: json['is_read'] as bool? ?? false,
      readAt: json['read_at']?.toString(),
      hasAttachment: json['has_attachment'] as bool? ?? (attachmentObj != null),
      attachment: attachmentObj,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'priority': priority,
        'summary': summary,
        'content': content,
        'date_time': dateTime,
        'sent_at': sentAt,
        'is_read': isRead,
        'read_at': readAt,
        'has_attachment': hasAttachment,
        'attachment': attachment?.toJson(),
      };

  IconData get icon {
    final cat = category.toLowerCase();
    final pri = (priority ?? '').toLowerCase();

    if (cat.contains('maintenance')) {
      return Icons.handyman_rounded;
    }
    if (cat.contains('safety') || cat.contains('security')) {
      return Icons.shield_rounded;
    }
    if (cat.contains('event')) {
      return Icons.celebration_rounded;
    }
    if (cat.contains('wifi') || cat.contains('internet')) {
      return Icons.wifi_rounded;
    }
    if (cat.contains('water') || cat.contains('plumb')) {
      return Icons.water_drop_rounded;
    }
    if (cat.contains('electric') || cat.contains('power')) {
      return Icons.bolt_rounded;
    }
    if (cat.contains('clean') || cat.contains('room')) {
      return Icons.cleaning_services_rounded;
    }
    if (pri == 'high' || pri == 'urgent' || cat == 'important') {
      return Icons.notifications_active_rounded;
    }
    return Icons.campaign_rounded;
  }

  Color get iconBg {
    final cat = category.toLowerCase();

    if (cat.contains('maintenance')) {
      return const Color(0xFFE8F5E9); // Light green
    }
    if (cat.contains('safety') || cat.contains('security')) {
      return const Color(0xFFFFF7ED); // Light warm amber
    }
    if (cat.contains('event')) {
      return const Color(0xFFEEF2FF); // Light indigo
    }
    if (cat.contains('wifi') || cat.contains('internet')) {
      return const Color(0xFFE0F2FE); // Light sky blue
    }
    if (cat.contains('water')) {
      return const Color(0xFFE0F2FE); // Light cyan
    }
    if (cat.contains('electric')) {
      return const Color(0xFFFEF3C7); // Light amber
    }
    if (cat.contains('clean') || cat.contains('room')) {
      return const Color(0xFFF3E8FF); // Light purple
    }
    final pri = (priority ?? '').toLowerCase();
    if (pri == 'high' || pri == 'urgent' || cat == 'important') {
      return const Color(0xFFFEE2E2); // Light red
    }
    return const Color(0xFFE8F3ED); // Light sage green
  }

  Color get iconColor {
    final cat = category.toLowerCase();

    if (cat.contains('maintenance')) {
      return const Color(0xFF16A34A);
    }
    if (cat.contains('safety') || cat.contains('security')) {
      return const Color(0xFFEA580C);
    }
    if (cat.contains('event')) {
      return const Color(0xFF4F46E5);
    }
    if (cat.contains('wifi') || cat.contains('internet')) {
      return const Color(0xFF0284C7);
    }
    if (cat.contains('water')) {
      return const Color(0xFF0284C7);
    }
    if (cat.contains('electric')) {
      return const Color(0xFFD97706);
    }
    if (cat.contains('clean') || cat.contains('room')) {
      return const Color(0xFF9333EA);
    }
    final pri = (priority ?? '').toLowerCase();
    if (pri == 'high' || pri == 'urgent' || cat == 'important') {
      return const Color(0xFFDC2626);
    }
    return const Color(0xFF0F4734);
  }

  Color get tagColor => iconColor;

  Color get priorityColor {
    final pri = (priority ?? '').toLowerCase();
    switch (pri) {
      case 'high':
      case 'urgent':
        return const Color(0xFFDC2626);
      case 'medium':
        return const Color(0xFFD97706);
      case 'low':
        return const Color(0xFF059669);
      default:
        return const Color(0xFF4B5563);
    }
  }

  Color get priorityBgColor {
    final pri = (priority ?? '').toLowerCase();
    switch (pri) {
      case 'high':
      case 'urgent':
        return const Color(0xFFFEE2E2);
      case 'medium':
        return const Color(0xFFFEF3C7);
      case 'low':
        return const Color(0xFFECFDF5);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  String get displayCategory {
    final pri = (priority ?? '').toLowerCase();
    if (pri == 'urgent') {
      return 'Urgent';
    }
    if (category.toLowerCase() == 'events') {
      return 'Event';
    }
    return category;
  }
}

class NoticesMetaModel {
  final int page;
  final int limit;
  final int totalRecords;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;
  final int unreadCount;

  NoticesMetaModel({
    this.page = 1,
    this.limit = 10,
    this.totalRecords = 0,
    this.totalPages = 1,
    this.hasNext = false,
    this.hasPrev = false,
    this.unreadCount = 0,
  });

  factory NoticesMetaModel.fromJson(Map<String, dynamic> json) {
    return NoticesMetaModel(
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 10,
      totalRecords: (json['total_records'] as num?)?.toInt() ?? 0,
      totalPages: (json['total_pages'] as num?)?.toInt() ?? 1,
      hasNext: json['has_next'] as bool? ?? false,
      hasPrev: json['has_prev'] as bool? ?? false,
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'page': page,
        'limit': limit,
        'total_records': totalRecords,
        'total_pages': totalPages,
        'has_next': hasNext,
        'has_prev': hasPrev,
        'unread_count': unreadCount,
      };
}
