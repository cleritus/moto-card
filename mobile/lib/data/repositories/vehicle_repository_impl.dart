import '../../domain/entities/vehicle.dart';
import '../../domain/repositories/vehicle_repository.dart';
import '../datasources/vehicle_remote_data_source.dart';

class VehicleRepositoryImpl implements VehicleRepository {
  final VehicleRemoteDataSource _dataSource;

  VehicleRepositoryImpl({required VehicleRemoteDataSource dataSource})
      : _dataSource = dataSource;

  @override
  Future<List<Vehicle>> getVehicles({int page = 1, int limit = 20}) async {
    return await _dataSource.getVehicles(page: page, limit: limit);
  }

  @override
  Future<Vehicle> getVehicle(String id) async {
    return await _dataSource.getVehicle(id);
  }

  @override
  Future<Vehicle> createVehicle(Vehicle vehicle) async {
    return await _dataSource.createVehicle(vehicle.toJson());
  }

  @override
  Future<Vehicle> updateVehicle(Vehicle vehicle) async {
    return await _dataSource.updateVehicle(vehicle.id, vehicle.toJson());
  }

  @override
  Future<void> deleteVehicle(String id) async {
    await _dataSource.deleteVehicle(id);
  }
}