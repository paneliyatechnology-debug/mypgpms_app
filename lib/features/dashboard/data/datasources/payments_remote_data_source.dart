import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/payment_item_model.dart';
import '../models/payments_overview_model.dart';

abstract class PaymentsRemoteDataSource {
  Future<PaymentsOverviewResponseModel> getPaymentsOverview();
  Future<PaymentsListResponseModel> getPayments({
    String status = 'all',
    int page = 1,
    int limit = 10,
    String tab = '',
  });
  Future<PaymentDetailsResponseModel> getPaymentDetails(dynamic id);
  Future<InitiateUpiResponseModel> initiateUpi(dynamic paymentId);
  Future<Map<String, dynamic>> payPayment({
    required dynamic paymentId,
    required String paymentMethod,
    required String upiRefNo,
    String? note,
    String? imagePath,
  });
  Future<PaymentReceiptResponseModel> getPaymentReceipt(dynamic paymentId);
}

class PaymentsRemoteDataSourceImpl implements PaymentsRemoteDataSource {
  final DioClient dioClient;

  PaymentsRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<PaymentsOverviewResponseModel> getPaymentsOverview() async {
    try {
      final response = await dioClient.dio.get(
        ApiEndpoints.paymentsOverview,
        options: Options(
          headers: {
            'Accept': 'application/json',
          },
        ),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return PaymentsOverviewResponseModel.fromJson(data);
      }
      throw ServerException(message: 'Invalid response format from payments overview API');
    } on DioException catch (e) {
      final responseData = e.response?.data;
      final message = responseData is Map<String, dynamic>
          ? responseData['message']?.toString()
          : e.message;
      throw ServerException(
        message: message ?? 'Failed to retrieve payments overview data',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<PaymentsListResponseModel> getPayments({
    String status = 'all',
    int page = 1,
    int limit = 10,
    String tab = '',
  }) async {
    try {
      final response = await dioClient.dio.get(
        ApiEndpoints.payments,
        queryParameters: {
          'status': status,
          'page': page,
          'limit': limit,
          'tab': tab,
        },
        options: Options(
          headers: {
            'Accept': 'application/json',
          },
        ),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return PaymentsListResponseModel.fromJson(data);
      }
      throw ServerException(message: 'Invalid response format from payments API');
    } on DioException catch (e) {
      final responseData = e.response?.data;
      final message = responseData is Map<String, dynamic>
          ? responseData['message']?.toString()
          : e.message;
      throw ServerException(
        message: message ?? 'Failed to retrieve payments list data',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<PaymentDetailsResponseModel> getPaymentDetails(dynamic id) async {
    try {
      final response = await dioClient.dio.get(
        '${ApiEndpoints.payments}/$id',
        options: Options(
          headers: {
            'Accept': 'application/json',
          },
        ),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return PaymentDetailsResponseModel.fromJson(data);
      }
      throw ServerException(message: 'Invalid response format from payment details API');
    } on DioException catch (e) {
      final responseData = e.response?.data;
      final message = responseData is Map<String, dynamic>
          ? responseData['message']?.toString()
          : e.message;
      throw ServerException(
        message: message ?? 'Failed to retrieve payment details',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<InitiateUpiResponseModel> initiateUpi(dynamic paymentId) async {
    try {
      final response = await dioClient.dio.post(
        '${ApiEndpoints.payments}/$paymentId/initiate-upi',
        options: Options(
          headers: {
            'Accept': 'application/json',
          },
        ),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return InitiateUpiResponseModel.fromJson(data);
      }
      throw ServerException(message: 'Invalid response format from initiate UPI API');
    } on DioException catch (e) {
      final responseData = e.response?.data;
      final message = responseData is Map<String, dynamic>
          ? responseData['message']?.toString()
          : e.message;
      throw ServerException(
        message: message ?? 'Failed to initiate UPI payment',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<Map<String, dynamic>> payPayment({
    required dynamic paymentId,
    required String paymentMethod,
    required String upiRefNo,
    String? note,
    String? imagePath,
  }) async {
    try {
      final formMap = <String, dynamic>{
        'payment_method': paymentMethod,
        'upi_ref_no': upiRefNo,
      };

      if (note != null && note.trim().isNotEmpty) {
        formMap['note'] = note.trim();
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
        '${ApiEndpoints.payments}/$paymentId/pay',
        data: formData,
        options: Options(
          headers: {
            'Accept': 'application/json',
          },
          contentType: 'multipart/form-data',
        ),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data;
      }
      return {'success': true, 'message': 'Payment submitted successfully'};
    } on DioException catch (e) {
      final responseData = e.response?.data;
      final message = responseData is Map<String, dynamic>
          ? responseData['message']?.toString()
          : e.message;
      throw ServerException(
        message: message ?? 'Failed to submit payment',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<PaymentReceiptResponseModel> getPaymentReceipt(dynamic paymentId) async {
    try {
      final response = await dioClient.dio.get(
        '${ApiEndpoints.payments}/$paymentId/receipt',
        options: Options(
          headers: {
            'Accept': 'application/json',
          },
        ),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return PaymentReceiptResponseModel.fromJson(data);
      }
      throw ServerException(message: 'Invalid response format from payment receipt API');
    } on DioException catch (e) {
      final responseData = e.response?.data;
      final message = responseData is Map<String, dynamic>
          ? responseData['message']?.toString()
          : e.message;
      throw ServerException(
        message: message ?? 'Failed to retrieve payment receipt',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
}
