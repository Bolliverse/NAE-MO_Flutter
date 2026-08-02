import 'package:flutter_test/flutter_test.dart';
import 'package:nae_mo/core/database/app_database.dart';
import 'package:nae_mo/core/errors/app_exception.dart';
import 'package:nae_mo/core/errors/failure.dart';
import 'package:nae_mo/features/task/data/datasources/task_local_data_source.dart';
import 'package:nae_mo/features/task/data/mappers/task_mapper.dart';
import 'package:nae_mo/features/task/data/repositories/task_repository_impl.dart';
import 'package:nae_mo/features/task/domain/entities/task.dart';
import 'package:nae_mo/features/task/domain/usecases/params/create_task_params.dart';
import 'package:nae_mo/features/task/domain/usecases/params/update_task_params.dart';

void main() {
  late _FakeTaskLocalDataSource dataSource;
  late TaskRepositoryImpl repository;

  setUp(() {
    dataSource = _FakeTaskLocalDataSource();
    repository = TaskRepositoryImpl(
      dataSource: dataSource,
      mapper: const TaskMapper(),
    );
  });

  group('getTaskById', () {
    test('maps the stored v2 kind and target date', () async {
      final targetDate = DateTime(2026, 8, 12);
      dataSource.row = _row(
        id: 'event',
        kind: TaskKind.event,
        targetDate: targetDate,
        isAllDay: false,
        startDateTime: DateTime(2026, 7, 1, 9),
      );

      final result = await repository.getTaskById('event');

      expect(dataSource.requestedId, 'event');
      expect(result.failure, isNull);
      expect(result.data?.kind, TaskKind.event);
      expect(result.data?.targetDate, targetDate);
    });

    test('maps a cache exception to CacheFailure', () async {
      dataSource.getByIdException = const CacheException('read failed');

      final result = await repository.getTaskById('missing');

      expect(result.data, isNull);
      expect(result.failure, const CacheFailure('read failed'));
    });
  });

  group('getTasksForTodayOverview', () {
    test('preserves selected-date rows and earlier incomplete todos', () async {
      final selectedDate = DateTime(2026, 8, 12);
      final earlierDate = DateTime(2026, 8, 10);
      dataSource.rows = [
        _row(
          id: 'selected-event',
          kind: TaskKind.event,
          targetDate: selectedDate,
          isCompleted: false,
          isAllDay: true,
        ),
        _row(
          id: 'selected-completed-todo',
          kind: TaskKind.todo,
          targetDate: selectedDate,
          isCompleted: true,
        ),
        _row(
          id: 'earlier-incomplete-todo',
          kind: TaskKind.todo,
          targetDate: earlierDate,
          isCompleted: false,
        ),
      ];

      final result = await repository.getTasksForTodayOverview(selectedDate);

      expect(dataSource.requestedOverviewDate, selectedDate);
      expect(result.failure, isNull);
      expect(
        result.data?.map((task) => task.id),
        [
          'selected-event',
          'selected-completed-todo',
          'earlier-incomplete-todo',
        ],
      );
      expect(result.data?[0].kind, TaskKind.event);
      expect(result.data?[0].targetDate, selectedDate);
      expect(result.data?[1].isCompleted, isTrue);
      expect(result.data?[2].targetDate, earlierDate);
    });

    test('maps a cache exception to CacheFailure', () async {
      dataSource.getForTodayOverviewException =
          const CacheException('overview failed');

      final result =
          await repository.getTasksForTodayOverview(DateTime(2026, 8, 12));

      expect(result.data, isNull);
      expect(result.failure, const CacheFailure('overview failed'));
    });
  });

  test('createTask forwards v2 scheduling fields exactly', () async {
    final targetDate = DateTime(2026, 8, 12);
    final startDateTime = DateTime(2026, 8, 12, 9);
    final endDateTime = DateTime(2026, 8, 12, 10);
    final params = CreateTaskParams(
      title: 'Planning',
      kind: TaskKind.event,
      targetDate: targetDate,
      hasTime: true,
      startDateTime: startDateTime,
      endDateTime: endDateTime,
    );
    dataSource.row = _row(
      id: 'created',
      kind: TaskKind.event,
      targetDate: targetDate,
      startDateTime: startDateTime,
      endDateTime: endDateTime,
    );

    final result = await repository.createTask(params);

    expect(dataSource.insertParams, same(params));
    expect(dataSource.insertParams?.kind, TaskKind.event);
    expect(dataSource.insertParams?.targetDate, targetDate);
    expect(dataSource.insertedId, isNotEmpty);
    expect(result.failure, isNull);
  });

  test('updateTask forwards kind, target date, and clearTime exactly',
      () async {
    final targetDate = DateTime(2026, 8, 13);
    final params = UpdateTaskParams(
      id: 'todo',
      kind: TaskKind.todo,
      targetDate: targetDate,
      clearTime: true,
    );
    dataSource.row = _row(
      id: 'todo',
      kind: TaskKind.todo,
      targetDate: targetDate,
    );

    final result = await repository.updateTask(params);

    expect(dataSource.updateParams, same(params));
    expect(dataSource.updateParams?.kind, TaskKind.todo);
    expect(dataSource.updateParams?.targetDate, targetDate);
    expect(dataSource.updateParams?.clearTime, isTrue);
    expect(result.failure, isNull);
  });

  test('createTask maps a cache exception to CacheFailure', () async {
    dataSource.insertException = const CacheException('write failed');
    final params = CreateTaskParams(
      title: 'Planning',
      kind: TaskKind.todo,
      targetDate: DateTime(2026, 8, 12),
    );

    final result = await repository.createTask(params);

    expect(result.data, isNull);
    expect(result.failure, const CacheFailure('write failed'));
  });
}

