import 'package:nae_mo/core/utils/result.dart';
import 'package:nae_mo/features/task/data/repositories/task_repository_provider.dart';
import 'package:nae_mo/features/task/domain/entities/task.dart';
import 'package:nae_mo/features/task/domain/repositories/task_repository.dart';
import 'package:nae_mo/features/task/domain/usecases/params/update_task_params.dart';
import 'package:nae_mo/features/task/domain/validation/task_validator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'update_task_use_case.g.dart';

class UpdateTaskUseCase {
  final TaskRepository _repository;
  const UpdateTaskUseCase(this._repository);

  Future<Result<Task>> call(UpdateTaskParams params) async {
    final currentResult = await _repository.getTaskById(params.id);
    final readFailure = currentResult.failure;
    if (readFailure != null) return fail<Task>(readFailure);

    final draft = params.resolve(currentResult.data!);
    final validationFailure = TaskValidator.validate(draft);
    if (validationFailure != null) return fail<Task>(validationFailure);

    return _repository.updateTask(params);
  }
}

@riverpod
UpdateTaskUseCase updateTaskUseCase(UpdateTaskUseCaseRef ref) =>
    UpdateTaskUseCase(ref.read(taskRepositoryProvider));
