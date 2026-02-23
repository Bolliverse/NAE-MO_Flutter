import 'package:drift/drift.dart';
import 'package:nae_mo/core/database/app_database.dart';
import 'package:nae_mo/core/errors/app_exception.dart';
import 'package:nae_mo/features/task/data/datasources/task_local_data_source.dart';
import 'package:nae_mo/features/task/domain/usecases/params/create_task_params.dart';
import 'package:nae_mo/features/task/domain/usecases/params/update_task_params.dart';

class TaskLocalDataSourceImpl implements TaskLocalDataSource {
  final AppDatabase _db;
  const TaskLocalDataSourceImpl(this._db);

  @override
  Future<List<TaskTableData>> getByDate(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
      return await (_db.select(_db.taskTable)
            ..where(
              (t) =>
                  t.startDateTime.isBetweenValues(startOfDay, endOfDay) |
                  (t.isAllDay.equals(true) &
                      t.startDateTime.isBetweenValues(startOfDay, endOfDay)),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.startDateTime)]))
          .get();
    } catch (e) {
      throw CacheException('태스크를 불러오는 데 실패했습니다: $e');
    }
  }

  @override
  Future<List<TaskTableData>> getByRange(DateTime start, DateTime end) async {
    try {
      return await (_db.select(_db.taskTable)
            ..where((t) => t.startDateTime.isBetweenValues(start, end))
            ..orderBy([(t) => OrderingTerm.asc(t.startDateTime)]))
          .get();
    } catch (e) {
      throw CacheException('태스크를 불러오는 데 실패했습니다: $e');
    }
  }

  @override
  Future<List<TaskTableData>> getUnscheduled() async {
    try {
      return await (_db.select(_db.taskTable)
            ..where(
              (t) => t.hasTime.equals(false) & t.isCompleted.equals(false),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .get();
    } catch (e) {
      throw CacheException('태스크를 불러오는 데 실패했습니다: $e');
    }
  }

  @override
  Future<TaskTableData> insert(String id, CreateTaskParams params) async {
    try {
      await _db.into(_db.taskTable).insert(
            TaskTableCompanion(
              id: Value(id),
              title: Value(params.title),
              categoryId: Value(params.categoryId),
              hasTime: Value(params.hasTime),
              startDateTime: Value(params.startDateTime),
              endDateTime: Value(params.endDateTime),
              isAllDay: Value(params.isAllDay),
            ),
          );
      return await _getById(id);
    } catch (e) {
      throw CacheException('태스크를 생성하는 데 실패했습니다: $e');
    }
  }

  @override
  Future<TaskTableData> update(UpdateTaskParams params) async {
    try {
      final current = await _getById(params.id);
      await (_db.update(_db.taskTable)
            ..where((t) => t.id.equals(params.id)))
          .write(
        TaskTableCompanion(
          title: Value(params.title ?? current.title),
          categoryId: Value(params.categoryId ?? current.categoryId),
          hasTime: Value(params.hasTime ?? current.hasTime),
          startDateTime: Value(params.startDateTime ?? current.startDateTime),
          endDateTime: Value(params.endDateTime ?? current.endDateTime),
          isAllDay: Value(params.isAllDay ?? current.isAllDay),
          isCompleted: Value(params.isCompleted ?? current.isCompleted),
        ),
      );
      return await _getById(params.id);
    } catch (e) {
      throw CacheException('태스크를 수정하는 데 실패했습니다: $e');
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await (_db.delete(_db.taskTable)..where((t) => t.id.equals(id))).go();
    } catch (e) {
      throw CacheException('태스크를 삭제하는 데 실패했습니다: $e');
    }
  }

  @override
  Future<TaskTableData> toggleComplete(String id) async {
    try {
      final current = await _getById(id);
      await (_db.update(_db.taskTable)..where((t) => t.id.equals(id))).write(
        TaskTableCompanion(isCompleted: Value(!current.isCompleted)),
      );
      return await _getById(id);
    } catch (e) {
      throw CacheException('태스크 완료 상태를 변경하는 데 실패했습니다: $e');
    }
  }

  Future<TaskTableData> _getById(String id) async {
    final result = await (_db.select(_db.taskTable)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (result == null) throw CacheException('태스크를 찾을 수 없습니다: $id');
    return result;
  }
}
