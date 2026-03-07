import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/fuel_log_provider.dart';

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
        title: const Text('Tankowanie'),
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
            _buildInfoCard(
              context,
              'Informacje',
              Icons.local_gas_station,
              [
                _buildInfoRow('Data', _formatDate(fuelLog.date)),
                _buildInfoRow('Przebieg', '${fuelLog.mileage} km'),
                _buildInfoRow('Paliwo', '${numberFormat.format(fuelLog.fuelAmount)} L'),
                _buildInfoRow('Koszt', '${numberFormat.format(fuelLog.totalCost)} zł'),
                if (fuelLog.notes != null && fuelLog.notes!.isNotEmpty)
                  _buildInfoRow('Notatki', fuelLog.notes!),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              context,
              'Szczegóły',
              Icons.description_outlined,
              [
                _buildInfoRow('Utworzono', _formatDate(fuelLog.createdAt)),
                _buildInfoRow('Zaktualizowano', _formatDate(fuelLog.updatedAt)),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.push('/vehicles/$vehicleId/fuel-logs/$id/edit'),
              icon: const Icon(Icons.edit),
              label: const Text('Edytuj tankowanie'),
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
                label: const Text('Spróbuj ponownie'),
              ),
            ],
          ),
        );
      case FuelLogDetailStatus.initial:
        return const Center(child: CircularProgressIndicator());
    }
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
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
        title: const Text('Usuń tankowanie'),
        content: const Text('Czy na pewno chcesz usunąć to tankowanie?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop(true);
              await ref.read(fuelLogDetailNotifierProvider((vehicleId, id))).deleteFuelLog(id);
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