import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/exceptions/app_exception.dart';
import '../../domain/entities/service_log.dart';
import '../../domain/repositories/service_log_repository.dart';
import 'providers.dart';

enum ServiceLogListStatus { initial, loading, loaded, error }

class ServiceLogListState {
  final ServiceLogListStatus status;
  final List<ServiceLog> serviceLogs;
  final String? errorMessage;

  const ServiceLogListState({
    this.status = ServiceLogListStatus.initial,
    this.serviceLogs = const [],
    this.errorMessage,
  });

  ServiceLogListState copyWith({
    ServiceLogListStatus? status,
    List<ServiceLog>? serviceLogs,
    String? errorMessage,
  }) =>
      ServiceLogListState(
        status: status ?? this.status,
        serviceLogs: serviceLogs ?? this.serviceLogs,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}

class ServiceLogListNotifier extends StateNotifier<ServiceLogListState> {
  final ServiceLogRepository _repository;
  final String _vehicleId;

  ServiceLogListNotifier(this._repository, this._vehicleId)
      : super(const ServiceLogListState()) {
    loadServiceLogs();
  }

  Future<void> loadServiceLogs({int page = 1}) async {
    state = state.copyWith(status: ServiceLogListStatus.loading, errorMessage: null);
    try {
      final serviceLogs = await _repository.getServiceLogs(_vehicleId, page: page);
      state = state.copyWith(
        status: ServiceLogListStatus.loaded,
        serviceLogs: serviceLogs,
      );
    } on AppException catch (e) {
      state = state.copyWith(
        status: ServiceLogListStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        status: ServiceLogListStatus.error,
        errorMessage: 'Wystąpił błąd',
      );
    }
  }

  Future<void> refresh() async {
    await loadServiceLogs();
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final serviceLogListProvider =
    StateNotifierProvider.family<ServiceLogListNotifier, ServiceLogListState, String>(
  (ref, vehicleId) {
    final repository = ref.watch(serviceLogRepositoryProvider);
    return ServiceLogListNotifier(repository, vehicleId);
  },
);

enum ServiceLogDetailStatus { initial, loading, loaded, error }

class ServiceLogDetailState {
  final ServiceLogDetailStatus status;
  final ServiceLog? serviceLog;
  final String? errorMessage;

  const ServiceLogDetailState({
    this.status = ServiceLogDetailStatus.initial,
    this.serviceLog,
    this.errorMessage,
  });

  ServiceLogDetailState copyWith({
    ServiceLogDetailStatus? status,
    ServiceLog? serviceLog,
    String? errorMessage,
  }) =>
      ServiceLogDetailState(
        status: status ?? this.status,
        serviceLog: serviceLog ?? this.serviceLog,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}

class ServiceLogDetailNotifier extends StateNotifier<ServiceLogDetailState> {
  final ServiceLogRepository _repository;
  final String _vehicleId;

  ServiceLogDetailNotifier(this._repository, this._vehicleId)
      : super(const ServiceLogDetailState());

  Future<void> loadServiceLog(String id) async {
    state = state.copyWith(status: ServiceLogDetailStatus.loading, errorMessage: null);
    try {
      final serviceLog = await _repository.getServiceLog(_vehicleId, id);
      state = state.copyWith(
        status: ServiceLogDetailStatus.loaded,
        serviceLog: serviceLog,
      );
    } on AppException catch (e) {
      state = state.copyWith(
        status: ServiceLogDetailStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        status: ServiceLogDetailStatus.error,
        errorMessage: 'Wystąpił błąd',
      );
    }
  }

  Future<void> createServiceLog(ServiceLog serviceLog) async {
    state = state.copyWith(status: ServiceLogDetailStatus.loading, errorMessage: null);
    try {
      final createdServiceLog = await _repository.createServiceLog(_vehicleId, serviceLog);
      state = state.copyWith(
        status: ServiceLogDetailStatus.loaded,
        serviceLog: createdServiceLog,
      );
    } on AppException catch (e) {
      state = state.copyWith(
        status: ServiceLogDetailStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        status: ServiceLogDetailStatus.error,
        errorMessage: 'Wystąpił błąd',
      );
    }
  }

  Future<void> updateServiceLog(ServiceLog serviceLog) async {
    state = state.copyWith(status: ServiceLogDetailStatus.loading, errorMessage: null);
    try {
      final updatedServiceLog = await _repository.updateServiceLog(_vehicleId, serviceLog);
      state = state.copyWith(
        status: ServiceLogDetailStatus.loaded,
        serviceLog: updatedServiceLog,
      );
    } on AppException catch (e) {
      state = state.copyWith(
        status: ServiceLogDetailStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        status: ServiceLogDetailStatus.error,
        errorMessage: 'Wystąpił błąd',
      );
    }
  }

  Future<void> deleteServiceLog(String id) async {
    state = state.copyWith(status: ServiceLogDetailStatus.loading, errorMessage: null);
    try {
      await _repository.deleteServiceLog(_vehicleId, id);
      state = const ServiceLogDetailState(status: ServiceLogDetailStatus.loaded);
    } on AppException catch (e) {
      state = state.copyWith(
        status: ServiceLogDetailStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        status: ServiceLogDetailStatus.error,
        errorMessage: 'Wystąpił błąd',
      );
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  void reset() {
    state = const ServiceLogDetailState();
  }
}

final serviceLogDetailProvider =
    StateNotifierProvider.family<ServiceLogDetailNotifier, ServiceLogDetailState, (
      String vehicleId,
      String id,
    )>(
  (ref, params) {
    final repository = ref.watch(serviceLogRepositoryProvider);
    final notifier = ServiceLogDetailNotifier(repository, params.$1);
    if (params.$2 != 'new') notifier.loadServiceLog(params.$2);
    return notifier;
  },
);

final serviceLogDetailNotifierProvider =
    Provider.family<ServiceLogDetailNotifier, (String vehicleId, String id)>(
  (ref, params) {
    return ref.watch(serviceLogDetailProvider(params).notifier);
  },
);