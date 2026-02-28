import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../config/constants.dart';

class TokenInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;
  final Dio _dio;
  bool _isRefreshing = false;

  TokenInterceptor({
    required FlutterSecureStorage storage,
    required Dio dio,
  })  : _storage = storage,
        _dio = dio;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (_shouldRefreshToken(err)) {
      try {
        if (_isRefreshing) {
          await Future.delayed(const Duration(milliseconds: 100));
          return handler.next(err);
        }

        _isRefreshing = true;
        final refreshToken = await _storage.read(key: AppConstants.refreshTokenKey);

        if (refreshToken != null) {
          final response = await _dio.post(
            '/auth/refresh',
            data: {'refreshToken': refreshToken},
            options: Options(
              headers: {'Authorization': null},
            ),
          );

          final responseData = response.data as Map<String, dynamic>;
          final tokens = responseData['data']['tokens'] as Map<String, dynamic>;
          final newAccessToken = tokens['accessToken'] as String;
          final newRefreshToken = tokens['refreshToken'] as String;

          await _storage.write(key: AppConstants.accessTokenKey, value: newAccessToken);
          await _storage.write(key: AppConstants.refreshTokenKey, value: newRefreshToken);

          final options = err.requestOptions;
          options.headers['Authorization'] = 'Bearer $newAccessToken';

          final retryResponse = await _dio.fetch(options);
          _isRefreshing = false;
          return handler.resolve(retryResponse);
        }
      } catch (_) {
        await _storage.deleteAll();
        _isRefreshing = false;
      }
    }
    _isRefreshing = false;
    return handler.next(err);
  }

  bool _shouldRefreshToken(DioException err) =>
      err.response?.statusCode == 401 &&
      err.requestOptions.path != '/auth/login' &&
      err.requestOptions.path != '/auth/refresh';
}