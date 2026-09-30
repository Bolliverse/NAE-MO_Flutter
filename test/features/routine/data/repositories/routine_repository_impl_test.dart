import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nae_mo/core/database/app_database.dart';
import 'package:nae_mo/core/errors/app_exception.dart';
import 'package:nae_mo/core/errors/failure.dart';
import 'package:nae_mo/features/category/data/datasources/category_local_data_source_impl.dart';
import 'package:nae_mo/features/routine/data/repositories/routine_repository_impl.dart';
import 'package:nae_mo/features/routine/domain/entities/routine_definition.dart';
import 'package:nae_mo/features/routine/domain/entities/routine_rule.dart';
import 'package:nae_mo/features/routine/domain/usecases/routine_use_cases.dart';
import 'package:nae_mo/features/task/domain/entities/task.dart';

void main() {
  late AppDatabase db;
  late RoutineRepositoryImpl repository;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = RoutineRepositoryImpl(db);
  });
  tearDown(() => db.close());

  test('round-trips every rule field and canonical weekly day order', () async {
    final category = (await db.select(db.categoryTable).get()).first;
    final input =
        _routine(id: 'weekly-z', title: '  격주 운동  ', categoryId: category.id);
    final saved = await CreateRoutineUseCase(repository)(input);
    expect(saved.failure, null);
    expect(saved.data!.title, '격주 운동');
    expect(saved.data!.rule.weekdays, {1, 6, 7});

    final stored = (await db.select(db.routineTable).get()).single;
    expect(stored.weekdays, '1,6,7');
    expect(stored.interval, 2);
    expect(stored.customUnit, 'week');
    expect(stored.startMinute, 540);
    expect(stored.endMinute, 600);
    expect(stored.categoryId, category.id);

    final loadedList = (await GetRoutinesUseCase(repository)()).data!;
    final loaded = loadedList.single;
    expect(loaded.id, input.id);
    expect(loaded.title, '격주 운동');
    expect(loaded.kind, TaskKind.todo);
    expect(loaded.rule.frequency, RoutineFrequency.custom);
    expect(loaded.rule.creationMode, RoutineCreationMode.manual);
    expect(loaded.rule.customUnit, RoutineIntervalUnit.week);
    expect(loaded.rule.weekdays, {1, 6, 7});
    expect(loaded.hasTime, true);
    expect(loaded.startMinute, 540);
    expect(loaded.endMinute, 600);
    expect(loaded.rule.validate(), null);
    expect(() => loadedList.clear(), throwsUnsupportedError);
  });

  test('lists routines stably and keeps a bounded all-day event', () async {
    final event = _routine(
        id: 'z',
        kind: TaskKind.event,
        isAllDay: true,
        hasTime: false,
        startMinute: null,
        endMinute: null,
        rule: RoutineRule(
            id: 'z',
            startDate: DateTime(2026, 9, 30),
            endDate: DateTime(2026, 12, 31),
            frequency: RoutineFrequency.monthly,
            creationMode: RoutineCreationMode.automatic));
    final todo = _routine(id: 'a');
    expect((await CreateRoutineUseCase(repository)(event)).failure, null);
    expect((await CreateRoutineUseCase(repository)(todo)).failure, null);
    final loaded = (await repository.getAll()).data!;
    expect(loaded.map((routine) => routine.id), ['a', 'z']);
    expect(loaded.last.isAllDay, true);
    expect(loaded.last.rule.endDate, DateTime(2026, 12, 31));
    expect(loaded.last.rule.creationMode, RoutineCreationMode.automatic);
  });

  test('duplicate ID failure leaves the original routine unchanged', () async {
    final original = _routine(id: 'same');
    final duplicate = _routine(id: 'same', title: '다른 제목');
    expect((await CreateRoutineUseCase(repository)(original)).failure, null);
    expect((await CreateRoutineUseCase(repository)(duplicate)).failure,
        isA<CacheFailure>());
    final loaded = (await repository.getAll()).data!;
    expect(loaded.length, 1);
    expect(loaded.single.title, original.title);
  });

  test('deleting a category clears Task and routine links atomically',
      () async {
    final category = (await db.select(db.categoryTable).get()).first;
    expect(
        (await CreateRoutineUseCase(repository)(
                _routine(id: 'linked', categoryId: category.id)))
            .failure,
        null);
    await db.into(db.taskTable).insert(TaskTableCompanion.insert(
        id: 'instance',
        title: '운동',
        categoryId: Value(category.id),
        routineId: const Value('linked'),
        targetDate: Value(DateTime(2026, 9, 30))));

    await CategoryLocalDataSourceImpl(db).delete(category.id);
    final linkedTask = (await db.select(db.taskTable).get()).single;
    expect(linkedTask.categoryId, null);
    expect(linkedTask.routineId, 'linked');
    expect((await repository.getAll()).data!.single.categoryId, null);
    expect(
        (await db.select(db.categoryTable).get())
            .any((row) => row.id == category.id),
        false);
  });

  test('failed category delete rolls back both link updates', () async {
    final category = (await db.select(db.categoryTable).get()).first;
    expect(
        (await CreateRoutineUseCase(repository)(
                _routine(id: 'linked', categoryId: category.id)))
            .failure,
        null);
    await db.into(db.taskTable).insert(TaskTableCompanion.insert(
        id: 'instance',
        title: '운동',
        categoryId: Value(category.id),
        targetDate: Value(DateTime(2026, 9, 30))));
    await db.customStatement('''CREATE TRIGGER reject_category_delete
      BEFORE DELETE ON categories BEGIN
      SELECT RAISE(ABORT, 'simulated failure'); END''');

    await expectLater(CategoryLocalDataSourceImpl(db).delete(category.id),
        throwsA(isA<CacheException>()));
    expect(
        (await db.select(db.taskTable).get()).single.categoryId, category.id);
    expect((await repository.getAll()).data!.single.categoryId, category.id);
  });
}

RoutineDefinition _routine({
  required String id,
  String title = '격주 운동',
  TaskKind kind = TaskKind.todo,
  String? categoryId,
  bool hasTime = true,
  bool isAllDay = false,
  int? startMinute = 540,
  int? endMinute = 600,
  RoutineRule? rule,
}) =>
    RoutineDefinition(
      rule: rule ??
          RoutineRule(
              id: id,
              startDate: DateTime(2026, 9, 30),
              frequency: RoutineFrequency.custom,
              creationMode: RoutineCreationMode.manual,
              interval: 2,
              customUnit: RoutineIntervalUnit.week,
              weekdays: {7, 1, 6}),
      title: title,
      kind: kind,
      categoryId: categoryId,
      hasTime: hasTime,
      isAllDay: isAllDay,
      startMinute: startMinute,
      endMinute: endMinute,
    );
