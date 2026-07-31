import 'package:drift/drift.dart';
import 'package:nae_mo/core/database/connection/connection.dart' as conn;
import 'package:nae_mo/core/database/tables/category_table.dart';
import 'package:nae_mo/core/database/tables/task_table.dart';
import 'package:nae_mo/features/task/domain/entities/task.dart';
import 'package:uuid/uuid.dart';

import 'app_database.steps.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [CategoryTable, TaskTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? conn.openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await _seedDefaultCategories();
        },
        onUpgrade: stepByStep(
          from1To2: (m, schema) async {
            await m.addColumn(schema.tasks, schema.tasks.kind);
            await m.addColumn(schema.tasks, schema.tasks.targetDate);
            await customStatement('''
            UPDATE tasks
            SET kind = CASE WHEN is_all_day = 1 THEN 'event' ELSE 'todo' END,
                target_date = CAST(strftime(
                  '%s', datetime(
                    COALESCE(start_date_time, created_at),
                    'unixepoch', 'localtime', 'start of day', 'utc'
                  )
                ) AS INTEGER),
                is_completed = CASE WHEN is_all_day = 1 THEN 0 ELSE is_completed END,
                has_time = CASE
                  WHEN is_all_day = 1 OR start_date_time IS NULL
                    OR end_date_time IS NULL OR end_date_time <= start_date_time
                  THEN 0 ELSE has_time END,
                start_date_time = CASE
                  WHEN is_all_day = 1 OR start_date_time IS NULL
                    OR end_date_time IS NULL OR end_date_time <= start_date_time
                  THEN NULL ELSE start_date_time END,
                end_date_time = CASE
                  WHEN is_all_day = 1 OR start_date_time IS NULL
                    OR end_date_time IS NULL OR end_date_time <= start_date_time
                  THEN NULL ELSE end_date_time END
          ''');
          },
        ),
      );

  Future<void> _seedDefaultCategories() async {
    const uuid = Uuid();
    final defaults = [
      CategoryTableCompanion(
        id: Value(uuid.v4()),
        name: const Value('업무'),
        color: const Value(0xFF2196F3), // Blue
        sortOrder: const Value(0),
      ),
      CategoryTableCompanion(
        id: Value(uuid.v4()),
        name: const Value('개인'),
        color: const Value(0xFF4CAF50), // Green
        sortOrder: const Value(1),
      ),
      CategoryTableCompanion(
        id: Value(uuid.v4()),
        name: const Value('건강'),
        color: const Value(0xFFFF9800), // Orange
        sortOrder: const Value(2),
      ),
      CategoryTableCompanion(
        id: Value(uuid.v4()),
        name: const Value('학습'),
        color: const Value(0xFF9C27B0), // Purple
        sortOrder: const Value(3),
      ),
    ];
    for (final category in defaults) {
      await into(categoryTable).insert(category);
    }
  }
}
