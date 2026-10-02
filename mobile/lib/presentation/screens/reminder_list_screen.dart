import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../domain/entities/reminder.dart';
import '../providers/reminder_provider.dart';
import '../providers/vehicle_provider.dart';
import '../utils/format.dart';
import '../utils/interval_status.dart';
import '../widgets/delete_confirmation_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_view.dart';
import '../widgets/garage_button.dart';
import '../widgets/interval_bar.dart';
import '../widgets/screen_header.dart';
import '../widgets/stamp_badge.dart';
import '../widgets/workshop_card.dart';

/// §6 row 7 — alerts as work orders, each carrying its own interval bar.
class ReminderListScreen extends ConsumerStatefulWidget {
  const ReminderListScreen({super.key, required this.vehicleId});

  final String vehicleId;

  @override
  ConsumerState<ReminderListScreen> createState() => _ReminderListScreenState();
}

class _ReminderListScreenState extends ConsumerState<ReminderListScreen> {
  ReminderFilter _filter = ReminderFilter.active;

  void _changeFilter(ReminderFilter filter) {
    if (_filter != filter) {
      setState(() => _filter = filter);
      ref
          .read(reminderListProvider((widget.vehicleId, filter)).notifier)
          .setFilter(filter);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reminderListProvider((widget.vehicleId, _filter)));
    final vehicle = ref.watch(vehicleDetailProvider(widget.vehicleId)).vehicle;

    ref.listen<ReminderListState>(
        reminderListProvider((widget.vehicleId, _filter)), (previous, next) {
      if (next.status == ReminderListStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage ?? 'Coś się zacięło.')),
        );
      }
    });

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                ScreenHeader(
                  tagLeft: vehicle?.name ?? 'ALERTY',
                  tagRight: 'ZLECENIA',
                  title: 'ALERTY',
                  subtitle:
                      'POZYCJI: ${Fmt.serial(state.reminders.length, width: 2)}',
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppGeo.screenMargin,
                    16,
                    AppGeo.screenMargin,
                    4,
                  ),
                  child: SegmentedButton<ReminderFilter>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: ReminderFilter.active,
                        label: Text('OTWARTE'),
                      ),
                      ButtonSegment(
                        value: ReminderFilter.completed,
                        label: Text('ODHACZONE'),
                      ),
                      ButtonSegment(
                        value: ReminderFilter.all,
                        label: Text('WSZYSTKIE'),
                      ),
                    ],
                    selected: {_filter},
                    onSelectionChanged: (selection) =>
                        _changeFilter(selection.first),
                  ),
                ),
                Expanded(child: _buildBody(context, state, vehicle?.mileage)),
              ],
            ),
            Positioned(
              right: AppGeo.screenMargin,
              bottom: 24,
              child: GarageFab(
                onPressed: () => context
                    .push('/vehicles/${widget.vehicleId}/reminders/new'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ReminderListState state,
    int? vehicleMileage,
  ) {
    switch (state.status) {
      case ReminderListStatus.loading:
      case ReminderListStatus.initial:
        return const LoadingView(label: 'ZBIERAM ZLECENIA');
      case ReminderListStatus.error:
        return ErrorView(
          detail: state.errorMessage,
          onRetry: () => ref
              .read(reminderListProvider((widget.vehicleId, _filter)).notifier)
              .refresh(),
        );
      case ReminderListStatus.loaded:
        if (state.reminders.isEmpty) {
          return EmptyState(
            tag: 'POZYCJI: 00',
            title: _emptyTitle(),
            subtitle: _emptySubtitle(),
          );
        }
        return RefreshIndicator(
          color: AppColors.oxideLit,
          backgroundColor: AppColors.dirtyBlack,
          onRefresh: () => ref
              .read(reminderListProvider((widget.vehicleId, _filter)).notifier)
              .refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              AppGeo.screenMargin,
              16,
              AppGeo.screenMargin,
              110,
            ),
            itemCount: state.reminders.length,
            itemBuilder: (context, index) => _WorkOrderCard(
              vehicleId: widget.vehicleId,
              reminder: state.reminders[index],
              vehicleMileage: vehicleMileage,
            ),
          ),
        );
    }
  }

  String _emptyTitle() {
    switch (_filter) {
      case ReminderFilter.active:
        return 'NIC NIE WISI. JEDŹ.';
      case ReminderFilter.completed:
        return 'NIC ODHACZONE.';
      case ReminderFilter.all:
        return 'TABLICA PUSTA.';
    }
  }

  String _emptySubtitle() {
    switch (_filter) {
      case ReminderFilter.active:
        return 'Żadne zlecenie nie czeka.';
      case ReminderFilter.completed:
        return 'Jeszcze nic nie zostało odhaczone.';
      case ReminderFilter.all:
        return 'Powieś pierwsze zlecenie na tablicy.';
    }
  }
}

