import 'package:dio/dio.dart';
import '../../core/exceptions/app_exception.dart';
import '../../domain/entities/service_log.dart';

class ServiceLogRemoteDataSource {
  final Dio _dio;

  ServiceLogRemoteDataSource({required Dio dio}) : _dio = dio;

  Future<List<ServiceLog>> getServiceLogs(
    String vehicleId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/service-logs/$vehicleId',
        queryParameters: {'page': page, 'limit': limit},
      );
      return _parseServiceLogList(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<ServiceLog> getServiceLog(String vehicleId, String id) async {
    try {
      final response = await _dio.get('/service-logs/$vehicleId/$id');
      return _parseServiceLog(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<ServiceLog> createServiceLog(
    String vehicleId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.post('/service-logs/$vehicleId', data: data);
      return _parseServiceLog(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<ServiceLog> updateServiceLog(
    String vehicleId,
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.put('/service-logs/$vehicleId/$id', data: data);
      return _parseServiceLog(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteServiceLog(String vehicleId, String id) async {
    try {
      await _dio.delete('/service-logs/$vehicleId/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  List<ServiceLog> _parseServiceLogList(Map<String, dynamic> data) {
    if (data['success'] != true) {
      throw AppException(message: data['message'] ?? 'Failed to load service logs');
    }
    final serviceLogsData = data['data']['serviceLogs'] as List;
    return serviceLogsData
        .map((json) => ServiceLog.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  ServiceLog _parseServiceLog(Map<String, dynamic> data) {
    if (data['success'] != true) {
      throw AppException(message: data['message'] ?? 'Failed to load service log');
    }
    return ServiceLog.fromJson(data['data']['serviceLog'] as Map<String, dynamic>);
  }

  AppException _handleError(DioException e) {
    final message = e.response?.data['message'] as String?;
    return switch (e.response?.statusCode) {
      400 => ValidationException(message: message ?? 'Validation error'),
      401 => AuthException(message: message ?? 'Unauthorized'),
      403 => AuthException(message: message ?? 'Forbidden'),
      404 => AppException(message: message ?? 'Service log not found'),
      _ => NetworkException(message: e.message ?? 'Network error'),
    };
  }
}