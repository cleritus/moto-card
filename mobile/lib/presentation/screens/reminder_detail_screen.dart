import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/reminder.dart';
import '../providers/reminder_provider.dart';
import '../utils/date_utils.dart' as app_date_utils;
import '../widgets/delete_confirmation_dialog.dart';
import '../widgets/info_card.dart';
import '../widgets/info_row.dart';

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
        final isOverdue = reminder.type == ReminderType.date &&
            reminder.dueDate != null &&
            !reminder.isCompleted &&
            reminder.dueDate!.isBefore(DateTime.now());

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildCompletionCard(context, ref, reminder),
            const SizedBox(height: 16),
            InfoCard(
              title: 'Informacje',
              icon: reminder.type == ReminderType.date ? Icons.event : Icons.speed,
              children: [
                InfoRow(label: 'Tytuł', value: reminder.title),
                InfoRow(label: 'Typ', value: reminder.type == ReminderType.date ? 'Data' : 'Przebieg'),
                if (reminder.type == ReminderType.date && reminder.dueDate != null)
                  InfoRow(
                    label: 'Data przypomnienia',
                    value: app_date_utils.DateUtils.formatDate(reminder.dueDate!),
                    isOverdue: isOverdue,
                  ),
                if (reminder.type == ReminderType.mileage && reminder.dueMileage != null)
                  InfoRow(label: 'Przebieg', value: '${reminder.dueMileage} km'),
                InfoRow(label: 'Status', value: reminder.isCompleted ? 'Ukończone' : 'Aktywne'),
                if (reminder.isCompleted && reminder.completedAt != null)
                  InfoRow(label: 'Ukończono', value: app_date_utils.DateUtils.formatDateTime(reminder.completedAt!)),
              ],
            ),
            const SizedBox(height: 16),
            if (reminder.notes != null && reminder.notes!.isNotEmpty)
              InfoCard(
                title: 'Notatki',
                icon: Icons.note,
                children: [
                  InfoRow(label: '', value: reminder.notes!, wrap: true),
                ],
              ),
            const SizedBox(height: 16),
            InfoCard(
              title: 'Szczegóły',
              icon: Icons.description_outlined,
              children: [
                InfoRow(label: 'Utworzono', value: app_date_utils.DateUtils.formatDateTime(reminder.createdAt)),
                InfoRow(label: 'Zaktualizowano', value: app_date_utils.DateUtils.formatDateTime(reminder.updatedAt)),
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

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog<bool>(
      context: context,
      builder: (context) => DeleteConfirmationDialog(
        title: 'Usuń przypomnienie',
        message: 'Czy na pewno chcesz usunąć to przypomnienie?',
        onConfirm: () async {
          await ref.read(reminderDetailNotifierProvider((vehicleId, id))).deleteReminder(id);
          if (context.mounted) {
            context.pop();
          }
        },
      ),
    );
  }
}