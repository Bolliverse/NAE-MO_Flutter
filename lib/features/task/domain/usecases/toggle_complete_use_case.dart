import 'package:nae_mo/core/errors/failure.dart';
import 'package:nae_mo/core/utils/result.dart';
import 'package:nae_mo/features/task/data/repositories/task_repository_provider.dart';
import 'package:nae_mo/features/task/domain/entities/task.dart';
import 'package:nae_mo/features/task/domain/repositories/task_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'toggle_complete_use_case.g.dart';

class ToggleCompleteUseCase {
  final TaskRepository _repository;
  const ToggleCompleteUseCase(this._repository);

  Future<Result<Task>> call(String id) async {
    final currentResult = await _repository.getTaskById(id);
    final readFailure = currentResult.failure;
    if (readFailure != null) return fail<Task>(readFailure);

    if (currentResult.data!.kind == TaskKind.event) {
      return fail<Task>(
        const ValidationFailure('일정은 완료 상태를 가질 수 없습니다.'),
      );
    }

    return _repository.toggleComplete(id);
  }
}

@riverpod
ToggleCompleteUseCase toggleCompleteUseCase(ToggleCompleteUseCaseRef ref) =>
    ToggleCompleteUseCase(ref.read(taskRepositoryProvider));
