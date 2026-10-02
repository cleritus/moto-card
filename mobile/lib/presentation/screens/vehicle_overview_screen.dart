import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../domain/entities/fuel_log.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/entities/vehicle.dart';
import '../providers/fuel_log_provider.dart';
import '../providers/providers.dart';
import '../providers/reminder_provider.dart';
import '../providers/service_log_provider.dart';
import '../providers/vehicle_provider.dart';
import '../utils/format.dart';
import '../utils/interval_status.dart';
import '../widgets/data_plate.dart';
import '../widgets/double_rule.dart';
import '../widgets/error_view.dart';
import '../widgets/garage_button.dart';
import '../widgets/hazard_banner.dart';
import '../widgets/interval_bar.dart';
import '../widgets/interval_gauge.dart';
import '../widgets/section_header.dart';
import '../widgets/workshop_card.dart';

/// §6 row 3 — the vehicle. Designed hero (oil black, never a photo per §9),
/// the worst-interval dial, and the INTERWAŁY section with one bar per
/// mileage alert (§7).
class VehicleOverviewScreen extends ConsumerWidget {
  const VehicleOverviewScreen({
    super.key,
    required this.id,
    this.onOpenServiceBook,
  });

  final String id;

  /// Switches the parent shell to the SERWIS tab instead of pushing a
  /// second, nav-less instance of that screen on top of the stack.
  final VoidCallback? onOpenServiceBook;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(vehicleDetailProvider(id));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (state.status == VehicleDetailStatus.initial) {
        ref.read(vehicleDetailNotifierProvider(id)).loadVehicle(id);
      }
    });

    return Scaffold(
      body: SafeArea(bottom: false, child: _buildBody(context, ref, state)),
    );
  }

  Widget _buildBody(
      BuildContext context, WidgetRef ref, VehicleDetailState state) {
    switch (state.status) {
      case VehicleDetailStatus.loading:
      case VehicleDetailStatus.initial:
        return const LoadingView(label: 'WYKAZ POJAZDU');
      case VehicleDetailStatus.error:
        return ErrorView(
          detail: state.errorMessage,
          onRetry: () =>
              ref.read(vehicleDetailNotifierProvider(id)).loadVehicle(id),
        );
      case VehicleDetailStatus.loaded:
        if (state.vehicle == null) {
          return const EmptyVehicle();
        }
        return _loaded(context, ref, state.vehicle!);
    }
  }

  Widget _loaded(BuildContext context, WidgetRef ref, Vehicle vehicle) {
    final fuelState = ref.watch(fuelLogListProvider(id));
    final serviceState = ref.watch(serviceLogListProvider(id));
    final reminderState = ref.watch(
      reminderListProvider((id, ReminderFilter.active)),
    );

    final fuelLogs = fuelState.fuelLogs;
    final consumption = _averageConsumption(fuelLogs);
    final activeReminders = reminderState.reminders;

    final intervals = activeReminders
        .map((r) => IntervalStatus.forReminder(r, vehicle.mileage))
        .whereType<IntervalStatus>()
        .toList()
      ..sort((a, b) => b.percent.compareTo(a.percent));
    final worst = IntervalStatus.worst(intervals);

    if (vehicle.mileage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkMileageReminders(ref, activeReminders, vehicle.mileage!);
      });
    }

    return RefreshIndicator(
      color: AppColors.oxideLit,
      backgroundColor: AppColors.dirtyBlack,
      onRefresh: () async {
        await ref.read(vehicleDetailNotifierProvider(id)).loadVehicle(id);
        ref.read(fuelLogListProvider(id).notifier).refresh();
        ref.read(serviceLogListProvider(id).notifier).refresh();
        ref
            .read(reminderListProvider((id, ReminderFilter.active)).notifier)
            .refresh();
      },
      child: ListView(
        padding: const EdgeInsets.only(bottom: 48),
        children: [
          _TopMarkings(onEdit: () => context.push('/vehicles/$id/edit')),
          _Hero(vehicle: vehicle, worst: worst),
          if (worst != null && worst.isOverdue)
            HazardBanner(
              text: 'SERWIS ZALEGŁY / ${Fmt.km(worst.overdueBy)} KM',
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppGeo.screenMargin,
              18,
              AppGeo.screenMargin,
              0,
            ),
            child: Column(
              children: [
                GarageButton(
                  label: '+ ZAPISZ SERWIS',
                  onPressed: () =>
                      context.push('/vehicles/$id/service-logs/new'),
                ),
                const SizedBox(height: 12),
                GarageButton.ghost(
                  label: 'KSIĄŻKA SERWISOWA',
                  trailingArrow: true,
                  onPressed: onOpenServiceBook ??
                      () => context.push('/vehicles/$id/service-logs'),
                ),
              ],
            ),
          ),
          if (intervals.isNotEmpty) ...[
            SectionHeader(
              'INTERWAŁY',
              tag: '${intervals.length} POZYCJE',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppGeo.screenMargin,
              ),
              child: WorkshopCard(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.fromLTRB(14, 15, 14, 15),
                child: Column(
                  children: [
                    for (int i = 0; i < intervals.length; i++) ...[
                      if (i > 0) const SizedBox(height: 17),
                      IntervalBar(status: intervals[i]),
                    ],
                  ],
                ),
              ),
            ),
          ],
          if (consumption != null) ...[
            SectionHeader(
              'SPALANIE',
              tag: '${fuelLogs.length} TANKOWAŃ',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppGeo.screenMargin,
              ),
              child: WorkshopCard(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ŚREDNIA', style: AppText.label()),
                        const SizedBox(height: 6),
                        Text(
                          Fmt.decimal1(consumption),
                          style: AppText.data(size: 33, weight: FontWeight.w600)
                              .copyWith(letterSpacing: 0, height: 1),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text('L / 100 KM', style: AppText.micro()),
                  ],
                ),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppGeo.screenMargin,
              AppGeo.sectionGap,
              AppGeo.screenMargin,
              0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: CounterTile(
                    label: 'SERWISY',
                    value: Fmt.serial(serviceState.serviceLogs.length, width: 2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CounterTile(
                    label: 'TANKOWAŃ',
                    value: Fmt.serial(fuelLogs.length, width: 2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CounterTile(
                    label: 'ALERTY',
                    value: Fmt.serial(activeReminders.length, width: 2),
                    highlight: activeReminders.isNotEmpty,
                  ),
                ),
              ],
            ),
          ),
          const SectionHeader('DANE POJAZDU', tag: 'TABLICZKA', bottomGap: 12),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppGeo.screenMargin,
            ),
            child: WorkshopCard(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: DataPlate(
                rows: [
                  DataPlateRow('MARKA', vehicle.make),
                  DataPlateRow('MODEL', vehicle.vehicleModel),
                  DataPlateRow('ROK', '${vehicle.year}'),
                  if (vehicle.engineCapacity != null)
                    DataPlateRow('POJEMNOŚĆ', '${vehicle.engineCapacity} cm³'),
                  if (vehicle.licensePlate.isNotEmpty)
                    DataPlateRow('NR REJ.', vehicle.licensePlate.toUpperCase()),
                  if (vehicle.vin != null && vehicle.vin!.isNotEmpty)
                    DataPlateRow('VIN', vehicle.vin!.toUpperCase()),
                  if (vehicle.purchaseDate != null)
                    DataPlateRow('ZAKUP', Fmt.date(vehicle.purchaseDate!)),
                ],
              ),
            ),
          ),
          if (vehicle.notes != null && vehicle.notes!.isNotEmpty) ...[
            const SectionHeader('NOTATKI', bottomGap: 12),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppGeo.screenMargin,
              ),
              child: WorkshopCard(
                margin: EdgeInsets.zero,
                child: Text(vehicle.notes!, style: AppText.body()),
              ),
            ),
          ],
        ],
      ),
    );
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

  void _checkMileageReminders(
    WidgetRef ref,
    List<Reminder> reminders,
    int currentMileage,
  ) {
    final notificationService = ref.read(notificationServiceProvider);
    for (final reminder in reminders) {
      if (reminder.type == ReminderType.mileage) {
        notificationService.checkMileageReminder(
          reminder: reminder,
          currentMileage: currentMileage,
        );
      }
    }
  }
}

