import 'package:flutter_test/flutter_test.dart' hide fail;
import 'package:nae_mo/core/errors/failure.dart';
import 'package:nae_mo/core/utils/result.dart';
import 'package:nae_mo/features/task/domain/entities/task.dart';
import 'package:nae_mo/features/task/domain/repositories/task_repository.dart';
import 'package:nae_mo/features/task/domain/usecases/create_task_use_case.dart';
import 'package:nae_mo/features/task/domain/usecases/params/create_task_params.dart';
import 'package:nae_mo/features/task/domain/usecases/params/schedule_task_params.dart';
import 'package:nae_mo/features/task/domain/usecases/params/update_task_params.dart';
import 'package:nae_mo/features/task/domain/usecases/schedule_task_use_case.dart';
import 'package:nae_mo/features/task/domain/usecases/toggle_complete_use_case.dart';
import 'package:nae_mo/features/task/domain/usecases/update_task_use_case.dart';

void main() {
  group('CreateTaskUseCase', () {
    test('rejects an invalid draft without creating a task', () async {
      final repository = _FakeTaskRepository();
      final useCase = CreateTaskUseCase(repository);

      final result = await useCase(
        CreateTaskParams(
          title: 'Invalid',
          kind: TaskKind.todo,
          targetDate: DateTime(2026, 8, 12, 9),
        ),
      );

      expect(result.data, isNull);
      expect(
        result.failure,
        const ValidationFailure('대상 날짜는 자정으로 정규화되어야 합니다.'),
      );
      expect(repository.createCalls, 0);
    });

    test('creates a valid task exactly once', () async {
      final repository = _FakeTaskRepository();
      final useCase = CreateTaskUseCase(repository);
      final params = CreateTaskParams(
        title: 'Valid',
        kind: TaskKind.todo,
        targetDate: DateTime(2026, 8, 12),
      );

      final result = await useCase(params);

      expect(result.failure, isNull);
      expect(repository.createCalls, 1);
      expect(repository.createdParams, same(params));
    });
  });

  group('UpdateTaskUseCase', () {
    test('preserves a read failure without updating', () async {
      const readFailure = CacheFailure('read failed');
      final repository = _FakeTaskRepository(readFailure: readFailure);
      final useCase = UpdateTaskUseCase(repository);

      final result = await useCase(
        const UpdateTaskParams(id: 'task', title: 'Changed'),
      );

      expect(result.data, isNull);
      expect(result.failure, same(readFailure));
      expect(repository.operations, ['get']);
      expect(repository.updateCalls, 0);
    });

    test('merges a patch over the stored task before validating', () async {
      final repository = _FakeTaskRepository(
        task: _task(
          hasTime: true,
          startDateTime: DateTime(2026, 8, 12, 9),
          endDateTime: DateTime(2026, 8, 12, 10),
        ),
      );
      final useCase = UpdateTaskUseCase(repository);

      final result = await useCase(
        UpdateTaskParams(
          id: 'task',
          endDateTime: DateTime(2026, 8, 12, 8, 30),
        ),
      );

      expect(
        result.failure,
        const ValidationFailure('종료 시각은 시작 시각보다 늦어야 합니다.'),
      );
      expect(repository.operations, ['get']);
      expect(repository.updateCalls, 0);
    });

    test('updates a valid resolved task exactly once', () async {
      final repository = _FakeTaskRepository();
      final useCase = UpdateTaskUseCase(repository);
      const params = UpdateTaskParams(id: 'task', title: 'Changed');

      final result = await useCase(params);

      expect(result.failure, isNull);
      expect(repository.operations, ['get', 'update']);
      expect(repository.updateCalls, 1);
      expect(repository.updatedParams, same(params));
    });

    test('rejects clearing timestamps while the task remains timed', () async {
      final repository = _FakeTaskRepository(
        task: _task(
          hasTime: true,
          startDateTime: DateTime(2026, 8, 12, 9),
          endDateTime: DateTime(2026, 8, 12, 10),
        ),
      );
      final useCase = UpdateTaskUseCase(repository);

      final result = await useCase(
        const UpdateTaskParams(id: 'task', clearTime: true),
      );

      expect(
        result.failure,
        const ValidationFailure('시간 지정 항목은 시작과 종료 시각이 필요합니다.'),
      );
      expect(repository.updateCalls, 0);
    });

    test('allows clearing timestamps when the patch also disables time',
        () async {
      final repository = _FakeTaskRepository(
        task: _task(
          hasTime: true,
          startDateTime: DateTime(2026, 8, 12, 9),
          endDateTime: DateTime(2026, 8, 12, 10),
        ),
      );
      final useCase = UpdateTaskUseCase(repository);
      const params = UpdateTaskParams(
        id: 'task',
        clearTime: true,
        hasTime: false,
      );

      final result = await useCase(params);

      expect(result.failure, isNull);
      expect(repository.operations, ['get', 'update']);
      expect(repository.updateCalls, 1);
      expect(repository.updatedParams, same(params));
    });
  });

  group('ScheduleTaskUseCase', () {
    test('moves an older unscheduled todo to the scheduled local date',
        () async {
      final repository = _FakeTaskRepository(
        task: _task(targetDate: DateTime(2026, 8, 10)),
      );
      final updateUseCase = _UpdateUseCaseRepositoryAdapter(repository);
      final useCase = ScheduleTaskUseCase(updateUseCase);
      final startDateTime = DateTime.utc(2026, 8, 12, 16);
      final endDateTime = DateTime.utc(2026, 8, 12, 17);
      final localStart = startDateTime.toLocal();

      final result = await useCase(
        ScheduleTaskParams(
          taskId: 'task',
          startDateTime: startDateTime,
          endDateTime: endDateTime,
        ),
      );

      expect(result.failure, isNull);
      expect(repository.operations, ['get', 'update']);
      expect(repository.updateCalls, 1);
      expect(repository.updatedParams?.id, 'task');
      expect(repository.updatedParams?.hasTime, isTrue);
      expect(repository.updatedParams?.startDateTime, startDateTime);
      expect(repository.updatedParams?.endDateTime, endDateTime);
      expect(
        repository.updatedParams?.targetDate,
        DateTime(localStart.year, localStart.month, localStart.day),
      );
    });

    test('rejects an invalid range without updating', () async {
      final repository = _FakeTaskRepository();
      final updateUseCase = _UpdateUseCaseRepositoryAdapter(repository);
      final useCase = ScheduleTaskUseCase(updateUseCase);

      final result = await useCase(
        ScheduleTaskParams(
          taskId: 'task',
          startDateTime: DateTime(2026, 8, 12, 10),
          endDateTime: DateTime(2026, 8, 12, 9),
        ),
      );

      expect(
        result.failure,
        const ValidationFailure('종료 시각은 시작 시각보다 늦어야 합니다.'),
      );
      expect(repository.operations, ['get']);
      expect(repository.updateCalls, 0);
    });
  });

  group('ToggleCompleteUseCase', () {
    test('rejects event completion without toggling', () async {
      final repository = _FakeTaskRepository(
        task: _task(kind: TaskKind.event, isAllDay: true),
      );
      final useCase = ToggleCompleteUseCase(repository);

      final result = await useCase('task');

      expect(result.data, isNull);
      expect(
        result.failure,
        const ValidationFailure('일정은 완료 상태를 가질 수 없습니다.'),
      );
      expect(repository.operations, ['get']);
      expect(repository.toggleCalls, 0);
    });

    test('reads and toggles a todo', () async {
      final repository = _FakeTaskRepository();
      final useCase = ToggleCompleteUseCase(repository);

      final result = await useCase('task');

      expect(result.failure, isNull);
      expect(repository.operations, ['get', 'toggle']);
      expect(repository.toggleCalls, 1);
      expect(repository.toggledId, 'task');
    });

    test('preserves a read failure without toggling', () async {
      const readFailure = CacheFailure('read failed');
      final repository = _FakeTaskRepository(readFailure: readFailure);
      final useCase = ToggleCompleteUseCase(repository);

      final result = await useCase('task');

      expect(result.data, isNull);
      expect(result.failure, same(readFailure));
      expect(repository.operations, ['get']);
      expect(repository.toggleCalls, 0);
    });
  });
}

