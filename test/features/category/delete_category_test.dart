import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nae_mo/core/database/app_database.dart';
import 'package:nae_mo/core/errors/failure.dart';
import 'package:nae_mo/features/category/data/datasources/category_local_data_source_impl.dart';
import 'package:nae_mo/features/category/data/mappers/category_mapper.dart';
import 'package:nae_mo/features/category/data/repositories/category_repository_impl.dart';
import 'package:nae_mo/features/category/domain/usecases/delete_category_use_case.dart';
import 'package:nae_mo/features/task/domain/entities/task.dart';

void main() {
  late AppDatabase db;
  late CategoryRepositoryImpl repository;
  late DeleteCategoryUseCase delete;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = CategoryRepositoryImpl(
        dataSource: CategoryLocalDataSourceImpl(db),
        mapper: const CategoryMapper());
    delete = DeleteCategoryUseCase(repository);
  });
  tearDown(() => db.close());

  test(
      'deletion only clears links, preserving all task fields and other categories',
      () async {
    final categories = (await repository.getCategories()).data!;
    final id = categories.first.id;
    final other = categories.last.id;
    for (var index = 0; index < 4; index++) {
      await db.into(db.taskTable).insert(TaskTableCompanion.insert(
            id: 'task-$index',
            title: '항목 $index',
            kind: Value(index == 0 ? TaskKind.event : TaskKind.todo),
            categoryId: Value(index < 2
                ? id
                : index == 2
                    ? other
                    : null),
            isCompleted: Value(index == 1),
            targetDate: Value(DateTime(2026, 9, 18 + index)),
            isAllDay: Value(index == 0),
          ));
    }
    final before = await db.select(db.taskTable).get();
    final result = await delete(id);
    expect(result.failure, isNull);
    final after = await db.select(db.taskTable).get();
    expect(after.length, before.length);
    for (final item in before) {
      final expected = item.toJson();
      if (item.categoryId == id) expected['categoryId'] = null;
      expect(after.singleWhere((row) => row.id == item.id).toJson(), expected);
    }
    expect((await repository.getCategories()).data!.map((item) => item.id),
        categories.skip(1).map((item) => item.id));
    expect((await delete(id)).failure, isNull);
  });

  test(
      'database failure rolls back category removal and link clearing together',
      () async {
    final id = (await repository.getCategories()).data!.first.id;
    await db.into(db.taskTable).insert(TaskTableCompanion.insert(
        id: 'linked', title: '보존할 항목', categoryId: Value(id)));
    final before = await db.select(db.taskTable).get();
    await db.customStatement('''CREATE TRIGGER reject_category_delete
      BEFORE DELETE ON categories BEGIN
      SELECT RAISE(ABORT, 'simulated failure'); END''');
    expect((await delete(id)).failure, isA<CacheFailure>());
    expect(await db.select(db.taskTable).get(), before);
    expect(
        (await repository.getCategories()).data!.any((item) => item.id == id),
        isTrue);
  });
}
