import 'package:nae_mo/core/utils/result.dart';
import 'package:nae_mo/features/task/data/repositories/task_repository_provider.dart';
import 'package:nae_mo/features/task/domain/entities/task.dart';
import 'package:nae_mo/features/task/domain/repositories/task_repository.dart';
import 'package:nae_mo/features/task/domain/usecases/params/schedule_task_params.dart';
import 'package:nae_mo/features/task/domain/usecases/params/update_task_params.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'schedule_task_use_case.g.dart';

/// Task Dock에서 Timeline으로 드래그했을 때 호출
class ScheduleTaskUseCase {
  final TaskRepository _repository;
  const ScheduleTaskUseCase(this._repository);

  Future<Result<Task>> call(ScheduleTaskParams params) =>
      _repository.updateTask(
        UpdateTaskParams(
          id: params.taskId,
          hasTime: true,
          startDateTime: params.startDateTime,
          endDateTime: params.endDateTime,
        ),
      );
}

@riverpod
ScheduleTaskUseCase scheduleTaskUseCase(ScheduleTaskUseCaseRef ref) =>
    ScheduleTaskUseCase(ref.read(taskRepositoryProvider));
