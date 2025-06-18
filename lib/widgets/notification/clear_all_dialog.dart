import 'package:flutter/material.dart';

typedef ClearAllCallback = Future<void> Function();

class ClearAllDialog extends StatelessWidget {
  final ClearAllCallback onConfirm;

  const ClearAllDialog({super.key, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Hapus Semua Notifikasi'),
      content: const Text(
        'Apakah Anda yakin ingin menghapus semua notifikasi? Tindakan ini tidak dapat dibatalkan.',
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
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Hapus'),
        ),
      ],
    );
  }
}
