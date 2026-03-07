import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/exceptions/app_exception.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/repositories/reminder_repository.dart';
import 'providers.dart';

enum ReminderListStatus { initial, loading, loaded, error }

class ReminderListState {
  final ReminderListStatus status;
  final List<Reminder> reminders;
  final ReminderFilter filter;
  final String? errorMessage;

  const ReminderListState({
    this.status = ReminderListStatus.initial,
    this.reminders = const [],
    this.filter = ReminderFilter.active,
    this.errorMessage,
  });

  ReminderListState copyWith({
    ReminderListStatus? status,
    List<Reminder>? reminders,
    ReminderFilter? filter,
    String? errorMessage,
  }) =>
      ReminderListState(
        status: status ?? this.status,
        reminders: reminders ?? this.reminders,
        filter: filter ?? this.filter,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}

class ReminderListNotifier extends StateNotifier<ReminderListState> {
  final ReminderRepository _repository;
  final String _vehicleId;

  ReminderListNotifier(this._repository, this._vehicleId, ReminderFilter filter)
      : super(ReminderListState(filter: filter)) {
    loadReminders();
  }

  Future<void> loadReminders({int page = 1}) async {
    state = state.copyWith(status: ReminderListStatus.loading, errorMessage: null);
    try {
      final reminders = await _repository.getReminders(_vehicleId, page: page, filter: state.filter);
      state = state.copyWith(
        status: ReminderListStatus.loaded,
        reminders: reminders,
      );
    } on AppException catch (e) {
      state = state.copyWith(
        status: ReminderListStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        status: ReminderListStatus.error,
        errorMessage: 'Wystąpił błąd',
      );
    }
  }

  Future<void> refresh() async {
    await loadReminders();
  }

  void setFilter(ReminderFilter filter) {
    if (state.filter != filter) {
      state = state.copyWith(filter: filter);
      loadReminders();
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final reminderListProvider =
    StateNotifierProvider.family<ReminderListNotifier, ReminderListState, (String vehicleId, ReminderFilter filter)>(
  (ref, params) {
    final repository = ref.watch(reminderRepositoryProvider);
    return ReminderListNotifier(repository, params.$1, params.$2);
  },
);

enum ReminderDetailStatus { initial, loading, loaded, error }

class ReminderDetailState {
  final ReminderDetailStatus status;
  final Reminder? reminder;
  final String? errorMessage;

  const ReminderDetailState({
    this.status = ReminderDetailStatus.initial,
    this.reminder,
    this.errorMessage,
  });

  ReminderDetailState copyWith({
    ReminderDetailStatus? status,
    Reminder? reminder,
    String? errorMessage,
  }) =>
      ReminderDetailState(
        status: status ?? this.status,
        reminder: reminder ?? this.reminder,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}

class ReminderDetailNotifier extends StateNotifier<ReminderDetailState> {
  final ReminderRepository _repository;
  final String _vehicleId;

  ReminderDetailNotifier(this._repository, this._vehicleId)
      : super(const ReminderDetailState());

  Future<void> loadReminder(String id) async {
    state = state.copyWith(status: ReminderDetailStatus.loading, errorMessage: null);
    try {
      final reminder = await _repository.getReminder(_vehicleId, id);
      state = state.copyWith(
        status: ReminderDetailStatus.loaded,
        reminder: reminder,
      );
    } on AppException catch (e) {
      state = state.copyWith(
        status: ReminderDetailStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        status: ReminderDetailStatus.error,
        errorMessage: 'Wystąpił błąd',
      );
    }
  }

  Future<void> createReminder(Reminder reminder) async {
    state = state.copyWith(status: ReminderDetailStatus.loading, errorMessage: null);
    try {
      final createdReminder = await _repository.createReminder(_vehicleId, reminder);
      state = state.copyWith(
        status: ReminderDetailStatus.loaded,
        reminder: createdReminder,
      );
    } on AppException catch (e) {
      state = state.copyWith(
        status: ReminderDetailStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        status: ReminderDetailStatus.error,
        errorMessage: 'Wystąpił błąd',
      );
    }
  }

  Future<void> updateReminder(Reminder reminder) async {
    state = state.copyWith(status: ReminderDetailStatus.loading, errorMessage: null);
    try {
      final updatedReminder = await _repository.updateReminder(_vehicleId, reminder);
      state = state.copyWith(
        status: ReminderDetailStatus.loaded,
        reminder: updatedReminder,
      );
    } on AppException catch (e) {
      state = state.copyWith(
        status: ReminderDetailStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        status: ReminderDetailStatus.error,
        errorMessage: 'Wystąpił błąd',
      );
    }
  }

  Future<void> deleteReminder(String id) async {
    state = state.copyWith(status: ReminderDetailStatus.loading, errorMessage: null);
    try {
      await _repository.deleteReminder(_vehicleId, id);
      state = const ReminderDetailState(status: ReminderDetailStatus.loaded);
    } on AppException catch (e) {
      state = state.copyWith(
        status: ReminderDetailStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        status: ReminderDetailStatus.error,
        errorMessage: 'Wystąpił błąd',
      );
    }
  }

  Future<void> markAsCompleted(String id) async {
    try {
      final reminder = await _repository.markAsCompleted(_vehicleId, id);
      if (state.status == ReminderDetailStatus.loaded && state.reminder?.id == id) {
        state = state.copyWith(reminder: reminder);
      }
    } catch (e) {
      // Don't update state for quick toggle - let UI handle it
    }
  }

  Future<void> markAsIncomplete(String id) async {
    try {
      final reminder = await _repository.markAsIncomplete(_vehicleId, id);
      if (state.status == ReminderDetailStatus.loaded && state.reminder?.id == id) {
        state = state.copyWith(reminder: reminder);
      }
    } catch (e) {
      // Don't update state for quick toggle - let UI handle it
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  void reset() {
    state = const ReminderDetailState();
  }
}

final reminderDetailProvider =
    StateNotifierProvider.family<ReminderDetailNotifier, ReminderDetailState, (
      String vehicleId,
      String id,
    )>(
  (ref, params) {
    final repository = ref.watch(reminderRepositoryProvider);
    return ReminderDetailNotifier(repository, params.$1)..loadReminder(params.$2);
  },
);

final reminderDetailNotifierProvider =
    Provider.family<ReminderDetailNotifier, (String vehicleId, String id)>(
  (ref, params) {
    return ref.watch(reminderDetailProvider(params).notifier);
  },
);