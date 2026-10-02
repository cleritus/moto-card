import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/fuel_log.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/entities/service_log.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/repositories/fuel_log_repository.dart';
import '../../domain/repositories/reminder_repository.dart';
import '../../domain/repositories/service_log_repository.dart';
import '../../domain/repositories/vehicle_repository.dart';
import '../exceptions/app_exception.dart';
import '../utils/calendar_date.dart';
import '../../presentation/providers/fuel_log_provider.dart';
import '../../presentation/providers/reminder_provider.dart';
import '../../presentation/providers/service_log_provider.dart';
import '../../presentation/providers/vehicle_provider.dart';

/// What the user sees in the confirmation dialog before a gated tool runs.
class AiActionPreview {
  final String title;
  final String message;
  final String confirmLabel;

  const AiActionPreview({
    required this.title,
    required this.message,
    required this.confirmLabel,
  });
}

/// Executes Claude's tool calls against the app's OWN existing repositories
/// — the same objects the manual-CRUD screens use (same JWT, same error
/// handling, same backend). Never talks to Anthropic itself; that is
/// [ClaudeClient]'s job. Throws [AppException] on failure; the orchestrator
/// turns that into an `is_error` tool_result for Claude.
///
/// Also holds a [Ref] purely to invalidate the relevant list providers after
/// a write — writes go straight through the repository, bypassing the
/// StateNotifiers the manual-CRUD screens use (and refresh themselves after
/// submit), so without this the Garage/list screens keep showing stale data
/// until a manual pull-to-refresh.
class AiToolExecutor {
  final VehicleRepository _vehicleRepository;
  final FuelLogRepository _fuelLogRepository;
  final ServiceLogRepository _serviceLogRepository;
  final ReminderRepository _reminderRepository;
  final Ref _ref;

  AiToolExecutor({
    required VehicleRepository vehicleRepository,
    required FuelLogRepository fuelLogRepository,
    required ServiceLogRepository serviceLogRepository,
    required ReminderRepository reminderRepository,
    required Ref ref,
  })  : _vehicleRepository = vehicleRepository,
        _fuelLogRepository = fuelLogRepository,
        _serviceLogRepository = serviceLogRepository,
        _reminderRepository = reminderRepository,
        _ref = ref;

  Future<String> execute(String name, Map<String, dynamic> input) async {
    switch (name) {
      case 'list_vehicles':
        return _listVehicles();
      case 'get_vehicle':
        return _getVehicle(input);
      case 'add_vehicle':
        return _addVehicle(input);
      case 'update_vehicle':
        return _updateVehicle(input);
      case 'delete_vehicle':
        return _deleteVehicle(input);
      case 'list_fuel_logs':
        return _listFuelLogs(input);
      case 'get_fuel_log':
        return _getFuelLog(input);
      case 'add_fuel_log':
        return _addFuelLog(input);
      case 'update_fuel_log':
        return _updateFuelLog(input);
      case 'delete_fuel_log':
        return _deleteFuelLog(input);
      case 'list_service_logs':
        return _listServiceLogs(input);
      case 'get_service_log':
        return _getServiceLog(input);
      case 'add_service_log':
        return _addServiceLog(input);
      case 'update_service_log':
        return _updateServiceLog(input);
      case 'delete_service_log':
        return _deleteServiceLog(input);
      case 'list_reminders':
        return _listReminders(input);
      case 'get_reminder':
        return _getReminder(input);
      case 'add_reminder':
        return _addReminder(input);
      case 'update_reminder':
        return _updateReminder(input);
      case 'delete_reminder':
        return _deleteReminder(input);
      case 'complete_reminder':
        return _completeReminder(input);
      case 'incomplete_reminder':
        return _incompleteReminder(input);
      default:
        throw AppException(message: 'Nieznane narzędzie: $name');
    }
  }

  // --- confirmation gate ---

  /// Edits and deletes need the user's explicit OK in the UI before they run
  /// — enforced by the orchestrator, not left to the model's good manners.
  /// complete/incomplete reminder stay open: one tap undoes them.
  static const _gatedTools = {
    'update_vehicle',
    'delete_vehicle',
    'update_fuel_log',
    'delete_fuel_log',
    'update_service_log',
    'delete_service_log',
    'update_reminder',
    'delete_reminder',
  };

  bool isGated(String name) => _gatedTools.contains(name);

