class ComplaintCategoriesResponseModel {
  final bool success;
  final String? message;
  final List<ComplaintCategoryModel> data;

  ComplaintCategoriesResponseModel({
    required this.success,
    this.message,
    this.data = const [],
  });

  factory ComplaintCategoriesResponseModel.fromJson(Map<String, dynamic> json) {
    List<ComplaintCategoryModel> list = [];
    if (json['data'] is List) {
      list = (json['data'] as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => ComplaintCategoryModel.fromJson(e))
          .toList();
    }
    return ComplaintCategoriesResponseModel(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      data: list,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        'data': data.map((e) => e.toJson()).toList(),
      };
}

class ComplaintCategoryModel {
  final int id;
  final String name;
  final String key;
  final String? icon;
  final String? description;
  final WifiOptionsModel? wifiOptions;

  ComplaintCategoryModel({
    required this.id,
    required this.name,
    required this.key,
    this.icon,
    this.description,
    this.wifiOptions,
  });

  factory ComplaintCategoryModel.fromJson(Map<String, dynamic> json) {
    return ComplaintCategoryModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      key: json['key']?.toString() ?? '',
      icon: json['icon']?.toString(),
      description: json['description']?.toString(),
      wifiOptions: json['wifi_options'] is Map<String, dynamic>
          ? WifiOptionsModel.fromJson(json['wifi_options'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'key': key,
        'icon': icon,
        'description': description,
        'wifi_options': wifiOptions?.toJson(),
      };
}

class WifiOptionsModel {
  final List<String> issueTypes;
  final List<String> deviceTypes;

  WifiOptionsModel({
    this.issueTypes = const [],
    this.deviceTypes = const [],
  });

  factory WifiOptionsModel.fromJson(Map<String, dynamic> json) {
    List<String> issues = [];
    List<String> devices = [];

    if (json['issue_types'] is List) {
      issues = (json['issue_types'] as List).map((e) => e.toString()).toList();
    }
    if (json['device_types'] is List) {
      devices = (json['device_types'] as List).map((e) => e.toString()).toList();
    }

    return WifiOptionsModel(
      issueTypes: issues,
      deviceTypes: devices,
    );
  }

  Map<String, dynamic> toJson() => {
        'issue_types': issueTypes,
        'device_types': deviceTypes,
      };
}
