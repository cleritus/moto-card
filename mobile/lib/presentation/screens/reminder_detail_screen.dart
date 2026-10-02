import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../domain/entities/reminder.dart';
import '../providers/reminder_provider.dart';
import '../providers/vehicle_provider.dart';
import '../utils/format.dart';
import '../utils/interval_status.dart';
import '../widgets/data_plate.dart';
import '../widgets/delete_confirmation_dialog.dart';
import '../widgets/error_view.dart';
import '../widgets/garage_app_bar.dart';
import '../widgets/garage_button.dart';
import '../widgets/hazard_banner.dart';
import '../widgets/interval_bar.dart';
import '../widgets/section_header.dart';
import '../widgets/stamp_badge.dart';
import '../widgets/workshop_card.dart';

/// §6 row 7 — one work order, open.
class ReminderDetailScreen extends ConsumerWidget {
  const ReminderDetailScreen({
    super.key,
    required this.vehicleId,
    required this.id,
  });

  final String vehicleId;
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reminderDetailProvider((vehicleId, id)));

    ref.listen<ReminderDetailState>(
      reminderDetailProvider((vehicleId, id)),
      (previous, next) {
        if (next.status == ReminderDetailStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next.errorMessage ?? 'Coś się zacięło.')),
          );
        }
      },
    );

    return Scaffold(
      appBar: const GarageAppBar(title: 'ZLECENIE', subtitle: 'TABLICA ALERTÓW'),
      body: _buildBody(context, ref, state),
    );
  }

  Widget _buildBody(
      BuildContext context, WidgetRef ref, ReminderDetailState state) {
    switch (state.status) {
      case ReminderDetailStatus.initial:
      case ReminderDetailStatus.loading:
        return const LoadingView();
      case ReminderDetailStatus.error:
        return ErrorView(
          detail: state.errorMessage,
          onRetry: () => ref
              .read(reminderDetailNotifierProvider((vehicleId, id)))
              .loadReminder(id),
        );
      case ReminderDetailStatus.loaded:
        final reminder = state.reminder;
        if (reminder == null) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('Tego zlecenia nie ma na tablicy.'),
            ),
          );
        }

        final mileage = ref.watch(vehicleDetailProvider(vehicleId)).vehicle?.mileage;
        final status = IntervalStatus.forReminder(reminder, mileage);

        return ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppGeo.screenMargin,
                20,
                AppGeo.screenMargin,
                0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      reminder.title.toUpperCase(),
                      style: AppText.h1(size: 30),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _statusStamp(reminder, status),
                ],
              ),
            ),
            if (status != null && status.isOverdue)
              HazardBanner(
                text: 'ZALEGŁE / ${Fmt.km(status.overdueBy)} KM PO TERMINIE',
              ),
            if (status != null) ...[
              const SectionHeader('INTERWAŁ', bottomGap: 12),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppGeo.screenMargin,
                ),
                child: WorkshopCard(
                  margin: EdgeInsets.zero,
                  padding: const EdgeInsets.fromLTRB(14, 15, 14, 15),
                  child: IntervalBar(status: status),
                ),
              ),
            ],
            const SectionHeader('ZLECENIE', tag: 'TABLICZKA', bottomGap: 12),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppGeo.screenMargin,
              ),
              child: WorkshopCard(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: DataPlate(
                  rows: [
                    DataPlateRow(
                      'TYP',
                      reminder.type == ReminderType.date ? 'DATA' : 'PRZEBIEG',
                    ),
                    if (reminder.type == ReminderType.date &&
                        reminder.dueDate != null)
                      DataPlateRow('TERMIN', Fmt.date(reminder.dueDate!)),
                    if (reminder.type == ReminderType.mileage &&
                        reminder.dueMileage != null)
                      DataPlateRow('PRZY', Fmt.kmUnit(reminder.dueMileage!)),
                    if (reminder.intervalKm != null)
                      DataPlateRow('INTERWAŁ', Fmt.kmUnit(reminder.intervalKm!)),
                    if (reminder.lastDoneMileage != null)
                      DataPlateRow(
                        'OSTATNIO',
                        Fmt.kmUnit(reminder.lastDoneMileage!),
                      ),
                    DataPlateRow(
                      'STATUS',
                      reminder.isCompleted ? 'ODHACZONE' : 'OTWARTE',
                    ),
                    if (reminder.isCompleted && reminder.completedAt != null)
                      DataPlateRow(
                        'WYKONANO',
                        Fmt.date(reminder.completedAt!),
                      ),
                  ],
                ),
              ),
            ),
            if (reminder.notes != null && reminder.notes!.trim().isNotEmpty) ...[
              const SectionHeader('NOTATKI', bottomGap: 12),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppGeo.screenMargin,
                ),
                child: WorkshopCard(
                  margin: EdgeInsets.zero,
                  child: Text(reminder.notes!, style: AppText.body()),
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
              child: Column(
                children: [
                  GarageButton(
                    label: reminder.isCompleted
                        ? 'COFNIJ ODHACZENIE'
                        : 'ODHACZ / WYKONANE',
                    onPressed: () async {
                      final notifier = ref.read(
                        reminderDetailNotifierProvider((vehicleId, id)),
                      );
                      if (reminder.isCompleted) {
                        await notifier.markAsIncomplete(id);
                      } else {
                        await notifier.markAsCompleted(id);
                      }
                      _refreshLists(ref);
                    },
                  ),
                  const SizedBox(height: 12),
                  GarageButton.ghost(
                    label: 'EDYTUJ ZLECENIE',
                    trailingArrow: true,
                    onPressed: () =>
                        context.push('/vehicles/$vehicleId/reminders/$id/edit'),
                  ),
                  const SizedBox(height: 12),
                  GarageButton.danger(
                    label: 'ZDEJMIJ Z TABLICY',
                    onPressed: () => _confirmDelete(context, ref),
                  ),
                ],
              ),
            ),
          ],
        );
    }
  }

  Widget _statusStamp(Reminder reminder, IntervalStatus? status) {
    if (reminder.isCompleted) {
      return const StampBadge(
        label: 'WYKONANO',
        variant: StampVariant.wykonano,
      );
    }
    if (status != null) {
      return StampBadge(
        label: status.stampLabel,
        variant: status.stampVariant,
      );
    }
    if (reminder.type == ReminderType.date && reminder.dueDate != null) {
      final now = DateTime.now();
      final days = DateTime(reminder.dueDate!.year, reminder.dueDate!.month,
              reminder.dueDate!.day)
          .difference(DateTime(now.year, now.month, now.day))
          .inDays;
      if (days < 0) {
        return const StampBadge(
          label: 'ZALEGŁE',
          variant: StampVariant.zalegle,
        );
      }
      if (days <= 7) {
        return const StampBadge(label: 'TERMIN', variant: StampVariant.termin);
      }
    }
    return const StampBadge(label: 'OTWARTE', variant: StampVariant.neutral);
  }

  void _refreshLists(WidgetRef ref) {
    for (final filter in ReminderFilter.values) {
      ref.read(reminderListProvider((vehicleId, filter)).notifier).refresh();
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog<bool>(
      context: context,
      builder: (dialogContext) => DeleteConfirmationDialog(
        title: 'ZDEJMIJ ZLECENIE',
        message: 'Usunąć to zlecenie z tablicy?',
        confirmLabel: 'ZDEJMIJ',
        onConfirm: () async {
          final isCompleted = ref
                  .read(reminderDetailProvider((vehicleId, id)))
                  .reminder
                  ?.isCompleted ??
              false;
          await ref
              .read(reminderDetailNotifierProvider((vehicleId, id)))
              .deleteReminder(id);
          if (context.mounted) {
            final filter = isCompleted
                ? ReminderFilter.completed
                : ReminderFilter.active;
            ref
                .read(reminderListProvider((vehicleId, filter)).notifier)
                .refresh();
            context.pop();
          }
        },
      ),
    );
  }
}
