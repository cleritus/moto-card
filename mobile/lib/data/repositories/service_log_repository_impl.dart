import '../../domain/entities/service_log.dart';
import '../../domain/repositories/service_log_repository.dart';
import '../datasources/service_log_remote_data_source.dart';

class ServiceLogRepositoryImpl implements ServiceLogRepository {
  final ServiceLogRemoteDataSource _dataSource;

  ServiceLogRepositoryImpl({required ServiceLogRemoteDataSource dataSource})
      : _dataSource = dataSource;

  @override
  Future<List<ServiceLog>> getServiceLogs(
    String vehicleId, {
    int page = 1,
    int limit = 20,
  }) async {
    return await _dataSource.getServiceLogs(vehicleId, page: page, limit: limit);
  }

  @override
  Future<ServiceLog> getServiceLog(String vehicleId, String id) async {
    return await _dataSource.getServiceLog(vehicleId, id);
  }

  @override
  Future<ServiceLog> createServiceLog(String vehicleId, ServiceLog serviceLog) async {
    return await _dataSource.createServiceLog(vehicleId, serviceLog.toJson());
  }

  @override
  Future<ServiceLog> updateServiceLog(String vehicleId, ServiceLog serviceLog) async {
    return await _dataSource.updateServiceLog(vehicleId, serviceLog.id, serviceLog.toJson());
  }

  @override
  Future<void> deleteServiceLog(String vehicleId, String id) async {
    await _dataSource.deleteServiceLog(vehicleId, id);
  }
}