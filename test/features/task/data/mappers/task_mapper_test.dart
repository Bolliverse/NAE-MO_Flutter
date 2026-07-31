import 'package:flutter_test/flutter_test.dart';
import 'package:nae_mo/core/database/app_database.dart';
import 'package:nae_mo/features/task/data/mappers/task_mapper.dart';
import 'package:nae_mo/features/task/domain/entities/task.dart';

void main() {
  const mapper = TaskMapper();

  group('TaskMapper.toEntity', () {
    test('uses canonical v2 kind and target date over legacy fields', () {
      final targetDate = DateTime(2026, 8, 12);
      final entity = mapper.toEntity(
        _row(
          kind: TaskKind.event,
          targetDate: targetDate,
          isAllDay: false,
          startDateTime: DateTime(2026, 8, 2, 19, 20),
          createdAt: DateTime(2026, 7, 31, 10),
        ),
      );

      expect(entity.kind, TaskKind.event);
      expect(entity.targetDate, targetDate);
    });
  });
}

TaskTableData _row({
  required TaskKind kind,
  required DateTime targetDate,
  required bool isAllDay,
  DateTime? startDateTime,
  required DateTime createdAt,
}) =>
    TaskTableData(
      id: 'task',
      title: 'Task',
      kind: kind,
      targetDate: targetDate,
      isCompleted: false,
      hasTime: startDateTime != null,
      startDateTime: startDateTime,
      isAllDay: isAllDay,
      isRecurring: false,
      createdAt: createdAt,
    );
