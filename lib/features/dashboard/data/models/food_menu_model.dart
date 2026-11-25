class FoodMenuResponseModel {
  final bool success;
  final String? message;
  final List<FoodMenuDateItemModel> data;
  final FoodMenuMetaModel? meta;

  FoodMenuResponseModel({
    required this.success,
    this.message,
    this.data = const [],
    this.meta,
  });

  factory FoodMenuResponseModel.fromJson(Map<String, dynamic> json) {
    List<FoodMenuDateItemModel> list = [];
    if (json['data'] is List) {
      list = (json['data'] as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => FoodMenuDateItemModel.fromJson(e))
          .toList();
    }
    return FoodMenuResponseModel(
      success: json['success'] as bool? ?? false,
      message: json['message']?.toString(),
      data: list,
      meta: json['meta'] is Map<String, dynamic>
          ? FoodMenuMetaModel.fromJson(json['meta'] as Map<String, dynamic>)
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

class FoodMenuDateItemModel {
  final String date;
  final String dayOfWeek;
  final int totalItems;
  final FoodMealsModel? meals;

  FoodMenuDateItemModel({
    required this.date,
    required this.dayOfWeek,
    this.totalItems = 0,
    this.meals,
  });

  factory FoodMenuDateItemModel.fromJson(Map<String, dynamic> json) {
    return FoodMenuDateItemModel(
      date: json['date']?.toString() ?? '',
      dayOfWeek: json['day_of_week']?.toString() ?? '',
      totalItems: json['total_items'] as int? ?? 0,
      meals: json['meals'] is Map<String, dynamic>
          ? FoodMealsModel.fromJson(json['meals'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'day_of_week': dayOfWeek,
        'total_items': totalItems,
        if (meals != null) 'meals': meals!.toJson(),
      };
}

class FoodMealsModel {
  final List<FoodMealItemModel> breakfast;
  final List<FoodMealItemModel> lunch;
  final List<FoodMealItemModel> dinner;

  FoodMealsModel({
    this.breakfast = const [],
    this.lunch = const [],
    this.dinner = const [],
  });

  factory FoodMealsModel.fromJson(Map<String, dynamic> json) {
    List<FoodMealItemModel> parseList(dynamic raw) {
      if (raw is List) {
        return raw
            .whereType<Map<String, dynamic>>()
            .map((e) => FoodMealItemModel.fromJson(e))
            .toList();
      }
      return [];
    }

    return FoodMealsModel(
      breakfast: parseList(json['breakfast']),
      lunch: parseList(json['lunch']),
      dinner: parseList(json['dinner']),
    );
  }

  Map<String, dynamic> toJson() => {
        'breakfast': breakfast.map((e) => e.toJson()).toList(),
        'lunch': lunch.map((e) => e.toJson()).toList(),
        'dinner': dinner.map((e) => e.toJson()).toList(),
      };

  bool get isEmpty => breakfast.isEmpty && lunch.isEmpty && dinner.isEmpty;
  bool get isNotEmpty => !isEmpty;
}

class FoodMealItemModel {
  final int id;
  final int? branchId;
  final String? menuDate;
  final String? dayOfWeek;
  final String mealType;
  final String name;
  final String? description;
  final String? image;
  final String? imageUrl;
  final String? startTime;
  final String? endTime;
  final String? includedItems;
  final bool isActive;
  final bool isFeedbackOpen;
  final int sortOrder;
  final String? createdAt;
  final String? updatedAt;
  final dynamic myFeedback;

  FoodMealItemModel({
    required this.id,
    this.branchId,
    this.menuDate,
    this.dayOfWeek,
    required this.mealType,
    required this.name,
    this.description,
    this.image,
    this.imageUrl,
    this.startTime,
    this.endTime,
    this.includedItems,
    this.isActive = true,
    this.isFeedbackOpen = false,
    this.sortOrder = 0,
    this.createdAt,
    this.updatedAt,
    this.myFeedback,
  });

  String get displayTitle {
    final type = mealType.toLowerCase();
    if (type == 'breakfast') return 'Breakfast';
    if (type == 'lunch') return 'Lunch';
    if (type == 'dinner') return 'Dinner';
    return mealType;
  }

  String get displayTiming {
    if (startTime != null && endTime != null && startTime!.isNotEmpty && endTime!.isNotEmpty) {
      return '$startTime - $endTime';
    }
    return startTime ?? endTime ?? '';
  }

  String get displayItems {
    if (includedItems != null && includedItems!.isNotEmpty) {
      return '$name • $includedItems';
    }
    return name;
  }

  factory FoodMealItemModel.fromJson(Map<String, dynamic> json) {
    return FoodMealItemModel(
      id: json['id'] as int? ?? 0,
      branchId: json['branch_id'] as int?,
      menuDate: json['menu_date']?.toString(),
      dayOfWeek: json['day_of_week']?.toString(),
      mealType: json['meal_type']?.toString() ?? 'Meal',
      name: json['name']?.toString() ?? 'Food',
      description: json['description']?.toString(),
      image: json['image']?.toString(),
      imageUrl: json['image_url']?.toString(),
      startTime: json['start_time']?.toString(),
      endTime: json['end_time']?.toString(),
      includedItems: json['included_items']?.toString(),
      isActive: json['is_active'] as bool? ?? true,
      isFeedbackOpen: json['is_feedback_open'] as bool? ?? false,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      myFeedback: json['my_feedback'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'branch_id': branchId,
        'menu_date': menuDate,
        'day_of_week': dayOfWeek,
        'meal_type': mealType,
        'name': name,
        'description': description,
        'image': image,
        'image_url': imageUrl,
        'start_time': startTime,
        'end_time': endTime,
        'included_items': includedItems,
        'is_active': isActive,
        'is_feedback_open': isFeedbackOpen,
        'sort_order': sortOrder,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'my_feedback': myFeedback,
      };
}

class FoodMenuMetaModel {
  final int page;
  final int limit;
  final int totalPages;
  final int total;
  final int? branchId;
  final String? branchName;
  final String? startDate;
  final String? endDate;

  FoodMenuMetaModel({
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.total,
    this.branchId,
    this.branchName,
    this.startDate,
    this.endDate,
  });

  factory FoodMenuMetaModel.fromJson(Map<String, dynamic> json) {
    return FoodMenuMetaModel(
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 20,
      totalPages: json['total_pages'] as int? ?? 1,
      total: json['total'] as int? ?? 0,
      branchId: json['branch_id'] as int?,
      branchName: json['branch_name']?.toString(),
      startDate: json['start_date']?.toString(),
      endDate: json['end_date']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'page': page,
        'limit': limit,
        'total_pages': totalPages,
        'total': total,
        'branch_id': branchId,
        'branch_name': branchName,
        'start_date': startDate,
        'end_date': endDate,
      };
}
