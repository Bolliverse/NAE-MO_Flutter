import 'package:nae_mo/features/task/domain/entities/task.dart';
import 'package:nae_mo/features/task/domain/validation/task_validator.dart';

class UpdateTaskParams {
  final String id;
  final String? title;
  final TaskKind? kind;
  final DateTime? targetDate;
  final String? categoryId;
  final bool? hasTime;
  final DateTime? startDateTime;
  final DateTime? endDateTime;
  final bool? isAllDay;
  final bool? isCompleted;
  final bool clearTime;

  const UpdateTaskParams({
    required this.id,
    this.title,
    this.kind,
    this.targetDate,
    this.categoryId,
    this.hasTime,
    this.startDateTime,
    this.endDateTime,
    this.isAllDay,
    this.isCompleted,
    this.clearTime = false,
  });

  TaskDraft resolve(Task current) => TaskDraft(
        kind: kind ?? current.kind,
        targetDate: targetDate ?? current.targetDate,
        isCompleted: isCompleted ?? current.isCompleted,
        hasTime: hasTime ?? current.hasTime,
        startDateTime:
            clearTime ? null : startDateTime ?? current.startDateTime,
        endDateTime: clearTime ? null : endDateTime ?? current.endDateTime,
        isAllDay: isAllDay ?? current.isAllDay,
      );
}