  static const _idKeys = {
    'vehicleId',
    'fuelLogId',
    'serviceLogId',
    'reminderId',
  };

  static const _fieldLabels = {
    'name': 'Nazwa',
    'make': 'Marka',
    'vehicleModel': 'Model',
    'year': 'Rok',
    'licensePlate': 'Nr rej.',
    'mileage': 'Przebieg',
    'engineCapacity': 'Pojemność',
    'vin': 'VIN',
    'purchaseDate': 'Data zakupu',
    'notes': 'Notatki',
    'fuelAmount': 'Litry',
    'totalCost': 'Koszt',
    'date': 'Data',
    'serviceType': 'Rodzaj serwisu',
    'description': 'Opis',
    'mechanic': 'Mechanik',
    'title': 'Tytuł',
    'type': 'Typ',
    'dueDate': 'Termin',
    'dueMileage': 'Przebieg docelowy',
    'intervalKm': 'Interwał',
    'lastDoneMileage': 'Ostatnio wykonano przy',
  };

  String _subjectFor(String name) {
    if (name.endsWith('_vehicle')) return 'pojazd';
    if (name.endsWith('_fuel_log')) return 'tankowanie';
    if (name.endsWith('_service_log')) return 'wpis serwisowy';
    return 'przypomnienie';
  }

  String _show(Object? value) =>
      value == null || value.toString().isEmpty ? '—' : value.toString();

  /// Builds the dialog text for a gated call: which object it hits (looked up
  /// through the same repositories, so the user sees a name, not an id) and,
  /// for updates, old -> new per changed field. If the lookup fails the
  /// dialog still appears — the gate never depends on the lookup working.
  Future<AiActionPreview> describe(
    String name,
    Map<String, dynamic> input,
  ) async {
    final isDelete = name.startsWith('delete_');
    final subject = _subjectFor(name);
    var target = 'nie udało się pobrać szczegółów';
    var vehicleLine = '';
    var current = <String, dynamic>{};
    var isVehicle = false;

    try {
      final vehicleId = input['vehicleId'] as String?;
      if (vehicleId != null) {
        final vehicle = await _vehicleRepository.getVehicle(vehicleId);
        if (name.endsWith('_vehicle')) {
          isVehicle = true;
          target =
              '${vehicle.name} (${vehicle.make} ${vehicle.vehicleModel}, ${vehicle.year})';
          current = {
            ..._vehicleSummary(vehicle),
            'purchaseDate': vehicle.purchaseDate != null
                ? formatCalendarDate(vehicle.purchaseDate!)
                : null,
            'notes': vehicle.notes,
          };
        } else {
          vehicleLine = 'Pojazd: ${vehicle.name}\n';
          if (name.endsWith('_fuel_log')) {
            final log = await _fuelLogRepository.getFuelLog(
              vehicleId,
              _require(input, 'fuelLogId'),
            );
            target =
                '${formatCalendarDate(log.date)}: ${log.fuelAmount} l, ${log.totalCost} zł, ${log.mileage} km';
            current = _fuelLogSummary(log);
          } else if (name.endsWith('_service_log')) {
            final log = await _serviceLogRepository.getServiceLog(
              vehicleId,
              _require(input, 'serviceLogId'),
            );
            target =
                '${log.serviceType}, ${formatCalendarDate(log.date)}, ${log.mileage} km';
            current = _serviceLogSummary(log);
          } else {
            final reminder = await _reminderRepository.getReminder(
              vehicleId,
              _require(input, 'reminderId'),
            );
            target = reminder.title;
            current = _reminderSummary(reminder);
          }
        }
      }
    } catch (_) {
      // Fall through with the generic target text.
    }

    final buffer = StringBuffer('${vehicleLine}Obiekt: $target');
    if (isDelete) {
      if (isVehicle) {
        buffer.write(
          '\n\nRazem z całą historią: tankowania, serwisy, przypomnienia. '
          'Nieodwracalne.',
        );
      }
    } else {
      buffer.write('\n\nZmiany:');
      for (final entry in input.entries) {
        if (_idKeys.contains(entry.key)) continue;
        final label = _fieldLabels[entry.key] ?? entry.key;
        buffer.write(
          '\n• $label: ${_show(current[entry.key])} → ${_show(entry.value)}',
        );
      }
    }

    return AiActionPreview(
      title: isDelete ? 'Usunąć $subject?' : 'Zmienić $subject?',
      message: buffer.toString(),
      confirmLabel: isDelete ? 'USUŃ' : 'ZMIEŃ',
    );
  }

