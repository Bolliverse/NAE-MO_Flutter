import 'package:nae_mo/features/task/domain/entities/task.dart';
import 'package:nae_mo/features/task/domain/validation/task_validator.dart';

class CreateTaskParams {
  final String title;
  final TaskKind kind;
  final DateTime targetDate;
  final String? categoryId;
  final bool hasTime;
  final DateTime? startDateTime;
  final DateTime? endDateTime;
  final bool isAllDay;

  const CreateTaskParams({
    required this.title,
    required this.kind,
    required this.targetDate,
    this.categoryId,
    this.hasTime = false,
    this.startDateTime,
    this.endDateTime,
    this.isAllDay = false,
  });

  TaskDraft toDraft() => TaskDraft(
        kind: kind,
        targetDate: targetDate,
        isCompleted: false,
        hasTime: hasTime,
        startDateTime: startDateTime,
        endDateTime: endDateTime,
        isAllDay: isAllDay,
      );
}
