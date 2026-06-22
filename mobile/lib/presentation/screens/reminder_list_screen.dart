import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../domain/entities/reminder.dart';
import '../providers/reminder_provider.dart';
import '../utils/date_utils.dart' as app_date_utils;
import '../widgets/data_list_tile.dart';
import '../widgets/empty_state.dart';

class ReminderListScreen extends ConsumerStatefulWidget {
  final String vehicleId;

  const ReminderListScreen({super.key, required this.vehicleId});

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

    ref.listen<ReminderListState>(
        reminderListProvider((widget.vehicleId, _filter)), (previous, next) {
      if (next.status == ReminderListStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage ?? 'Wystąpił błąd')),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('PRZYPOMNIENIA')),
      body: Column(
        children: [
          _buildFilterSelector(),
          Expanded(child: _buildBody(context, ref, state)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            context.push('/vehicles/${widget.vehicleId}/reminders/new'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterSelector() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: SegmentedButton<ReminderFilter>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: ReminderFilter.active, label: Text('AKTYWNE')),
            ButtonSegment(
                value: ReminderFilter.completed, label: Text('UKOŃCZONE')),
            ButtonSegment(value: ReminderFilter.all, label: Text('WSZYSTKIE')),
          ],
          selected: {_filter},
          onSelectionChanged: (selection) => _changeFilter(selection.first),
        ),
      );

  Widget _buildBody(
      BuildContext context, WidgetRef ref, ReminderListState state) {
    switch (state.status) {
      case ReminderListStatus.loading:
      case ReminderListStatus.initial:
        return const Center(child: CircularProgressIndicator());
      case ReminderListStatus.loaded:
        if (state.reminders.isEmpty) {
          return EmptyState(
            icon: _filter == ReminderFilter.completed
                ? Icons.check_circle_outline
                : Icons.notifications_none,
            title: _getEmptyMessage(),
            subtitle: _getEmptySubmessage(),
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref
              .read(reminderListProvider((widget.vehicleId, _filter)).notifier)
              .refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: state.reminders.length,
            itemBuilder: (context, index) {
              final reminder = state.reminders[index];
              return _ReminderListItem(
                  vehicleId: widget.vehicleId, reminder: reminder);
            },
          ),
        );
      case ReminderListStatus.error:
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
                onPressed: () => ref
                    .read(reminderListProvider((widget.vehicleId, _filter))
                        .notifier)
                    .refresh(),
                icon: const Icon(Icons.refresh),
                label: const Text('SPRÓBUJ PONOWNIE'),
              ),
            ],
          ),
        );
    }
  }

  String _getEmptyMessage() {
    switch (_filter) {
      case ReminderFilter.active:
        return 'Brak aktywnych przypomnień';
      case ReminderFilter.completed:
        return 'Brak ukończonych przypomnień';
      case ReminderFilter.all:
        return 'Brak przypomnień';
    }
  }

  String _getEmptySubmessage() {
    switch (_filter) {
      case ReminderFilter.active:
        return 'Wszystkie przypomnienia są ukończone';
      case ReminderFilter.completed:
        return 'Nie masz jeszcze ukończonych przypomnień';
      case ReminderFilter.all:
        return 'Dodaj swoje pierwsze przypomnienie';
    }
  }
}

class _ReminderListItem extends ConsumerWidget {
  final String vehicleId;
  final Reminder reminder;

  const _ReminderListItem({required this.vehicleId, required this.reminder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = reminder.isCompleted
        ? ReminderFilter.completed
        : ReminderFilter.active;

    return Dismissible(
      key: Key(reminder.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Usuń przypomnienie'),
                content:
                    const Text('Czy na pewno chcesz usunąć to przypomnienie?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Anuluj'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Usuń'),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        ref.read(reminderListProvider((vehicleId, filter)).notifier).clearError();
        ref
            .read(reminderDetailNotifierProvider((vehicleId, reminder.id)))
            .deleteReminder(reminder.id)
            .then((_) {
          ref
              .read(reminderListProvider((vehicleId, filter)).notifier)
              .refresh();
        });
      },
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        color: Theme.of(context).colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: Icon(Icons.delete, color: Theme.of(context).colorScheme.onError),
      ),
      child: DataListTile(
        primary: reminder.title,
        secondary: _subtitle(reminder),
        badge: _StatusBadge(reminder: reminder),
        onTap: () =>
            context.push('/vehicles/$vehicleId/reminders/${reminder.id}'),
      ),
    );
  }

  String _subtitle(Reminder reminder) {
    if (reminder.type == ReminderType.mileage && reminder.dueMileage != null) {
      return 'PRZY ${reminder.dueMileage} KM';
    }
    if (reminder.dueDate != null) {
      final date = app_date_utils.DateUtils.formatDate(reminder.dueDate!);
      if (reminder.isCompleted) return date;
      final relative = _relativeDays(reminder.dueDate!);
      return '$relative · $date';
    }
    return '';
  }

  String _relativeDays(DateTime due) {
    final now = DateTime.now();
    final days = DateTime(due.year, due.month, due.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
    if (days < 0) return '${-days} dni temu';
    if (days == 0) return 'Dziś';
    return 'Za $days dni';
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.reminder});

  final Reminder reminder;

  @override
  Widget build(BuildContext context) {
    final (color, label) = _status();
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(38),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          letterSpacing: 1,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  (Color, String) _status() {
    if (reminder.isCompleted) return (Colors.green, 'GOTOWE');
    if (reminder.type == ReminderType.date && reminder.dueDate != null) {
      final now = DateTime.now();
      final days = DateTime(reminder.dueDate!.year, reminder.dueDate!.month,
              reminder.dueDate!.day)
          .difference(DateTime(now.year, now.month, now.day))
          .inDays;
      if (days < 0) return (Colors.red, 'ZALEGŁE');
      if (days <= 7) return (Colors.orange, 'WKRÓTCE');
    }
    return (AppColors.darkLabel, 'AKTYWNE');
  }
}
