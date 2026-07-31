import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nae_mo/core/database/app_database.dart';
import 'package:nae_mo/features/task/data/datasources/task_local_data_source_impl.dart';
import 'package:nae_mo/features/task/domain/entities/task.dart';
import 'package:nae_mo/features/task/domain/usecases/params/create_task_params.dart';
import 'package:nae_mo/features/task/domain/usecases/params/update_task_params.dart';

void main() {
  late AppDatabase database;
  late TaskLocalDataSourceImpl dataSource;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    dataSource = TaskLocalDataSourceImpl(database);
  });

  tearDown(() => database.close());

  test('insert persists canonical kind and normalized local target date',
      () async {
    final input = DateTime.utc(2026, 8, 12, 18, 45, 3, 4, 5);
    final expectedTargetDate = _localMidnight(input);

    final stored = await _insert(
      dataSource,
      id: 'canonical-event',
      kind: TaskKind.event,
      targetDate: input,
      isAllDay: true,
    );

    expect(stored.kind, TaskKind.event);
    expect(stored.targetDate, expectedTargetDate);
    expect(stored.targetDate.isUtc, isFalse);
    expect(stored.targetDate.hour, 0);
    expect(stored.targetDate.minute, 0);
    expect(stored.targetDate.second, 0);
    expect(stored.targetDate.millisecond, 0);
    expect(stored.targetDate.microsecond, 0);
  });

  test('date and range queries use normalized inclusive target dates',
      () async {
    await _insert(
      dataSource,
      id: 'range-start',
      targetDate: DateTime(2026, 8, 10, 8),
    );
    await _insert(
      dataSource,
      id: 'range-end',
      targetDate: DateTime(2026, 8, 11, 18),
    );
    await _insert(
      dataSource,
      id: 'outside-range',
      targetDate: DateTime(2026, 8, 12, 8),
    );

    final exact = await dataSource.getByDate(DateTime(2026, 8, 11, 23, 59));
    final range = await dataSource.getByRange(
      DateTime(2026, 8, 10, 12),
      DateTime(2026, 8, 11, 23, 59, 59, 999, 999),
    );

    expect(exact.map((row) => row.id), ['range-end']);
    expect(
      range.map((row) => row.id),
      unorderedEquals(['range-start', 'range-end']),
    );
  });

  test('today overview includes selected rows and earlier incomplete todos',
      () async {
    final selectedDate = DateTime(2026, 8, 12);
    final earlierDate = DateTime(2026, 8, 10);
    final laterDate = DateTime(2026, 8, 13);

    await _insert(
      dataSource,
      id: 'selected-event',
      kind: TaskKind.event,
      targetDate: selectedDate,
      isAllDay: true,
    );
    await _insert(
      dataSource,
      id: 'selected-completed-todo',
      targetDate: selectedDate,
    );
    await _setCompleted(dataSource, 'selected-completed-todo');
    await _insert(
      dataSource,
      id: 'earlier-incomplete-todo',
      targetDate: earlierDate,
    );
    await _insert(
      dataSource,
      id: 'earlier-event',
      kind: TaskKind.event,
      targetDate: earlierDate,
      isAllDay: true,
    );
    await _insert(
      dataSource,
      id: 'earlier-completed-todo',
      targetDate: earlierDate,
    );
    await _setCompleted(dataSource, 'earlier-completed-todo');
    await _insert(
      dataSource,
      id: 'later-todo',
      targetDate: laterDate,
    );

    final rows = await dataSource.getForTodayOverview(
      DateTime(2026, 8, 12, 20, 30),
    );

    expect(
      rows.map((row) => row.id),
      unorderedEquals([
        'selected-event',
        'selected-completed-todo',
        'earlier-incomplete-todo',
      ]),
    );
  });

  test('unscheduled query returns only incomplete untimed todos', () async {
    final targetDate = DateTime(2026, 8, 12);
    await _insert(
      dataSource,
      id: 'incomplete-untimed-todo',
      targetDate: targetDate,
    );
    await _insert(
      dataSource,
      id: 'all-day-event',
      kind: TaskKind.event,
      targetDate: targetDate,
      isAllDay: true,
    );
    await _insert(
      dataSource,
      id: 'timed-todo',
      targetDate: targetDate,
      hasTime: true,
      startDateTime: DateTime(2026, 8, 12, 9),
      endDateTime: DateTime(2026, 8, 12, 10),
    );
    await _insert(
      dataSource,
      id: 'completed-todo',
      targetDate: targetDate,
    );
    await _setCompleted(dataSource, 'completed-todo');

    final rows = await dataSource.getUnscheduled();

    expect(rows.map((row) => row.id), ['incomplete-untimed-todo']);
  });

  test('update persists canonical date and kind and clears both timestamps',
      () async {
    await _insert(
      dataSource,
      id: 'timed-event',
      kind: TaskKind.event,
      targetDate: DateTime(2026, 8, 12),
      hasTime: true,
      startDateTime: DateTime(2026, 8, 12, 9),
      endDateTime: DateTime(2026, 8, 12, 10),
    );
    final updatedTargetInput = DateTime.utc(2026, 8, 14, 18, 45);

    final stored = await dataSource.update(
      UpdateTaskParams(
        id: 'timed-event',
        kind: TaskKind.todo,
        targetDate: updatedTargetInput,
        hasTime: false,
        clearTime: true,
      ),
    );

    expect(stored.kind, TaskKind.todo);
    expect(stored.targetDate, _localMidnight(updatedTargetInput));
    expect(stored.hasTime, isFalse);
    expect(stored.startDateTime, isNull);
    expect(stored.endDateTime, isNull);

    final raw = await dataSource.getById('timed-event');
    expect(raw.startDateTime, isNull);
    expect(raw.endDateTime, isNull);
  });
}

Future<TaskTableData> _insert(
  TaskLocalDataSourceImpl dataSource, {
  required String id,
  TaskKind kind = TaskKind.todo,
  required DateTime targetDate,
  bool hasTime = false,
  DateTime? startDateTime,
  DateTime? endDateTime,
  bool isAllDay = false,
}) =>
    dataSource.insert(
      id,
      CreateTaskParams(
        title: id,
        kind: kind,
        targetDate: targetDate,
        hasTime: hasTime,
        startDateTime: startDateTime,
        endDateTime: endDateTime,
        isAllDay: isAllDay,
      ),
    );

Future<void> _setCompleted(
  TaskLocalDataSourceImpl dataSource,
  String id,
) async {
  await dataSource.update(
    UpdateTaskParams(id: id, isCompleted: true),
  );
}

DateTime _localMidnight(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}
