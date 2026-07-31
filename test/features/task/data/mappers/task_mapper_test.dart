import 'package:flutter_test/flutter_test.dart';
import 'package:nae_mo/core/database/app_database.dart';
import 'package:nae_mo/features/task/data/mappers/task_mapper.dart';
import 'package:nae_mo/features/task/domain/entities/task.dart';

void main() {
  const mapper = TaskMapper();

  group('TaskMapper.toEntity', () {
    test('maps an all-day legacy row to an event', () {
      final entity = mapper.toEntity(
        _legacyRow(isAllDay: true, createdAt: DateTime(2026, 7, 31)),
      );

      expect(entity.kind, TaskKind.event);
    });

    test('maps a non-all-day legacy row to a todo', () {
      final entity = mapper.toEntity(
        _legacyRow(isAllDay: false, createdAt: DateTime(2026, 7, 31)),
      );

      expect(entity.kind, TaskKind.todo);
    });

    test('uses startDateTime for targetDate when present', () {
      final startDateTime = DateTime(2026, 8, 2, 19, 20);
      final entity = mapper.toEntity(
        _legacyRow(
          isAllDay: false,
          startDateTime: startDateTime,
          createdAt: DateTime(2026, 7, 31),
        ),
      );

      expect(entity.targetDate, DateTime(2026, 8, 2));
    });

    test('falls back to createdAt for targetDate', () {
      final entity = mapper.toEntity(
        _legacyRow(
          isAllDay: false,
          createdAt: DateTime(2026, 7, 31, 19, 20),
        ),
      );

      expect(entity.targetDate, DateTime(2026, 7, 31));
    });

    test('converts UTC input to local time before truncating targetDate', () {
      final input = DateTime.utc(2026, 7, 31, 23, 30);
      final expectedLocal = input.toLocal();
      final entity = mapper.toEntity(
        _legacyRow(
          isAllDay: false,
          startDateTime: input,
          createdAt: DateTime(2026, 7, 31),
        ),
      );

      expect(
        entity.targetDate,
        DateTime(expectedLocal.year, expectedLocal.month, expectedLocal.day),
      );
    });
  });
}

TaskTableData _legacyRow({
  required bool isAllDay,
  DateTime? startDateTime,
  required DateTime createdAt,
}) =>
    TaskTableData(
      id: 'task',
      title: 'Task',
      kind: TaskKind.todo,
      targetDate: DateTime(2000),
      isCompleted: false,
      hasTime: startDateTime != null,
      startDateTime: startDateTime,
      isAllDay: isAllDay,
      isRecurring: false,
      createdAt: createdAt,
    );
