import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../domain/entities/service_log.dart';
import '../providers/service_log_provider.dart';
import '../providers/vehicle_provider.dart';
import '../utils/format.dart';
import '../widgets/delete_confirmation_dialog.dart';
import '../widgets/double_rule.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_view.dart';
import '../widgets/garage_button.dart';
import '../widgets/screen_header.dart';
import '../widgets/stamp_badge.dart';
import '../widgets/workshop_card.dart';

/// §8 — the service book.
///
/// Not a list of tiles: leaves in a binder. Years are separated by a thick
/// rule with the year on the left, every entry is a card with the binder
/// perforation down its left edge, and the hierarchy is inverted versus the
/// old screen — mileage and date on top, the job underneath, cost at the
/// bottom. That is how a real service book reads: date stamp first.
class ServiceLogListScreen extends ConsumerWidget {
  const ServiceLogListScreen({super.key, required this.vehicleId});

  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(serviceLogListProvider(vehicleId));
    final vehicle = ref.watch(vehicleDetailProvider(vehicleId)).vehicle;

    ref.listen<ServiceLogListState>(serviceLogListProvider(vehicleId),
        (previous, next) {
      if (next.status == ServiceLogListStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage ?? 'Coś się zacięło.')),
        );
      }
    });

    final logs = [...state.serviceLogs]
      ..sort((a, b) => b.date.compareTo(a.date));
    final numbers = _entryNumbers(logs);
    final last = logs.isNotEmpty ? logs.first.date : null;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                ScreenHeader(
                  tagLeft: vehicle?.name ?? 'KSIĄŻKA',
                  tagRight: logs.isEmpty
                      ? 'Nº ————'
                      : 'Nº ${Fmt.serial(numbers[logs.first.id] ?? 0)}',
                  title: 'KSIĄŻKA SERWISOWA',
                  titleSize: 30,
                  subtitle: last == null
                      ? 'WPISÓW: 00'
                      : 'WPISÓW: ${Fmt.serial(logs.length, width: 2)}'
                          ' · OSTATNI ${Fmt.date(last)}',
                ),
                Expanded(
                  child: _buildBody(context, ref, state, logs, numbers),
                ),
              ],
            ),
            Positioned(
              right: AppGeo.screenMargin,
              bottom: 24,
              child: GarageFab(
                onPressed: () =>
                    context.push('/vehicles/$vehicleId/service-logs/new'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Entry numbers run from the oldest leaf forward, like a paper book.
  Map<String, int> _entryNumbers(List<ServiceLog> descending) {
    final numbers = <String, int>{};
    for (var i = 0; i < descending.length; i++) {
      numbers[descending[i].id] = descending.length - i;
    }
    return numbers;
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    ServiceLogListState state,
    List<ServiceLog> logs,
    Map<String, int> numbers,
  ) {
    switch (state.status) {
      case ServiceLogListStatus.loading:
      case ServiceLogListStatus.initial:
        return const LoadingView(label: 'OTWIERAM KSIĄŻKĘ');
      case ServiceLogListStatus.error:
        return ErrorView(
          detail: state.errorMessage,
          onRetry: () =>
              ref.read(serviceLogListProvider(vehicleId).notifier).refresh(),
        );
      case ServiceLogListStatus.loaded:
        if (logs.isEmpty) {
          return const EmptyState(
            tag: 'WPISÓW: 00',
            title: 'W WARSZTACIE CISZA.',
            subtitle: 'Nic jeszcze nie zapisane.',
          );
        }

        // Flatten into year dividers + leaves so the book scrolls as one.
        final items = <Widget>[];
        int? currentYear;
        for (final log in logs) {
          if (log.date.year != currentYear) {
            currentYear = log.date.year;
            items.add(YearDivider(year: currentYear));
          }
          items.add(
            _ServiceLeaf(
              vehicleId: vehicleId,
              serviceLog: log,
              number: numbers[log.id] ?? 0,
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.oxideLit,
          backgroundColor: AppColors.dirtyBlack,
          onRefresh: () =>
              ref.read(serviceLogListProvider(vehicleId).notifier).refresh(),
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
}

/// One leaf in the binder.
class _ServiceLeaf extends ConsumerWidget {
  const _ServiceLeaf({
    required this.vehicleId,
    required this.serviceLog,
    required this.number,
  });

  final String vehicleId;
  final ServiceLog serviceLog;
  final int number;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final description = serviceLog.description?.trim();
    final notes = serviceLog.notes?.trim();
    final mechanic = serviceLog.mechanic?.trim();

    return Dismissible(
      key: Key(serviceLog.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => confirmDelete(
        context,
        title: 'WYRWIJ KARTKĘ',
        message: 'Usunąć wpis Nº ${Fmt.serial(number)} z książki serwisowej?',
      ),
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
      background: const SwipeDeleteBackground(),
      child: WorkshopCard(
        binding: true,
        padding: const EdgeInsets.fromLTRB(13, 12, 13, 11),
        onTap: () =>
            context.push('/vehicles/$vehicleId/service-logs/${serviceLog.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mileage is the eye anchor; the date stamp sits beside it.
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    Fmt.kmUnit(serviceLog.mileage),
                    style: AppText.data(size: 17, weight: FontWeight.w600)
                        .copyWith(letterSpacing: 0),
                  ),
                ),
                Text(
                  Fmt.date(serviceLog.date),
                  style: AppText.data(size: 11.5, color: AppColors.fadedInk)
                      .copyWith(letterSpacing: 11.5 * 0.06),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              serviceLog.serviceType.toUpperCase(),
              style: AppText.condensed(size: 21),
            ),
            Container(
              height: 1,
              margin: const EdgeInsets.fromLTRB(0, 10, 0, 9),
              color: AppColors.hairline,
            ),
            if (description != null && description.isNotEmpty)
              Text(
                description.toUpperCase(),
                style: AppText.data(size: 11, color: AppColors.agedPaper)
                    .copyWith(letterSpacing: 11 * 0.05),
              ),
            if (mechanic != null && mechanic.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'WARSZTAT / ${mechanic.toUpperCase()}',
                  style: AppText.micro(),
                ),
              ),
            if (notes != null && notes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 7),
                child: Text(
                  notes,
                  style: AppText.body(size: 13.5, color: AppColors.fadedInk),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      Fmt.money(serviceLog.totalCost),
                      style: AppText.data(size: 15, weight: FontWeight.w600)
                          .copyWith(letterSpacing: 0),
                    ),
                  ),
                  const StampBadge(
                    label: 'WYKONANO',
                    variant: StampVariant.wykonano,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
