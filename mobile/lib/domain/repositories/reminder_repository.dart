import '../entities/reminder.dart';

abstract class ReminderRepository {
  Future<List<Reminder>> getReminders(
    String vehicleId, {
    int page = 1,
    int limit = 20,
    ReminderFilter filter = ReminderFilter.active,
  });
  Future<Reminder> getReminder(String vehicleId, String id);
  Future<Reminder> createReminder(String vehicleId, Reminder reminder);
  Future<Reminder> updateReminder(String vehicleId, Reminder reminder);
  Future<void> deleteReminder(String vehicleId, String id);
  Future<Reminder> markAsCompleted(String vehicleId, String id);
  Future<Reminder> markAsIncomplete(String vehicleId, String id);
}