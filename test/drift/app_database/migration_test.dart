// dart format width=80
// ignore_for_file: unused_local_variable, unused_import
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nae_mo/core/database/app_database.dart';
import 'generated/schema.dart';

import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;

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
