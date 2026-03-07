import 'package:dio/dio.dart';
import '../../core/exceptions/app_exception.dart';
import '../../domain/entities/fuel_log.dart';

class FuelLogRemoteDataSource {
  final Dio _dio;

  FuelLogRemoteDataSource({required Dio dio}) : _dio = dio;

  Future<List<FuelLog>> getFuelLogs(
    String vehicleId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/fuel-logs/$vehicleId',
        queryParameters: {'page': page, 'limit': limit},
      );
      return _parseFuelLogList(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<FuelLog> getFuelLog(String vehicleId, String id) async {
    try {
      final response = await _dio.get('/fuel-logs/$vehicleId/$id');
      return _parseFuelLog(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<FuelLog> createFuelLog(
    String vehicleId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.post('/fuel-logs/$vehicleId', data: data);
      return _parseFuelLog(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<FuelLog> updateFuelLog(
    String vehicleId,
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.put('/fuel-logs/$vehicleId/$id', data: data);
      return _parseFuelLog(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteFuelLog(String vehicleId, String id) async {
    try {
      await _dio.delete('/fuel-logs/$vehicleId/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  List<FuelLog> _parseFuelLogList(Map<String, dynamic> data) {
    if (data['success'] != true) {
      throw AppException(message: data['message'] ?? 'Failed to load fuel logs');
    }
    final fuelLogsData = data['data']['fuelLogs'] as List;
    return fuelLogsData
        .map((json) => FuelLog.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  FuelLog _parseFuelLog(Map<String, dynamic> data) {
    if (data['success'] != true) {
      throw AppException(message: data['message'] ?? 'Failed to load fuel log');
    }
    return FuelLog.fromJson(data['data']['fuelLog'] as Map<String, dynamic>);
  }

  AppException _handleError(DioException e) {
    final message = e.response?.data['message'] as String?;
    return switch (e.response?.statusCode) {
      400 => ValidationException(message: message ?? 'Validation error'),
      401 => AuthException(message: message ?? 'Unauthorized'),
      403 => AuthException(message: message ?? 'Forbidden'),
      404 => AppException(message: message ?? 'Fuel log not found'),
      _ => NetworkException(message: e.message ?? 'Network error'),
    };
  }
}