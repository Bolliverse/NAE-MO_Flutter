import 'package:nae_mo/core/utils/result.dart';
import 'package:nae_mo/features/task/data/repositories/task_repository_provider.dart';
import 'package:nae_mo/features/task/domain/entities/task.dart';
import 'package:nae_mo/features/task/domain/repositories/task_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'get_tasks_by_range_use_case.g.dart';

class GetTasksByRangeUseCase {
  final TaskRepository _repository;
  const GetTasksByRangeUseCase(this._repository);

  Future<Result<List<Task>>> call(DateTime start, DateTime end) =>
      _repository.getTasksByRange(start, end);
}

@riverpod
GetTasksByRangeUseCase getTasksByRangeUseCase(GetTasksByRangeUseCaseRef ref) =>
    GetTasksByRangeUseCase(ref.read(taskRepositoryProvider));
