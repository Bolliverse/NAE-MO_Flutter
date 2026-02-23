import 'package:nae_mo/core/utils/result.dart';
import 'package:nae_mo/features/task/data/repositories/task_repository_provider.dart';
import 'package:nae_mo/features/task/domain/repositories/task_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'delete_task_use_case.g.dart';

class DeleteTaskUseCase {
  final TaskRepository _repository;
  const DeleteTaskUseCase(this._repository);

  Future<Result<void>> call(String id) => _repository.deleteTask(id);
}

@riverpod
DeleteTaskUseCase deleteTaskUseCase(DeleteTaskUseCaseRef ref) =>
    DeleteTaskUseCase(ref.read(taskRepositoryProvider));
