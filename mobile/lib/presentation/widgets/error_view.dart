import 'package:flutter/material.dart';

import '../../config/theme.dart';
import 'double_rule.dart';
import 'garage_button.dart';

/// Failure state in workshop voice (§10): `COŚ SIĘ ZACIĘŁO.` with the raw
/// detail in mono underneath and `SPRÓBUJ JESZCZE RAZ` as the way out.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.detail, required this.onRetry});

  final String? detail;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppGeo.screenMargin + 12,
          vertical: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('AWARIA', style: AppText.micro(color: AppColors.oxideLit)),
            const SizedBox(height: 10),
            const DoubleRule(),
            const SizedBox(height: 16),
            Text('COŚ SIĘ ZACIĘŁO.', style: AppText.h1(size: 28)),
            if (detail != null && detail!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                decoration: const BoxDecoration(
                  color: AppColors.grease,
                  border: Border(
                    left: BorderSide(color: AppColors.oxideOrange, width: 3),
                  ),
                ),
                child: Text(
                  detail!,
                  style: AppText.data(size: 11, color: AppColors.fadedInk)
                      .copyWith(height: 1.6),
                ),
              ),
            ],
            const SizedBox(height: 24),
            GarageButton(label: 'SPRÓBUJ JESZCZE RAZ', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}

/// Inline failure strip for forms — `COŚ SIĘ ZACIĘŁO.` over the raw detail
/// in mono, behind an oxide margin bar (§10).
class FaultStrip extends StatelessWidget {
  const FaultStrip({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
      decoration: const BoxDecoration(
        color: AppColors.grease,
        border: Border(
          left: BorderSide(color: AppColors.oxideOrange, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'COŚ SIĘ ZACIĘŁO.',
            style: AppText.button(size: 14, color: AppColors.oxideLit),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: AppText.data(size: 11, color: AppColors.fadedInk)
                .copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}

/// Shared loading state — a flat linear bar instead of a spinning Material
/// ring where a page is still blank.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.label = 'WCZYTYWANIE'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 140,
            height: 6,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.grease,
                border: Border.fromBorderSide(AppGeo.structure),
              ),
              child: const LinearProgressIndicator(
                minHeight: 6,
                backgroundColor: AppColors.grease,
                color: AppColors.oxideOrange,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(label.toUpperCase(), style: AppText.micro()),
        ],
      ),
    );
  }
}
