import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/dashboard_response_model.dart';

abstract class DashboardRemoteDataSource {
  Future<DashboardResponseModel> getDashboardData();
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final DioClient dioClient;
  static const String dashboardPath = '/dashboard';

  DashboardRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<DashboardResponseModel> getDashboardData() async {
    try {
      final response = await dioClient.dio.get(
        dashboardPath,
        options: Options(
          headers: {
            'Accept': 'application/json',
          },
        ),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return DashboardResponseModel.fromJson(data);
      }
      throw ServerException(message: 'Invalid response format from dashboard API');
    } on DioException catch (e) {
      final responseData = e.response?.data;
      final message = responseData is Map<String, dynamic>
          ? responseData['message']?.toString()
          : e.message;
      throw ServerException(
        message: message ?? 'Failed to retrieve dashboard data',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
}
