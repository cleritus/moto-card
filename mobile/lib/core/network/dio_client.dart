import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../config/constants.dart';

class DioClient {
  late final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  DioClient({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(_authInterceptor());
    _dio.interceptors.add(_logInterceptor());
  }

  Dio get dio => _dio;

  Interceptor _authInterceptor() => InterceptorsWrapper(
        onRequest: (final options, final handler) async {
          final token = await _secureStorage.read(key: AppConstants.accessTokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (final error, final handler) async {
          if (error.response?.statusCode == 401) {
            // Handle token refresh or logout
            await _secureStorage.deleteAll();
          }
          return handler.next(error);
        },
      );

  Interceptor _logInterceptor() => LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (final object) => debugPrint('[DIO] $object'),
      );
}
