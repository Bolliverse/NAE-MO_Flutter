import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:nae_mo/core/database/tables/category_table.dart';
import 'package:nae_mo/core/database/tables/task_table.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [CategoryTable, TaskTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

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

QueryExecutor _openConnection() {
  if (kIsWeb) {
    // Web: 인메모리 DB (앱 종료 시 데이터 사라짐 — 추후 WebDatabase로 교체)
    return NativeDatabase.memory();
  }
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'nae_mo.db'));
    return NativeDatabase.createInBackground(file);
  });
}
