import '../entities/fuel_log.dart';

abstract class FuelLogRepository {
  Future<List<FuelLog>> getFuelLogs(
    String vehicleId, {
    int page = 1,
    int limit = 20,
  });
  Future<FuelLog> getFuelLog(String vehicleId, String id);
  Future<FuelLog> createFuelLog(String vehicleId, FuelLog fuelLog);
  Future<FuelLog> updateFuelLog(String vehicleId, FuelLog fuelLog);
  Future<void> deleteFuelLog(String vehicleId, String id);
}