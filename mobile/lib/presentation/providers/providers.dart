import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/datasources/vehicle_remote_data_source.dart';
import '../../data/datasources/fuel_log_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/vehicle_repository_impl.dart';
import '../../data/repositories/fuel_log_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/vehicle_repository.dart';
import '../../domain/repositories/fuel_log_repository.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

final dioClientProvider = Provider<DioClient>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return DioClient(secureStorage: storage);
});

final dioProvider = Provider<Dio>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return dioClient.dio;
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthRemoteDataSource(dio: dio);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dataSource = ref.watch(authRemoteDataSourceProvider);
  final storage = ref.watch(secureStorageProvider);
  return AuthRepositoryImpl(dataSource: dataSource, storage: storage);
});

final vehicleRemoteDataSourceProvider = Provider<VehicleRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return VehicleRemoteDataSource(dio: dio);
});

final vehicleRepositoryProvider = Provider<VehicleRepository>((ref) {
  final dataSource = ref.watch(vehicleRemoteDataSourceProvider);
  return VehicleRepositoryImpl(dataSource: dataSource);
});

final fuelLogRemoteDataSourceProvider = Provider<FuelLogRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return FuelLogRemoteDataSource(dio: dio);
});

final fuelLogRepositoryProvider = Provider<FuelLogRepository>((ref) {
  final dataSource = ref.watch(fuelLogRemoteDataSourceProvider);
  return FuelLogRepositoryImpl(dataSource: dataSource);
});