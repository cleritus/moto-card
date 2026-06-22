import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/service_log.dart';
import '../providers/service_log_provider.dart';
import '../utils/date_utils.dart' as app_date_utils;
import '../widgets/data_list_tile.dart';
import '../widgets/empty_state.dart';
import '../widgets/section_header.dart';

class ServiceLogListScreen extends ConsumerWidget {
  final String vehicleId;

  const ServiceLogListScreen({super.key, required this.vehicleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(serviceLogListProvider(vehicleId));

    ref.listen<ServiceLogListState>(serviceLogListProvider(vehicleId),
        (previous, next) {
      if (next.status == ServiceLogListStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage ?? 'Wystąpił błąd')),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('SERWIS')),
      body: _buildBody(context, ref, state),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/vehicles/$vehicleId/service-logs/new'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, WidgetRef ref, ServiceLogListState state) {
    switch (state.status) {
      case ServiceLogListStatus.loading:
      case ServiceLogListStatus.initial:
        return const Center(child: CircularProgressIndicator());
      case ServiceLogListStatus.loaded:
        if (state.serviceLogs.isEmpty) {
          return const EmptyState(
            icon: Icons.build,
            title: 'Brak serwisów',
            subtitle: 'Dodaj swój pierwszy serwis',
          );
        }
        return RefreshIndicator(
          onRefresh: () =>
              ref.read(serviceLogListProvider(vehicleId).notifier).refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: state.serviceLogs.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) return const SectionHeader('Historia serwisów');
              final serviceLog = state.serviceLogs[index - 1];
              return _ServiceLogListItem(
                  vehicleId: vehicleId, serviceLog: serviceLog);
            },
          ),
        );
      case ServiceLogListStatus.error:
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
                    .read(serviceLogListProvider(vehicleId).notifier)
                    .refresh(),
                icon: const Icon(Icons.refresh),
                label: const Text('SPRÓBUJ PONOWNIE'),
              ),
            ],
          ),
        );
    }
  }
}

class _ServiceLogListItem extends ConsumerWidget {
  final String vehicleId;
  final ServiceLog serviceLog;

  const _ServiceLogListItem(
      {required this.vehicleId, required this.serviceLog});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(serviceLog.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Usuń serwis'),
                content: const Text('Czy na pewno chcesz usunąć ten serwis?'),
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
        ref.read(serviceLogListProvider(vehicleId).notifier).clearError();
        ref
            .read(serviceLogDetailNotifierProvider((vehicleId, serviceLog.id)))
            .deleteServiceLog(serviceLog.id)
            .then((_) {
          ref.read(serviceLogListProvider(vehicleId).notifier).refresh();
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
        primary: serviceLog.serviceType,
        secondary: '${app_date_utils.DateUtils.formatDate(serviceLog.date)} · '
            '${serviceLog.mileage} km',
        trailing: '${serviceLog.totalCost.toStringAsFixed(2)} zł',
        onTap: () =>
            context.push('/vehicles/$vehicleId/service-logs/${serviceLog.id}'),
      ),
    );
  }
}
