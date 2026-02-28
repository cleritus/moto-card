import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../config/constants.dart';
import '../../core/exceptions/app_exception.dart';
import '../../domain/entities/auth_response.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _dataSource;
  final FlutterSecureStorage _storage;

  AuthRepositoryImpl({
    required AuthRemoteDataSource dataSource,
    required FlutterSecureStorage storage,
  })  : _dataSource = dataSource,
        _storage = storage;

  @override
  Future<User> login({required String email, required String password}) async {
    final response = await _dataSource.login(email, password);
    await _saveTokens(response);
    return response.user!;
  }

  @override
  Future<User> register({required String email, required String password}) async {
    final response = await _dataSource.register(email, password);
    await _saveTokens(response);
    return response.user!;
  }

  @override
  Future<void> logout() async {
    try {
      await _dataSource.logout();
    } catch (_) {
      // Ignore logout errors
    }
    await _clearTokens();
  }

  @override
  Future<User?> getCurrentUser() async {
    final userJson = await _storage.read(key: AppConstants.userKey);
    if (userJson == null) return null;
    return User.fromJson(jsonDecode(userJson));
  }

  @override
  Future<void> refreshToken() async {
    final refreshToken = await _storage.read(key: AppConstants.refreshTokenKey);
    if (refreshToken == null) throw AuthException(message: 'No refresh token');

    final response = await _dataSource.refreshToken(refreshToken);
    await _saveTokens(response);
  }

  Future<void> _saveTokens(AuthResponse response) async {
    await _storage.write(key: AppConstants.accessTokenKey, value: response.accessToken);
    await _storage.write(key: AppConstants.refreshTokenKey, value: response.refreshToken);
    if (response.user != null) {
      await _storage.write(key: AppConstants.userKey, value: jsonEncode(response.user!.toJson()));
    }
  }

  Future<void> _clearTokens() async {
    await _storage.delete(key: AppConstants.accessTokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
    await _storage.delete(key: AppConstants.userKey);
  }
}