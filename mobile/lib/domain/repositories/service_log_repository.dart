import '../entities/service_log.dart';

abstract class ServiceLogRepository {
  Future<List<ServiceLog>> getServiceLogs(
    String vehicleId, {
    int page = 1,
    int limit = 20,
  });
  Future<ServiceLog> getServiceLog(String vehicleId, String id);
  Future<ServiceLog> createServiceLog(String vehicleId, ServiceLog serviceLog);
  Future<ServiceLog> updateServiceLog(String vehicleId, ServiceLog serviceLog);
  Future<void> deleteServiceLog(String vehicleId, String id);
}