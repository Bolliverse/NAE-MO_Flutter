import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nae_mo/core/errors/failure.dart';
import 'package:nae_mo/core/utils/result.dart';
import 'package:nae_mo/features/routine/data/repositories/routine_repository_impl.dart';
import 'package:nae_mo/features/routine/domain/entities/routine_definition.dart';
import 'package:nae_mo/features/routine/domain/entities/routine_rule.dart';
import 'package:nae_mo/features/routine/domain/repositories/routine_repository.dart';
import 'package:nae_mo/features/routine/domain/usecases/get_routine_occurrences.dart';
import 'package:nae_mo/features/task/data/repositories/task_repository_provider.dart';
import 'package:nae_mo/features/task/domain/entities/task.dart';
import 'package:nae_mo/features/task/domain/repositories/task_repository.dart';
import 'package:nae_mo/features/task/domain/usecases/create_task_use_case.dart';
import 'package:nae_mo/features/task/domain/usecases/params/create_task_params.dart';

class ManualRoutineCandidate {
  const ManualRoutineCandidate(this.definition, this.date);

  final RoutineDefinition definition;
  final DateTime date;

  String get routineId => definition.id;
}

/// Candidates remain virtual until a user explicitly confirms them.
class GetManualRoutineCandidates {
  const GetManualRoutineCandidates(this._routines, this._tasks);

  final RoutineRepository _routines;
  final TaskRepository _tasks;

  Future<Result<List<ManualRoutineCandidate>>> call(
      DateTime selectedDate) async {
    final date = DateTime(
      selectedDate.toLocal().year,
      selectedDate.toLocal().month,
      selectedDate.toLocal().day,
    );
    final routinesResult = await _routines.getAll();
    if (routinesResult.failure case final failure?) return fail(failure);
    final tasksResult = await _tasks.getTasksByDate(date);
    if (tasksResult.failure case final failure?) return fail(failure);

    final addedIds = tasksResult.data!
        .map((task) => task.routineId)
        .whereType<String>()
        .toSet();
    final candidates = <ManualRoutineCandidate>[];
    const occurrences = GetRoutineOccurrences();
    for (final definition in routinesResult.data!) {
      if (definition.rule.creationMode != RoutineCreationMode.manual ||
          addedIds.contains(definition.id)) {
        continue;
      }
      final result = occurrences(
        definition.rule,
        from: date,
        through: date,
      );
      if (result.failure case final failure?) return fail(failure);
      if (result.data!.isNotEmpty) {
        candidates.add(ManualRoutineCandidate(definition, date));
      }
    }
    return success(List.unmodifiable(candidates));
  }
}

class ConfirmManualRoutineCandidate {
  const ConfirmManualRoutineCandidate(this._candidates, this._createTask);

  final GetManualRoutineCandidates _candidates;
  final CreateTaskUseCase _createTask;

  Future<Result<Task>> call(String routineId, DateTime date) async {
    final result = await _candidates(date);
    if (result.failure case final failure?) return fail(failure);
    for (final candidate in result.data!) {
      if (candidate.routineId != routineId) continue;
      final definition = candidate.definition;
      final localDate = candidate.date;
      final start = definition.hasTime
          ? DateTime(localDate.year, localDate.month, localDate.day, 0,
              definition.startMinute!)
          : null;
      final end = definition.hasTime
          ? DateTime(localDate.year, localDate.month, localDate.day, 0,
              definition.endMinute!)
          : null;
      return _createTask(CreateTaskParams(
        title: definition.title,
        kind: definition.kind,
        targetDate: candidate.date,
        categoryId: definition.categoryId,
        routineId: definition.id,
        hasTime: definition.hasTime,
        isAllDay: definition.isAllDay,
        startDateTime: start,
        endDateTime: end,
      ));
    }
    return fail(const ValidationFailure('이 날짜에 추가할 수동 루틴 후보가 없습니다.'));
  }
}

final getManualRoutineCandidatesProvider =
    Provider.autoDispose<GetManualRoutineCandidates>(
        (ref) => GetManualRoutineCandidates(
              ref.watch(routineRepositoryProvider),
              ref.watch(taskRepositoryProvider),
            ));

final confirmManualRoutineCandidateProvider =
    Provider.autoDispose<ConfirmManualRoutineCandidate>(
        (ref) => ConfirmManualRoutineCandidate(
              ref.watch(getManualRoutineCandidatesProvider),
              ref.watch(createTaskUseCaseProvider),
            ));