  // --- helpers ---

  String _require(Map<String, dynamic> input, String key) {
    final value = input[key] as String?;
    if (value == null || value.isEmpty) {
      throw AppException(message: 'Brakuje wymaganego pola: $key.');
    }
    return value;
  }

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  // --- vehicles ---

  Future<String> _listVehicles() async {
    final vehicles = await _vehicleRepository.getVehicles(limit: 100);
    return jsonEncode(vehicles.map(_vehicleSummary).toList());
  }

  Future<String> _getVehicle(Map<String, dynamic> input) async {
    final vehicle =
        await _vehicleRepository.getVehicle(_require(input, 'vehicleId'));
    return jsonEncode(_vehicleSummary(vehicle));
  }

  Map<String, dynamic> _vehicleSummary(Vehicle v) => {
        'id': v.id,
        'name': v.name,
        'make': v.make,
        'vehicleModel': v.vehicleModel,
        'year': v.year,
        'mileage': v.mileage,
        'engineCapacity': v.engineCapacity,
        'licensePlate': v.licensePlate,
        'vin': v.vin,
      };

  Future<String> _addVehicle(Map<String, dynamic> input) async {
    final now = DateTime.now();
    final purchaseDateStr = input['purchaseDate'] as String?;
    final created = await _vehicleRepository.createVehicle(Vehicle(
      id: '',
      userId: '',
      name: _require(input, 'name'),
      make: _require(input, 'make'),
      vehicleModel: _require(input, 'vehicleModel'),
      year: (input['year'] as num?)?.toInt() ??
          (throw AppException(message: 'Brakuje wymaganego pola: year.')),
      licensePlate: _require(input, 'licensePlate'),
      mileage: (input['mileage'] as num?)?.toInt(),
      engineCapacity: (input['engineCapacity'] as num?)?.toInt(),
      vin: input['vin'] as String?,
      purchaseDate:
          purchaseDateStr != null ? parseCalendarDate(purchaseDateStr) : null,
      notes: input['notes'] as String?,
      createdAt: now,
      updatedAt: now,
    ));
    _ref.invalidate(vehicleListProvider);
    return jsonEncode(_vehicleSummary(created));
  }

  Future<String> _updateVehicle(Map<String, dynamic> input) async {
    final vehicleId = _require(input, 'vehicleId');
    final current = await _vehicleRepository.getVehicle(vehicleId);
    final purchaseDateStr = input['purchaseDate'] as String?;
    final updated = await _vehicleRepository.updateVehicle(current.copyWith(
      name: input['name'] as String?,
      make: input['make'] as String?,
      vehicleModel: input['vehicleModel'] as String?,
      year: (input['year'] as num?)?.toInt(),
      licensePlate: input['licensePlate'] as String?,
      mileage: (input['mileage'] as num?)?.toInt(),
      engineCapacity: (input['engineCapacity'] as num?)?.toInt(),
      vin: input['vin'] as String?,
      purchaseDate:
          purchaseDateStr != null ? parseCalendarDate(purchaseDateStr) : null,
      notes: input['notes'] as String?,
      updatedAt: DateTime.now(),
    ));
    _ref.invalidate(vehicleListProvider);
    return jsonEncode(_vehicleSummary(updated));
  }

  Future<String> _deleteVehicle(Map<String, dynamic> input) async {
    final vehicleId = _require(input, 'vehicleId');
    await _vehicleRepository.deleteVehicle(vehicleId);
    _ref.invalidate(vehicleListProvider);
    return jsonEncode({'deleted': true, 'vehicleId': vehicleId});
  }

  // --- fuel logs ---

  Map<String, dynamic> _fuelLogSummary(FuelLog f) => {
        'id': f.id,
        'mileage': f.mileage,
        'fuelAmount': f.fuelAmount,
        'totalCost': f.totalCost,
        'date': formatCalendarDate(f.date),
        'notes': f.notes,
      };

  Future<String> _listFuelLogs(Map<String, dynamic> input) async {
    final vehicleId = _require(input, 'vehicleId');
    final logs = await _fuelLogRepository.getFuelLogs(
      vehicleId,
      page: (input['page'] as num?)?.toInt() ?? 1,
      limit: (input['limit'] as num?)?.toInt() ?? 20,
    );
    return jsonEncode(logs.map(_fuelLogSummary).toList());
  }

