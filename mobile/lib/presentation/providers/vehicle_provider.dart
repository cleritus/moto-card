import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/exceptions/app_exception.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/repositories/vehicle_repository.dart';
import 'auth_provider.dart';
import 'providers.dart';

enum VehicleListStatus { initial, loading, loaded, error }

class VehicleListState {
  final VehicleListStatus status;
  final List<Vehicle> vehicles;
  final String? errorMessage;

  const VehicleListState({
    this.status = VehicleListStatus.initial,
    this.vehicles = const [],
    this.errorMessage,
  });

  VehicleListState copyWith({
    VehicleListStatus? status,
    List<Vehicle>? vehicles,
    String? errorMessage,
  }) =>
      VehicleListState(
        status: status ?? this.status,
        vehicles: vehicles ?? this.vehicles,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}

class VehicleListNotifier extends StateNotifier<VehicleListState> {
  final VehicleRepository _repository;
  final Ref _ref;

  VehicleListNotifier(this._repository, this._ref) : super(const VehicleListState()) {
    loadVehicles();
  }

  Future<void> loadVehicles({int page = 1}) async {
    state = state.copyWith(status: VehicleListStatus.loading, errorMessage: null);
    try {
      final vehicles = await _repository.getVehicles(page: page);
      state = state.copyWith(
        status: VehicleListStatus.loaded,
        vehicles: vehicles,
      );
    } on AuthException catch (_) {
      _ref.read(authProvider.notifier).logout();
    } on AppException catch (e) {
      state = state.copyWith(status: VehicleListStatus.error, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(status: VehicleListStatus.error, errorMessage: 'Wystąpił błąd');
    }
  }

  Future<void> refresh() async {
    await loadVehicles();
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final vehicleListProvider = StateNotifierProvider<VehicleListNotifier, VehicleListState>((ref) {
  final repository = ref.watch(vehicleRepositoryProvider);
  return VehicleListNotifier(repository, ref);
});

enum VehicleDetailStatus { initial, loading, loaded, error }

class VehicleDetailState {
  final VehicleDetailStatus status;
  final Vehicle? vehicle;
  final String? errorMessage;

  const VehicleDetailState({
    this.status = VehicleDetailStatus.initial,
    this.vehicle,
    this.errorMessage,
  });

  VehicleDetailState copyWith({
    VehicleDetailStatus? status,
    Vehicle? vehicle,
    String? errorMessage,
  }) =>
      VehicleDetailState(
        status: status ?? this.status,
        vehicle: vehicle ?? this.vehicle,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}

class VehicleDetailNotifier extends StateNotifier<VehicleDetailState> {
  final VehicleRepository _repository;

  VehicleDetailNotifier(this._repository) : super(const VehicleDetailState());

  Future<void> loadVehicle(String id) async {
    state = state.copyWith(status: VehicleDetailStatus.loading, errorMessage: null);
    try {
      final vehicle = await _repository.getVehicle(id);
      state = state.copyWith(
        status: VehicleDetailStatus.loaded,
        vehicle: vehicle,
      );
    } on AppException catch (e) {
      state = state.copyWith(status: VehicleDetailStatus.error, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(status: VehicleDetailStatus.error, errorMessage: 'Wystąpił błąd');
    }
  }

  Future<void> createVehicle(Vehicle vehicle) async {
    state = state.copyWith(status: VehicleDetailStatus.loading, errorMessage: null);
    try {
      final createdVehicle = await _repository.createVehicle(vehicle);
      state = state.copyWith(
        status: VehicleDetailStatus.loaded,
        vehicle: createdVehicle,
      );
    } on AppException catch (e) {
      state = state.copyWith(status: VehicleDetailStatus.error, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(status: VehicleDetailStatus.error, errorMessage: 'Wystąpił błąd');
    }
  }

  Future<void> updateVehicle(Vehicle vehicle) async {
    state = state.copyWith(status: VehicleDetailStatus.loading, errorMessage: null);
    try {
      final updatedVehicle = await _repository.updateVehicle(vehicle);
      state = state.copyWith(
        status: VehicleDetailStatus.loaded,
        vehicle: updatedVehicle,
      );
    } on AppException catch (e) {
      state = state.copyWith(status: VehicleDetailStatus.error, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(status: VehicleDetailStatus.error, errorMessage: 'Wystąpił błąd');
    }
  }

  Future<void> deleteVehicle(String id) async {
    state = state.copyWith(status: VehicleDetailStatus.loading, errorMessage: null);
    try {
      await _repository.deleteVehicle(id);
      state = const VehicleDetailState(status: VehicleDetailStatus.loaded);
    } on AppException catch (e) {
      state = state.copyWith(status: VehicleDetailStatus.error, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(status: VehicleDetailStatus.error, errorMessage: 'Wystąpił błąd');
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  void reset() {
    state = const VehicleDetailState();
  }
}

final vehicleDetailProvider =
    StateNotifierProvider.family<VehicleDetailNotifier, VehicleDetailState, String>((ref, id) {
  final repository = ref.watch(vehicleRepositoryProvider);
  return VehicleDetailNotifier(repository);
});

final vehicleDetailNotifierProvider =
    Provider.family<VehicleDetailNotifier, String>((ref, id) {
  return ref.watch(vehicleDetailProvider(id).notifier);
});