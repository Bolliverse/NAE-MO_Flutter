import 'package:nae_mo/core/database/app_database.dart';
import 'package:nae_mo/features/task/domain/entities/task.dart';

class TaskMapper {
  const TaskMapper();

  Task toEntity(TaskTableData data) => Task(
        id: data.id,
        title: data.title,
        kind: data.kind,
        targetDate: data.targetDate,
        categoryId: data.categoryId,
        isCompleted: data.isCompleted,
        hasTime: data.hasTime,
        startDateTime: data.startDateTime,
        endDateTime: data.endDateTime,
        isAllDay: data.isAllDay,
        isRecurring: data.isRecurring,
        recurrenceRule: data.recurrenceRule,
        createdAt: data.createdAt,
      );

  List<Task> toEntityList(List<TaskTableData> dataList) =>
      dataList.map(toEntity).toList();
}
