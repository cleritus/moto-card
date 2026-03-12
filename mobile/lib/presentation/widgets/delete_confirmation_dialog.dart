import 'package:flutter/material.dart';

class DeleteConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onConfirm;

  const DeleteConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Anuluj'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(true);
            onConfirm();
          },
          child: const Text('Usuń'),
        ),
      ],
    );
  }
}