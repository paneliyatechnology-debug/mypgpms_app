import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/checkout_model.dart';

abstract class CheckoutRemoteDataSource {
  Future<Map<String, dynamic>> submitCheckoutRequest(CheckoutRequestPayload payload);
}

class CheckoutRemoteDataSourceImpl implements CheckoutRemoteDataSource {
  final DioClient dioClient;

  CheckoutRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<Map<String, dynamic>> submitCheckoutRequest(CheckoutRequestPayload payload) async {
    try {
      final response = await dioClient.dio.post(
        ApiEndpoints.staysCheckouts,
        data: payload.toJson(),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data;
      }
      return {'success': true, 'message': 'Checkout request submitted successfully'};
    } on DioException catch (e) {
      final responseData = e.response?.data;
      final message = responseData is Map<String, dynamic>
          ? responseData['message']?.toString()
          : e.message;
      throw ServerException(
        message: message ?? 'Failed to submit checkout request',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
}