Task _task({
  TaskKind kind = TaskKind.todo,
  DateTime? targetDate,
  bool hasTime = false,
  DateTime? startDateTime,
  DateTime? endDateTime,
  bool isAllDay = false,
}) {
  return Task(
    id: 'task',
    title: 'Task',
    kind: kind,
    targetDate: targetDate ?? DateTime(2026, 8, 12),
    isCompleted: false,
    hasTime: hasTime,
    startDateTime: startDateTime,
    endDateTime: endDateTime,
    isAllDay: isAllDay,
    isRecurring: false,
    createdAt: DateTime(2026, 7, 31),
  );
}

class _FakeTaskRepository implements TaskRepository {
  _FakeTaskRepository({Task? task, this.readFailure}) : task = task ?? _task();

  final Task task;
  final Failure? readFailure;
  final List<String> operations = [];
  int createCalls = 0;
  int updateCalls = 0;
  int toggleCalls = 0;
  CreateTaskParams? createdParams;
  UpdateTaskParams? updatedParams;
  String? toggledId;

  @override
  Future<Result<Task>> getTaskById(String id) async {
    operations.add('get');
    final failure = readFailure;
    return failure == null ? success(task) : fail(failure);
  }

  @override
  Future<Result<Task>> createTask(CreateTaskParams params) async {
    operations.add('create');
    createCalls++;
    createdParams = params;
    return success(task);
  }

