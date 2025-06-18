import 'package:flutter/material.dart';
import 'package:smart/models/notifikasi.dart';
import 'package:smart/utils/notification_utils.dart';

class NotificationDetailsDialog extends StatelessWidget {
  final NotificationModel notification;

  const NotificationDetailsDialog({Key? key, required this.notification})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(notification.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(notification.body),
          const SizedBox(height: 16),
          Text(
            'Waktu: ${NotificationUtils.formatTime(notification.createdAt.toIso8601String())}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Tutup'),
        ),
      ],
    );
  }
}
