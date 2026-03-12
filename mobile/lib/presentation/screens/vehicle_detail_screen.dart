import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/vehicle_provider.dart';
import '../utils/date_utils.dart' as app_date_utils;
import '../widgets/delete_confirmation_dialog.dart';
import '../widgets/info_card.dart';
import '../widgets/info_row.dart';

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
            InfoCard(
              title: 'Informacje',
              icon: Icons.info_outline,
              children: [
                InfoRow(label: 'Nazwa', value: vehicle.name),
                InfoRow(label: 'Marka', value: vehicle.make),
                InfoRow(label: 'Model', value: vehicle.vehicleModel),
                InfoRow(label: 'Rok', value: vehicle.year.toString()),
                if (vehicle.mileage != null)
                  InfoRow(label: 'Przebieg', value: '${vehicle.mileage} km'),
              ],
            ),
            const SizedBox(height: 16),
            InfoCard(
              title: 'Szczegóły',
              icon: Icons.description_outlined,
              children: [
                InfoRow(label: 'Utworzono', value: app_date_utils.DateUtils.formatDateTime(vehicle.createdAt)),
                InfoRow(label: 'Zaktualizowano', value: app_date_utils.DateUtils.formatDateTime(vehicle.updatedAt)),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => context.push('/vehicles/$id/fuel-logs'),
              icon: const Icon(Icons.local_gas_station),
              label: const Text('Tankowania'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => context.push('/vehicles/$id/service-logs'),
              icon: const Icon(Icons.build),
              label: const Text('Serwisy'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => context.push('/vehicles/$id/reminders'),
              icon: const Icon(Icons.notifications),
              label: const Text('Przypomnienia'),
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

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog<bool>(
      context: context,
      builder: (context) => DeleteConfirmationDialog(
        title: 'Usuń pojazd',
        message: 'Czy na pewno chcesz usunąć ten pojazd?',
        onConfirm: () async {
          await ref.read(vehicleDetailNotifierProvider(id)).deleteVehicle(id);
          if (context.mounted) {
            context.pop();
          }
        },
      ),
    );
  }
}