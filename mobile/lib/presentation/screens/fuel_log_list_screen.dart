import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/fuel_log.dart';
import '../providers/fuel_log_provider.dart';
import '../utils/date_utils.dart' as app_date_utils;
import '../widgets/data_list_tile.dart';
import '../widgets/empty_state.dart';
import '../widgets/section_header.dart';

class FuelLogListScreen extends ConsumerWidget {
  final String vehicleId;

  const FuelLogListScreen({super.key, required this.vehicleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(fuelLogListProvider(vehicleId));

    ref.listen<FuelLogListState>(fuelLogListProvider(vehicleId),
        (previous, next) {
      if (next.status == FuelLogListStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage ?? 'Wystąpił błąd')),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('TANKOWANIE')),
      body: _buildBody(context, ref, state),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/vehicles/$vehicleId/fuel-logs/new'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, WidgetRef ref, FuelLogListState state) {
    switch (state.status) {
      case FuelLogListStatus.loading:
      case FuelLogListStatus.initial:
        return const Center(child: CircularProgressIndicator());
      case FuelLogListStatus.loaded:
        if (state.fuelLogs.isEmpty) {
          return const EmptyState(
            icon: Icons.local_gas_station,
            title: 'Brak tankowań',
            subtitle: 'Dodaj swoje pierwsze tankowanie',
          );
        }
        final consumptions = _consumptionById(state.fuelLogs);
        return RefreshIndicator(
          onRefresh: () =>
              ref.read(fuelLogListProvider(vehicleId).notifier).refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: state.fuelLogs.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) return const SectionHeader('Historia tankowań');
              final fuelLog = state.fuelLogs[index - 1];
              return _FuelLogListItem(
                vehicleId: vehicleId,
                fuelLog: fuelLog,
                consumption: consumptions[fuelLog.id],
              );
            },
          ),
        );
      case FuelLogListStatus.error:
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
                onPressed: () =>
                    ref.read(fuelLogListProvider(vehicleId).notifier).refresh(),
                icon: const Icon(Icons.refresh),
                label: const Text('SPRÓBUJ PONOWNIE'),
              ),
            ],
          ),
        );
    }
  }

  /// Per-entry L/100km using the previous fill-up (sorted by mileage).
  Map<String, double> _consumptionById(List<FuelLog> logs) {
    final sorted = [...logs]..sort((a, b) => a.mileage.compareTo(b.mileage));
    final result = <String, double>{};
    for (var i = 1; i < sorted.length; i++) {
      final distance = sorted[i].mileage - sorted[i - 1].mileage;
      if (distance > 0) {
        result[sorted[i].id] = sorted[i].fuelAmount / distance * 100;
      }
    }
    return result;
  }
}

class _FuelLogListItem extends ConsumerWidget {
  final String vehicleId;
  final FuelLog fuelLog;
  final double? consumption;

  const _FuelLogListItem({
    required this.vehicleId,
    required this.fuelLog,
    this.consumption,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(fuelLog.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Usuń tankowanie'),
                content:
                    const Text('Czy na pewno chcesz usunąć to tankowanie?'),
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
        ref.read(fuelLogListProvider(vehicleId).notifier).clearError();
        ref
            .read(fuelLogDetailNotifierProvider((vehicleId, fuelLog.id)))
            .deleteFuelLog(fuelLog.id)
            .then((_) {
          ref.read(fuelLogListProvider(vehicleId).notifier).refresh();
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
        primary: '${fuelLog.fuelAmount.toStringAsFixed(1)} L',
        secondary: '${fuelLog.mileage} km · '
            '${app_date_utils.DateUtils.formatDate(fuelLog.date)}',
        tertiary: consumption != null
            ? '${consumption!.toStringAsFixed(1)} L/100km'
            : null,
        trailing: '${fuelLog.totalCost.toStringAsFixed(2)} zł',
        onTap: () =>
            context.push('/vehicles/$vehicleId/fuel-logs/${fuelLog.id}'),
      ),
    );
  }
}
