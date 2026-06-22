import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/fuel_log_provider.dart';
import '../utils/date_utils.dart' as app_date_utils;
import '../widgets/delete_confirmation_dialog.dart';
import '../widgets/info_card.dart';
import '../widgets/info_row.dart';

class FuelLogDetailScreen extends ConsumerWidget {
  final String vehicleId;
  final String id;

  const FuelLogDetailScreen({super.key, required this.vehicleId, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(fuelLogDetailProvider((vehicleId, id)));

    ref.listen<FuelLogDetailState>(
      fuelLogDetailProvider((vehicleId, id)),
      (previous, next) {
        if (next.status == FuelLogDetailStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next.errorMessage ?? 'Wystąpił błąd')),
          );
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('TANKOWANIE'),
        actions: [
          if (state.fuelLog != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => context.push('/vehicles/$vehicleId/fuel-logs/$id/edit'),
            ),
          if (state.fuelLog != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _confirmDelete(context, ref),
            ),
        ],
      ),
      body: _buildBody(context, ref, state),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, FuelLogDetailState state) {
    final numberFormat = NumberFormat.decimalPattern('pl_PL');

    switch (state.status) {
      case FuelLogDetailStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case FuelLogDetailStatus.loaded:
        if (state.fuelLog == null) {
          return const Center(child: Text('Tankowanie nie zostało znalezione'));
        }
        final fuelLog = state.fuelLog!;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            InfoCard(
              title: 'Informacje',
              icon: Icons.local_gas_station,
              children: [
                InfoRow(label: 'Data', value: app_date_utils.DateUtils.formatDateTime(fuelLog.date)),
                InfoRow(label: 'Przebieg', value: '${fuelLog.mileage} km'),
                InfoRow(label: 'Paliwo', value: '${numberFormat.format(fuelLog.fuelAmount)} L'),
                InfoRow(label: 'Koszt', value: '${numberFormat.format(fuelLog.totalCost)} zł'),
                if (fuelLog.notes != null && fuelLog.notes!.isNotEmpty)
                  InfoRow(label: 'Notatki', value: fuelLog.notes!),
              ],
            ),
            const SizedBox(height: 16),
            InfoCard(
              title: 'Szczegóły',
              icon: Icons.description_outlined,
              children: [
                InfoRow(label: 'Utworzono', value: app_date_utils.DateUtils.formatDateTime(fuelLog.createdAt)),
                InfoRow(label: 'Zaktualizowano', value: app_date_utils.DateUtils.formatDateTime(fuelLog.updatedAt)),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.push('/vehicles/$vehicleId/fuel-logs/$id/edit'),
              icon: const Icon(Icons.edit),
              label: const Text('EDYTUJ TANKOWANIE'),
            ),
          ],
        );
      case FuelLogDetailStatus.error:
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
                    ref.read(fuelLogDetailNotifierProvider((vehicleId, id))).loadFuelLog(id),
                icon: const Icon(Icons.refresh),
                label: const Text('SPRÓBUJ PONOWNIE'),
              ),
            ],
          ),
        );
      case FuelLogDetailStatus.initial:
        return const Center(child: CircularProgressIndicator());
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog<bool>(
      context: context,
      builder: (context) => DeleteConfirmationDialog(
        title: 'Usuń tankowanie',
        message: 'Czy na pewno chcesz usunąć to tankowanie?',
        onConfirm: () async {
          await ref.read(fuelLogDetailNotifierProvider((vehicleId, id))).deleteFuelLog(id);
          if (context.mounted) {
            ref.read(fuelLogListProvider(vehicleId).notifier).refresh();
            context.pop();
          }
        },
      ),
    );
  }
}