  Future<String> _getFuelLog(Map<String, dynamic> input) async {
    final log = await _fuelLogRepository.getFuelLog(
      _require(input, 'vehicleId'),
      _require(input, 'fuelLogId'),
    );
    return jsonEncode(_fuelLogSummary(log));
  }

  Future<String> _addFuelLog(Map<String, dynamic> input) async {
    final vehicleId = _require(input, 'vehicleId');
    final mileage = (input['mileage'] as num?)?.toInt();
    final fuelAmount = (input['fuelAmount'] as num?)?.toDouble();
    final totalCost = (input['totalCost'] as num?)?.toDouble();
    if (mileage == null || fuelAmount == null || totalCost == null) {
      throw AppException(
        message: 'Brakuje wymaganych pól (mileage, fuelAmount, totalCost).',
      );
    }
    final dateStr = input['date'] as String?;
    final now = DateTime.now();
    final created = await _fuelLogRepository.createFuelLog(
      vehicleId,
      FuelLog(
        id: '',
        vehicleId: vehicleId,
        date: dateStr != null ? parseCalendarDate(dateStr) : _today(),
        mileage: mileage,
        fuelAmount: fuelAmount,
        totalCost: totalCost,
        notes: input['notes'] as String?,
        createdAt: now,
        updatedAt: now,
      ),
    );
    _ref.invalidate(fuelLogListProvider(vehicleId));
    return jsonEncode(_fuelLogSummary(created));
  }

  Future<String> _updateFuelLog(Map<String, dynamic> input) async {
    final vehicleId = _require(input, 'vehicleId');
    final fuelLogId = _require(input, 'fuelLogId');
    final current = await _fuelLogRepository.getFuelLog(vehicleId, fuelLogId);
    final dateStr = input['date'] as String?;
    final updated = await _fuelLogRepository.updateFuelLog(
      vehicleId,
      current.copyWith(
        mileage: (input['mileage'] as num?)?.toInt(),
        fuelAmount: (input['fuelAmount'] as num?)?.toDouble(),
        totalCost: (input['totalCost'] as num?)?.toDouble(),
        date: dateStr != null ? parseCalendarDate(dateStr) : null,
        notes: input['notes'] as String?,
        updatedAt: DateTime.now(),
      ),
    );
    _ref.invalidate(fuelLogListProvider(vehicleId));
    return jsonEncode(_fuelLogSummary(updated));
  }

  Future<String> _deleteFuelLog(Map<String, dynamic> input) async {
    final vehicleId = _require(input, 'vehicleId');
    final fuelLogId = _require(input, 'fuelLogId');
    await _fuelLogRepository.deleteFuelLog(vehicleId, fuelLogId);
    _ref.invalidate(fuelLogListProvider(vehicleId));
    return jsonEncode({'deleted': true, 'fuelLogId': fuelLogId});
  }

  // --- service logs ---

  Map<String, dynamic> _serviceLogSummary(ServiceLog s) => {
        'id': s.id,
        'mileage': s.mileage,
        'serviceType': s.serviceType,
        'date': formatCalendarDate(s.date),
        'totalCost': s.totalCost,
        'description': s.description,
        'mechanic': s.mechanic,
        'notes': s.notes,
      };

  Future<String> _listServiceLogs(Map<String, dynamic> input) async {
    final vehicleId = _require(input, 'vehicleId');
    final logs = await _serviceLogRepository.getServiceLogs(
      vehicleId,
      page: (input['page'] as num?)?.toInt() ?? 1,
      limit: (input['limit'] as num?)?.toInt() ?? 20,
    );
    return jsonEncode(logs.map(_serviceLogSummary).toList());
  }

  Future<String> _getServiceLog(Map<String, dynamic> input) async {
    final log = await _serviceLogRepository.getServiceLog(
      _require(input, 'vehicleId'),
      _require(input, 'serviceLogId'),
    );
    return jsonEncode(_serviceLogSummary(log));
  }

