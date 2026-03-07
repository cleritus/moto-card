import '../../domain/entities/fuel_log.dart';
import '../../domain/repositories/fuel_log_repository.dart';
import '../datasources/fuel_log_remote_data_source.dart';

class FuelLogRepositoryImpl implements FuelLogRepository {
  final FuelLogRemoteDataSource _dataSource;

  FuelLogRepositoryImpl({required FuelLogRemoteDataSource dataSource})
      : _dataSource = dataSource;

  @override
  Future<List<FuelLog>> getFuelLogs(
    String vehicleId, {
    int page = 1,
    int limit = 20,
  }) async {
    return await _dataSource.getFuelLogs(vehicleId, page: page, limit: limit);
  }

  @override
  Future<FuelLog> getFuelLog(String vehicleId, String id) async {
    return await _dataSource.getFuelLog(vehicleId, id);
  }

  @override
  Future<FuelLog> createFuelLog(String vehicleId, FuelLog fuelLog) async {
    return await _dataSource.createFuelLog(vehicleId, fuelLog.toJson());
  }

  @override
  Future<FuelLog> updateFuelLog(String vehicleId, FuelLog fuelLog) async {
    return await _dataSource.updateFuelLog(vehicleId, fuelLog.id, fuelLog.toJson());
  }

  @override
  Future<void> deleteFuelLog(String vehicleId, String id) async {
    await _dataSource.deleteFuelLog(vehicleId, id);
  }
}