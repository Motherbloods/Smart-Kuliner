import 'package:intl/intl.dart';

String formatDate(DateTime date) {
  final months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

String formatDatePesanan(DateTime date) {
  return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(date);
}