  Future<String> _addServiceLog(Map<String, dynamic> input) async {
    final vehicleId = _require(input, 'vehicleId');
    final mileage = (input['mileage'] as num?)?.toInt();
    final serviceType = input['serviceType'] as String?;
    if (mileage == null || serviceType == null || serviceType.isEmpty) {
      throw AppException(
        message: 'Brakuje wymaganych pól (mileage, serviceType).',
      );
    }
    final dateStr = input['date'] as String?;
    final now = DateTime.now();
    final created = await _serviceLogRepository.createServiceLog(
      vehicleId,
      ServiceLog(
        id: '',
        vehicleId: vehicleId,
        date: dateStr != null ? parseCalendarDate(dateStr) : _today(),
        mileage: mileage,
        serviceType: serviceType,
        description: input['description'] as String?,
        mechanic: input['mechanic'] as String?,
        totalCost: (input['totalCost'] as num?)?.toDouble() ?? 0,
        notes: input['notes'] as String?,
        createdAt: now,
        updatedAt: now,
      ),
    );
    _ref.invalidate(serviceLogListProvider(vehicleId));
    return jsonEncode(_serviceLogSummary(created));
  }

  Future<String> _updateServiceLog(Map<String, dynamic> input) async {
    final vehicleId = _require(input, 'vehicleId');
    final serviceLogId = _require(input, 'serviceLogId');
    final current =
        await _serviceLogRepository.getServiceLog(vehicleId, serviceLogId);
    final dateStr = input['date'] as String?;
    final updated = await _serviceLogRepository.updateServiceLog(
      vehicleId,
      current.copyWith(
        mileage: (input['mileage'] as num?)?.toInt(),
        serviceType: input['serviceType'] as String?,
        date: dateStr != null ? parseCalendarDate(dateStr) : null,
        totalCost: (input['totalCost'] as num?)?.toDouble(),
        description: input['description'] as String?,
        mechanic: input['mechanic'] as String?,
        notes: input['notes'] as String?,
        updatedAt: DateTime.now(),
      ),
    );
    _ref.invalidate(serviceLogListProvider(vehicleId));
    return jsonEncode(_serviceLogSummary(updated));
  }

  Future<String> _deleteServiceLog(Map<String, dynamic> input) async {
    final vehicleId = _require(input, 'vehicleId');
    final serviceLogId = _require(input, 'serviceLogId');
    await _serviceLogRepository.deleteServiceLog(vehicleId, serviceLogId);
    _ref.invalidate(serviceLogListProvider(vehicleId));
    return jsonEncode({'deleted': true, 'serviceLogId': serviceLogId});
  }

  // --- reminders ---

  Map<String, dynamic> _reminderSummary(Reminder r) => {
        'id': r.id,
        'title': r.title,
        'type': r.type.name,
        'dueDate': r.dueDate != null ? formatCalendarDate(r.dueDate!) : null,
        'dueMileage': r.dueMileage,
        'intervalKm': r.intervalKm,
        'lastDoneMileage': r.lastDoneMileage,
        'isCompleted': r.isCompleted,
        'notes': r.notes,
      };

  Future<String> _listReminders(Map<String, dynamic> input) async {
    final vehicleId = _require(input, 'vehicleId');
    final filterStr = input['filter'] as String?;
    final filter = ReminderFilter.values.firstWhere(
      (f) => f.name == filterStr,
      orElse: () => ReminderFilter.active,
    );
    final reminders = await _reminderRepository.getReminders(
      vehicleId,
      page: (input['page'] as num?)?.toInt() ?? 1,
      limit: (input['limit'] as num?)?.toInt() ?? 20,
      filter: filter,
    );
    return jsonEncode(reminders.map(_reminderSummary).toList());
  }

  Future<String> _getReminder(Map<String, dynamic> input) async {
    final reminder = await _reminderRepository.getReminder(
      _require(input, 'vehicleId'),
      _require(input, 'reminderId'),
    );
    return jsonEncode(_reminderSummary(reminder));
  }

  /// The reminder list provider is keyed by (vehicleId, filter) — invalidate
  /// all three filter tabs since we don't know which one is on screen.
  void _invalidateReminders(String vehicleId) {
    for (final filter in ReminderFilter.values) {
      _ref.invalidate(reminderListProvider((vehicleId, filter)));
    }
  }

