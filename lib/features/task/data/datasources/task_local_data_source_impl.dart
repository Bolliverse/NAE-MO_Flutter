import 'package:drift/drift.dart';
import 'package:nae_mo/core/database/app_database.dart';
import 'package:nae_mo/core/errors/app_exception.dart';
import 'package:nae_mo/features/task/data/datasources/task_local_data_source.dart';
import 'package:nae_mo/features/task/domain/entities/task.dart';
import 'package:nae_mo/features/task/domain/usecases/params/create_task_params.dart';
import 'package:nae_mo/features/task/domain/usecases/params/update_task_params.dart';

class TaskLocalDataSourceImpl implements TaskLocalDataSource {
  final AppDatabase _db;
  const TaskLocalDataSourceImpl(this._db);

  @override
  Future<TaskTableData> getById(String id) async {
    try {
      final result = await (_db.select(_db.taskTable)
            ..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      if (result == null) {
        throw CacheException('태스크를 찾을 수 없습니다: $id');
      }
      return result;
    } on CacheException {
      rethrow;
    } catch (e) {
      throw CacheException('태스크를 불러오는 데 실패했습니다: $e');
    }
  }

  @override
  Future<List<TaskTableData>> getByDate(DateTime date) async {
    try {
      final targetDate = _dateOnly(date);
      return await (_db.select(_db.taskTable)
            ..where((t) => t.targetDate.equals(targetDate))
            ..orderBy([(t) => OrderingTerm.asc(t.startDateTime)]))
          .get();
    } catch (e) {
      throw CacheException('태스크를 불러오는 데 실패했습니다: $e');
    }
  }

  @override
  Future<List<TaskTableData>> getByRange(DateTime start, DateTime end) async {
    try {
      final startDate = _dateOnly(start);
      final endDate = _dateOnly(end);
      return await (_db.select(_db.taskTable)
            ..where(
              (t) => t.targetDate.isBetweenValues(startDate, endDate),
            )
            ..orderBy([
              (t) => OrderingTerm.asc(t.targetDate),
              (t) => OrderingTerm.asc(t.startDateTime),
            ]))
          .get();
    } catch (e) {
      throw CacheException('태스크를 불러오는 데 실패했습니다: $e');
    }
  }

  @override
  Future<List<TaskTableData>> getForTodayOverview(
    DateTime selectedDate,
  ) async {
    try {
      final targetDate = _dateOnly(selectedDate);
      return await (_db.select(_db.taskTable)
            ..where(
              (t) =>
                  t.targetDate.equals(targetDate) |
                  (t.kind.equalsValue(TaskKind.todo) &
                      t.targetDate.isSmallerThanValue(targetDate) &
                      t.isCompleted.equals(false)),
            )
            ..orderBy([
              (t) => OrderingTerm.asc(t.targetDate),
              (t) => OrderingTerm.asc(t.startDateTime),
              (t) => OrderingTerm.asc(t.createdAt),
            ]))
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
              (t) =>
                  t.kind.equalsValue(TaskKind.todo) &
                  t.hasTime.equals(false) &
                  t.isCompleted.equals(false),
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
              kind: Value(params.kind),
              targetDate: Value(_dateOnly(params.targetDate)),
              categoryId: Value(params.categoryId),
              hasTime: Value(params.hasTime),
              startDateTime: Value(params.startDateTime),
              endDateTime: Value(params.endDateTime),
              isAllDay: Value(params.isAllDay),
            ),
          );
      return await getById(id);
    } catch (e) {
      throw CacheException('태스크를 생성하는 데 실패했습니다: $e');
    }
  }

  @override
  Future<TaskTableData> update(UpdateTaskParams params) async {
    try {
      final current = await getById(params.id);
      await (_db.update(_db.taskTable)..where((t) => t.id.equals(params.id)))
          .write(
        TaskTableCompanion(
          title: Value(params.title ?? current.title),
          kind: Value(params.kind ?? current.kind),
          targetDate: Value(
            _dateOnly(params.targetDate ?? current.targetDate),
          ),
          categoryId: Value(params.categoryId ?? current.categoryId),
          hasTime: Value(params.hasTime ?? current.hasTime),
          startDateTime: params.clearTime
              ? const Value(null)
              : Value(params.startDateTime ?? current.startDateTime),
          endDateTime: params.clearTime
              ? const Value(null)
              : Value(params.endDateTime ?? current.endDateTime),
          isAllDay: Value(params.isAllDay ?? current.isAllDay),
          isCompleted: Value(params.isCompleted ?? current.isCompleted),
        ),
      );
      return await getById(params.id);
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
      final current = await getById(id);
      await (_db.update(_db.taskTable)..where((t) => t.id.equals(id))).write(
        TaskTableCompanion(isCompleted: Value(!current.isCompleted)),
      );
      return await getById(id);
    } catch (e) {
      throw CacheException('태스크 완료 상태를 변경하는 데 실패했습니다: $e');
    }
  }
}

DateTime _dateOnly(DateTime date) {
  final local = date.toLocal();
  return DateTime(local.year, local.month, local.day);
}
