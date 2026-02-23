/// Dock → Timeline 드래그 시 사용
class ScheduleTaskParams {
  final String taskId;
  final DateTime startDateTime;
  final DateTime endDateTime;

  const ScheduleTaskParams({
    required this.taskId,
    required this.startDateTime,
    required this.endDateTime,
  });
}
