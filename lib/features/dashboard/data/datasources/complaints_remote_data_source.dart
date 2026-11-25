import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/complaint_category_model.dart';
import '../models/complaint_model.dart';

abstract class ComplaintsRemoteDataSource {
  Future<List<ComplaintCategoryModel>> getComplaintCategories();
  Future<List<ComplaintItemModel>> getComplaints({
    String status = 'all',
    String categoryId = '',
    String priority = 'all',
    String search = '',
    int page = 1,
    int limit = 20,
  });
  Future<ComplaintItemModel> getComplaintDetails(int complaintId);
  Future<Map<String, dynamic>> createComplaint({
    required int categoryId,
    required String title,
    required String description,
    required int locationId,
    List<String>? attachmentPaths,
  });
}

class ComplaintsRemoteDataSourceImpl implements ComplaintsRemoteDataSource {
  final DioClient dioClient;

  ComplaintsRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<ComplaintCategoryModel>> getComplaintCategories() async {
    try {
      final response = await dioClient.dio.get(
        ApiEndpoints.complaintCategories,
        options: Options(
          headers: {
            'Accept': 'application/json',
          },
        ),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final parsed = ComplaintCategoriesResponseModel.fromJson(data);
        return parsed.data;
      }
      throw ServerException(message: 'Invalid response format from complaint categories API');
    } on DioException catch (e) {
      final responseData = e.response?.data;
      final message = responseData is Map<String, dynamic>
          ? responseData['message']?.toString()
          : e.message;
      throw ServerException(
        message: message ?? 'Failed to retrieve complaint categories',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<ComplaintItemModel>> getComplaints({
    String status = 'all',
    String categoryId = '',
    String priority = 'all',
    String search = '',
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await dioClient.dio.get(
        ApiEndpoints.complaints,
        queryParameters: {
          'status': status,
          if (categoryId.isNotEmpty) 'category_id': categoryId,
          'priority': priority,
          'search': search,
          'page': page,
          'limit': limit,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final parsed = ComplaintListResponseModel.fromJson(data);
        return parsed.data;
      }
      throw ServerException(message: 'Invalid response format from complaints API');
    } on DioException catch (e) {
      final responseData = e.response?.data;
      final message = responseData is Map<String, dynamic>
          ? responseData['message']?.toString()
          : e.message;
      throw ServerException(
        message: message ?? 'Failed to retrieve complaints',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<ComplaintItemModel> getComplaintDetails(int complaintId) async {
    try {
      final response = await dioClient.dio.get(
        '${ApiEndpoints.complaints}/$complaintId',
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data['data'] is Map<String, dynamic>) {
          return ComplaintItemModel.fromJson(data['data'] as Map<String, dynamic>);
        }
      }
      throw ServerException(message: 'Invalid response format from complaint details API');
    } on DioException catch (e) {
      final responseData = e.response?.data;
      final message = responseData is Map<String, dynamic>
          ? responseData['message']?.toString()
          : e.message;
      throw ServerException(
        message: message ?? 'Failed to retrieve complaint details',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<Map<String, dynamic>> createComplaint({
    required int categoryId,
    required String title,
    required String description,
    required int locationId,
    List<String>? attachmentPaths,
  }) async {
    try {
      final formData = FormData();
      formData.fields.addAll([
        MapEntry('category_id', categoryId.toString()),
        MapEntry('title', title),
        MapEntry('description', description),
        MapEntry('location_id', locationId.toString()),
      ]);

      if (attachmentPaths != null && attachmentPaths.isNotEmpty) {
        for (final path in attachmentPaths) {
          final fileName = path.split('/').last;
          formData.files.add(
            MapEntry(
              'attachments',
              await MultipartFile.fromFile(path, filename: fileName),
            ),
          );
        }
      }

      final response = await dioClient.dio.post(
        ApiEndpoints.complaints,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data;
      }
      return {'success': true, 'message': 'Complaint registered successfully'};
    } on DioException catch (e) {
      final responseData = e.response?.data;
      final message = responseData is Map<String, dynamic>
          ? responseData['message']?.toString()
          : e.message;
      throw ServerException(
        message: message ?? 'Failed to register complaint',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
}