  /// Backend does NOT enforce dueDate-for-type-date or
  /// dueMileage-for-type-mileage — enforced here so Claude re-asks instead
  /// of creating a garbage reminder.
  void _validateReminderFields({
    required ReminderType type,
    DateTime? dueDate,
    int? dueMileage,
  }) {
    if (type == ReminderType.date && dueDate == null) {
      throw AppException(
        message:
            'Brakuje daty (dueDate) dla przypomnienia typu "date" — dopytaj usera.',
      );
    }
    if (type == ReminderType.mileage && dueMileage == null) {
      throw AppException(
        message:
            'Brakuje przebiegu (dueMileage) dla przypomnienia typu "mileage" — dopytaj usera.',
      );
    }
  }

  Future<String> _addReminder(Map<String, dynamic> input) async {
    final vehicleId = _require(input, 'vehicleId');
    final title = _require(input, 'title');
    final typeStr = _require(input, 'type');
    final type = ReminderType.values.firstWhere(
      (t) => t.name == typeStr,
      orElse: () =>
          throw AppException(message: 'Nieprawidłowy typ przypomnienia: $typeStr.'),
    );
    final dueDateStr = input['dueDate'] as String?;
    final dueDate = dueDateStr != null ? parseCalendarDate(dueDateStr) : null;
    final dueMileage = (input['dueMileage'] as num?)?.toInt();
    _validateReminderFields(type: type, dueDate: dueDate, dueMileage: dueMileage);

    final now = DateTime.now();
    final created = await _reminderRepository.createReminder(
      vehicleId,
      Reminder(
        id: '',
        vehicleId: vehicleId,
        title: title,
        type: type,
        dueDate: dueDate,
        dueMileage: dueMileage,
        intervalKm: (input['intervalKm'] as num?)?.toInt(),
        lastDoneMileage: (input['lastDoneMileage'] as num?)?.toInt(),
        isCompleted: false,
        notes: input['notes'] as String?,
        createdAt: now,
        updatedAt: now,
      ),
    );
    _invalidateReminders(vehicleId);
    return jsonEncode(_reminderSummary(created));
  }

  Future<String> _updateReminder(Map<String, dynamic> input) async {
    final vehicleId = _require(input, 'vehicleId');
    final reminderId = _require(input, 'reminderId');
    final current = await _reminderRepository.getReminder(vehicleId, reminderId);

    final typeStr = input['type'] as String?;
    final type = typeStr != null
        ? ReminderType.values.firstWhere(
            (t) => t.name == typeStr,
            orElse: () =>
                throw AppException(message: 'Nieprawidłowy typ przypomnienia: $typeStr.'),
          )
        : current.type;
    final dueDateStr = input['dueDate'] as String?;
    final dueDate = dueDateStr != null ? parseCalendarDate(dueDateStr) : current.dueDate;
    final dueMileage = (input['dueMileage'] as num?)?.toInt() ?? current.dueMileage;
    _validateReminderFields(type: type, dueDate: dueDate, dueMileage: dueMileage);

    final updated = await _reminderRepository.updateReminder(
      vehicleId,
      current.copyWith(
        title: input['title'] as String?,
        type: type,
        dueDate: dueDate,
        dueMileage: dueMileage,
        intervalKm: (input['intervalKm'] as num?)?.toInt(),
        lastDoneMileage: (input['lastDoneMileage'] as num?)?.toInt(),
        notes: input['notes'] as String?,
        updatedAt: DateTime.now(),
      ),
    );
    _invalidateReminders(vehicleId);
    return jsonEncode(_reminderSummary(updated));
  }

  Future<String> _deleteReminder(Map<String, dynamic> input) async {
    final vehicleId = _require(input, 'vehicleId');
    final reminderId = _require(input, 'reminderId');
    await _reminderRepository.deleteReminder(vehicleId, reminderId);
    _invalidateReminders(vehicleId);
    return jsonEncode({'deleted': true, 'reminderId': reminderId});
  }

  Future<String> _completeReminder(Map<String, dynamic> input) async {
    final vehicleId = _require(input, 'vehicleId');
    final updated = await _reminderRepository.markAsCompleted(
      vehicleId,
      _require(input, 'reminderId'),
    );
    _invalidateReminders(vehicleId);
    return jsonEncode(_reminderSummary(updated));
  }

  Future<String> _incompleteReminder(Map<String, dynamic> input) async {
    final vehicleId = _require(input, 'vehicleId');
    final updated = await _reminderRepository.markAsIncomplete(
      vehicleId,
      _require(input, 'reminderId'),
    );
    _invalidateReminders(vehicleId);
    return jsonEncode(_reminderSummary(updated));
  }
}