TaskTableData _row({
  required String id,
  required TaskKind kind,
  required DateTime targetDate,
  bool isCompleted = false,
  bool isAllDay = false,
  DateTime? startDateTime,
  DateTime? endDateTime,
}) =>
    TaskTableData(
      id: id,
      title: id,
      kind: kind,
      targetDate: targetDate,
      isCompleted: isCompleted,
      hasTime: startDateTime != null,
      startDateTime: startDateTime,
      endDateTime: endDateTime,
      isAllDay: isAllDay,
      isRecurring: false,
      createdAt: DateTime(2026, 7, 31),
    );

class _FakeTaskLocalDataSource implements TaskLocalDataSource {
  TaskTableData? row;
  List<TaskTableData> rows = const [];
  String? requestedId;
  DateTime? requestedOverviewDate;
  String? insertedId;
  CreateTaskParams? insertParams;
  UpdateTaskParams? updateParams;
  CacheException? getByIdException;
  CacheException? getForTodayOverviewException;
  CacheException? insertException;

  @override
  Future<TaskTableData> getById(String id) async {
    requestedId = id;
    final exception = getByIdException;
    if (exception != null) throw exception;
    return row!;
  }

  @override
  Future<List<TaskTableData>> getForTodayOverview(DateTime selectedDate) async {
    requestedOverviewDate = selectedDate;
    final exception = getForTodayOverviewException;
    if (exception != null) throw exception;
    return rows;
  }

  @override
  Future<List<TaskTableData>> getByDate(DateTime date) async => rows;

  @override
  Future<List<TaskTableData>> getByRange(DateTime start, DateTime end) async =>
      rows;

  @override
  Future<List<TaskTableData>> getUnscheduled() async => rows;

  @override
  Future<TaskTableData> insert(String id, CreateTaskParams params) async {
    insertedId = id;
    insertParams = params;
    final exception = insertException;
    if (exception != null) throw exception;
    return row!;
  }

  @override
  Future<TaskTableData> update(UpdateTaskParams params) async {
    updateParams = params;
    return row!;
  }

  @override
  Future<void> delete(String id) async {}

  @override
  Future<TaskTableData> toggleComplete(String id) async => row!;
}
