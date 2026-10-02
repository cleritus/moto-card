import 'package:flutter/material.dart';

import '../../config/theme.dart';
import 'garage_button.dart';

/// Square confirmation dialog in workshop voice. The destructive action is
/// lit oxide, never rust text (§2.2).
class DeleteConfirmationDialog extends StatelessWidget {
  const DeleteConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onConfirm,
    this.confirmLabel = 'USUŃ',
  });

  final String title;
  final String message;
  final VoidCallback onConfirm;
  final String confirmLabel;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      title: Text(title.toUpperCase(), style: AppText.h2()),
      content: Text(message, style: AppText.body(color: AppColors.fadedInk)),
      actions: [
        Row(
          children: [
            Expanded(
              child: GarageButton.ghost(
                label: 'ANULUJ',
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GarageButton(
                label: confirmLabel,
                onPressed: () {
                  Navigator.of(context).pop(true);
                  onConfirm();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Reveal behind a swiped-away card: rust fill with a bone label (4.71:1).
/// Rust is fill-only, so the word rides on top of it rather than being red
/// text on dark.
class SwipeDeleteBackground extends StatelessWidget {
  const SwipeDeleteBackground({
    super.key,
    this.label = 'USUŃ',
    this.margin = const EdgeInsets.only(bottom: AppGeo.cardGap),
  });

  final String label;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      color: AppColors.rustRed,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 18),
      child: Text(
        label.toUpperCase(),
        style: AppText.button(size: 15, color: AppColors.bone),
      ),
    );
  }
}

/// Swipe-to-delete confirmation shared by the list screens.
Future<bool> confirmDelete(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'USUŃ',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => DeleteConfirmationDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      onConfirm: () {},
    ),
  );
  return result ?? false;
}
