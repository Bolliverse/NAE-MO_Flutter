class CreateTaskParams {
  final String title;
  final String? categoryId;
  final bool hasTime;
  final DateTime? startDateTime;
  final DateTime? endDateTime;
  final bool isAllDay;

  const CreateTaskParams({
    required this.title,
    this.categoryId,
    this.hasTime = false,
    this.startDateTime,
    this.endDateTime,
    this.isAllDay = false,
  });
}
