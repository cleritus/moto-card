import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/fuel_log.dart';
import '../providers/fuel_log_provider.dart';

class FuelLogListScreen extends ConsumerWidget {
  final String vehicleId;

  const FuelLogListScreen({super.key, required this.vehicleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(fuelLogListProvider(vehicleId));

    ref.listen<FuelLogListState>(fuelLogListProvider(vehicleId), (previous, next) {
      if (next.status == FuelLogListStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage ?? 'Wystąpił błąd')),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tankowania'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(fuelLogListProvider(vehicleId).notifier).refresh(),
          ),
        ],
      ),
      body: _buildBody(context, ref, state),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/vehicles/$vehicleId/fuel-logs/new'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, FuelLogListState state) {
    switch (state.status) {
      case FuelLogListStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case FuelLogListStatus.loaded:
        if (state.fuelLogs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.local_gas_station_outlined,
                  size: 80,
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(77),
                ),
                const SizedBox(height: 16),
                Text(
                  'Brak tankowań',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Dodaj swoje pierwsze tankowanie',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                      ),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref.read(fuelLogListProvider(vehicleId).notifier).refresh(),
          child: ListView.builder(
            itemCount: state.fuelLogs.length,
            itemBuilder: (context, index) {
              final fuelLog = state.fuelLogs[index];
              return _FuelLogListItem(vehicleId: vehicleId, fuelLog: fuelLog);
            },
          ),
        );
      case FuelLogListStatus.error:
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
                onPressed: () => ref.read(fuelLogListProvider(vehicleId).notifier).refresh(),
                icon: const Icon(Icons.refresh),
                label: const Text('Spróbuj ponownie'),
              ),
            ],
          ),
        );
      case FuelLogListStatus.initial:
        return const Center(child: CircularProgressIndicator());
    }
  }
}

class _FuelLogListItem extends ConsumerWidget {
  final String vehicleId;
  final FuelLog fuelLog;

  const _FuelLogListItem({required this.vehicleId, required this.fuelLog});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormatter = DateFormat('dd.MM.yy');
    final numberFormat = NumberFormat.decimalPattern('pl_PL');

    return Dismissible(
      key: Key(fuelLog.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
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
            .read(fuelLogListProvider(vehicleId).notifier)
            .clearError();
        ref
            .read(fuelLogDetailNotifierProvider((vehicleId, fuelLog.id)))
            .deleteFuelLog(fuelLog.id)
            .then((_) {
          ref.read(fuelLogListProvider(vehicleId).notifier).refresh();
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
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Icon(
              Icons.local_gas_station,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          title: Text('${numberFormat.format(fuelLog.fuelAmount)} L'),
          subtitle: Text('${dateFormatter.format(fuelLog.date)} • ${fuelLog.mileage} km'),
          trailing: Text('${numberFormat.format(fuelLog.totalCost)} zł'),
          onTap: () => context.push('/vehicles/$vehicleId/fuel-logs/${fuelLog.id}'),
        ),
      ),
    );
  }
}