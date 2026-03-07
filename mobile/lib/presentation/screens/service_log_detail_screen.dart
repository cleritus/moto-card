import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/service_log_provider.dart';

class ServiceLogDetailScreen extends ConsumerWidget {
  final String vehicleId;
  final String id;

  const ServiceLogDetailScreen({super.key, required this.vehicleId, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(serviceLogDetailProvider((vehicleId, id)));

    ref.listen<ServiceLogDetailState>(
      serviceLogDetailProvider((vehicleId, id)),
      (previous, next) {
        if (next.status == ServiceLogDetailStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next.errorMessage ?? 'Wystąpił błąd')),
          );
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Serwis'),
        actions: [
          if (state.serviceLog != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => context.push('/vehicles/$vehicleId/service-logs/$id/edit'),
            ),
          if (state.serviceLog != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _confirmDelete(context, ref),
            ),
        ],
      ),
      body: _buildBody(context, ref, state),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, ServiceLogDetailState state) {
    switch (state.status) {
      case ServiceLogDetailStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case ServiceLogDetailStatus.loaded:
        if (state.serviceLog == null) {
          return const Center(child: Text('Serwis nie został znaleziony'));
        }
        final serviceLog = state.serviceLog!;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildInfoCard(
              context,
              'Informacje',
              Icons.build,
              [
                _buildInfoRow('Data', _formatDate(serviceLog.date)),
                _buildInfoRow('Typ serwisu', serviceLog.serviceType),
                _buildInfoRow('Przebieg', '${serviceLog.mileage} km'),
                _buildInfoRow('Koszt', '${serviceLog.totalCost.toStringAsFixed(2)} zł'),
                if (serviceLog.mechanic != null && serviceLog.mechanic!.isNotEmpty)
                  _buildInfoRow('Mechanik', serviceLog.mechanic!),
              ],
            ),
            const SizedBox(height: 16),
            if (serviceLog.description != null && serviceLog.description!.isNotEmpty)
              _buildInfoCard(
                context,
                'Opis',
                Icons.description,
                [
                  _buildInfoRow('', serviceLog.description!, wrap: true),
                ],
              ),
            const SizedBox(height: 16),
            if (serviceLog.notes != null && serviceLog.notes!.isNotEmpty)
              _buildInfoCard(
                context,
                'Notatki',
                Icons.note,
                [
                  _buildInfoRow('', serviceLog.notes!, wrap: true),
                ],
              ),
            const SizedBox(height: 16),
            _buildInfoCard(
              context,
              'Szczegóły',
              Icons.description_outlined,
              [
                _buildInfoRow('Utworzono', _formatDate(serviceLog.createdAt)),
                _buildInfoRow('Zaktualizowano', _formatDate(serviceLog.updatedAt)),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.push('/vehicles/$vehicleId/service-logs/$id/edit'),
              icon: const Icon(Icons.edit),
              label: const Text('Edytuj serwis'),
            ),
          ],
        );
      case ServiceLogDetailStatus.error:
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
                    ref.read(serviceLogDetailNotifierProvider((vehicleId, id))).loadServiceLog(id),
                icon: const Icon(Icons.refresh),
                label: const Text('Spróbuj ponownie'),
              ),
            ],
          ),
        );
      case ServiceLogDetailStatus.initial:
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

  Widget _buildInfoRow(String label, String value, {bool wrap = false}) {
    if (wrap) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(value),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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
        title: const Text('Usuń serwis'),
        content: const Text('Czy na pewno chcesz usunąć ten serwis?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop(true);
              await ref.read(serviceLogDetailNotifierProvider((vehicleId, id))).deleteServiceLog(id);
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