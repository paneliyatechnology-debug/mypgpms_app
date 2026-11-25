import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/staff_model.dart';

abstract class StaffRemoteDataSource {
  Future<List<StaffMemberModel>> getStaffList({
    int branchId = 1,
    String staffRole = 'all',
    String status = 'all',
    String search = '',
    int page = 1,
    int limit = 20,
  });
}

class StaffRemoteDataSourceImpl implements StaffRemoteDataSource {
  final DioClient dioClient;

  StaffRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<StaffMemberModel>> getStaffList({
    int branchId = 1,
    String staffRole = 'all',
    String status = 'all',
    String search = '',
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await dioClient.dio.get(
        ApiEndpoints.staff,
        queryParameters: {
          'branch_id': branchId,
          'staff_role': staffRole,
          'status': status,
          'search': search,
          'page': page,
          'limit': limit,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final parsed = StaffListResponseModel.fromJson(data);
        return parsed.data;
      }
      throw ServerException(message: 'Invalid response format from staff list API');
    } on DioException catch (e) {
      final responseData = e.response?.data;
      final message = responseData is Map<String, dynamic>
          ? responseData['message']?.toString()
          : e.message;
      throw ServerException(
        message: message ?? 'Failed to retrieve staff directory',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
}
