import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../domain/entities/fuel_log.dart';
import '../providers/fuel_log_provider.dart';
import '../providers/vehicle_provider.dart';
import '../utils/format.dart';
import '../widgets/delete_confirmation_dialog.dart';
import '../widgets/double_rule.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_view.dart';
import '../widgets/garage_button.dart';
import '../widgets/screen_header.dart';
import '../widgets/workshop_card.dart';

/// §6 row 4 — the fuel register, laid out as a ledger: every fill-up is a
/// numbered leaf, mileage and date on top, litres and cost in the body.
class FuelLogListScreen extends ConsumerWidget {
  const FuelLogListScreen({super.key, required this.vehicleId});

  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(fuelLogListProvider(vehicleId));
    final vehicle = ref.watch(vehicleDetailProvider(vehicleId)).vehicle;

    ref.listen<FuelLogListState>(fuelLogListProvider(vehicleId),
        (previous, next) {
      if (next.status == FuelLogListStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage ?? 'Coś się zacięło.')),
        );
      }
    });

    final logs = [...state.fuelLogs]..sort((a, b) => b.date.compareTo(a.date));
    final consumptions = _consumptionById(state.fuelLogs);
    final average = _average(consumptions.values);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                ScreenHeader(
                  tagLeft: vehicle?.name ?? 'PALIWO',
                  tagRight: 'REJESTR',
                  title: 'PALIWO',
                  subtitle: average == null
                      ? 'TANKOWAŃ: ${Fmt.serial(logs.length, width: 2)}'
                      : 'TANKOWAŃ: ${Fmt.serial(logs.length, width: 2)}'
                          ' · ŚREDNIA ${Fmt.decimal1(average)} L/100 KM',
                ),
                Expanded(
                  child: _buildBody(context, ref, state, logs, consumptions),
                ),
              ],
            ),
            Positioned(
              right: AppGeo.screenMargin,
              bottom: 24,
              child: GarageFab(
                onPressed: () =>
                    context.push('/vehicles/$vehicleId/fuel-logs/new'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    FuelLogListState state,
    List<FuelLog> logs,
    Map<String, double> consumptions,
  ) {
    switch (state.status) {
      case FuelLogListStatus.loading:
      case FuelLogListStatus.initial:
        return const LoadingView(label: 'OTWIERAM REJESTR');
      case FuelLogListStatus.error:
        return ErrorView(
          detail: state.errorMessage,
          onRetry: () =>
              ref.read(fuelLogListProvider(vehicleId).notifier).refresh(),
        );
      case FuelLogListStatus.loaded:
        if (logs.isEmpty) {
          return const EmptyState(
            tag: 'TANKOWAŃ: 00',
            title: 'REJESTR PUSTY.',
            subtitle: 'Pierwsze tankowanie jeszcze nie zapisane.',
          );
        }

        final items = <Widget>[];
        int? currentYear;
        for (var i = 0; i < logs.length; i++) {
          final log = logs[i];
          if (log.date.year != currentYear) {
            currentYear = log.date.year;
            items.add(YearDivider(year: currentYear));
          }
          items.add(
            _FuelLeaf(
              vehicleId: vehicleId,
              fuelLog: log,
              number: logs.length - i,
              consumption: consumptions[log.id],
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.oxideLit,
          backgroundColor: AppColors.dirtyBlack,
          onRefresh: () =>
              ref.read(fuelLogListProvider(vehicleId).notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppGeo.screenMargin,
              0,
              AppGeo.screenMargin,
              110,
            ),
            children: items,
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

  double? _average(Iterable<double> values) {
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }
}

class _FuelLeaf extends ConsumerWidget {
  const _FuelLeaf({
    required this.vehicleId,
    required this.fuelLog,
    required this.number,
    this.consumption,
  });

  final String vehicleId;
  final FuelLog fuelLog;
  final int number;
  final double? consumption;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(fuelLog.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => confirmDelete(
        context,
        title: 'SKREŚL TANKOWANIE',
        message: 'Usunąć tankowanie Nº ${Fmt.serial(number)} z rejestru?',
      ),
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
      background: const SwipeDeleteBackground(),
      child: WorkshopCard(
        spineLabel: 'Nº ${Fmt.serial(number)}',
        padding: const EdgeInsets.fromLTRB(13, 12, 13, 11),
        onTap: () =>
            context.push('/vehicles/$vehicleId/fuel-logs/${fuelLog.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    Fmt.kmUnit(fuelLog.mileage),
                    style: AppText.data(size: 17, weight: FontWeight.w600)
                        .copyWith(letterSpacing: 0),
                  ),
                ),
                Text(
                  Fmt.date(fuelLog.date),
                  style: AppText.data(size: 11.5, color: AppColors.fadedInk)
                      .copyWith(letterSpacing: 11.5 * 0.06),
                ),
              ],
            ),
            Container(
              height: 1,
              margin: const EdgeInsets.fromLTRB(0, 10, 0, 10),
              color: AppColors.hairline,
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _Figure(label: 'PALIWO', value: Fmt.litres(fuelLog.fuelAmount)),
                const Spacer(),
                _Figure(
                  label: 'KOSZT',
                  value: Fmt.money(fuelLog.totalCost),
                  alignRight: true,
                ),
              ],
            ),
            if (consumption != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  'SPALANIE ${Fmt.decimal1(consumption!)} L / 100 KM',
                  style: AppText.micro(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({
    required this.label,
    required this.value,
    this.alignRight = false,
  });

  final String label;
  final String value;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.label(size: 9.5)),
        const SizedBox(height: 5),
        Text(
          value,
          style: AppText.data(size: 19, weight: FontWeight.w600)
              .copyWith(letterSpacing: 0, height: 1),
        ),
      ],
    );
  }
}
