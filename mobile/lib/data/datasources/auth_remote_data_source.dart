import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/exceptions/app_exception.dart';
import '../../domain/entities/auth_response.dart';
import '../../domain/entities/user.dart';

class AuthRemoteDataSource {
  final Dio _dio;

  AuthRemoteDataSource({required Dio dio}) : _dio = dio;

  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      return _parseAuthResponse(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<AuthResponse> register(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {'email': email, 'password': password},
      );
      return _parseAuthResponse(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } on DioException catch (e) {
      // Logout errors are not critical
      debugPrint('Logout error: ${e.message}');
    }
  }

  Future<AuthResponse> refreshToken(String refreshToken) async {
    try {
      final response = await _dio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
        options: Options(
          headers: {'Authorization': null},
        ),
      );
      return _parseRefreshResponse(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<User> getCurrentUser() async {
    try {
      final response = await _dio.get('/auth/me');
      return User.fromJson(response.data['data']['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  AuthResponse _parseAuthResponse(Map<String, dynamic> data) {
    if (data['success'] != true) {
      throw AuthException(message: data['message'] ?? 'Authentication failed');
    }
    return AuthResponse.fromJson(data);
  }

  AuthResponse _parseRefreshResponse(Map<String, dynamic> data) {
    if (data['success'] != true) {
      throw AuthException(message: data['message'] ?? 'Token refresh failed');
    }
    final tokens = data['data']['tokens'] as Map<String, dynamic>;
    return AuthResponse(
      accessToken: tokens['accessToken'] as String,
      refreshToken: tokens['refreshToken'] as String,
    );
  }

  AppException _handleError(DioException e) {
    final message = e.response?.data['message'] as String?;
    return switch (e.response?.statusCode) {
      400 => ValidationException(message: message ?? 'Validation error'),
      401 => AuthException(message: message ?? 'Unauthorized'),
      409 => AuthException(message: message ?? 'User already exists'),
      _ => NetworkException(message: e.message ?? 'Network error'),
    };
  }
}