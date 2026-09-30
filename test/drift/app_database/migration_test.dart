// dart format width=80
// ignore_for_file: unused_local_variable, unused_import
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nae_mo/core/database/app_database.dart';
import 'generated/schema.dart';

import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;
import 'generated/schema_v3.dart' as v3;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('simple database migrations', () {
    // These simple tests verify all possible schema updates with a simple (no
    // data) migration. This is a quick way to ensure that written database
    // migrations properly alter the schema.
    const versions = GeneratedHelper.versions;
    for (final (i, fromVersion) in versions.indexed) {
      group('from $fromVersion', () {
        for (final toVersion in versions.skip(i + 1)) {
          test('to $toVersion', () async {
            final schema = await verifier.schemaAt(fromVersion);
            final db = AppDatabase(schema.newConnection());
            await verifier.migrateAndValidate(db, toVersion);
            await db.close();
          });
        }
      });
    }
  });

  test('fresh v3 database stores routine rules and links materialized tasks',
      () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final date = DateTime(2026, 9, 30);

    await db.into(db.routineTable).insert(RoutineTableCompanion.insert(
          id: 'routine-1',
          title: '격주 운동',
          kind: 'todo',
          startDate: date,
          frequency: 'custom',
          creationMode: 'manual',
          interval: const Value(2),
          customUnit: const Value('week'),
          weekdays: const Value('1,6,7'),
          hasTime: const Value(true),
          startMinute: const Value(540),
          endMinute: const Value(600),
        ));
    await db.into(db.taskTable).insert(TaskTableCompanion.insert(
          id: 'confirmed-instance',
          title: '격주 운동',
          targetDate: Value(date),
          routineId: const Value('routine-1'),
        ));

    final routine = (await db.select(db.routineTable).get()).single;
    expect(routine.id, 'routine-1');
    expect(routine.interval, 2);
    expect(routine.customUnit, 'week');
    expect(routine.weekdays, '1,6,7');
    expect(routine.startMinute, 540);
    expect(routine.endMinute, 600);
    expect((await db.select(db.taskTable).get()).single.routineId, 'routine-1');
  });

  test('v1 data survives both upgrade steps through v3', () async {
    final created = DateTime.utc(2026, 9, 27, 12);
    final start = DateTime.utc(2026, 9, 30, 9);
    final end = DateTime.utc(2026, 9, 30, 10);
    final legacy = v1.TasksData(
      id: 'v1-task',
      title: '업그레이드 전 Todo',
      categoryId: 'v1-category',
      isCompleted: true,
      hasTime: true,
      startDateTime: start,
      endDateTime: end,
      isAllDay: false,
      isRecurring: true,
      recurrenceRule: 'FREQ=WEEKLY',
      createdAt: created,
    );
    await verifier.testWithDataIntegrity(
      oldVersion: 1,
      newVersion: 3,
      createOld: v1.DatabaseAtV1.new,
      createNew: v3.DatabaseAtV3.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.insert(
            oldDb.categories,
            const v1.CategoriesData(
                id: 'v1-category',
                name: '기존',
                color: 0xFF2196F3,
                sortOrder: 0));
        batch.insert(oldDb.tasks, legacy);
      },
      validateItems: (newDb) async {
        expect((await newDb.select(newDb.categories).get()).single.name, '기존');
        final upgraded = (await newDb.select(newDb.tasks).get()).single;
        expect(upgraded.id, legacy.id);
        expect(upgraded.kind, 'todo');
        expect(upgraded.categoryId, legacy.categoryId);
        expect(upgraded.routineId, null);
        expect(upgraded.isCompleted, isTrue);
        expect(upgraded.isRecurring, isTrue);
        expect(upgraded.recurrenceRule, legacy.recurrenceRule);
        expect(upgraded.targetDate, _localMidnight(start));
        expect(await newDb.select(newDb.routines).get(), isEmpty);
      },
    );
  });

  test('migration from v2 to v3 preserves tasks and categories', () async {
    final date = DateTime(2026, 9, 30);
    final created = DateTime(2026, 9, 29, 12);
    const oldCategory = v2.CategoriesData(
        id: 'work', name: '업무', color: 0xFF67C1DE, sortOrder: 0);
    final oldTask = v2.TasksData(
      id: 'recurring-task',
      title: '기존 일정',
      kind: 'event',
      targetDate: date,
      categoryId: oldCategory.id,
      isCompleted: false,
      hasTime: false,
      isAllDay: true,
      isRecurring: true,
      recurrenceRule: 'FREQ=WEEKLY',
      createdAt: created,
    );

    await verifier.testWithDataIntegrity(
      oldVersion: 2,
      newVersion: 3,
      createOld: v2.DatabaseAtV2.new,
      createNew: v3.DatabaseAtV3.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.insert(oldDb.categories, oldCategory);
        batch.insert(oldDb.tasks, oldTask);
      },
      validateItems: (newDb) async {
        expect(await newDb.select(newDb.categories).get(), [
          const v3.CategoriesData(
              id: 'work', name: '업무', color: 0xFF67C1DE, sortOrder: 0),
        ]);
        expect(await newDb.select(newDb.tasks).get(), [
          v3.TasksData(
            id: oldTask.id,
            title: oldTask.title,
            kind: oldTask.kind,
            targetDate: date,
            categoryId: oldTask.categoryId,
            routineId: null,
            isCompleted: oldTask.isCompleted,
            hasTime: oldTask.hasTime,
            isAllDay: oldTask.isAllDay,
            isRecurring: oldTask.isRecurring,
            recurrenceRule: oldTask.recurrenceRule,
            createdAt: created,
          ),
        ]);
        expect(await newDb.select(newDb.routines).get(), isEmpty);
      },
    );
  });

  test('migration from v1 to v2 normalizes legacy planner rows', () async {
    final allDayStart = DateTime.utc(2026, 1, 14, 22, 45);
    final validTimedStart = DateTime.utc(2026, 4, 20, 8);
    final validTimedEnd = DateTime.utc(2026, 4, 20, 9, 30);
    final legacyUntimedStart = DateTime.utc(2026, 5, 11, 6);
    final legacyUntimedEnd = DateTime.utc(2026, 5, 11, 7);
    final malformedStart = DateTime.utc(2026, 7, 3, 12);
    final malformedEnd = DateTime.utc(2026, 7, 3, 11, 30);
    final missingStartEnd = DateTime.utc(2026, 9, 8, 14);
    final allDayCreatedAt = DateTime.utc(2026, 1, 10);
    final validTimedCreatedAt = DateTime.utc(2026, 4, 1);
    final legacyUntimedCreatedAt = DateTime.utc(2026, 5, 1);
    final malformedCreatedAt = DateTime.utc(2026, 7, 1);
    final missingStartCreatedAt = DateTime.utc(2026, 9, 7, 18, 30);

    const oldCategoriesData = <v1.CategoriesData>[
      v1.CategoriesData(
        id: 'recurring-category',
        name: 'Recurring work',
        color: 0xFF1565C0,
        sortOrder: 4,
      ),
    ];
    const expectedNewCategoriesData = <v2.CategoriesData>[
      v2.CategoriesData(
        id: 'recurring-category',
        name: 'Recurring work',
        color: 0xFF1565C0,
        sortOrder: 4,
      ),
    ];

    final oldTasksData = <v1.TasksData>[
      v1.TasksData(
        id: 'completed-all-day',
        title: 'Completed all-day event',
        isCompleted: true,
        hasTime: true,
        startDateTime: allDayStart,
        endDateTime: allDayStart.add(const Duration(hours: 1)),
        isAllDay: true,
        isRecurring: false,
        createdAt: allDayCreatedAt,
      ),
      v1.TasksData(
        id: 'valid-timed',
        title: 'Valid timed todo',
        categoryId: 'recurring-category',
        isCompleted: true,
        hasTime: true,
        startDateTime: validTimedStart,
        endDateTime: validTimedEnd,
        isAllDay: false,
        isRecurring: true,
        recurrenceRule: 'FREQ=WEEKLY',
        createdAt: validTimedCreatedAt,
      ),
      v1.TasksData(
        id: 'legacy-untimed-with-range',
        title: 'Legacy untimed todo with timestamps',
        isCompleted: false,
        hasTime: false,
        startDateTime: legacyUntimedStart,
        endDateTime: legacyUntimedEnd,
        isAllDay: false,
        isRecurring: false,
        createdAt: legacyUntimedCreatedAt,
      ),
      v1.TasksData(
        id: 'malformed-timed',
        title: 'Malformed timed todo',
        isCompleted: false,
        hasTime: true,
        startDateTime: malformedStart,
        endDateTime: malformedEnd,
        isAllDay: false,
        isRecurring: false,
        createdAt: malformedCreatedAt,
      ),
      v1.TasksData(
        id: 'missing-start',
        title: 'Incomplete timed todo',
        isCompleted: false,
        hasTime: true,
        startDateTime: null,
        endDateTime: missingStartEnd,
        isAllDay: false,
        isRecurring: false,
        createdAt: missingStartCreatedAt,
      ),
    ];
    final expectedNewTasksData = <v2.TasksData>[
      v2.TasksData(
        id: 'completed-all-day',
        title: 'Completed all-day event',
        kind: 'event',
        targetDate: _localMidnight(allDayStart),
        isCompleted: false,
        hasTime: false,
        isAllDay: true,
        isRecurring: false,
        createdAt: allDayCreatedAt.toLocal(),
      ),
      v2.TasksData(
        id: 'valid-timed',
        title: 'Valid timed todo',
        kind: 'todo',
        targetDate: _localMidnight(validTimedStart),
        categoryId: 'recurring-category',
        isCompleted: true,
        hasTime: true,
        startDateTime: validTimedStart.toLocal(),
        endDateTime: validTimedEnd.toLocal(),
        isAllDay: false,
        isRecurring: true,
        recurrenceRule: 'FREQ=WEEKLY',
        createdAt: validTimedCreatedAt.toLocal(),
      ),
      v2.TasksData(
        id: 'legacy-untimed-with-range',
        title: 'Legacy untimed todo with timestamps',
        kind: 'todo',
        targetDate: _localMidnight(legacyUntimedStart),
        isCompleted: false,
        hasTime: false,
        startDateTime: null,
        endDateTime: null,
        isAllDay: false,
        isRecurring: false,
        createdAt: legacyUntimedCreatedAt.toLocal(),
      ),
      v2.TasksData(
        id: 'malformed-timed',
        title: 'Malformed timed todo',
        kind: 'todo',
        targetDate: _localMidnight(malformedStart),
        isCompleted: false,
        hasTime: false,
        isAllDay: false,
        isRecurring: false,
        createdAt: malformedCreatedAt.toLocal(),
      ),
      v2.TasksData(
        id: 'missing-start',
        title: 'Incomplete timed todo',
        kind: 'todo',
        targetDate: _localMidnight(missingStartCreatedAt),
        isCompleted: false,
        hasTime: false,
        startDateTime: null,
        endDateTime: null,
        isAllDay: false,
        isRecurring: false,
        createdAt: missingStartCreatedAt.toLocal(),
      ),
    ];

    await verifier.testWithDataIntegrity(
      oldVersion: 1,
      newVersion: 2,
      createOld: v1.DatabaseAtV1.new,
      createNew: v2.DatabaseAtV2.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.insertAll(oldDb.categories, oldCategoriesData);
        batch.insertAll(oldDb.tasks, oldTasksData);
      },
      validateItems: (newDb) async {
        expect(
          await newDb.select(newDb.categories).get(),
          unorderedEquals(expectedNewCategoriesData),
        );
        expect(
          await newDb.select(newDb.tasks).get(),
          unorderedEquals(expectedNewTasksData),
        );
      },
    );
  });
}

DateTime _localMidnight(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}
