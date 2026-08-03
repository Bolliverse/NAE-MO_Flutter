import 'package:nae_mo/core/utils/result.dart';
import 'package:nae_mo/features/task/domain/entities/task.dart';
import 'package:nae_mo/features/task/domain/usecases/params/schedule_task_params.dart';
import 'package:nae_mo/features/task/domain/usecases/params/update_task_params.dart';
import 'package:nae_mo/features/task/domain/usecases/update_task_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'schedule_task_use_case.g.dart';

/// Task Dock에서 Timeline으로 드래그했을 때 호출
class ScheduleTaskUseCase {
  final UpdateTaskUseCase _updateTask;
  const ScheduleTaskUseCase(this._updateTask);

  Future<Result<Task>> call(ScheduleTaskParams params) {
    final localStart = params.startDateTime.toLocal();
    return _updateTask(
      UpdateTaskParams(
        id: params.taskId,
        targetDate: DateTime(localStart.year, localStart.month, localStart.day),
        hasTime: true,
        startDateTime: params.startDateTime,
        endDateTime: params.endDateTime,
      ),
    );
  }
}

@riverpod
ScheduleTaskUseCase scheduleTaskUseCase(ScheduleTaskUseCaseRef ref) =>
    ScheduleTaskUseCase(ref.read(updateTaskUseCaseProvider));