class _TopMarkings extends StatelessWidget {
  const _TopMarkings({required this.onEdit});

  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppGeo.screenMargin,
        10,
        AppGeo.screenMargin,
        0,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('MOTO / POJAZD', style: AppText.micro()),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onEdit,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: Text(
                    'EDYTUJ',
                    style: AppText.micro(color: AppColors.oxideLit),
                  ),
                ),
              ),
            ],
          ),
          const DoubleRule(margin: EdgeInsets.only(top: 6)),
        ],
      ),
    );
  }
}

/// Designed hero: oil black and type. Never the owner's photograph (§9).
class _Hero extends StatelessWidget {
  const _Hero({required this.vehicle, required this.worst});

  final Vehicle vehicle;
  final IntervalStatus? worst;

  @override
  Widget build(BuildContext context) {
    final spec = [
      vehicle.vehicleModel.toUpperCase(),
      '${vehicle.year}',
      if (vehicle.licensePlate.isNotEmpty) vehicle.licensePlate.toUpperCase(),
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppGeo.screenMargin,
        18,
        AppGeo.screenMargin,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            vehicle.make.toUpperCase(),
            style: AppText.label(size: 10).copyWith(letterSpacing: 10 * 0.18),
          ),
          const SizedBox(height: 2),
          Text(
            vehicle.name.toUpperCase(),
            style: AppText.display(size: 44),
          ),
          const SizedBox(height: 9),
          Text(
            spec,
            style: AppText.data(size: 11.5, color: AppColors.fadedInk)
                .copyWith(letterSpacing: 11.5 * 0.1),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.mileage != null ? Fmt.km(vehicle.mileage!) : '—',
                      style: AppText.dataXl(size: 44),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'KM · STAN ${Fmt.date(vehicle.updatedAt)}',
                      style: AppText.micro()
                          .copyWith(letterSpacing: 9.5 * 0.18),
                    ),
                  ],
                ),
              ),
              if (worst != null) ...[
                const SizedBox(width: 14),
                IntervalGauge(status: worst!),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// "Vehicle not found" — kept separate so the message stays in voice.
class EmptyVehicle extends StatelessWidget {
  const EmptyVehicle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DoubleRule(),
            const SizedBox(height: 16),
            Text('STANOWISKO PUSTE.', style: AppText.h1(size: 26)),
            const SizedBox(height: 10),
            Text(
              'Tej maszyny nie ma już w garażu.',
              style: AppText.body(color: AppColors.fadedInk),
            ),
          ],
        ),
      ),
    );
  }
}
