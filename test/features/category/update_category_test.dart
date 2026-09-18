import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nae_mo/core/database/app_database.dart';
import 'package:nae_mo/core/errors/failure.dart';
import 'package:nae_mo/features/category/data/datasources/category_local_data_source_impl.dart';
import 'package:nae_mo/features/category/data/mappers/category_mapper.dart';
import 'package:nae_mo/features/category/data/repositories/category_repository_impl.dart';
import 'package:nae_mo/features/category/domain/usecases/update_category_use_case.dart';
import 'package:nae_mo/features/calendar/domain/usecases/get_today_overview_use_case.dart';
import 'package:nae_mo/features/task/data/datasources/task_local_data_source_impl.dart';
import 'package:nae_mo/features/task/data/mappers/task_mapper.dart';
import 'package:nae_mo/features/task/data/repositories/task_repository_impl.dart';
import 'package:nae_mo/features/task/domain/entities/task.dart';
import 'package:nae_mo/features/task/domain/usecases/params/create_task_params.dart';

void main() {
  late AppDatabase database;
  late CategoryRepositoryImpl categories;
  late UpdateCategoryUseCase update;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    categories = CategoryRepositoryImpl(
      dataSource: CategoryLocalDataSourceImpl(database),
      mapper: const CategoryMapper(),
    );
    update = UpdateCategoryUseCase(categories);
  });
  tearDown(() => database.close());

  test('persists name and color without changing identity, order or task links',
      () async {
    final category = (await categories.getCategories()).data!.first;
    final before = await database.select(database.categoryTable).get();
    final tasks = TaskRepositoryImpl(
        dataSource: TaskLocalDataSourceImpl(database),
        mapper: const TaskMapper());
    final date = DateTime(2026, 9, 17);
    for (final kind in TaskKind.values) {
      await tasks.createTask(CreateTaskParams(
          title: kind.name,
          kind: kind,
          targetDate: date,
          categoryId: category.id,
          isAllDay: kind == TaskKind.event));
    }
    final storedTasks = await database.select(database.taskTable).get();
    final result = await update(UpdateCategoryParams(
        id: category.id, name: '  프로젝트  ', color: 0xFFFFA629));
    expect(result.failure, isNull);
    expect(result.data!.id, category.id);
    expect(result.data!.sortOrder, category.sortOrder);
    expect(result.data!.name, '프로젝트');
    final after = await database.select(database.categoryTable).get();
    expect(after.length, before.length);
    expect(after.where((item) => item.id != category.id),
        before.where((item) => item.id != category.id));
    expect(await database.select(database.taskTable).get(), storedTasks);
    final overview =
        (await GetTodayOverviewUseCase(tasks, categories)(date)).data!;
    for (final entry in [...overview.allDayEvents, ...overview.untimedTodos]) {
      expect(entry.category!.name, '프로젝트');
      expect(entry.category!.color, 0xFFFFA629);
      expect(entry.task.categoryId, category.id);
    }
    expect(overview.allDayEvents.length, 1);
    expect(overview.untimedTodos.length, 1);
  });

  test('rejects blank names and missing IDs without changing stored categories',
      () async {
    final before = await categories.getCategories();
    final blank = await update(UpdateCategoryParams(
        id: before.data!.first.id, name: '  ', color: 0xFFFFA629));
    expect(blank.failure, isA<ValidationFailure>());
    final missing = await update(const UpdateCategoryParams(
        id: 'missing', name: '이름', color: 0xFFFFA629));
    expect(missing.failure, isA<CacheFailure>());
    expect((await categories.getCategories()).data!.map((item) => item.name),
        before.data!.map((item) => item.name));
  });
}
