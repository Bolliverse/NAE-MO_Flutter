import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nae_mo/core/database/app_database.dart';
import 'package:nae_mo/core/database/app_database_provider.dart';
import 'package:nae_mo/core/errors/failure.dart';
import 'package:nae_mo/core/utils/result.dart';
import 'package:nae_mo/features/routine/domain/entities/routine_definition.dart';
import 'package:nae_mo/features/routine/domain/entities/routine_rule.dart';
import 'package:nae_mo/features/routine/domain/repositories/routine_repository.dart';
import 'package:nae_mo/features/task/domain/entities/task.dart';

class RoutineRepositoryImpl implements RoutineRepository {
  const RoutineRepositoryImpl(this._db);
  final AppDatabase _db;

  @override
  Future<Result<List<RoutineDefinition>>> getAll() async {
    try {
      // Drift's select/orderBy API: https://drift.simonbinder.eu/dart_api/select/
      final rows = await (_db.select(_db.routineTable)
            ..orderBy([
              (t) => OrderingTerm.asc(t.createdAt),
              (t) => OrderingTerm.asc(t.id),
            ]))
          .get();
      return success(List.unmodifiable(rows.map(_toEntity)));
    } catch (_) {
      return fail(const CacheFailure('루틴을 불러오지 못했습니다.'));
    }
  }

  @override
  Future<Result<RoutineDefinition>> create(RoutineDefinition routine) async {
    try {
      final weekdays = routine.rule.weekdays.toList()..sort();
      // Companion inserts and returning defaults:
      // https://drift.simonbinder.eu/dart_api/writes/
      final row = await _db.into(_db.routineTable).insertReturning(
            RoutineTableCompanion.insert(
              id: routine.id,
              title: routine.title.trim(),
              kind: routine.kind.name,
              categoryId: Value(routine.categoryId),
              startDate: routine.rule.startDate,
              endDate: Value(routine.rule.endDate),
              frequency: routine.rule.frequency.name,
              creationMode: routine.rule.creationMode.name,
              interval: Value(routine.rule.interval),
              customUnit: Value(routine.rule.customUnit?.name),
              weekdays: Value(weekdays.join(',')),
              hasTime: Value(routine.hasTime),
              isAllDay: Value(routine.isAllDay),
              startMinute: Value(routine.startMinute),
              endMinute: Value(routine.endMinute),
            ),
          );
      return success(_toEntity(row));
    } catch (_) {
      return fail(const CacheFailure('루틴을 저장하지 못했습니다.'));
    }
  }
}

RoutineDefinition _toEntity(RoutineTableData row) {
  final weekdays = row.weekdays.isEmpty
      ? <int>{}
      : row.weekdays.split(',').map(int.parse).toSet();
  return RoutineDefinition(
    rule: RoutineRule(
      id: row.id,
      startDate: row.startDate,
      endDate: row.endDate,
      frequency: RoutineFrequency.values.byName(row.frequency),
      creationMode: RoutineCreationMode.values.byName(row.creationMode),
      interval: row.interval,
      customUnit: row.customUnit == null
          ? null
          : RoutineIntervalUnit.values.byName(row.customUnit!),
      weekdays: weekdays,
    ),
    title: row.title,
    kind: TaskKind.values.byName(row.kind),
    categoryId: row.categoryId,
    hasTime: row.hasTime,
    isAllDay: row.isAllDay,
    startMinute: row.startMinute,
    endMinute: row.endMinute,
  );
}

final routineRepositoryProvider = Provider.autoDispose<RoutineRepository>(
  (ref) => RoutineRepositoryImpl(ref.watch(appDatabaseProvider)),
);
