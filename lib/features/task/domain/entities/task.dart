class Task {
  final String id;
  final String title;
  final String? categoryId;
  final bool isCompleted;
  final bool hasTime;
  final DateTime? startDateTime;
  final DateTime? endDateTime;
  final bool isAllDay;
  final bool isRecurring;
  final String? recurrenceRule;
  final DateTime createdAt;

  const Task({
    required this.id,
    required this.title,
    this.categoryId,
    required this.isCompleted,
    required this.hasTime,
    this.startDateTime,
    this.endDateTime,
    required this.isAllDay,
    required this.isRecurring,
    this.recurrenceRule,
    required this.createdAt,
  });

  bool get isScheduled => hasTime && startDateTime != null;
  bool get isUnscheduled => !hasTime || startDateTime == null;
}
