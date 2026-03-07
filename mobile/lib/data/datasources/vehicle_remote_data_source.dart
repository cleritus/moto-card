import 'package:dio/dio.dart';
import '../../core/exceptions/app_exception.dart';
import '../../domain/entities/vehicle.dart';

class VehicleRemoteDataSource {
  final Dio _dio;

  VehicleRemoteDataSource({required Dio dio}) : _dio = dio;

  Future<List<Vehicle>> getVehicles({int page = 1, int limit = 20}) async {
    try {
      final response = await _dio.get(
        '/vehicles',
        queryParameters: {'page': page, 'limit': limit},
      );
      return _parseVehicleList(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Vehicle> getVehicle(String id) async {
    try {
      final response = await _dio.get('/vehicles/$id');
      return _parseVehicle(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Vehicle> createVehicle(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/vehicles', data: data);
      return _parseVehicle(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Vehicle> updateVehicle(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/vehicles/$id', data: data);
      return _parseVehicle(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteVehicle(String id) async {
    try {
      await _dio.delete('/vehicles/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  List<Vehicle> _parseVehicleList(Map<String, dynamic> data) {
    if (data['success'] != true) {
      throw AppException(message: data['message'] ?? 'Failed to load vehicles');
    }
    final vehiclesData = data['data']['vehicles'] as List;
    return vehiclesData
        .map((json) => Vehicle.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Vehicle _parseVehicle(Map<String, dynamic> data) {
    if (data['success'] != true) {
      throw AppException(message: data['message'] ?? 'Failed to load vehicle');
    }
    return Vehicle.fromJson(data['data']['vehicle'] as Map<String, dynamic>);
  }

  AppException _handleError(DioException e) {
    final message = e.response?.data['message'] as String?;
    return switch (e.response?.statusCode) {
      400 => ValidationException(message: message ?? 'Validation error'),
      401 => AuthException(message: message ?? 'Unauthorized'),
      403 => AuthException(message: message ?? 'Forbidden'),
      404 => AppException(message: message ?? 'Vehicle not found'),
      _ => NetworkException(message: e.message ?? 'Network error'),
    };
  }
}