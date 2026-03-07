import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/vehicle_provider.dart';

class VehicleDetailScreen extends ConsumerWidget {
  final String id;

  const VehicleDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(vehicleDetailProvider(id));

    ref.listen<VehicleDetailState>(vehicleDetailProvider(id), (previous, next) {
      if (next.status == VehicleDetailStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage ?? 'Wystąpił błąd')),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(state.vehicle?.name ?? 'Pojazd'),
        actions: [
          if (state.vehicle != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => context.push('/vehicles/$id/edit'),
            ),
          if (state.vehicle != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _confirmDelete(context, ref),
            ),
        ],
      ),
      body: _buildBody(context, ref, state),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, VehicleDetailState state) {
    switch (state.status) {
      case VehicleDetailStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case VehicleDetailStatus.loaded:
        if (state.vehicle == null) {
          return const Center(child: Text('Pojazd nie został znaleziony'));
        }
        final vehicle = state.vehicle!;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildInfoCard(
              context,
              'Informacje',
              Icons.info_outline,
              [
                _buildInfoRow('Nazwa', vehicle.name),
                _buildInfoRow('Marka', vehicle.make),
                _buildInfoRow('Model', vehicle.vehicleModel),
                _buildInfoRow('Rok', vehicle.year.toString()),
                if (vehicle.mileage != null)
                  _buildInfoRow('Przebieg', '${vehicle.mileage} km'),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              context,
              'Szczegóły',
              Icons.description_outlined,
              [
                _buildInfoRow('Utworzono', _formatDate(vehicle.createdAt)),
                _buildInfoRow('Zaktualizowano', _formatDate(vehicle.updatedAt)),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.push('/vehicles/$id/edit'),
              icon: const Icon(Icons.edit),
              label: const Text('Edytuj pojazd'),
            ),
          ],
        );
      case VehicleDetailStatus.error:
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
                onPressed: () => ref.read(vehicleDetailNotifierProvider(id)).loadVehicle(id),
                icon: const Icon(Icons.refresh),
                label: const Text('Spróbuj ponownie'),
              ),
            ],
          ),
        );
      case VehicleDetailStatus.initial:
        return const Center(child: CircularProgressIndicator());
    }
  }

  Widget _buildInfoCard(BuildContext context, String title, IconData icon, List<Widget> children) {
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
    return '${date.day}.${date.month}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usuń pojazd'),
        content: const Text('Czy na pewno chcesz usunąć ten pojazd?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop(true);
              await ref.read(vehicleDetailNotifierProvider(id)).deleteVehicle(id);
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