import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nae_mo/core/database/app_database.dart';
import 'package:nae_mo/core/errors/failure.dart';
import 'package:nae_mo/features/routine/data/repositories/routine_repository_impl.dart';
import 'package:nae_mo/features/routine/domain/entities/routine_definition.dart';
import 'package:nae_mo/features/routine/domain/entities/routine_rule.dart';
import 'package:nae_mo/features/routine/domain/usecases/manual_routine_candidates.dart';
import 'package:nae_mo/features/task/data/datasources/task_local_data_source_impl.dart';
import 'package:nae_mo/features/task/data/mappers/task_mapper.dart';
import 'package:nae_mo/features/task/data/repositories/task_repository_impl.dart';
import 'package:nae_mo/features/task/domain/entities/task.dart';
import 'package:nae_mo/features/task/domain/usecases/create_task_use_case.dart';

void main() {
  late AppDatabase database;
  late RoutineRepositoryImpl routines;
  late TaskRepositoryImpl tasks;
  late GetManualRoutineCandidates candidates;
  late ConfirmManualRoutineCandidate confirm;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    routines = RoutineRepositoryImpl(database);
    tasks = TaskRepositoryImpl(
      dataSource: TaskLocalDataSourceImpl(database),
      mapper: const TaskMapper(),
    );
    candidates = GetManualRoutineCandidates(routines, tasks);
    confirm = ConfirmManualRoutineCandidate(
      candidates,
      CreateTaskUseCase(tasks),
    );
  });

  tearDown(() => database.close());

  test('only matching manual rules appear for the selected day', () async {
    await routines.create(_routine('manual', DateTime(2026, 10, 1)));
    await routines.create(_routine(
      'automatic',
      DateTime(2026, 10, 1),
      mode: RoutineCreationMode.automatic,
      end: DateTime(2026, 10, 3),
    ));
    await routines.create(_routine('later', DateTime(2026, 10, 3)));

    expect(
      (await candidates(DateTime(2026, 9, 30))).data,
      isEmpty,
    );
    expect(
      (await candidates(DateTime(2026, 10, 2)))
          .data!
          .map((item) => item.routineId),
      ['manual'],
    );
  });

  test('confirmation stores a linked event once and hides its candidate',
      () async {
    final date = DateTime(2026, 10, 2);
    await routines.create(_routine(
      'event',
      DateTime(2026, 10, 1),
      kind: TaskKind.event,
      startMinute: 540,
      endMinute: 600,
    ));

    final created = (await confirm('event', date)).data!;
    expect(created.routineId, 'event');
    expect(created.kind, TaskKind.event);
    expect(created.startDateTime, DateTime(2026, 10, 2, 9));
    expect(created.endDateTime, DateTime(2026, 10, 2, 10));
    expect((await candidates(date)).data, isEmpty);
    expect((await confirm('event', date)).failure, isA<ValidationFailure>());
    expect((await tasks.getTasksByDate(date)).data, hasLength(1));

    await tasks.deleteTask(created.id);
    expect((await candidates(date)).data, hasLength(1));
  });

  test('concurrent confirmations cannot create two rows for one occurrence',
      () async {
    final date = DateTime(2026, 10, 2);
    await routines.create(_routine('todo', DateTime(2026, 10, 1)));

    await Future.wait([confirm('todo', date), confirm('todo', date)]);

    final rows = (await tasks.getTasksByDate(date)).data!;
    expect(rows, hasLength(1));
    expect(rows.single.routineId, 'todo');
  });
}

RoutineDefinition _routine(
  String id,
  DateTime start, {
  RoutineCreationMode mode = RoutineCreationMode.manual,
  DateTime? end,
  TaskKind kind = TaskKind.todo,
  int? startMinute,
  int? endMinute,
}) =>
    RoutineDefinition(
      rule: RoutineRule(
        id: id,
        startDate: start,
        endDate: end,
        frequency: RoutineFrequency.daily,
        creationMode: mode,
      ),
      title: id,
      kind: kind,
      hasTime: startMinute != null,
      startMinute: startMinute,
      endMinute: endMinute,
    );
