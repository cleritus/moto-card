import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../providers/fuel_log_provider.dart';
import '../utils/format.dart';
import '../widgets/data_plate.dart';
import '../widgets/delete_confirmation_dialog.dart';
import '../widgets/error_view.dart';
import '../widgets/garage_app_bar.dart';
import '../widgets/garage_button.dart';
import '../widgets/section_header.dart';
import '../widgets/workshop_card.dart';

/// §6 row 4 — a single fill-up, read as a name plate.
class FuelLogDetailScreen extends ConsumerWidget {
  const FuelLogDetailScreen({
    super.key,
    required this.vehicleId,
    required this.id,
  });

  final String vehicleId;
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(fuelLogDetailProvider((vehicleId, id)));

    ref.listen<FuelLogDetailState>(
      fuelLogDetailProvider((vehicleId, id)),
      (previous, next) {
        if (next.status == FuelLogDetailStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next.errorMessage ?? 'Coś się zacięło.')),
          );
        }
      },
    );

    return Scaffold(
      appBar: const GarageAppBar(
        title: 'TANKOWANIE',
        subtitle: 'REJESTR PALIWA',
      ),
      body: _buildBody(context, ref, state),
    );
  }

  Widget _buildBody(
      BuildContext context, WidgetRef ref, FuelLogDetailState state) {
    switch (state.status) {
      case FuelLogDetailStatus.initial:
      case FuelLogDetailStatus.loading:
        return const LoadingView();
      case FuelLogDetailStatus.error:
        return ErrorView(
          detail: state.errorMessage,
          onRetry: () => ref
              .read(fuelLogDetailNotifierProvider((vehicleId, id)))
              .loadFuelLog(id),
        );
      case FuelLogDetailStatus.loaded:
        final fuelLog = state.fuelLog;
        if (fuelLog == null) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('Tego tankowania nie ma w rejestrze.'),
            ),
          );
        }
        final notes = fuelLog.notes?.trim();
        final pricePerLitre =
            fuelLog.fuelAmount > 0 ? fuelLog.totalCost / fuelLog.fuelAmount : null;

        return ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppGeo.screenMargin,
                20,
                AppGeo.screenMargin,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Fmt.date(fuelLog.date),
                    style: AppText.micro(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    Fmt.litres(fuelLog.fuelAmount),
                    style: AppText.dataXl(size: 42),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'PRZY ${Fmt.kmUnit(fuelLog.mileage)}',
                    style: AppText.micro().copyWith(letterSpacing: 9.5 * 0.18),
                  ),
                ],
              ),
            ),
            const SectionHeader('ROZLICZENIE', tag: 'TABLICZKA', bottomGap: 12),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppGeo.screenMargin,
              ),
              child: WorkshopCard(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: DataPlate(
                  rows: [
                    DataPlateRow('DATA', Fmt.date(fuelLog.date)),
                    DataPlateRow('PRZEBIEG', Fmt.kmUnit(fuelLog.mileage)),
                    DataPlateRow('PALIWO', Fmt.litres(fuelLog.fuelAmount)),
                    if (pricePerLitre != null)
                      DataPlateRow('CENA / L', Fmt.money(pricePerLitre)),
                    DataPlateRow('KOSZT', Fmt.money(fuelLog.totalCost),
                        emphasis: true),
                  ],
                ),
              ),
            ),
            if (notes != null && notes.isNotEmpty) ...[
              const SectionHeader('NOTATKI', bottomGap: 12),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppGeo.screenMargin,
                ),
                child: WorkshopCard(
                  margin: EdgeInsets.zero,
                  child: Text(notes, style: AppText.body()),
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppGeo.screenMargin,
                AppGeo.sectionGap,
                AppGeo.screenMargin,
                0,
              ),
              child: Column(
                children: [
                  GarageButton(
                    label: 'EDYTUJ WPIS',
                    onPressed: () => context
                        .push('/vehicles/$vehicleId/fuel-logs/$id/edit'),
                  ),
                  const SizedBox(height: 12),
                  GarageButton.danger(
                    label: 'SKREŚL TANKOWANIE',
                    onPressed: () => _confirmDelete(context, ref),
                  ),
                ],
              ),
            ),
          ],
        );
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog<bool>(
      context: context,
      builder: (dialogContext) => DeleteConfirmationDialog(
        title: 'SKREŚL TANKOWANIE',
        message: 'Usunąć to tankowanie z rejestru?',
        onConfirm: () async {
          await ref
              .read(fuelLogDetailNotifierProvider((vehicleId, id)))
              .deleteFuelLog(id);
          if (context.mounted) {
            ref.read(fuelLogListProvider(vehicleId).notifier).refresh();
            context.pop();
          }
        },
      ),
    );
  }
}
