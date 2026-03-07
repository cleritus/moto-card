import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/exceptions/app_exception.dart';
import '../../domain/entities/fuel_log.dart';
import '../../domain/repositories/fuel_log_repository.dart';
import 'providers.dart';

enum FuelLogListStatus { initial, loading, loaded, error }

class FuelLogListState {
  final FuelLogListStatus status;
  final List<FuelLog> fuelLogs;
  final String? errorMessage;

  const FuelLogListState({
    this.status = FuelLogListStatus.initial,
    this.fuelLogs = const [],
    this.errorMessage,
  });

  FuelLogListState copyWith({
    FuelLogListStatus? status,
    List<FuelLog>? fuelLogs,
    String? errorMessage,
  }) =>
      FuelLogListState(
        status: status ?? this.status,
        fuelLogs: fuelLogs ?? this.fuelLogs,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}

class FuelLogListNotifier extends StateNotifier<FuelLogListState> {
  final FuelLogRepository _repository;
  final String _vehicleId;

  FuelLogListNotifier(this._repository, this._vehicleId)
      : super(const FuelLogListState()) {
    loadFuelLogs();
  }

  Future<void> loadFuelLogs({int page = 1}) async {
    state = state.copyWith(status: FuelLogListStatus.loading, errorMessage: null);
    try {
      final fuelLogs = await _repository.getFuelLogs(_vehicleId, page: page);
      state = state.copyWith(
        status: FuelLogListStatus.loaded,
        fuelLogs: fuelLogs,
      );
    } on AppException catch (e) {
      state = state.copyWith(
        status: FuelLogListStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        status: FuelLogListStatus.error,
        errorMessage: 'Wystąpił błąd',
      );
    }
  }

  Future<void> refresh() async {
    await loadFuelLogs();
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final fuelLogListProvider =
    StateNotifierProvider.family<FuelLogListNotifier, FuelLogListState, String>(
  (ref, vehicleId) {
    final repository = ref.watch(fuelLogRepositoryProvider);
    return FuelLogListNotifier(repository, vehicleId);
  },
);

enum FuelLogDetailStatus { initial, loading, loaded, error }

class FuelLogDetailState {
  final FuelLogDetailStatus status;
  final FuelLog? fuelLog;
  final String? errorMessage;

  const FuelLogDetailState({
    this.status = FuelLogDetailStatus.initial,
    this.fuelLog,
    this.errorMessage,
  });

  FuelLogDetailState copyWith({
    FuelLogDetailStatus? status,
    FuelLog? fuelLog,
    String? errorMessage,
  }) =>
      FuelLogDetailState(
        status: status ?? this.status,
        fuelLog: fuelLog ?? this.fuelLog,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}

class FuelLogDetailNotifier extends StateNotifier<FuelLogDetailState> {
  final FuelLogRepository _repository;
  final String _vehicleId;

  FuelLogDetailNotifier(this._repository, this._vehicleId)
      : super(const FuelLogDetailState());

  Future<void> loadFuelLog(String id) async {
    state = state.copyWith(status: FuelLogDetailStatus.loading, errorMessage: null);
    try {
      final fuelLog = await _repository.getFuelLog(_vehicleId, id);
      state = state.copyWith(
        status: FuelLogDetailStatus.loaded,
        fuelLog: fuelLog,
      );
    } on AppException catch (e) {
      state = state.copyWith(
        status: FuelLogDetailStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        status: FuelLogDetailStatus.error,
        errorMessage: 'Wystąpił błąd',
      );
    }
  }

  Future<void> createFuelLog(FuelLog fuelLog) async {
    state = state.copyWith(status: FuelLogDetailStatus.loading, errorMessage: null);
    try {
      final createdFuelLog = await _repository.createFuelLog(_vehicleId, fuelLog);
      state = state.copyWith(
        status: FuelLogDetailStatus.loaded,
        fuelLog: createdFuelLog,
      );
    } on AppException catch (e) {
      state = state.copyWith(
        status: FuelLogDetailStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        status: FuelLogDetailStatus.error,
        errorMessage: 'Wystąpił błąd',
      );
    }
  }

  Future<void> updateFuelLog(FuelLog fuelLog) async {
    state = state.copyWith(status: FuelLogDetailStatus.loading, errorMessage: null);
    try {
      final updatedFuelLog = await _repository.updateFuelLog(_vehicleId, fuelLog);
      state = state.copyWith(
        status: FuelLogDetailStatus.loaded,
        fuelLog: updatedFuelLog,
      );
    } on AppException catch (e) {
      state = state.copyWith(
        status: FuelLogDetailStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        status: FuelLogDetailStatus.error,
        errorMessage: 'Wystąpił błąd',
      );
    }
  }

  Future<void> deleteFuelLog(String id) async {
    state = state.copyWith(status: FuelLogDetailStatus.loading, errorMessage: null);
    try {
      await _repository.deleteFuelLog(_vehicleId, id);
      state = const FuelLogDetailState(status: FuelLogDetailStatus.loaded);
    } on AppException catch (e) {
      state = state.copyWith(
        status: FuelLogDetailStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        status: FuelLogDetailStatus.error,
        errorMessage: 'Wystąpił błąd',
      );
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  void reset() {
    state = const FuelLogDetailState();
  }
}

final fuelLogDetailProvider =
    StateNotifierProvider.family<FuelLogDetailNotifier, FuelLogDetailState, (
      String vehicleId,
      String id,
    )>(
  (ref, params) {
    final repository = ref.watch(fuelLogRepositoryProvider);
    return FuelLogDetailNotifier(repository, params.$1)..loadFuelLog(params.$2);
  },
);

final fuelLogDetailNotifierProvider =
    Provider.family<FuelLogDetailNotifier, (String vehicleId, String id)>(
  (ref, params) {
    return ref.watch(fuelLogDetailProvider(params).notifier);
  },
);