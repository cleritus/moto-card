import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/service_log_provider.dart';
import '../utils/date_utils.dart' as app_date_utils;
import '../widgets/delete_confirmation_dialog.dart';
import '../widgets/info_card.dart';
import '../widgets/info_row.dart';

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
            InfoCard(
              title: 'Informacje',
              icon: Icons.build,
              children: [
                InfoRow(label: 'Data', value: app_date_utils.DateUtils.formatDateTime(serviceLog.date)),
                InfoRow(label: 'Typ serwisu', value: serviceLog.serviceType),
                InfoRow(label: 'Przebieg', value: '${serviceLog.mileage} km'),
                InfoRow(label: 'Koszt', value: '${serviceLog.totalCost.toStringAsFixed(2)} zł'),
                if (serviceLog.mechanic != null && serviceLog.mechanic!.isNotEmpty)
                  InfoRow(label: 'Mechanik', value: serviceLog.mechanic!),
              ],
            ),
            const SizedBox(height: 16),
            if (serviceLog.description != null && serviceLog.description!.isNotEmpty)
              InfoCard(
                title: 'Opis',
                icon: Icons.description,
                children: [
                  InfoRow(label: '', value: serviceLog.description!, wrap: true),
                ],
              ),
            const SizedBox(height: 16),
            if (serviceLog.notes != null && serviceLog.notes!.isNotEmpty)
              InfoCard(
                title: 'Notatki',
                icon: Icons.note,
                children: [
                  InfoRow(label: '', value: serviceLog.notes!, wrap: true),
                ],
              ),
            const SizedBox(height: 16),
            InfoCard(
              title: 'Szczegóły',
              icon: Icons.description_outlined,
              children: [
                InfoRow(label: 'Utworzono', value: app_date_utils.DateUtils.formatDateTime(serviceLog.createdAt)),
                InfoRow(label: 'Zaktualizowano', value: app_date_utils.DateUtils.formatDateTime(serviceLog.updatedAt)),
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

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog<bool>(
      context: context,
      builder: (context) => DeleteConfirmationDialog(
        title: 'Usuń serwis',
        message: 'Czy na pewno chcesz usunąć ten serwis?',
        onConfirm: () async {
          await ref.read(serviceLogDetailNotifierProvider((vehicleId, id))).deleteServiceLog(id);
          if (context.mounted) {
            ref.read(serviceLogListProvider(vehicleId).notifier).refresh();
            context.pop();
          }
        },
      ),
    );
  }
}