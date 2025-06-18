import 'package:flutter/material.dart';

typedef ConfirmCallback = Future<void> Function();

class MarkAllAsReadDialog extends StatelessWidget {
  final ConfirmCallback onConfirm;

  const MarkAllAsReadDialog({super.key, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tandai Semua Sudah Dibaca'),
      content: const Text(
        'Apakah Anda yakin ingin menandai semua notifikasi sebagai sudah dibaca?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: () async {
            Navigator.of(context).pop();
            await onConfirm();
          },
          child: const Text('Ya'),
        ),
      ],
    );
  }
}
