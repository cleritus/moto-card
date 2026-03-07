import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/service_log.dart';
import '../providers/service_log_provider.dart';

class ServiceLogListScreen extends ConsumerWidget {
  final String vehicleId;

  const ServiceLogListScreen({super.key, required this.vehicleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(serviceLogListProvider(vehicleId));

    ref.listen<ServiceLogListState>(serviceLogListProvider(vehicleId), (previous, next) {
      if (next.status == ServiceLogListStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage ?? 'Wystąpił błąd')),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Serwisy'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(serviceLogListProvider(vehicleId).notifier).refresh(),
          ),
        ],
      ),
      body: _buildBody(context, ref, state),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/vehicles/$vehicleId/service-logs/new'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, ServiceLogListState state) {
    switch (state.status) {
      case ServiceLogListStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case ServiceLogListStatus.loaded:
        if (state.serviceLogs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.build_outlined,
                  size: 80,
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(77),
                ),
                const SizedBox(height: 16),
                Text(
                  'Brak serwisów',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Dodaj swój pierwszy serwis',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                      ),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref.read(serviceLogListProvider(vehicleId).notifier).refresh(),
          child: ListView.builder(
            itemCount: state.serviceLogs.length,
            itemBuilder: (context, index) {
              final serviceLog = state.serviceLogs[index];
              return _ServiceLogListItem(vehicleId: vehicleId, serviceLog: serviceLog);
            },
          ),
        );
      case ServiceLogListStatus.error:
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
                onPressed: () => ref.read(serviceLogListProvider(vehicleId).notifier).refresh(),
                icon: const Icon(Icons.refresh),
                label: const Text('Spróbuj ponownie'),
              ),
            ],
          ),
        );
      case ServiceLogListStatus.initial:
        return const Center(child: CircularProgressIndicator());
    }
  }
}

class _ServiceLogListItem extends ConsumerWidget {
  final String vehicleId;
  final ServiceLog serviceLog;

  const _ServiceLogListItem({required this.vehicleId, required this.serviceLog});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormatter = DateFormat('dd.MM.yy');
    final numberFormat = NumberFormat.decimalPattern('pl_PL');

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
        ref
            .read(serviceLogListProvider(vehicleId).notifier)
            .clearError();
        ref
            .read(serviceLogDetailNotifierProvider((vehicleId, serviceLog.id)))
            .deleteServiceLog(serviceLog.id)
            .then((_) {
          ref.read(serviceLogListProvider(vehicleId).notifier).refresh();
        });
      },
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Icon(
              Icons.build,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          title: Text(serviceLog.serviceType),
          subtitle: Text('${dateFormatter.format(serviceLog.date)} • ${serviceLog.mileage} km'),
          trailing: Text('${numberFormat.format(serviceLog.totalCost)} zł'),
          onTap: () => context.push('/vehicles/$vehicleId/service-logs/${serviceLog.id}'),
        ),
      ),
    );
  }
}