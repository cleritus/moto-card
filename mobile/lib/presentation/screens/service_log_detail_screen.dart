import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../domain/entities/service_log.dart';
import '../providers/service_log_provider.dart';
import '../utils/format.dart';
import '../widgets/data_plate.dart';
import '../widgets/delete_confirmation_dialog.dart';
import '../widgets/error_view.dart';
import '../widgets/garage_app_bar.dart';
import '../widgets/garage_button.dart';
import '../widgets/paper_sheet.dart';
import '../widgets/stamp_badge.dart';

/// §8, "wpis otwarty" — the open leaf.
///
/// The only screen in the app where paper is the background: dark ink on
/// aged paper (10.63:1), perforation on the left, a parts table with dotted
/// leaders, a rust WYKONANO stamp and a signature line. The sheet keeps its
/// margins and its own shadow, so it never floods the screen with light at
/// night (§12.1). Action buttons stay on the dark canvas *under* the sheet —
/// the sheet is a document, not an interface.
class ServiceLogDetailScreen extends ConsumerWidget {
  const ServiceLogDetailScreen({
    super.key,
    required this.vehicleId,
    required this.id,
  });

  final String vehicleId;
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(serviceLogDetailProvider((vehicleId, id)));

    ref.listen<ServiceLogDetailState>(
      serviceLogDetailProvider((vehicleId, id)),
      (previous, next) {
        if (next.status == ServiceLogDetailStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next.errorMessage ?? 'Coś się zacięło.')),
          );
        }
      },
    );

    return Scaffold(
      appBar: const GarageAppBar(
        title: 'WPIS SERWISOWY',
        subtitle: 'KSIĄŻKA SERWISOWA',
      ),
      body: _buildBody(context, ref, state),
    );
  }

  Widget _buildBody(
      BuildContext context, WidgetRef ref, ServiceLogDetailState state) {
    switch (state.status) {
      case ServiceLogDetailStatus.initial:
      case ServiceLogDetailStatus.loading:
        return const LoadingView(label: 'OTWIERAM WPIS');
      case ServiceLogDetailStatus.error:
        return ErrorView(
          detail: state.errorMessage,
          onRetry: () => ref
              .read(serviceLogDetailNotifierProvider((vehicleId, id)))
              .loadServiceLog(id),
        );
      case ServiceLogDetailStatus.loaded:
        final serviceLog = state.serviceLog;
        if (serviceLog == null) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('Tej kartki nie ma w książce.'),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            _Sheet(serviceLog: serviceLog),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
              child: Column(
                children: [
                  GarageButton(
                    label: 'EDYTUJ WPIS',
                    onPressed: () => context.push(
                      '/vehicles/$vehicleId/service-logs/$id/edit',
                    ),
                  ),
                  const SizedBox(height: 12),
                  GarageButton.danger(
                    label: 'WYRWIJ KARTKĘ',
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
        title: 'WYRWIJ KARTKĘ',
        message: 'Usunąć ten wpis z książki serwisowej? Tego się nie cofnie.',
        onConfirm: () async {
          await ref
              .read(serviceLogDetailNotifierProvider((vehicleId, id)))
              .deleteServiceLog(id);
          if (context.mounted) {
            ref.read(serviceLogListProvider(vehicleId).notifier).refresh();
            context.pop();
          }
        },
      ),
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet({required this.serviceLog});

  final ServiceLog serviceLog;

  @override
  Widget build(BuildContext context) {
    final description = serviceLog.description?.trim();
    final mechanic = serviceLog.mechanic?.trim();
    final notes = serviceLog.notes?.trim();

    return PaperSheet(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'KSIĄŻKA SERWISOWA',
              style: AppText.micro(color: AppColors.paperInkFaded),
            ),
            Text(
              Fmt.date(serviceLog.date),
              style: AppText.micro(color: AppColors.paperInkFaded),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          Fmt.kmUnit(serviceLog.mileage),
          style: AppText.data(
            size: 27,
            weight: FontWeight.w600,
            color: AppColors.paperInk,
          ).copyWith(letterSpacing: 0),
        ),
        const SizedBox(height: 4),
        Text(
          '${Fmt.date(serviceLog.date)} · ${Fmt.weekday(serviceLog.date)}',
          style: AppText.micro(color: AppColors.paperInkFaded),
        ),
        const SizedBox(height: 6),
        Text(
          serviceLog.serviceType.toUpperCase(),
          style: AppText.condensed(size: 26, color: AppColors.paperInk)
              .copyWith(height: 1),
        ),
        const PaperRule(),
        const SizedBox(height: 8),
        DataPlate(
          onPaper: true,
          padding: EdgeInsets.zero,
          rows: [
            if (description != null && description.isNotEmpty)
              DataPlateRow('ZAKRES', description),
            DataPlateRow('PRZEBIEG', Fmt.kmUnit(serviceLog.mileage)),
            if (mechanic != null && mechanic.isNotEmpty)
              DataPlateRow('MECHANIK', mechanic),
            DataPlateRow('KOSZT', Fmt.money(serviceLog.totalCost),
                emphasis: true),
          ],
        ),
        if (notes != null && notes.isNotEmpty) ...[
          const PaperRule(margin: EdgeInsets.fromLTRB(0, 4, 0, 2)),
          const SizedBox(height: 10),
          Text('NOTATKI', style: AppText.micro(color: AppColors.paperInkFaded)),
          const SizedBox(height: 4),
          Text(
            notes,
            style: AppText.body(size: 13.5, color: const Color(0xFF2C2820))
                .copyWith(height: 1.5),
          ),
        ],
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 16, right: 4),
            child: StampBadge(
              label: 'WYKONANO',
              sublabel: Fmt.date(serviceLog.date),
              variant: StampVariant.wykonanoPaper,
              rotationDegrees: -3,
            ),
          ),
        ),
        PaperSignatureLine(
          left: mechanic != null && mechanic.isNotEmpty
              ? 'WARSZTAT / $mechanic'
              : 'WARSZTAT / PL',
          right: 'FORM 02-A · REV. 03',
        ),
      ],
    );
  }
}
