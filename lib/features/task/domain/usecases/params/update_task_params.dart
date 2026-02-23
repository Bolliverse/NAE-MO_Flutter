class UpdateTaskParams {
  final String id;
  final String? title;
  final String? categoryId;
  final bool? hasTime;
  final DateTime? startDateTime;
  final DateTime? endDateTime;
  final bool? isAllDay;
  final bool? isCompleted;

  const UpdateTaskParams({
    required this.id,
    this.title,
    this.categoryId,
    this.hasTime,
    this.startDateTime,
    this.endDateTime,
    this.isAllDay,
    this.isCompleted,
  });
}
