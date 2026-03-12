import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/vehicle.dart';
import '../providers/vehicle_provider.dart';

class VehicleListScreen extends ConsumerWidget {
  const VehicleListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(vehicleListProvider);

    ref.listen<VehicleListState>(vehicleListProvider, (previous, next) {
      if (next.status == VehicleListStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage ?? 'Wystąpił błąd')),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Moje Pojazdy'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(vehicleListProvider.notifier).refresh(),
          ),
        ],
      ),
      body: _buildBody(context, ref, state),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/vehicles/new'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, VehicleListState state) {
    switch (state.status) {
      case VehicleListStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case VehicleListStatus.loaded:
        if (state.vehicles.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.motorcycle_outlined,
                  size: 80,
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(77),
                ),
                const SizedBox(height: 16),
                Text(
                  'Brak pojazdów',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Dodaj swój pierwszy pojazd',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                      ),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref.read(vehicleListProvider.notifier).refresh(),
          child: ListView.builder(
            itemCount: state.vehicles.length,
            itemBuilder: (context, index) {
              final vehicle = state.vehicles[index];
              return _VehicleListItem(vehicle: vehicle);
            },
          ),
        );
      case VehicleListStatus.error:
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
                onPressed: () => ref.read(vehicleListProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh),
                label: const Text('Spróbuj ponownie'),
              ),
            ],
          ),
        );
      case VehicleListStatus.initial:
        return const Center(child: CircularProgressIndicator());
    }
  }
}

class _VehicleListItem extends ConsumerWidget {
  final Vehicle vehicle;

  const _VehicleListItem({required this.vehicle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(vehicle.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Usuń pojazd'),
                content: Text(
                    'Czy na pewno chcesz usunąć ${vehicle.name}?'),
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
        ref.read(vehicleListProvider.notifier).clearError();
        ref.read(vehicleDetailNotifierProvider(vehicle.id)).deleteVehicle(vehicle.id).then((_) {
          ref.read(vehicleListProvider.notifier).refresh();
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
            child: Text(
              vehicle.make.substring(0, 1).toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(vehicle.name),
          subtitle: Text('${vehicle.make} ${vehicle.vehicleModel} • ${vehicle.year}'),
          trailing: vehicle.mileage != null
              ? Text('${vehicle.mileage} km')
              : null,
          onTap: () => context.push('/vehicles/${vehicle.id}'),
        ),
      ),
    );
  }
}