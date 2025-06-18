class TimelineStep {
  final String title;
  final DateTime? timestamp;
  final bool isCompleted;

  TimelineStep({
    required this.title,
    this.timestamp,
    required this.isCompleted,
  });
}
