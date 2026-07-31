import 'package:drift/drift.dart';
import 'package:nae_mo/core/database/connection/connection.dart' as conn;
import 'package:nae_mo/core/database/tables/category_table.dart';
import 'package:nae_mo/core/database/tables/task_table.dart';
import 'package:uuid/uuid.dart';

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