/// Work order card: title, status stamp, the due line, and — when the
/// reminder has an interval and the vehicle has an odometer reading — the
/// §7 interval bar repeated from the vehicle screen.
class _WorkOrderCard extends ConsumerWidget {
  const _WorkOrderCard({
    required this.vehicleId,
    required this.reminder,
    required this.vehicleMileage,
  });

  final String vehicleId;
  final Reminder reminder;
  final int? vehicleMileage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter =
        reminder.isCompleted ? ReminderFilter.completed : ReminderFilter.active;
    final status = IntervalStatus.forReminder(reminder, vehicleMileage);
    final (stampLabel, stampVariant) = _stamp(status);

    return Dismissible(
      key: Key(reminder.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => confirmDelete(
        context,
        title: 'ZDEJMIJ ZLECENIE',
        message: 'Usunąć „${reminder.title}" z tablicy?',
        confirmLabel: 'ZDEJMIJ',
      ),
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        ref
            .read(reminderListProvider((vehicleId, filter)).notifier)
            .clearError();
        ref
            .read(reminderDetailNotifierProvider((vehicleId, reminder.id)))
            .deleteReminder(reminder.id)
            .then((_) {
          ref
              .read(reminderListProvider((vehicleId, filter)).notifier)
              .refresh();
        });
      },
      background: const SwipeDeleteBackground(label: 'ZDEJMIJ'),
      child: WorkshopCard(
        onTap: () =>
            context.push('/vehicles/$vehicleId/reminders/${reminder.id}'),
        borderColor: status != null && status.isOverdue
            ? AppColors.oxideOrange
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    reminder.title.toUpperCase(),
                    style: AppText.condensed(size: 21, color: AppColors.bone),
                  ),
                ),
                const SizedBox(width: 10),
                StampBadge(label: stampLabel, variant: stampVariant),
              ],
            ),
            const SizedBox(height: 6),
            Text(_dueLine(), style: AppText.data(size: 11, color: AppColors.fadedInk)),
            if (status != null) ...[
              Container(
                height: 1,
                margin: const EdgeInsets.fromLTRB(0, 12, 0, 12),
                color: AppColors.hairline,
              ),
              IntervalBar(status: status, showStamp: false),
            ],
          ],
        ),
      ),
    );
  }

  String _dueLine() {
    if (reminder.isCompleted) {
      final at = reminder.completedAt;
      return at != null ? 'ODHACZONE ${Fmt.date(at)}' : 'ODHACZONE';
    }
    if (reminder.type == ReminderType.mileage) {
      final parts = <String>[];
      if (reminder.dueMileage != null) {
        parts.add('PRZY ${Fmt.kmUnit(reminder.dueMileage!)}');
      }
      if (reminder.intervalKm != null) {
        parts.add('CO ${Fmt.kmUnit(reminder.intervalKm!)}');
      }
      return parts.isEmpty ? 'BEZ TERMINU' : parts.join(' · ');
    }
    if (reminder.dueDate != null) {
      return '${Fmt.date(reminder.dueDate!)} · ${_relativeDays(reminder.dueDate!)}';
    }
    return 'BEZ TERMINU';
  }

  static String _relativeDays(DateTime due) {
    final now = DateTime.now();
    final days = DateTime(due.year, due.month, due.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
    if (days < 0) return '${-days} DNI PO TERMINIE';
    if (days == 0) return 'DZIŚ';
    return 'ZA $days DNI';
  }

  /// Status stamp. Mileage reminders take it from the interval maths; date
  /// reminders from the days left. Never a bare red word on black.
  (String, StampVariant) _stamp(IntervalStatus? status) {
    if (reminder.isCompleted) {
      return ('WYKONANO', StampVariant.wykonano);
    }
    if (status != null) {
      return (status.stampLabel, status.stampVariant);
    }
    if (reminder.type == ReminderType.date && reminder.dueDate != null) {
      final now = DateTime.now();
      final days = DateTime(reminder.dueDate!.year, reminder.dueDate!.month,
              reminder.dueDate!.day)
          .difference(DateTime(now.year, now.month, now.day))
          .inDays;
      if (days < 0) return ('ZALEGŁE', StampVariant.zalegle);
      if (days <= 7) return ('TERMIN', StampVariant.termin);
      if (days <= 30) return ('KONTROLA', StampVariant.kontrola);
      return ('OK', StampVariant.ok);
    }
    return ('OTWARTE', StampVariant.neutral);
  }
}
