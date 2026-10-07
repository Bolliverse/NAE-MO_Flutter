import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nae_mo/core/database/app_database.dart';
import 'package:nae_mo/core/database/app_database_provider.dart';
import 'package:nae_mo/core/errors/failure.dart';
import 'package:nae_mo/core/utils/result.dart';
import 'package:nae_mo/features/routine/domain/entities/routine_definition.dart';
import 'package:nae_mo/features/routine/domain/entities/routine_rule.dart';
import 'package:nae_mo/features/routine/domain/repositories/routine_repository.dart';
import 'package:nae_mo/features/routine/domain/usecases/get_routine_occurrences.dart';
import 'package:nae_mo/features/task/domain/entities/task.dart';
import 'package:uuid/uuid.dart';

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
    final validation = routine.validate();
    if (validation != null) return fail(validation);
    final occurrences =
        routine.rule.creationMode == RoutineCreationMode.automatic
            ? const GetRoutineOccurrences()(
                routine.rule,
                from: routine.rule.startDate,
                through: routine.rule.endDate!,
              )
            : success(const <RoutineOccurrence>[]);
    if (occurrences.failure case final failure?) return fail(failure);

    try {
      final weekdays = routine.rule.weekdays.toList()..sort();
      // The definition and every automatic occurrence commit or roll back together.
      // https://drift.simonbinder.eu/dart_api/transactions/
      final row = await _db.transaction(() async {
        final saved = await _db.into(_db.routineTable).insertReturning(
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
        if (occurrences.data!.isNotEmpty) {
          // Drift batches reuse the insert statement for each occurrence.
          // https://drift.simonbinder.eu/dart_api/writes/#inserts
          await _db.batch((batch) {
            batch.insertAll(
              _db.taskTable,
              [
                for (final occurrence in occurrences.data!)
                  _automaticTask(routine, occurrence.date),
              ],
            );
          });
        }
        return saved;
      });
      return success(_toEntity(row));
    } catch (_) {
      return fail(const CacheFailure('루틴을 저장하지 못했습니다.'));
    }
  }
}

TaskTableCompanion _automaticTask(RoutineDefinition routine, DateTime date) {
  DateTime? atMinute(int? minute) => minute == null
      ? null
      : DateTime(date.year, date.month, date.day, 0, minute);
  return TaskTableCompanion.insert(
    id: const Uuid().v4(),
    title: routine.title.trim(),
    kind: Value(routine.kind),
    targetDate: Value(date),
    categoryId: Value(routine.categoryId),
    routineId: Value(routine.id),
    hasTime: Value(routine.hasTime),
    isAllDay: Value(routine.isAllDay),
    startDateTime: Value(atMinute(routine.startMinute)),
    endDateTime: Value(atMinute(routine.endMinute)),
  );
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
