import 'package:flutter/material.dart';
import 'payments_overview_model.dart';

class PaymentsListResponseModel {
  final bool success;
  final String? message;
  final List<PaymentRecordModel> data;
  final PaymentsListMetaModel? meta;

  PaymentsListResponseModel({
    required this.success,
    this.message,
    this.data = const [],
    this.meta,
  });

  factory PaymentsListResponseModel.fromJson(Map<String, dynamic> json) {
    List<PaymentRecordModel> items = [];
    if (json['data'] is List) {
      for (final raw in (json['data'] as List)) {
        if (raw is Map) {
          try {
            items.add(PaymentRecordModel.fromJson(Map<String, dynamic>.from(raw)));
          } catch (_) {}
        }
      }
    }
    return PaymentsListResponseModel(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      data: items,
      meta: json['meta'] is Map
          ? PaymentsListMetaModel.fromJson(Map<String, dynamic>.from(json['meta'] as Map))
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

class PaymentsListMetaModel {
  final int page;
  final int limit;
  final int totalPages;
  final int totalItems;

  PaymentsListMetaModel({
    this.page = 1,
    this.limit = 10,
    this.totalPages = 1,
    this.totalItems = 0,
  });

  factory PaymentsListMetaModel.fromJson(Map<String, dynamic> json) {
    return PaymentsListMetaModel(
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 10,
      totalPages: (json['total_pages'] as num?)?.toInt() ?? 1,
      totalItems: (json['total'] as num?)?.toInt() ??
          (json['total_items'] as num?)?.toInt() ??
          0,
    );
  }

  Map<String, dynamic> toJson() => {
        'page': page,
        'limit': limit,
        'total_pages': totalPages,
        'total': totalItems,
        'total_items': totalItems,
      };
}

class PaymentResidentModel {
  final int? id;
  final String? name;
  final String? email;
  final String? phone;
  final String? profilePhotoUrl;

  PaymentResidentModel({
    this.id,
    this.name,
    this.email,
    this.phone,
    this.profilePhotoUrl,
  });

  factory PaymentResidentModel.fromJson(Map<String, dynamic> json) {
    return PaymentResidentModel(
      id: (json['id'] as num?)?.toInt(),
      name: json['name']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      profilePhotoUrl: json['profile_photo_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'profile_photo_url': profilePhotoUrl,
      };
}

class PaymentRecordModel {
  final int? id;
  final String? transactionId;
  final String? receiptNo;
  final String title;
  final String paymentType;
  final String status;
  final num amount;
  final num paidAmount;
  final String? dueDate;
  final String? paidAt;
  final String? paymentMethod;
  final String? paymentMethodDetails;
  final String? image;
  final String? imageUrl;
  final PaymentResidentModel? resident;
  final int? stayId;
  final String? bedNumber;
  final int? roomId;
  final int? branchId;
  final String? branchName;
  final String? pgName;
  final int? pgId;
  final String? roomNo;
  final String? roomType;
  final String? buildingName;
  final String? floorName;
  final int? floorNumber;
  final BillingPeriodModel? billingPeriod;
  final PaymentBreakdownModel? breakdown;
  final String? upiId;
  final String? upiRefNo;
  final dynamic refund;
  final String? notes;
  final String? createdAt;
  final String? updatedAt;

  PaymentRecordModel({
    this.id,
    this.transactionId,
    this.receiptNo,
    required this.title,
    this.paymentType = 'rent',
    this.status = 'pending',
    this.amount = 0,
    this.paidAmount = 0,
    this.dueDate,
    this.paidAt,
    this.paymentMethod,
    this.paymentMethodDetails,
    this.image,
    this.imageUrl,
    this.resident,
    this.stayId,
    this.bedNumber,
    this.roomId,
    this.branchId,
    this.branchName,
    this.pgName,
    this.pgId,
    this.roomNo,
    this.roomType,
    this.buildingName,
    this.floorName,
    this.floorNumber,
    this.billingPeriod,
    this.breakdown,
    this.upiId,
    this.upiRefNo,
    this.refund,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory PaymentRecordModel.fromJson(Map<String, dynamic> json) {
    return PaymentRecordModel(
      id: (json['id'] as num?)?.toInt(),
      transactionId: json['transaction_id']?.toString(),
      receiptNo: json['receipt_no']?.toString(),
      title: json['title']?.toString() ?? 'Payment',
      paymentType: json['payment_type']?.toString() ?? 'rent',
      status: json['status']?.toString() ?? 'pending',
      amount: (json['amount'] as num?) ?? 0,
      paidAmount: (json['paid_amount'] as num?) ?? 0,
      dueDate: json['due_date']?.toString(),
      paidAt: json['paid_at']?.toString(),
      paymentMethod: json['payment_method']?.toString(),
      paymentMethodDetails: json['payment_method_details']?.toString(),
      image: json['image']?.toString(),
      imageUrl: json['image_url']?.toString(),
      resident: json['resident'] is Map<String, dynamic>
          ? PaymentResidentModel.fromJson(json['resident'] as Map<String, dynamic>)
          : null,
      stayId: (json['stay_id'] as num?)?.toInt(),
      bedNumber: json['bed_number']?.toString(),
      roomId: (json['room_id'] as num?)?.toInt(),
      branchId: (json['branch_id'] as num?)?.toInt(),
      branchName: json['branch_name']?.toString(),
      pgName: json['pg_name']?.toString(),
      pgId: (json['pg_id'] as num?)?.toInt(),
      roomNo: json['room_no']?.toString(),
      roomType: json['room_type']?.toString(),
      buildingName: json['building_name']?.toString(),
      floorName: json['floor_name']?.toString(),
      floorNumber: (json['floor_number'] as num?)?.toInt(),
      billingPeriod: json['billing_period'] is Map<String, dynamic>
          ? BillingPeriodModel.fromJson(json['billing_period'] as Map<String, dynamic>)
          : null,
      breakdown: json['breakdown'] is Map<String, dynamic>
          ? PaymentBreakdownModel.fromJson(json['breakdown'] as Map<String, dynamic>)
          : null,
      upiId: json['upi_id']?.toString(),
      upiRefNo: json['upi_ref_no']?.toString(),
      refund: json['refund'],
      notes: json['notes']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'transaction_id': transactionId,
        'receipt_no': receiptNo,
        'title': title,
        'payment_type': paymentType,
        'status': status,
        'amount': amount,
        'paid_amount': paidAmount,
        'due_date': dueDate,
        'paid_at': paidAt,
        'payment_method': paymentMethod,
        'payment_method_details': paymentMethodDetails,
        'image': image,
        'image_url': imageUrl,
        'resident': resident?.toJson(),
        'stay_id': stayId,
        'bed_number': bedNumber,
        'room_id': roomId,
        'branch_id': branchId,
        'branch_name': branchName,
        'pg_name': pgName,
        'pg_id': pgId,
        'room_no': roomNo,
        'room_type': roomType,
        'building_name': buildingName,
        'floor_name': floorName,
        'floor_number': floorNumber,
        'billing_period': billingPeriod?.toJson(),
        'breakdown': breakdown?.toJson(),
        'upi_id': upiId,
        'upi_ref_no': upiRefNo,
        'refund': refund,
        'notes': notes,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  factory PaymentRecordModel.fromDetails(PaymentDetailsDataModel d) {
    return PaymentRecordModel(
      id: d.id,
      transactionId: d.transactionId,
      receiptNo: d.receiptNo,
      title: d.title,
      paymentType: d.paymentType,
      status: d.status,
      amount: d.amount,
      paidAmount: d.paidAmount,
      dueDate: d.dueDate,
      paidAt: d.paidAt,
      paymentMethod: d.paymentMethod,
      paymentMethodDetails: d.paymentMethodDetails,
      image: d.image,
      imageUrl: d.imageUrl,
      resident: d.resident,
      stayId: d.stayId,
      bedNumber: d.bedNumber,
      roomId: d.roomId,
      branchId: d.branchId,
      branchName: d.branchName,
      pgName: d.pgName,
      pgId: d.pgId,
      roomNo: d.roomNo,
      roomType: d.roomType,
      buildingName: d.buildingName,
      floorName: d.floorName,
      floorNumber: d.floorNumber,
      billingPeriod: d.billingPeriod,
      breakdown: d.breakdown,
      upiId: d.upiId,
      upiRefNo: d.upiRefNo,
      refund: d.refund,
      notes: d.notes,
      createdAt: d.createdAt,
      updatedAt: d.updatedAt,
    );
  }

  String get displayStatus {
    final s = status.trim().toLowerCase();
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
        return 'Failed';
      case 'rejected':
        return 'Rejected';
      case 'cancelled':
      case 'canceled':
        return 'Cancelled';
      default:
        if (status.isEmpty) return 'Pending';
        return status.replaceAll('_', ' ').split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
    }
  }

  bool get isPaid {
    final s = status.trim().toLowerCase();
    return s == 'paid' || s == 'completed' || s == 'success';
  }

  bool get isInReview {
    final s = status.trim().toLowerCase();
    return s == 'in_review' || s == 'in review' || s == 'under_review';
  }

  bool get isPending {
    final s = status.trim().toLowerCase();
    return s == 'pending' || s == 'due';
  }

  Color get statusBgColor {
    final s = status.trim().toLowerCase();
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
    final s = status.trim().toLowerCase();
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
}

class PaymentDetailsResponseModel {
  final bool success;
  final String? message;
  final PaymentDetailsDataModel? data;

  PaymentDetailsResponseModel({
    required this.success,
    this.message,
    this.data,
  });

  factory PaymentDetailsResponseModel.fromJson(Map<String, dynamic> json) {
    dynamic rawData = json['data'];
    if (rawData is List && rawData.isNotEmpty) {
      rawData = rawData.first;
    }
    return PaymentDetailsResponseModel(
      success: json['success'] as bool? ?? false,
      message: json['message']?.toString(),
      data: rawData is Map<String, dynamic>
          ? PaymentDetailsDataModel.fromJson(rawData)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        'data': data?.toJson(),
      };
}

class PaymentDetailsDataModel {
  final int? id;
  final String? transactionId;
  final String? receiptNo;
  final String title;
  final String paymentType;
  final String status;
  final num amount;
  final num paidAmount;
  final String? dueDate;
  final String? paidAt;
  final String? paymentMethod;
  final String? paymentMethodDetails;
  final String? image;
  final String? imageUrl;
  final PaymentResidentModel? resident;
  final int? stayId;
  final String? bedNumber;
  final int? roomId;
  final int? branchId;
  final String? branchName;
  final String? pgName;
  final int? pgId;
  final String? roomNo;
  final String? roomType;
  final String? buildingName;
  final String? floorName;
  final int? floorNumber;
  final BillingPeriodModel? billingPeriod;
  final PaymentBreakdownModel? breakdown;
  final String? upiId;
  final String? upiRefNo;
  final dynamic refund;
  final String? notes;
  final String? createdAt;
  final String? updatedAt;

  PaymentDetailsDataModel({
    this.id,
    this.transactionId,
    this.receiptNo,
    required this.title,
    this.paymentType = 'rent',
    this.status = 'pending',
    this.amount = 0,
    this.paidAmount = 0,
    this.dueDate,
    this.paidAt,
    this.paymentMethod,
    this.paymentMethodDetails,
    this.image,
    this.imageUrl,
    this.resident,
    this.stayId,
    this.bedNumber,
    this.roomId,
    this.branchId,
    this.branchName,
    this.pgName,
    this.pgId,
    this.roomNo,
    this.roomType,
    this.buildingName,
    this.floorName,
    this.floorNumber,
    this.billingPeriod,
    this.breakdown,
    this.upiId,
    this.upiRefNo,
    this.refund,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory PaymentDetailsDataModel.fromPaymentRecord(PaymentRecordModel record) {
    return PaymentDetailsDataModel(
      id: record.id,
      transactionId: record.transactionId,
      receiptNo: record.receiptNo,
      title: record.title,
      paymentType: record.paymentType,
      status: record.status,
      amount: record.amount,
      paidAmount: record.paidAmount,
      dueDate: record.dueDate,
      paidAt: record.paidAt,
      paymentMethod: record.paymentMethod,
      paymentMethodDetails: record.paymentMethodDetails,
      image: record.image,
      imageUrl: record.imageUrl,
      resident: record.resident,
      stayId: record.stayId,
      bedNumber: record.bedNumber,
      roomId: record.roomId,
      branchId: record.branchId,
      branchName: record.branchName,
      pgName: record.pgName,
      pgId: record.pgId,
      roomNo: record.roomNo,
      roomType: record.roomType,
      buildingName: record.buildingName,
      floorName: record.floorName,
      floorNumber: record.floorNumber,
      billingPeriod: record.billingPeriod,
      breakdown: record.breakdown,
      upiId: record.upiId,
      upiRefNo: record.upiRefNo,
      refund: record.refund,
      notes: record.notes,
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
    );
  }

  factory PaymentDetailsDataModel.fromJson(Map<String, dynamic> json) {
    return PaymentDetailsDataModel(
      id: (json['id'] as num?)?.toInt(),
      transactionId: json['transaction_id']?.toString(),
      receiptNo: json['receipt_no']?.toString(),
      title: json['title']?.toString() ?? 'Monthly Rent',
      paymentType: json['payment_type']?.toString() ?? 'rent',
      status: json['status']?.toString() ?? 'pending',
      amount: (json['amount'] as num?) ?? 0,
      paidAmount: (json['paid_amount'] as num?) ?? 0,
      dueDate: json['due_date']?.toString(),
      paidAt: json['paid_at']?.toString(),
      paymentMethod: json['payment_method']?.toString(),
      paymentMethodDetails: json['payment_method_details']?.toString(),
      image: json['image']?.toString(),
      imageUrl: json['image_url']?.toString(),
      resident: json['resident'] is Map<String, dynamic>
          ? PaymentResidentModel.fromJson(json['resident'] as Map<String, dynamic>)
          : null,
      stayId: (json['stay_id'] as num?)?.toInt(),
      bedNumber: json['bed_number']?.toString(),
      roomId: (json['room_id'] as num?)?.toInt(),
      branchId: (json['branch_id'] as num?)?.toInt(),
      branchName: json['branch_name']?.toString(),
      pgName: json['pg_name']?.toString(),
      pgId: (json['pg_id'] as num?)?.toInt(),
      roomNo: json['room_no']?.toString(),
      roomType: json['room_type']?.toString(),
      buildingName: json['building_name']?.toString(),
      floorName: json['floor_name']?.toString(),
      floorNumber: (json['floor_number'] as num?)?.toInt(),
      billingPeriod: json['billing_period'] is Map<String, dynamic>
          ? BillingPeriodModel.fromJson(json['billing_period'] as Map<String, dynamic>)
          : null,
      breakdown: json['breakdown'] is Map<String, dynamic>
          ? PaymentBreakdownModel.fromJson(json['breakdown'] as Map<String, dynamic>)
          : null,
      upiId: json['upi_id']?.toString(),
      upiRefNo: json['upi_ref_no']?.toString(),
      refund: json['refund'],
      notes: json['notes']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'transaction_id': transactionId,
        'receipt_no': receiptNo,
        'title': title,
        'payment_type': paymentType,
        'status': status,
        'amount': amount,
        'paid_amount': paidAmount,
        'due_date': dueDate,
        'paid_at': paidAt,
        'payment_method': paymentMethod,
        'payment_method_details': paymentMethodDetails,
        'image': image,
        'image_url': imageUrl,
        'resident': resident?.toJson(),
        'stay_id': stayId,
        'bed_number': bedNumber,
        'room_id': roomId,
        'branch_id': branchId,
        'branch_name': branchName,
        'pg_name': pgName,
        'pg_id': pgId,
        'room_no': roomNo,
        'room_type': roomType,
        'building_name': buildingName,
        'floor_name': floorName,
        'floor_number': floorNumber,
        'billing_period': billingPeriod?.toJson(),
        'breakdown': breakdown?.toJson(),
        'upi_id': upiId,
        'upi_ref_no': upiRefNo,
        'refund': refund,
        'notes': notes,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  String get displayStatus {
    final s = status.trim().toLowerCase();
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
        return 'Failed';
      case 'rejected':
        return 'Rejected';
      case 'cancelled':
      case 'canceled':
        return 'Cancelled';
      default:
        if (status.isEmpty) return 'Pending';
        return status.replaceAll('_', ' ').split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
    }
  }

  bool get isPaid {
    final s = status.trim().toLowerCase();
    return s == 'paid' || s == 'completed' || s == 'success';
  }

  bool get isInReview {
    final s = status.trim().toLowerCase();
    return s == 'in_review' || s == 'in review' || s == 'under_review';
  }

  bool get isPending {
    final s = status.trim().toLowerCase();
    return s == 'pending' || s == 'due';
  }

  Color get statusBgColor {
    final s = status.trim().toLowerCase();
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
    final s = status.trim().toLowerCase();
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
}

class InitiateUpiResponseModel {
  final bool success;
  final String? message;
  final InitiateUpiDataModel? data;

  InitiateUpiResponseModel({
    required this.success,
    this.message,
    this.data,
  });

  factory InitiateUpiResponseModel.fromJson(Map<String, dynamic> json) {
    return InitiateUpiResponseModel(
      success: json['success'] as bool? ?? false,
      message: json['message']?.toString(),
      data: json['data'] is Map<String, dynamic>
          ? InitiateUpiDataModel.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        'data': data?.toJson(),
      };
}

class UpiAppIntentsModel {
  final String? gpay;
  final String? phonepe;
  final String? paytm;
  final String? bhim;
  final String? defaultIntent;

  UpiAppIntentsModel({
    this.gpay,
    this.phonepe,
    this.paytm,
    this.bhim,
    this.defaultIntent,
  });

  factory UpiAppIntentsModel.fromJson(Map<String, dynamic> json) {
    return UpiAppIntentsModel(
      gpay: json['gpay']?.toString(),
      phonepe: json['phonepe']?.toString(),
      paytm: json['paytm']?.toString(),
      bhim: json['bhim']?.toString(),
      defaultIntent: json['default']?.toString() ?? json['default_intent']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'gpay': gpay,
        'phonepe': phonepe,
        'paytm': paytm,
        'bhim': bhim,
        'default': defaultIntent,
      };

  String? getIntentForApp(String appNameOrPkg) {
    final lower = appNameOrPkg.toLowerCase();
    if (lower.contains('google') ||
        lower.contains('gpay') ||
        lower.contains('paisa') ||
        lower.contains('tez')) {
      return gpay;
    }
    if (lower.contains('phonepe')) {
      return phonepe;
    }
    if (lower.contains('paytm')) {
      return paytm;
    }
    if (lower.contains('bhim')) {
      return bhim;
    }
    return defaultIntent;
  }
}

class InitiateUpiDataModel {
  final int paymentId;
  final num amount;
  final String payeeName;
  final String payeeUpi;
  final String qrCodeUrl;
  final String upiIntentUrl;
  final UpiAppIntentsModel? appIntents;
  final List<String> supportedApps;

  InitiateUpiDataModel({
    required this.paymentId,
    required this.amount,
    required this.payeeName,
    required this.payeeUpi,
    required this.qrCodeUrl,
    required this.upiIntentUrl,
    this.appIntents,
    this.supportedApps = const [],
  });

  factory InitiateUpiDataModel.fromJson(Map<String, dynamic> json) {
    List<String> apps = [];
    if (json['supported_apps'] is List) {
      apps = (json['supported_apps'] as List).map((e) => e.toString()).toList();
    }

    return InitiateUpiDataModel(
      paymentId: (json['payment_id'] as num?)?.toInt() ?? 1,
      amount: (json['amount'] as num?) ?? 0,
      payeeName: json['payee_name']?.toString() ?? '',
      payeeUpi: json['payee_upi']?.toString() ?? '',
      qrCodeUrl: json['qr_code_url']?.toString() ?? '',
      upiIntentUrl: json['upi_intent_url']?.toString() ?? '',
      appIntents: json['app_intents'] is Map
          ? UpiAppIntentsModel.fromJson(Map<String, dynamic>.from(json['app_intents'] as Map))
          : null,
      supportedApps: apps,
    );
  }

  Map<String, dynamic> toJson() => {
        'payment_id': paymentId,
        'amount': amount,
        'payee_name': payeeName,
        'payee_upi': payeeUpi,
        'qr_code_url': qrCodeUrl,
        'upi_intent_url': upiIntentUrl,
        'app_intents': appIntents?.toJson(),
        'supported_apps': supportedApps,
      };
}

class PaymentReceiptResponseModel {
  final bool success;
  final String? message;
  final PaymentReceiptDataModel? data;

  PaymentReceiptResponseModel({
    required this.success,
    this.message,
    this.data,
  });

  factory PaymentReceiptResponseModel.fromJson(Map<String, dynamic> json) {
    return PaymentReceiptResponseModel(
      success: json['success'] as bool? ?? false,
      message: json['message']?.toString(),
      data: json['data'] is Map<String, dynamic>
          ? PaymentReceiptDataModel.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        'data': data?.toJson(),
      };
}

class PaymentReceiptDataModel {
  final String fileUrl;
  final String? filePath;
  final String? filename;
  final String? receiptNo;
  final int? paymentId;
  final String? residentName;
  final num? amount;
  final String? status;

  PaymentReceiptDataModel({
    required this.fileUrl,
    this.filePath,
    this.filename,
    this.receiptNo,
    this.paymentId,
    this.residentName,
    this.amount,
    this.status,
  });

  factory PaymentReceiptDataModel.fromJson(Map<String, dynamic> json) {
    return PaymentReceiptDataModel(
      fileUrl: json['file_url']?.toString() ?? '',
      filePath: json['file_path']?.toString(),
      filename: json['filename']?.toString(),
      receiptNo: json['receipt_no']?.toString(),
      paymentId: (json['payment_id'] as num?)?.toInt(),
      residentName: json['resident_name']?.toString(),
      amount: (json['amount'] as num?),
      status: json['status']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'file_url': fileUrl,
        'file_path': filePath,
        'filename': filename,
        'receipt_no': receiptNo,
        'payment_id': paymentId,
        'resident_name': residentName,
        'amount': amount,
        'status': status,
      };
}
