import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
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
        title: const Text('PRZYPOMNIENIE'),
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
              label: const Text('EDYTUJ PRZYPOMNIENIE'),
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
                label: const Text('SPRÓBUJ PONOWNIE'),
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

    final Color accent;
    final IconData icon;
    final String label;
    if (reminder.isCompleted) {
      accent = Colors.green;
      icon = Icons.check_circle;
      label = 'UKOŃCZONE';
    } else if (isOverdue) {
      accent = AppColors.darkPrimary;
      icon = Icons.warning_amber_rounded;
      label = 'PO TERMINIE';
    } else {
      accent = AppColors.darkLabel;
      icon = Icons.pending_outlined;
      label = 'OCZEKUJĄCE';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withAlpha(30),
        border: Border.all(color: accent),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 22),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: reminder.isCompleted
                  ? FilledButton.styleFrom(
                      backgroundColor: AppColors.darkSurfaceBright,
                      foregroundColor: AppColors.darkOnBackground,
                    )
                  : null,
              onPressed: () async {
                final notifier =
                    ref.read(reminderDetailNotifierProvider((vehicleId, id)));
                if (reminder.isCompleted) {
                  await notifier.markAsIncomplete(id);
                } else {
                  await notifier.markAsCompleted(id);
                }
                _refreshLists(ref);
              },
              child: Text(
                reminder.isCompleted ? 'COFNIJ' : 'OZNACZ JAKO UKOŃCZONE',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _refreshLists(WidgetRef ref) {
    for (final filter in ReminderFilter.values) {
      ref.read(reminderListProvider((vehicleId, filter)).notifier).refresh();
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog<bool>(
      context: context,
      builder: (context) => DeleteConfirmationDialog(
        title: 'Usuń przypomnienie',
        message: 'Czy na pewno chcesz usunąć to przypomnienie?',
        onConfirm: () async {
          final isCompleted = ref.read(reminderDetailProvider((vehicleId, id))).reminder?.isCompleted ?? false;
          await ref.read(reminderDetailNotifierProvider((vehicleId, id))).deleteReminder(id);
          if (context.mounted) {
            final filter = isCompleted ? ReminderFilter.completed : ReminderFilter.active;
            ref.read(reminderListProvider((vehicleId, filter)).notifier).refresh();
            context.pop();
          }
        },
      ),
    );
  }
}