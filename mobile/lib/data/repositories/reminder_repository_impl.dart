import '../../domain/entities/reminder.dart';
import '../../domain/repositories/reminder_repository.dart';
import '../datasources/reminder_remote_data_source.dart';

class ReminderRepositoryImpl implements ReminderRepository {
  final ReminderRemoteDataSource _dataSource;

  ReminderRepositoryImpl({required ReminderRemoteDataSource dataSource})
      : _dataSource = dataSource;

  @override
  Future<List<Reminder>> getReminders(
    String vehicleId, {
    int page = 1,
    int limit = 20,
    ReminderFilter filter = ReminderFilter.active,
  }) async {
    return await _dataSource.getReminders(vehicleId, page: page, limit: limit, filter: filter);
  }

  @override
  Future<Reminder> getReminder(String vehicleId, String id) async {
    return await _dataSource.getReminder(vehicleId, id);
  }

  @override
  Future<Reminder> createReminder(String vehicleId, Reminder reminder) async {
    return await _dataSource.createReminder(vehicleId, reminder.toJson());
  }

  @override
  Future<Reminder> updateReminder(String vehicleId, Reminder reminder) async {
    return await _dataSource.updateReminder(vehicleId, reminder.id, reminder.toJson());
  }

  @override
  Future<void> deleteReminder(String vehicleId, String id) async {
    await _dataSource.deleteReminder(vehicleId, id);
  }

  @override
  Future<Reminder> markAsCompleted(String vehicleId, String id) async {
    return await _dataSource.markAsCompleted(vehicleId, id);
  }

  @override
  Future<Reminder> markAsIncomplete(String vehicleId, String id) async {
    return await _dataSource.markAsIncomplete(vehicleId, id);
  }
}