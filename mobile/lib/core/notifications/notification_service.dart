import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/entities/reminder.dart';

/// Schedules and cancels local notifications for [Reminder]s.
///
/// Date-type reminders are scheduled ahead of time (warning + due-day).
/// Mileage-type reminders can't be scheduled against a clock, so they're
/// checked opportunistically (see [checkMileageReminder]) and fired once
/// per due-mileage value, tracked via secure storage so repeated app opens
/// don't repeat the same alert.
class NotificationService {
  NotificationService({required FlutterSecureStorage secureStorage})
      : _secureStorage = secureStorage;

  final FlutterSecureStorage _secureStorage;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int warningDaysBeforeDue = 7;
  static const int mileageWarningThreshold = 500;
  static const String _channelId = 'reminders';
  static const String _channelName = 'Reminders';

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    // TZDateTime.from() below preserves the absolute instant of the plain
    // (device-local) DateTime it's given, regardless of which Location this
    // is set to — so UTC works without needing the device's real IANA zone.
    tz.setLocalLocation(tz.UTC);

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  /// Schedules (or reschedules) the notifications for a date-type reminder.
  /// No-op for mileage-type reminders and for completed ones.
  Future<void> scheduleForReminder(Reminder reminder) async {
    await cancelForReminder(reminder.id);

    if (reminder.isCompleted) return;
    if (reminder.type != ReminderType.date || reminder.dueDate == null) return;

    // The API returns dueDate as UTC; normalize to local before pulling
    // out calendar fields, or the warning/due days can land off by one.
    final due = reminder.dueDate!.toLocal();
    final now = DateTime.now();

    final warnAt = due.subtract(const Duration(days: warningDaysBeforeDue));
    if (warnAt.isAfter(now)) {
      await _scheduleAt(
        id: _warningNotificationId(reminder.id),
        time: DateTime(warnAt.year, warnAt.month, warnAt.day, 9),
        title: 'Za $warningDaysBeforeDue dni: ${reminder.title}',
        body: 'Termin: ${_formatDate(due)}',
      );
    }

    if (due.isAfter(now)) {
      await _scheduleAt(
        id: _dueNotificationId(reminder.id),
        time: DateTime(due.year, due.month, due.day, 9),
        title: 'Dziś: ${reminder.title}',
        body: 'Termin mija dzisiaj',
      );
    }
  }

  /// Cancels any pending scheduled notifications for this reminder.
  /// Safe to call even if none were ever scheduled.
  Future<void> cancelForReminder(String reminderId) async {
    await _plugin.cancel(_warningNotificationId(reminderId));
    await _plugin.cancel(_dueNotificationId(reminderId));
  }

  /// Opportunistic check for mileage-type reminders — call whenever a
  /// vehicle's current mileage and its reminders are both loaded (e.g. the
  /// vehicle overview screen). Fires an immediate notification once per
  /// due-mileage value when within [mileageWarningThreshold] km or overdue.
  Future<void> checkMileageReminder({
    required Reminder reminder,
    required int currentMileage,
  }) async {
    if (reminder.isCompleted) return;
    if (reminder.type != ReminderType.mileage || reminder.dueMileage == null) {
      return;
    }

    final remaining = reminder.dueMileage! - currentMileage;
    if (remaining > mileageWarningThreshold) return;

    final storageKey = 'mileage_notified_${reminder.id}_${reminder.dueMileage}';
    final alreadyNotified = await _secureStorage.read(key: storageKey);
    if (alreadyNotified != null) return;

    final title = remaining < 0
        ? 'Przekroczono przebieg: ${reminder.title}'
        : 'Zbliża się przebieg: ${reminder.title}';
    final body = remaining < 0
        ? 'Minęło ${-remaining} km od ${reminder.dueMileage} km'
        : 'Zostało $remaining km do ${reminder.dueMileage} km';

    await _plugin.show(
      _mileageNotificationId(reminder.id),
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
    await _secureStorage.write(key: storageKey, value: '1');
  }

  Future<void> _scheduleAt({
    required int id,
    required DateTime time,
    required String title,
    required String body,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(time, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.'
      '${date.month.toString().padLeft(2, '0')}.${date.year}';

  int _warningNotificationId(String reminderId) => _hashId(reminderId, 1);
  int _dueNotificationId(String reminderId) => _hashId(reminderId, 2);
  int _mileageNotificationId(String reminderId) => _hashId(reminderId, 3);

  /// Stable positive 31-bit id derived from the reminder's Mongo ObjectId,
  /// so the same reminder always maps to the same notification id (needed
  /// to cancel/reschedule it later).
  int _hashId(String reminderId, int salt) {
    var hash = salt;
    for (final codeUnit in reminderId.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x7FFFFFFF;
    }
    return hash;
  }
}
