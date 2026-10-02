import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../domain/entities/vehicle.dart';
import '../providers/auth_provider.dart';
import '../providers/vehicle_provider.dart';
import '../utils/format.dart';
import '../widgets/delete_confirmation_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_view.dart';
import '../widgets/garage_button.dart';
import '../widgets/screen_header.dart';
import '../widgets/workshop_card.dart';

/// §6 row 2 — the garage. Cards are machine plaques with a bay number in the
/// spine, not SaaS list rows.
class VehicleListScreen extends ConsumerWidget {
  const VehicleListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(vehicleListProvider);

    ref.listen<VehicleListState>(vehicleListProvider, (previous, next) {
      if (next.status == VehicleListStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage ?? 'Coś się zacięło.')),
        );
      }
    });

    final count = state.vehicles.length;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ScreenHeader(
              tagLeft: 'MOTO / GARAŻ',
              tagRight: 'WYLOGUJ',
              onTagRightTap: () => ref.read(authProvider.notifier).logout(),
              title: 'GARAŻ',
              subtitle: 'STANOWISKA: ${Fmt.serial(count, width: 2)}',
              action: SmallButton(
                label: '+ DO GARAŻU',
                onPressed: () => context.push('/vehicles/new'),
              ),
            ),
            Expanded(child: _buildBody(context, ref, state)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, WidgetRef ref, VehicleListState state) {
    switch (state.status) {
      case VehicleListStatus.loading:
      case VehicleListStatus.initial:
        return const LoadingView(label: 'OTWIERAM GARAŻ');
      case VehicleListStatus.loaded:
        if (state.vehicles.isEmpty) {
          return const EmptyState(
            tag: 'STANOWISKA: 00',
            title: 'PUSTY GARAŻ.',
            subtitle: 'Nic tu jeszcze nie stoi. Wprowadź pierwszą maszynę.',
          );
        }
        return RefreshIndicator(
          color: AppColors.oxideLit,
          backgroundColor: AppColors.dirtyBlack,
          onRefresh: () => ref.read(vehicleListProvider.notifier).refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              AppGeo.screenMargin,
              20,
              AppGeo.screenMargin,
              40,
            ),
            itemCount: state.vehicles.length + 1,
            itemBuilder: (context, index) {
              if (index == state.vehicles.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'PRZESUŃ KARTĘ W LEWO,\nABY WYPROWADZIĆ Z GARAŻU.',
                    style: AppText.micro().copyWith(
                      letterSpacing: 9.5 * 0.12,
                      height: 1.7,
                    ),
                  ),
                );
              }
              return _VehiclePlaque(
                vehicle: state.vehicles[index],
                bay: index + 1,
              );
            },
          ),
        );
      case VehicleListStatus.error:
        return ErrorView(
          detail: state.errorMessage,
          onRetry: () => ref.read(vehicleListProvider.notifier).refresh(),
        );
    }
  }
}

class _VehiclePlaque extends ConsumerWidget {
  const _VehiclePlaque({required this.vehicle, required this.bay});

  final Vehicle vehicle;
  final int bay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(vehicle.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => confirmDelete(
        context,
        title: 'WYPROWADŹ Z GARAŻU',
        message: 'Wyprowadzić ${vehicle.name} z garażu? '
            'Razem z maszyną znika jej książka serwisowa.',
        confirmLabel: 'WYPROWADŹ',
      ),
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        ref.read(vehicleListProvider.notifier).clearError();
        ref
            .read(vehicleDetailNotifierProvider(vehicle.id))
            .deleteVehicle(vehicle.id)
            .then((_) {
          ref.read(vehicleListProvider.notifier).refresh();
        });
      },
      background: const SwipeDeleteBackground(label: 'WYPROWADŹ'),
      child: WorkshopCard(
        spineLabel: 'Nº ${Fmt.serial(bay, width: 2)}',
        onTap: () => context.push('/vehicles/${vehicle.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(vehicle.make.toUpperCase(),
                style: AppText.label(size: 9.5).copyWith(
                  letterSpacing: 9.5 * 0.18,
                )),
            const SizedBox(height: 3),
            Text(
              vehicle.name.toUpperCase(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.condensed(size: 27, color: AppColors.bone)
                  .copyWith(height: 1, letterSpacing: 27 * 0.02),
            ),
            const SizedBox(height: 5),
            Text(
              '${vehicle.vehicleModel.toUpperCase()} · ${vehicle.year}',
              style: AppText.data(size: 11, color: AppColors.fadedInk),
            ),
            Container(
              margin: const EdgeInsets.only(top: 14),
              padding: const EdgeInsets.only(top: 11),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.hairline)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (vehicle.licensePlate.isNotEmpty)
                    PlateChip(text: vehicle.licensePlate),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        vehicle.mileage != null ? Fmt.km(vehicle.mileage!) : '—',
                        style: AppText.data(size: 21, weight: FontWeight.w600)
                            .copyWith(letterSpacing: 0, height: 1),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'KM',
                        style: AppText.micro(size: 9)
                            .copyWith(letterSpacing: 9 * 0.2),
                      ),
                    ],
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
