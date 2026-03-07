import 'package:dio/dio.dart';
import '../../core/exceptions/app_exception.dart';
import '../../domain/entities/reminder.dart';

class ReminderRemoteDataSource {
  final Dio _dio;

  ReminderRemoteDataSource({required Dio dio}) : _dio = dio;

  Future<List<Reminder>> getReminders(
    String vehicleId, {
    int page = 1,
    int limit = 20,
    ReminderFilter filter = ReminderFilter.active,
  }) async {
    try {
      final response = await _dio.get(
        '/reminders/$vehicleId',
        queryParameters: {'page': page, 'limit': limit, 'filter': filter.name},
      );
      return _parseReminderList(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Reminder> getReminder(String vehicleId, String id) async {
    try {
      final response = await _dio.get('/reminders/$vehicleId/$id');
      return _parseReminder(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Reminder> createReminder(
    String vehicleId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.post('/reminders/$vehicleId', data: data);
      return _parseReminder(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Reminder> updateReminder(
    String vehicleId,
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.put('/reminders/$vehicleId/$id', data: data);
      return _parseReminder(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteReminder(String vehicleId, String id) async {
    try {
      await _dio.delete('/reminders/$vehicleId/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Reminder> markAsCompleted(String vehicleId, String id) async {
    try {
      final response = await _dio.post('/reminders/$vehicleId/$id/complete');
      return _parseReminder(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Reminder> markAsIncomplete(String vehicleId, String id) async {
    try {
      final response = await _dio.post('/reminders/$vehicleId/$id/incomplete');
      return _parseReminder(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  List<Reminder> _parseReminderList(Map<String, dynamic> data) {
    if (data['success'] != true) {
      throw AppException(message: data['message'] ?? 'Failed to load reminders');
    }
    final remindersData = data['data']['reminders'] as List;
    return remindersData
        .map((json) => Reminder.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Reminder _parseReminder(Map<String, dynamic> data) {
    if (data['success'] != true) {
      throw AppException(message: data['message'] ?? 'Failed to load reminder');
    }
    return Reminder.fromJson(data['data']['reminder'] as Map<String, dynamic>);
  }

  AppException _handleError(DioException e) {
    final message = e.response?.data['message'] as String?;
    return switch (e.response?.statusCode) {
      400 => ValidationException(message: message ?? 'Validation error'),
      401 => AuthException(message: message ?? 'Unauthorized'),
      403 => AuthException(message: message ?? 'Forbidden'),
      404 => AppException(message: message ?? 'Reminder not found'),
      _ => NetworkException(message: e.message ?? 'Network error'),
    };
  }
}