import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/reminder.dart';
import '../providers/reminder_provider.dart';

class ReminderListScreen extends ConsumerStatefulWidget {
  final String vehicleId;

  const ReminderListScreen({super.key, required this.vehicleId});

  @override
  ConsumerState<ReminderListScreen> createState() => _ReminderListScreenState();
}

class _ReminderListScreenState extends ConsumerState<ReminderListScreen> {
  ReminderFilter _filter = ReminderFilter.active;

  @override
  void initState() {
    super.initState();
    _filter = ReminderFilter.active;
  }

  void _changeFilter(ReminderFilter filter) {
    if (_filter != filter) {
      setState(() => _filter = filter);
      ref.read(reminderListProvider((widget.vehicleId, filter)).notifier).setFilter(filter);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reminderListProvider((widget.vehicleId, _filter)));

    ref.listen<ReminderListState>(reminderListProvider((widget.vehicleId, _filter)), (previous, next) {
      if (next.status == ReminderListStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage ?? 'Wystąpił błąd')),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Przypomnienia'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(reminderListProvider((widget.vehicleId, _filter)).notifier).refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterSelector(),
          Expanded(child: _buildBody(context, ref, state)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/vehicles/${widget.vehicleId}/reminders/new'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SegmentedButton<ReminderFilter>(
        segments: const [
          ButtonSegment(
            value: ReminderFilter.active,
            label: Text('Aktywne'),
            icon: Icon(Icons.fiber_manual_record, size: 16),
          ),
          ButtonSegment(
            value: ReminderFilter.completed,
            label: Text('Zakończone'),
            icon: Icon(Icons.check_circle, size: 16),
          ),
          ButtonSegment(
            value: ReminderFilter.all,
            label: Text('Wszystkie'),
            icon: Icon(Icons.list, size: 16),
          ),
        ],
        selected: {_filter},
        onSelectionChanged: (Set<ReminderFilter> selection) {
          _changeFilter(selection.first);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, ReminderListState state) {
    switch (state.status) {
      case ReminderListStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case ReminderListStatus.loaded:
        if (state.reminders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _filter == ReminderFilter.completed ? Icons.check_circle_outline : Icons.notifications_outlined,
                  size: 80,
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(77),
                ),
                const SizedBox(height: 16),
                Text(
                  _getEmptyMessage(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getEmptySubmessage(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                      ),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref.read(reminderListProvider((widget.vehicleId, _filter)).notifier).refresh(),
          child: ListView.builder(
            itemCount: state.reminders.length,
            itemBuilder: (context, index) {
              final reminder = state.reminders[index];
              return _ReminderListItem(vehicleId: widget.vehicleId, reminder: reminder);
            },
          ),
        );
      case ReminderListStatus.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                state.errorMessage ?? 'Wystąpił błąd',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => ref.read(reminderListProvider((widget.vehicleId, _filter)).notifier).refresh(),
                icon: const Icon(Icons.refresh),
                label: const Text('Spróbuj ponownie'),
              ),
            ],
          ),
        );
      case ReminderListStatus.initial:
        return const Center(child: CircularProgressIndicator());
    }
  }

  String _getEmptyMessage() {
    switch (_filter) {
      case ReminderFilter.active:
        return 'Brak aktywnych przypomień';
      case ReminderFilter.completed:
        return 'Brak zakończonych przypomień';
      case ReminderFilter.all:
        return 'Brak przypomień';
    }
  }

  String _getEmptySubmessage() {
    switch (_filter) {
      case ReminderFilter.active:
        return 'Wszystkie przypomnienia są ukończone';
      case ReminderFilter.completed:
        return 'Nie masz jeszcze zakończonych przypomień';
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
    final dateFormatter = DateFormat('dd.MM.yyyy');

    return Dismissible(
      key: Key(reminder.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Usuń przypomnienie'),
                content: const Text('Czy na pewno chcesz usunąć to przypomnienie?'),
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
        ref
            .read(reminderListProvider((vehicleId, reminder.isCompleted ? ReminderFilter.completed : ReminderFilter.active)).notifier)
            .clearError();
        ref
            .read(reminderDetailNotifierProvider((vehicleId, reminder.id)))
            .deleteReminder(reminder.id)
            .then((_) {
          ref.read(reminderListProvider((vehicleId, reminder.isCompleted ? ReminderFilter.completed : ReminderFilter.active)).notifier).refresh();
        });
      },
      background: Container(
        color: Theme.of(context).colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: Icon(Icons.delete, color: Theme.of(context).colorScheme.onError),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: reminder.isCompleted
            ? Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(77)
            : null,
        child: ListTile(
          leading: Checkbox(
            value: reminder.isCompleted,
            onChanged: (value) {
              if (value == true) {
                ref.read(reminderDetailNotifierProvider((vehicleId, reminder.id))).markAsCompleted(reminder.id);
              } else {
                ref.read(reminderDetailNotifierProvider((vehicleId, reminder.id))).markAsIncomplete(reminder.id);
              }
              // Refresh after a short delay to show the update
              Future.delayed(const Duration(milliseconds: 300), () {
                ref.read(reminderListProvider((vehicleId, value == true ? ReminderFilter.completed : ReminderFilter.active)).notifier).refresh();
              });
            },
          ),
          title: Text(
            reminder.title,
            style: TextStyle(
              decoration: reminder.isCompleted ? TextDecoration.lineThrough : null,
              color: reminder.isCompleted
                  ? Theme.of(context).colorScheme.onSurface.withAlpha(153)
                  : null,
            ),
          ),
          subtitle: Text(_getSubtitle(reminder, dateFormatter)),
          trailing: reminder.type == ReminderType.date && reminder.dueDate != null
              ? Icon(
                  _getDueIcon(reminder),
                  color: _getDueColor(context, reminder),
                )
              : null,
          onTap: () => context.push('/vehicles/$vehicleId/reminders/${reminder.id}'),
        ),
      ),
    );
  }

  String _getSubtitle(Reminder reminder, DateFormat dateFormatter) {
    if (reminder.type == ReminderType.date && reminder.dueDate != null) {
      return '${dateFormatter.format(reminder.dueDate!)}';
    } else if (reminder.type == ReminderType.mileage && reminder.dueMileage != null) {
      return '${reminder.dueMileage} km';
    }
    return '';
  }

  IconData _getDueIcon(Reminder reminder) {
    if (reminder.isCompleted) return Icons.check_circle;
    if (reminder.dueDate == null) return Icons.event;
    final now = DateTime.now();
    final diff = reminder.dueDate!.difference(now).inDays;
    if (diff < 0) return Icons.warning;
    if (diff <= 7) return Icons.notifications_active;
    return Icons.event;
  }

  Color _getDueColor(BuildContext context, Reminder reminder) {
    if (reminder.isCompleted) return Theme.of(context).colorScheme.primary;
    if (reminder.dueDate == null) return Theme.of(context).colorScheme.onSurfaceVariant;
    final now = DateTime.now();
    final diff = reminder.dueDate!.difference(now).inDays;
    if (diff < 0) return Theme.of(context).colorScheme.error;
    if (diff <= 7) return Theme.of(context).colorScheme.primary;
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }
}