  @override
  Future<Result<Task>> updateTask(UpdateTaskParams params) async {
    operations.add('update');
    updateCalls++;
    updatedParams = params;
    return success(task);
  }

  @override
  Future<Result<Task>> toggleComplete(String id) async {
    operations.add('toggle');
    toggleCalls++;
    toggledId = id;
    return success(task);
  }

  @override
  Future<Result<void>> deleteTask(String id) => throw UnimplementedError();

  @override
  Future<Result<List<Task>>> getTasksByDate(DateTime date) =>
      throw UnimplementedError();

  @override
  Future<Result<List<Task>>> getTasksByRange(DateTime start, DateTime end) =>
      throw UnimplementedError();

  @override
  Future<Result<List<Task>>> getTasksForTodayOverview(DateTime selectedDate) =>
      throw UnimplementedError();

  @override
  Future<Result<List<Task>>> getUnscheduledTasks() =>
      throw UnimplementedError();
}

/// Lets the scheduling test compile against both constructor signatures while
/// still distinguishing a direct repository write from the validated path.
class _UpdateUseCaseRepositoryAdapter extends UpdateTaskUseCase
    implements TaskRepository {
  _UpdateUseCaseRepositoryAdapter(this.repository) : super(repository);

  final TaskRepository repository;

  @override
  Future<Result<Task>> getTaskById(String id) => repository.getTaskById(id);

  @override
  Future<Result<Task>> createTask(CreateTaskParams params) =>
      repository.createTask(params);

  @override
  Future<Result<Task>> updateTask(UpdateTaskParams params) =>
      repository.updateTask(params);

  @override
  Future<Result<Task>> toggleComplete(String id) =>
      repository.toggleComplete(id);

  @override
  Future<Result<void>> deleteTask(String id) => repository.deleteTask(id);

  @override
  Future<Result<List<Task>>> getTasksByDate(DateTime date) =>
      repository.getTasksByDate(date);

  @override
  Future<Result<List<Task>>> getTasksByRange(DateTime start, DateTime end) =>
      repository.getTasksByRange(start, end);

  @override
  Future<Result<List<Task>>> getTasksForTodayOverview(DateTime selectedDate) =>
      repository.getTasksForTodayOverview(selectedDate);

  @override
  Future<Result<List<Task>>> getUnscheduledTasks() =>
      repository.getUnscheduledTasks();
}
