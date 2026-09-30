import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nae_mo/core/utils/result.dart';
import 'package:nae_mo/features/routine/data/repositories/routine_repository_impl.dart';
import 'package:nae_mo/features/routine/domain/entities/routine_definition.dart';
import 'package:nae_mo/features/routine/domain/repositories/routine_repository.dart';

class CreateRoutineUseCase {
  const CreateRoutineUseCase(this._repository);
  final RoutineRepository _repository;

  Future<Result<RoutineDefinition>> call(RoutineDefinition routine) {
    final failure = routine.validate();
    if (failure != null) return Future.value(fail(failure));
    return _repository.create(routine);
  }
}

class GetRoutinesUseCase {
  const GetRoutinesUseCase(this._repository);
  final RoutineRepository _repository;

  Future<Result<List<RoutineDefinition>>> call() => _repository.getAll();
}

final createRoutineUseCaseProvider = Provider.autoDispose<CreateRoutineUseCase>(
  (ref) => CreateRoutineUseCase(ref.watch(routineRepositoryProvider)),
);

final getRoutinesUseCaseProvider = Provider.autoDispose<GetRoutinesUseCase>(
  (ref) => GetRoutinesUseCase(ref.watch(routineRepositoryProvider)),
);
