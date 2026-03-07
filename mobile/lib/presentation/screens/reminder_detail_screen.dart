import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/reminder.dart';
import '../providers/reminder_provider.dart';

class ReminderDetailScreen extends ConsumerWidget {
  final String vehicleId;
  final String id;

  const ReminderDetailScreen({super.key, required this.vehicleId, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reminderDetailProvider((vehicleId, id)));

    ref.listen<ReminderDetailState>(
      reminderDetailProvider((vehicleId, id)),
      (previous, next) {
        if (next.status == ReminderDetailStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next.errorMessage ?? 'Wystąpił błąd')),
          );
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Przypomnienie'),
        actions: [
          if (state.reminder != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => context.push('/vehicles/$vehicleId/reminders/$id/edit'),
            ),
          if (state.reminder != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _confirmDelete(context, ref),
            ),
        ],
      ),
      body: _buildBody(context, ref, state),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, ReminderDetailState state) {
    switch (state.status) {
      case ReminderDetailStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case ReminderDetailStatus.loaded:
        if (state.reminder == null) {
          return const Center(child: Text('Przypomnienie nie zostało znalezione'));
        }
        final reminder = state.reminder!;
        final dateFormatter = DateFormat('dd.MM.yyyy');
        final isOverdue = reminder.type == ReminderType.date &&
            reminder.dueDate != null &&
            !reminder.isCompleted &&
            reminder.dueDate!.isBefore(DateTime.now());

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildCompletionCard(context, ref, reminder),
            const SizedBox(height: 16),
            _buildInfoCard(
              context,
              'Informacje',
              reminder.type == ReminderType.date ? Icons.event : Icons.speed,
              [
                _buildInfoRow('Tytuł', reminder.title),
                _buildInfoRow('Typ', reminder.type == ReminderType.date ? 'Data' : 'Przebieg'),
                if (reminder.type == ReminderType.date && reminder.dueDate != null)
                  _buildInfoRow(
                    'Data przypomnienia',
                    dateFormatter.format(reminder.dueDate!),
                    isOverdue: isOverdue,
                  ),
                if (reminder.type == ReminderType.mileage && reminder.dueMileage != null)
                  _buildInfoRow('Przebieg', '${reminder.dueMileage} km'),
                _buildInfoRow('Status', reminder.isCompleted ? 'Ukończone' : 'Aktywne'),
                if (reminder.isCompleted && reminder.completedAt != null)
                  _buildInfoRow('Ukończono', _formatDate(reminder.completedAt!)),
              ],
            ),
            const SizedBox(height: 16),
            if (reminder.notes != null && reminder.notes!.isNotEmpty)
              _buildInfoCard(
                context,
                'Notatki',
                Icons.note,
                [
                  _buildInfoRow('', reminder.notes!, wrap: true),
                ],
              ),
            const SizedBox(height: 16),
            _buildInfoCard(
              context,
              'Szczegóły',
              Icons.description_outlined,
              [
                _buildInfoRow('Utworzono', _formatDate(reminder.createdAt)),
                _buildInfoRow('Zaktualizowano', _formatDate(reminder.updatedAt)),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.push('/vehicles/$vehicleId/reminders/$id/edit'),
              icon: const Icon(Icons.edit),
              label: const Text('Edytuj przypomnienie'),
            ),
          ],
        );
      case ReminderDetailStatus.error:
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
                onPressed: () =>
                    ref.read(reminderDetailNotifierProvider((vehicleId, id))).loadReminder(id),
                icon: const Icon(Icons.refresh),
                label: const Text('Spróbuj ponownie'),
              ),
            ],
          ),
        );
      case ReminderDetailStatus.initial:
        return const Center(child: CircularProgressIndicator());
    }
  }

  Widget _buildCompletionCard(BuildContext context, WidgetRef ref, Reminder reminder) {
    final isOverdue = reminder.type == ReminderType.date &&
        reminder.dueDate != null &&
        !reminder.isCompleted &&
        reminder.dueDate!.isBefore(DateTime.now());

    return Card(
      color: isOverdue
          ? Theme.of(context).colorScheme.errorContainer
          : reminder.isCompleted
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              isOverdue ? Icons.warning : (reminder.isCompleted ? Icons.check_circle : Icons.pending),
              size: 48,
              color: isOverdue
                  ? Theme.of(context).colorScheme.error
                  : (reminder.isCompleted
                      ? Theme.of(context).colorScheme.primary
                      : null),
            ),
            const SizedBox(height: 8),
            Text(
              isOverdue
                  ? 'Po terminie'
                  : (reminder.isCompleted ? 'Ukończone' : 'Oczekujące'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (!isOverdue) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  if (reminder.isCompleted) {
                    ref.read(reminderDetailNotifierProvider((vehicleId, id))).markAsIncomplete(id);
                  } else {
                    ref.read(reminderDetailNotifierProvider((vehicleId, id))).markAsCompleted(id);
                  }
                },
                icon: Icon(reminder.isCompleted ? Icons.undo : Icons.check_circle),
                label: Text(reminder.isCompleted ? 'Cofnij ukończenie' : 'Oznacz jako ukończone'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool wrap = false, bool isOverdue = false}) {
    if (wrap) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          value,
          style: TextStyle(
            color: isOverdue ? Colors.red : null,
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isOverdue ? Colors.red : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year.toString().substring(2)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog<bool>(
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
            onPressed: () async {
              Navigator.of(context).pop(true);
              await ref.read(reminderDetailNotifierProvider((vehicleId, id))).deleteReminder(id);
              if (context.mounted) {
                context.pop();
              }
            },
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
  }
}