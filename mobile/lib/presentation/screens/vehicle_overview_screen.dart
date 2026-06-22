import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../domain/entities/fuel_log.dart';
import '../../domain/entities/reminder.dart';
import '../providers/fuel_log_provider.dart';
import '../providers/reminder_provider.dart';
import '../providers/service_log_provider.dart';
import '../providers/vehicle_provider.dart';
import '../widgets/data_list_tile.dart';
import '../widgets/info_card.dart';
import '../widgets/info_row.dart';
import '../widgets/section_header.dart';
import '../widgets/stat_card.dart';

/// Tab 0 of the vehicle shell — profile with key statistics.
class VehicleOverviewScreen extends ConsumerWidget {
  const VehicleOverviewScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(vehicleDetailProvider(id));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (state.status == VehicleDetailStatus.initial) {
        ref.read(vehicleDetailNotifierProvider(id)).loadVehicle(id);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text((state.vehicle?.name ?? 'Pojazd').toUpperCase()),
        actions: [
          if (state.vehicle != null)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edytuj',
              onPressed: () => context.push('/vehicles/$id/edit'),
            ),
        ],
      ),
      body: _buildBody(context, ref, state),
    );
  }

  Widget _buildBody(
      BuildContext context, WidgetRef ref, VehicleDetailState state) {
    switch (state.status) {
      case VehicleDetailStatus.loading:
      case VehicleDetailStatus.initial:
        return const Center(child: CircularProgressIndicator());
      case VehicleDetailStatus.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  size: 64, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text(
                state.errorMessage ?? 'Wystąpił błąd',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () =>
                    ref.read(vehicleDetailNotifierProvider(id)).loadVehicle(id),
                icon: const Icon(Icons.refresh),
                label: const Text('SPRÓBUJ PONOWNIE'),
              ),
            ],
          ),
        );
      case VehicleDetailStatus.loaded:
        if (state.vehicle == null) {
          return const Center(child: Text('Pojazd nie został znaleziony'));
        }
        final vehicle = state.vehicle!;

        final fuelState = ref.watch(fuelLogListProvider(id));
        final serviceState = ref.watch(serviceLogListProvider(id));
        final reminderState = ref.watch(
          reminderListProvider((id, ReminderFilter.active)),
        );

        final fuelLogs = fuelState.fuelLogs;
        final totalFuel = fuelLogs.fold<double>(0, (s, f) => s + f.fuelAmount);
        final consumption = _averageConsumption(fuelLogs);
        final activeReminders = reminderState.reminders;
        final nextReminder = _nextReminder(activeReminders);

        return RefreshIndicator(
          onRefresh: () async {
            await ref.read(vehicleDetailNotifierProvider(id)).loadVehicle(id);
            ref.read(fuelLogListProvider(id).notifier).refresh();
            ref.read(serviceLogListProvider(id).notifier).refresh();
            ref
                .read(reminderListProvider((id, ReminderFilter.active)).notifier)
                .refresh();
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: 'Przebieg',
                        value: vehicle.mileage != null
                            ? '${vehicle.mileage}'
                            : '—',
                        unit: 'km',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        label: 'Paliwo',
                        value: '${totalFuel.round()} L',
                        unit: 'łącznie',
                      ),
                    ),
                  ],
                ),
              ),
              if (consumption != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.darkSurface,
                      border: Border.all(color: AppColors.darkBorder),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_fire_department,
                            color: AppColors.darkPrimary, size: 20),
                        const SizedBox(width: 10),
                        const Text(
                          'SPALANIE',
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkLabel,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${consumption.toStringAsFixed(1)} L/100km',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkOnBackground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: 'Serwisy',
                        value: '${serviceState.serviceLogs.length}',
                        compact: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        label: 'Tankowań',
                        value: '${fuelLogs.length}',
                        compact: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        label: 'Alerty',
                        value: '${activeReminders.length}',
                        compact: true,
                      ),
                    ),
                  ],
                ),
              ),
              if (nextReminder != null) ...[
                const SectionHeader('Następne przypomnienie'),
                DataListTile(
                  primary: nextReminder.title,
                  secondary: _reminderSubtitle(nextReminder),
                  trailing: _reminderDueLabel(nextReminder),
                ),
              ],
              const SectionHeader('Informacje'),
              InfoCard(
                title: 'Pojazd',
                icon: Icons.info_outline,
                children: [
                  InfoRow(label: 'Marka', value: vehicle.make),
                  InfoRow(label: 'Model', value: vehicle.vehicleModel),
                  InfoRow(label: 'Rok', value: vehicle.year.toString()),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
    }
  }

  /// Average fuel consumption (L/100km) from consecutive entries sorted by
  /// mileage. Returns null when fewer than two usable entries exist.
  double? _averageConsumption(List<FuelLog> logs) {
    if (logs.length < 2) return null;
    final sorted = [...logs]..sort((a, b) => a.mileage.compareTo(b.mileage));
    final consumptions = <double>[];
    for (var i = 1; i < sorted.length; i++) {
      final distance = sorted[i].mileage - sorted[i - 1].mileage;
      if (distance > 0) {
        consumptions.add(sorted[i].fuelAmount / distance * 100);
      }
    }
    if (consumptions.isEmpty) return null;
    return consumptions.reduce((a, b) => a + b) / consumptions.length;
  }

  Reminder? _nextReminder(List<Reminder> reminders) {
    final pending = reminders.where((r) => !r.isCompleted).toList()
      ..sort((a, b) {
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });
    return pending.isEmpty ? null : pending.first;
  }

  String _reminderSubtitle(Reminder reminder) {
    if (reminder.type == ReminderType.mileage && reminder.dueMileage != null) {
      return 'PRZY ${reminder.dueMileage} KM';
    }
    if (reminder.dueDate != null) {
      final d = reminder.dueDate!;
      return '${d.day.toString().padLeft(2, '0')}.'
          '${d.month.toString().padLeft(2, '0')}.${d.year}';
    }
    return '';
  }

  String? _reminderDueLabel(Reminder reminder) {
    if (reminder.dueDate == null) return null;
    final days = reminder.dueDate!
        .difference(DateTime(
            DateTime.now().year, DateTime.now().month, DateTime.now().day))
        .inDays;
    if (days < 0) return 'ZALEGŁE';
    if (days == 0) return 'DZIŚ';
    return 'za $days dni';
  }
}
