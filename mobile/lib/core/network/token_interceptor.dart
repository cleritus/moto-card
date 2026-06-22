import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../config/constants.dart';

class TokenInterceptor extends Interceptor {
  TokenInterceptor({
    required FlutterSecureStorage storage,
    required Dio dio,
  })  : _storage = storage,
        // Separate Dio WITHOUT this interceptor. The refresh and retry calls
        // must not re-enter the interceptor chain - doing so on the shared Dio
        // previously dead-locked the app on startup whenever the stored tokens
        // were expired (requests hung forever on a spinner).
        _refreshDio = Dio(
          BaseOptions(
            baseUrl: dio.options.baseUrl,
            connectTimeout: dio.options.connectTimeout,
            receiveTimeout: dio.options.receiveTimeout,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        );

  final FlutterSecureStorage _storage;
  final Dio _refreshDio;

  /// Single in-flight refresh shared by all concurrent 401s so the refresh
  /// token is rotated exactly once.
  Future<String?>? _refreshFuture;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (!_shouldRefreshToken(err)) {
      return handler.next(err);
    }

    final newAccessToken = await _refreshTokens();
    if (newAccessToken == null) {
      // Refresh missing/failed: the session was cleared, surface the 401 so the
      // app can redirect to login.
      return handler.next(err);
    }

    try {
      final options = err.requestOptions;
      options.headers['Authorization'] = 'Bearer $newAccessToken';
      final retryResponse = await _refreshDio.fetch<dynamic>(options);
      return handler.resolve(retryResponse);
    } on DioException catch (retryError) {
      return handler.next(retryError);
    }
  }

  Future<String?> _refreshTokens() => _refreshFuture ??=
      _performRefresh().whenComplete(() => _refreshFuture = null);

  Future<String?> _performRefresh() async {
    final refreshToken =
        await _storage.read(key: AppConstants.refreshTokenKey);
    if (refreshToken == null) return null;

    try {
      final response = await _refreshDio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      final responseData = response.data as Map<String, dynamic>;
      final tokens = responseData['data']['tokens'] as Map<String, dynamic>;
      final newAccessToken = tokens['accessToken'] as String;
      final newRefreshToken = tokens['refreshToken'] as String;

      await _storage.write(
        key: AppConstants.accessTokenKey,
        value: newAccessToken,
      );
      await _storage.write(
        key: AppConstants.refreshTokenKey,
        value: newRefreshToken,
      );
      return newAccessToken;
    } catch (_) {
      // Refresh token invalid/expired -> clear the session so downstream
      // AuthException handling logs the user out.
      await _storage.deleteAll();
      return null;
    }
  }

  bool _shouldRefreshToken(DioException err) =>
      err.response?.statusCode == 401 &&
      err.requestOptions.path != '/auth/login' &&
      err.requestOptions.path != '/auth/refresh';
}
