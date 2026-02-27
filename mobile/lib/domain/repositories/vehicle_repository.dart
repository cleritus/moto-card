import '../entities/vehicle.dart';

abstract class VehicleRepository {
  Future<List<Vehicle>> getVehicles();
  Future<Vehicle> getVehicle(String id);
  Future<Vehicle> createVehicle(Vehicle vehicle);
  Future<Vehicle> updateVehicle(Vehicle vehicle);
  Future<void> deleteVehicle(String id);
}
