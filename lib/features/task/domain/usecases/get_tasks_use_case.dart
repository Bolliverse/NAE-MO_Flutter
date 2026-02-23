import 'package:nae_mo/core/utils/result.dart';
import 'package:nae_mo/features/task/data/repositories/task_repository_provider.dart';
import 'package:nae_mo/features/task/domain/entities/task.dart';
import 'package:nae_mo/features/task/domain/repositories/task_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'get_tasks_use_case.g.dart';

class GetTasksUseCase {
  final TaskRepository _repository;
  const GetTasksUseCase(this._repository);

  Future<Result<List<Task>>> call(DateTime date) =>
      _repository.getTasksByDate(date);
}

@riverpod
GetTasksUseCase getTasksUseCase(GetTasksUseCaseRef ref) =>
    GetTasksUseCase(ref.read(taskRepositoryProvider));
