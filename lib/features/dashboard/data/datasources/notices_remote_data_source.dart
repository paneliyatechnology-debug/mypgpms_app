import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/notice_model.dart';

abstract class NoticesRemoteDataSource {
  Future<NoticesResponseModel> getNotices({
    String category = 'all',
    int page = 1,
    int limit = 10,
  });

  Future<NoticeDetailsResponseModel> getNoticeDetails(int id);

  Future<bool> markNoticeAsRead(int id);

  Future<bool> markAllNoticesAsRead();
}

class NoticesRemoteDataSourceImpl implements NoticesRemoteDataSource {
  final DioClient dioClient;

  NoticesRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<NoticesResponseModel> getNotices({
    String category = 'all',
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await dioClient.dio.get(
        ApiEndpoints.noticesResident,
        queryParameters: {
          'category': category,
          'page': page,
          'limit': limit,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return NoticesResponseModel.fromJson(data);
      }
      throw ServerException(message: 'Invalid response format from notices API');
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic> && data['message'] != null) {
        throw ServerException(message: data['message'].toString());
      }
      throw ServerException(message: e.message ?? 'Failed to fetch notices');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<NoticeDetailsResponseModel> getNoticeDetails(int id) async {
    try {
      final response = await dioClient.dio.get(
        '${ApiEndpoints.noticesResident}/$id',
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return NoticeDetailsResponseModel.fromJson(data);
      }
      throw ServerException(message: 'Invalid response format from notice details API');
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic> && data['message'] != null) {
        throw ServerException(message: data['message'].toString());
      }
      throw ServerException(message: e.message ?? 'Failed to fetch notice details');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<bool> markNoticeAsRead(int id) async {
    try {
      final response = await dioClient.dio.patch(
        '${ApiEndpoints.noticesResident}/$id/read',
      );
      final data = response.data;
      if (data is Map && data['success'] == true) {
        return true;
      }
      return false;
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic> && data['message'] != null) {
        throw ServerException(message: data['message'].toString());
      }
      throw ServerException(message: e.message ?? 'Failed to mark notice as read');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<bool> markAllNoticesAsRead() async {
    try {
      final response = await dioClient.dio.patch(
        '${ApiEndpoints.noticesResident}/read-all',
      );
      final data = response.data;
      if (data is Map && data['success'] == true) {
        return true;
      }
      return false;
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic> && data['message'] != null) {
        throw ServerException(message: data['message'].toString());
      }
      throw ServerException(message: e.message ?? 'Failed to mark all notices as read');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }
}
