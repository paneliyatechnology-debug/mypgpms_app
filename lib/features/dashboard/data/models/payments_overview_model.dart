class PaymentsOverviewResponseModel {
  final bool success;
  final String? message;
  final PaymentsOverviewDataModel? data;

  PaymentsOverviewResponseModel({
    required this.success,
    this.message,
    this.data,
  });

  factory PaymentsOverviewResponseModel.fromJson(Map<String, dynamic> json) {
    return PaymentsOverviewResponseModel(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      data: json['data'] is Map<String, dynamic>
          ? PaymentsOverviewDataModel.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        'data': data?.toJson(),
      };
}

class PaymentsOverviewDataModel {
  final OutstandingPaymentModel? outstanding;
  final BillingPeriodModel? billingPeriod;
  final PaymentBreakdownModel? breakdown;
  final SecurityDepositModel? securityDeposit;
  final List<RecentTransactionItemModel> recentTransactions;

  PaymentsOverviewDataModel({
    this.outstanding,
    this.billingPeriod,
    this.breakdown,
    this.securityDeposit,
    this.recentTransactions = const [],
  });

  factory PaymentsOverviewDataModel.fromJson(Map<String, dynamic> json) {
    List<RecentTransactionItemModel> txs = [];
    if (json['recent_transactions'] is List) {
      txs = (json['recent_transactions'] as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => RecentTransactionItemModel.fromJson(e))
          .toList();
    }

    return PaymentsOverviewDataModel(
      outstanding: json['outstanding'] is Map<String, dynamic>
          ? OutstandingPaymentModel.fromJson(json['outstanding'] as Map<String, dynamic>)
          : null,
      billingPeriod: json['billing_period'] is Map<String, dynamic>
          ? BillingPeriodModel.fromJson(json['billing_period'] as Map<String, dynamic>)
          : null,
      breakdown: json['breakdown'] is Map<String, dynamic>
          ? PaymentBreakdownModel.fromJson(json['breakdown'] as Map<String, dynamic>)
          : null,
      securityDeposit: json['security_deposit'] is Map<String, dynamic>
          ? SecurityDepositModel.fromJson(json['security_deposit'] as Map<String, dynamic>)
          : null,
      recentTransactions: txs,
    );
  }

  Map<String, dynamic> toJson() => {
        'outstanding': outstanding?.toJson(),
        'billing_period': billingPeriod?.toJson(),
        'breakdown': breakdown?.toJson(),
        'security_deposit': securityDeposit?.toJson(),
        'recent_transactions': recentTransactions.map((e) => e.toJson()).toList(),
      };
}

class OutstandingPaymentModel {
  final int? paymentId;
  final num? amount;
  final int? totalEntries;
  final String? status;
  final String? dueDate;
  final String? dueDateText;
  final String? notes;
  final List<PaymentEntryModel> entries;

  OutstandingPaymentModel({
    this.paymentId,
    this.amount,
    this.totalEntries,
    this.status,
    this.dueDate,
    this.dueDateText,
    this.notes,
    this.entries = const [],
  });

  factory OutstandingPaymentModel.fromJson(Map<String, dynamic> json) {
    List<PaymentEntryModel> entryList = [];
    if (json['entries'] is List) {
      entryList = (json['entries'] as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => PaymentEntryModel.fromJson(e))
          .toList();
    }

    return OutstandingPaymentModel(
      paymentId: json['payment_id'] as int?,
      amount: json['amount'] as num?,
      totalEntries: json['total_entries'] as int?,
      status: json['status']?.toString(),
      dueDate: json['due_date']?.toString(),
      dueDateText: json['due_date_text']?.toString(),
      notes: json['notes']?.toString(),
      entries: entryList,
    );
  }

  Map<String, dynamic> toJson() => {
        'payment_id': paymentId,
        'amount': amount,
        'total_entries': totalEntries,
        'status': status,
        'due_date': dueDate,
        'due_date_text': dueDateText,
        'notes': notes,
        'entries': entries.map((e) => e.toJson()).toList(),
      };
}

class PaymentEntryModel {
  final int? id;
  final int? paymentId;
  final String? title;
  final String? paymentType;
  final String? status;
  final num? amount;
  final num? paidAmount;
  final num? dueAmount;
  final String? dueDate;
  final String? dueDateText;
  final String? billingPeriodStart;
  final String? billingPeriodEnd;
  final String? notes;
  final PaymentBreakdownModel? breakdown;

  PaymentEntryModel({
    this.id,
    this.paymentId,
    this.title,
    this.paymentType,
    this.status,
    this.amount,
    this.paidAmount,
    this.dueAmount,
    this.dueDate,
    this.dueDateText,
    this.billingPeriodStart,
    this.billingPeriodEnd,
    this.notes,
    this.breakdown,
  });

  factory PaymentEntryModel.fromJson(Map<String, dynamic> json) {
    return PaymentEntryModel(
      id: json['id'] as int?,
      paymentId: json['payment_id'] as int?,
      title: json['title']?.toString(),
      paymentType: json['payment_type']?.toString(),
      status: json['status']?.toString(),
      amount: json['amount'] as num?,
      paidAmount: json['paid_amount'] as num?,
      dueAmount: json['due_amount'] as num?,
      dueDate: json['due_date']?.toString(),
      dueDateText: json['due_date_text']?.toString(),
      billingPeriodStart: json['billing_period_start']?.toString(),
      billingPeriodEnd: json['billing_period_end']?.toString(),
      notes: json['notes']?.toString(),
      breakdown: json['breakdown'] is Map<String, dynamic>
          ? PaymentBreakdownModel.fromJson(json['breakdown'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'payment_id': paymentId,
        'title': title,
        'payment_type': paymentType,
        'status': status,
        'amount': amount,
        'paid_amount': paidAmount,
        'due_amount': dueAmount,
        'due_date': dueDate,
        'due_date_text': dueDateText,
        'billing_period_start': billingPeriodStart,
        'billing_period_end': billingPeriodEnd,
        'notes': notes,
        'breakdown': breakdown?.toJson(),
      };
}

class BillingPeriodModel {
  final String? start;
  final String? end;

  BillingPeriodModel({this.start, this.end});

  factory BillingPeriodModel.fromJson(Map<String, dynamic> json) {
    return BillingPeriodModel(
      start: json['start']?.toString(),
      end: json['end']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'start': start,
        'end': end,
      };
}

class PaymentBreakdownModel {
  final num rent;
  final num deposit;
  final num securityDeposit;
  final num maintenance;
  final num electricity;
  final num other;
  final num total;

  PaymentBreakdownModel({
    this.rent = 0,
    this.deposit = 0,
    this.securityDeposit = 0,
    this.maintenance = 0,
    this.electricity = 0,
    this.other = 0,
    this.total = 0,
  });

  factory PaymentBreakdownModel.fromJson(Map<String, dynamic> json) {
    return PaymentBreakdownModel(
      rent: (json['rent'] as num?) ?? 0,
      deposit: (json['deposit'] as num?) ?? 0,
      securityDeposit: (json['security_deposit'] as num?) ?? (json['deposit'] as num?) ?? 0,
      maintenance: (json['maintenance'] as num?) ?? 0,
      electricity: (json['electricity'] as num?) ?? 0,
      other: (json['other'] as num?) ?? 0,
      total: (json['total'] as num?) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'rent': rent,
        'deposit': deposit,
        'security_deposit': securityDeposit,
        'maintenance': maintenance,
        'electricity': electricity,
        'other': other,
        'total': total,
      };
}

class SecurityDepositModel {
  final num amount;
  final bool isRefundable;
  final String tag;

  SecurityDepositModel({
    this.amount = 0,
    this.isRefundable = true,
    this.tag = 'Refundable',
  });

  factory SecurityDepositModel.fromJson(Map<String, dynamic> json) {
    return SecurityDepositModel(
      amount: (json['amount'] as num?) ?? 0,
      isRefundable: json['is_refundable'] as bool? ?? true,
      tag: json['tag']?.toString() ?? 'Refundable',
    );
  }

  Map<String, dynamic> toJson() => {
        'amount': amount,
        'is_refundable': isRefundable,
        'tag': tag,
      };
}

class RecentTransactionItemModel {
  final int? id;
  final String title;
  final String date;
  final num amount;
  final String method;
  final String status;

  RecentTransactionItemModel({
    this.id,
    required this.title,
    required this.date,
    required this.amount,
    required this.method,
    required this.status,
  });

  factory RecentTransactionItemModel.fromJson(Map<String, dynamic> json) {
    return RecentTransactionItemModel(
      id: json['id'] as int?,
      title: json['title']?.toString() ?? 'Payment',
      date: json['date']?.toString() ?? '',
      amount: (json['amount'] as num?) ?? 0,
      method: json['method']?.toString() ?? 'UPI',
      status: json['status']?.toString() ?? 'Success',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'date': date,
        'amount': amount,
        'method': method,
        'status': status,
      };
}
