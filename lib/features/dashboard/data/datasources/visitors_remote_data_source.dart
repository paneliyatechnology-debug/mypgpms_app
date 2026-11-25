import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/visitor_model.dart';

abstract class VisitorsRemoteDataSource {
  Future<List<VisitorItemModel>> getVisitors({
    String status = 'all',
    String purpose = 'all',
    int page = 1,
    int limit = 10,
    int? residentId,
  });

  Future<Map<String, dynamic>> addVisitor({
    required String visitorName,
    required String visitorPhone,
    required String purpose,
    required String visitDate,
    required String validUntil,
    required String entryTime,
    required int residentId,
    required int pgId,
    required int branchId,
    String? relation,
    String? adminNotes,
    String? status,
    String? photoPath,
  });

  Future<Map<String, dynamic>> updateVisitor({
    required int visitorId,
    required String visitorName,
    required String visitorPhone,
    required String purpose,
    required String visitDate,
    required String validUntil,
    required String entryTime,
    String? exitTime,
    required int branchId,
    String? adminNotes,
    String? photoPath,
  });

  Future<Map<String, dynamic>> deleteVisitor(int visitorId);
}

class VisitorsRemoteDataSourceImpl implements VisitorsRemoteDataSource {
  final DioClient dioClient;

  VisitorsRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<VisitorItemModel>> getVisitors({
    String status = 'all',
    String purpose = 'all',
    int page = 1,
    int limit = 10,
    int? residentId,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'status': status,
        'purpose': purpose,
        'page': page,
        'limit': limit,
        'resident_id': residentId != null ? residentId.toString() : '',
      };

      final response = await dioClient.dio.get(
        ApiEndpoints.visitors,
        queryParameters: queryParams,
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is List) {
        final list = data['data'] as List;
        return list
            .map((e) => VisitorItemModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      final responseData = e.response?.data;
      final message = responseData is Map<String, dynamic>
          ? responseData['message']?.toString()
          : e.message;
      throw ServerException(
        message: message ?? 'Failed to retrieve visitors',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<Map<String, dynamic>> addVisitor({
    required String visitorName,
    required String visitorPhone,
    required String purpose,
    required String visitDate,
    required String validUntil,
    required String entryTime,
    required int residentId,
    required int pgId,
    required int branchId,
    String? relation,
    String? adminNotes,
    String? status,
    String? photoPath,
  }) async {
    try {
      final formData = FormData();
      formData.fields.addAll([
        MapEntry('visitor_name', visitorName),
        MapEntry('visitor_phone', visitorPhone),
        MapEntry('purpose', purpose),
        if (relation != null && relation.isNotEmpty) MapEntry('relation', relation),
        MapEntry('visit_date', visitDate),
        MapEntry('valid_until', validUntil),
        MapEntry('entry_time', entryTime),
        MapEntry('resident_id', residentId.toString()),
        MapEntry('pg_id', pgId.toString()),
        MapEntry('branch_id', branchId.toString()),
        if (adminNotes != null && adminNotes.isNotEmpty)
          MapEntry('admin_notes', adminNotes),
        MapEntry('status', status ?? 'pending'),
      ]);

      if (photoPath != null && photoPath.isNotEmpty) {
        final fileName = photoPath.split('/').last;
        formData.files.add(
          MapEntry(
            'photo',
            await MultipartFile.fromFile(photoPath, filename: fileName),
          ),
        );
        formData.files.add(
          MapEntry(
            'visitor_photo',
            await MultipartFile.fromFile(photoPath, filename: fileName),
          ),
        );
      }

      final response = await dioClient.dio.post(
        ApiEndpoints.visitors,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data;
      }
      return {'success': true, 'message': 'Visitor added successfully'};
    } on DioException catch (e) {
      final responseData = e.response?.data;
      final message = responseData is Map<String, dynamic>
          ? responseData['message']?.toString()
          : e.message;
      throw ServerException(
        message: message ?? 'Failed to add visitor',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<Map<String, dynamic>> updateVisitor({
    required int visitorId,
    required String visitorName,
    required String visitorPhone,
    required String purpose,
    required String visitDate,
    required String validUntil,
    required String entryTime,
    String? exitTime,
    required int branchId,
    String? adminNotes,
    String? photoPath,
  }) async {
    try {
      final formData = FormData();
      formData.fields.addAll([
        MapEntry('visitor_name', visitorName),
        MapEntry('visitor_phone', visitorPhone),
        MapEntry('purpose', purpose),
        MapEntry('visit_date', visitDate),
        MapEntry('valid_until', validUntil),
        MapEntry('entry_time', entryTime),
        if (exitTime != null && exitTime.isNotEmpty) MapEntry('exit_time', exitTime),
        if (adminNotes != null && adminNotes.isNotEmpty)
          MapEntry('admin_notes', adminNotes),
        MapEntry('branch_id', branchId.toString()),
      ]);

      if (photoPath != null && photoPath.isNotEmpty) {
        final fileName = photoPath.split('/').last;
        formData.files.add(
          MapEntry(
            'visitor_photo',
            await MultipartFile.fromFile(photoPath, filename: fileName),
          ),
        );
      }

      final response = await dioClient.dio.put(
        '${ApiEndpoints.visitors}/$visitorId',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data;
      }
      return {'success': true, 'message': 'Visitor updated successfully'};
    } on DioException catch (e) {
      final responseData = e.response?.data;
      final message = responseData is Map<String, dynamic>
          ? responseData['message']?.toString()
          : e.message;
      throw ServerException(
        message: message ?? 'Failed to update visitor',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<Map<String, dynamic>> deleteVisitor(int visitorId) async {
    try {
      final response = await dioClient.dio.delete(
        '${ApiEndpoints.visitors}/$visitorId',
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data;
      }
      return {'success': true, 'message': 'Visitor deleted successfully'};
    } on DioException catch (e) {
      final responseData = e.response?.data;
      final message = responseData is Map<String, dynamic>
          ? responseData['message']?.toString()
          : e.message;
      throw ServerException(
        message: message ?? 'Failed to delete visitor',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
}
