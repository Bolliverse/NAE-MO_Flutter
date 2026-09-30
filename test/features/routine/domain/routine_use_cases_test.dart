import 'package:flutter_test/flutter_test.dart';
import 'package:nae_mo/core/errors/failure.dart';
import 'package:nae_mo/core/utils/result.dart' as result;
import 'package:nae_mo/features/routine/domain/entities/routine_definition.dart';
import 'package:nae_mo/features/routine/domain/entities/routine_rule.dart';
import 'package:nae_mo/features/routine/domain/repositories/routine_repository.dart';
import 'package:nae_mo/features/routine/domain/usecases/routine_use_cases.dart';
import 'package:nae_mo/features/task/domain/entities/task.dart';

void main() {
  test('create validates title, event/Todo shape and time range before writing',
      () async {
    final repository = _Repository();
    final create = CreateRoutineUseCase(repository);
    final invalid = [
      _definition(title: '   '),
      _definition(kind: TaskKind.event),
      _definition(kind: TaskKind.todo, isAllDay: true),
      _definition(
          kind: TaskKind.event,
          hasTime: true,
          isAllDay: true,
          startMinute: 540,
          endMinute: 600),
      _definition(hasTime: true, startMinute: 540),
      _definition(hasTime: true, startMinute: 600, endMinute: 540),
      _definition(hasTime: true, startMinute: -1, endMinute: 600),
      _definition(hasTime: true, startMinute: 540, endMinute: 1441),
      _definition(startMinute: 540),
      _definition(
          rule: RoutineRule(
              id: 'invalid-auto',
              startDate: DateTime(2026, 9, 30),
              frequency: RoutineFrequency.daily,
              creationMode: RoutineCreationMode.automatic)),
    ];
    for (final routine in invalid) {
      expect((await create(routine)).failure, isA<ValidationFailure>());
    }
    expect(repository.created, isEmpty);
  });

  test('valid manual Todo and bounded automatic event delegate exactly once',
      () async {
    final repository = _Repository();
    final create = CreateRoutineUseCase(repository);
    final manual = _definition();
    final event = _definition(
        kind: TaskKind.event,
        isAllDay: true,
        rule: RoutineRule(
            id: 'auto-event',
            startDate: DateTime(2026, 9, 30),
            endDate: DateTime(2026, 10, 30),
            frequency: RoutineFrequency.monthly,
            creationMode: RoutineCreationMode.automatic));

    expect((await create(manual)).data, same(manual));
    expect((await create(event)).data, same(event));
    expect(repository.created, [manual, event]);
    expect((await GetRoutinesUseCase(repository)()).data, [manual, event]);
  });

  test('repository failures remain visible to callers', () async {
    final repository = _Repository()..failure = const CacheFailure('storage');
    expect((await CreateRoutineUseCase(repository)(_definition())).failure,
        repository.failure);
    expect(
        (await GetRoutinesUseCase(repository)()).failure, repository.failure);
  });
}

RoutineDefinition _definition({
  String title = '운동',
  TaskKind kind = TaskKind.todo,
  bool hasTime = false,
  bool isAllDay = false,
  int? startMinute,
  int? endMinute,
  RoutineRule? rule,
}) =>
    RoutineDefinition(
      rule: rule ??
          RoutineRule(
              id: 'manual-todo',
              startDate: DateTime(2026, 9, 30),
              frequency: RoutineFrequency.weekly,
              creationMode: RoutineCreationMode.manual,
              weekdays: {1, 6, 7}),
      title: title,
      kind: kind,
      hasTime: hasTime,
      isAllDay: isAllDay,
      startMinute: startMinute,
      endMinute: endMinute,
    );

class _Repository extends Fake implements RoutineRepository {
  final created = <RoutineDefinition>[];
  Failure? failure;

  @override
  Future<result.Result<RoutineDefinition>> create(
      RoutineDefinition routine) async {
    if (failure != null) return result.fail(failure!);
    created.add(routine);
    return result.success(routine);
  }

  @override
  Future<result.Result<List<RoutineDefinition>>> getAll() async =>
      failure == null ? result.success(created) : result.fail(failure!);
}
