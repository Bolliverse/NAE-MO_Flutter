import 'package:nae_mo/core/utils/result.dart';
import 'package:nae_mo/features/task/data/repositories/task_repository_provider.dart';
import 'package:nae_mo/features/task/domain/entities/task.dart';
import 'package:nae_mo/features/task/domain/repositories/task_repository.dart';
import 'package:nae_mo/features/task/domain/usecases/params/create_task_params.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'create_task_use_case.g.dart';

class CreateTaskUseCase {
  final TaskRepository _repository;
  const CreateTaskUseCase(this._repository);

  Future<Result<Task>> call(CreateTaskParams params) =>
      _repository.createTask(params);
}

@riverpod
CreateTaskUseCase createTaskUseCase(CreateTaskUseCaseRef ref) =>
    CreateTaskUseCase(ref.read(taskRepositoryProvider));
