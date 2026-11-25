import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/food_menu_model.dart';

abstract class FoodMenuRemoteDataSource {
  Future<List<FoodMenuDateItemModel>> getFoodMenu({
    int branchId = 1,
    required String startDate,
    required String endDate,
    String mealType = 'all',
    int page = 1,
    int limit = 20,
  });

  Future<Map<String, dynamic>> submitFeedback({
    required int menuId,
    required int rating,
    String? comments,
    String? comment,
    String? imagePath,
  });
}

class FoodMenuRemoteDataSourceImpl implements FoodMenuRemoteDataSource {
  final DioClient dioClient;

  FoodMenuRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<FoodMenuDateItemModel>> getFoodMenu({
    int branchId = 1,
    required String startDate,
    required String endDate,
    String mealType = 'all',
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await dioClient.dio.get(
        ApiEndpoints.foodMenu,
        queryParameters: {
          'branch_id': branchId,
          'start_date': startDate,
          'end_date': endDate,
          'meal_type': mealType,
          'page': page,
          'limit': limit,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final parsed = FoodMenuResponseModel.fromJson(data);
        return parsed.data;
      }
      throw ServerException(message: 'Invalid response format from food menu API');
    } on DioException catch (e) {
      final responseData = e.response?.data;
      final message = responseData is Map<String, dynamic>
          ? responseData['message']?.toString()
          : e.message;
      throw ServerException(
        message: message ?? 'Failed to retrieve food menu',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<Map<String, dynamic>> submitFeedback({
    required int menuId,
    required int rating,
    String? comments,
    String? comment,
    String? imagePath,
  }) async {
    try {
      final textComment = (comments ?? comment)?.trim();
      final Map<String, dynamic> formMap = {
        'rating': rating.toString(),
      };

      if (textComment != null && textComment.isNotEmpty) {
        formMap['comments'] = textComment;
      }

      if (imagePath != null && imagePath.trim().isNotEmpty) {
        final file = File(imagePath);
        if (await file.exists()) {
          final fileName = imagePath.split(Platform.pathSeparator).last;
          formMap['image'] = await MultipartFile.fromFile(
            imagePath,
            filename: fileName,
          );
        }
      }

      final formData = FormData.fromMap(formMap);

      final response = await dioClient.dio.post(
        '${ApiEndpoints.foodMenu}/$menuId/feedback',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data;
      }
      return {'success': true, 'message': 'Feedback submitted successfully'};
    } on DioException catch (e) {
      final responseData = e.response?.data;
      final message = responseData is Map<String, dynamic>
          ? responseData['message']?.toString()
          : e.message;
      throw ServerException(
        message: message ?? 'Failed to submit feedback',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
}
