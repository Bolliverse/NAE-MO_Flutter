import 'package:nae_mo/core/utils/result.dart';
import 'package:nae_mo/features/task/data/repositories/task_repository_provider.dart';
import 'package:nae_mo/features/task/domain/entities/task.dart';
import 'package:nae_mo/features/task/domain/repositories/task_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'toggle_complete_use_case.g.dart';

class ToggleCompleteUseCase {
  final TaskRepository _repository;
  const ToggleCompleteUseCase(this._repository);

  Future<Result<Task>> call(String id) => _repository.toggleComplete(id);
}

@riverpod
ToggleCompleteUseCase toggleCompleteUseCase(ToggleCompleteUseCaseRef ref) =>
    ToggleCompleteUseCase(ref.read(taskRepositoryProvider));
