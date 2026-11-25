import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/room_model.dart';
import '../models/room_shift_model.dart';

abstract class RoomShiftRemoteDataSource {
  Future<Map<String, dynamic>> submitRoomShiftRequest(RoomShiftRequestPayload payload);
  Future<List<RoomShiftItemModel>> getRoomShifts({
    int branchId = 1,
    String status = 'all',
    String search = '',
    int page = 1,
    int limit = 10,
  });
  Future<List<RoomItemModel>> getRooms({int page = 1, int limit = 10});
}

class RoomShiftRemoteDataSourceImpl implements RoomShiftRemoteDataSource {
  final DioClient dioClient;

  RoomShiftRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<RoomItemModel>> getRooms({int page = 1, int limit = 10}) async {
    try {
      final response = await dioClient.dio.get(
        ApiEndpoints.rooms,
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final parsed = RoomsResponseModel.fromJson(data);
        return parsed.data;
      }
      return [];
    } on DioException catch (e) {
      final responseData = e.response?.data;
      final message = responseData is Map<String, dynamic>
          ? responseData['message']?.toString()
          : e.message;
      throw ServerException(
        message: message ?? 'Failed to fetch rooms',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<Map<String, dynamic>> submitRoomShiftRequest(RoomShiftRequestPayload payload) async {
    try {
      final response = await dioClient.dio.post(
        ApiEndpoints.roomShifts,
        data: payload.toJson(),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data;
      }
      return {'success': true, 'message': 'Room shift request submitted successfully'};
    } on DioException catch (e) {
      final responseData = e.response?.data;
      final message = responseData is Map<String, dynamic>
          ? responseData['message']?.toString()
          : e.message;
      throw ServerException(
        message: message ?? 'Failed to submit room shift request',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<RoomShiftItemModel>> getRoomShifts({
    int branchId = 1,
    String status = 'all',
    String search = '',
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await dioClient.dio.get(
        ApiEndpoints.roomShifts,
        queryParameters: {
          'branch_id': branchId,
          'status': status,
          if (search.isNotEmpty) 'search': search,
          'page': page,
          'limit': limit,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is List) {
        return (data['data'] as List)
            .whereType<Map<String, dynamic>>()
            .map(RoomShiftItemModel.fromJson)
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
