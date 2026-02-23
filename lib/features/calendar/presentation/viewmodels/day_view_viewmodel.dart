import 'package:nae_mo/core/providers/selected_date_provider.dart';
import 'package:nae_mo/core/utils/result.dart';
import 'package:nae_mo/features/calendar/presentation/states/day_view_state.dart';
import 'package:nae_mo/features/calendar/presentation/viewmodels/task_dock_viewmodel.dart';
import 'package:nae_mo/features/task/domain/usecases/get_tasks_use_case.dart';
import 'package:nae_mo/features/task/domain/usecases/params/schedule_task_params.dart';
import 'package:nae_mo/features/task/domain/usecases/params/update_task_params.dart';
import 'package:nae_mo/features/task/domain/usecases/schedule_task_use_case.dart';
import 'package:nae_mo/features/task/domain/usecases/toggle_complete_use_case.dart';
import 'package:nae_mo/features/task/domain/usecases/update_task_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'day_view_viewmodel.g.dart';

/// 타임라인에 표시되는 스케줄된 태스크 상태를 관리한다.
/// build()가 AsyncNotifier로 동작 — 날짜 변경 시 자동 재조회.
@riverpod
class DayViewViewModel extends _$DayViewViewModel {
  @override
  Future<DayViewState> build() async {
    final date = ref.watch(selectedDateProvider);
    final result = await ref.read(getTasksUseCaseProvider).call(date);
    return result.fold(
      onSuccess: (tasks) => DayViewState(
        date: date,
        // hasTime && startDateTime != null && !isAllDay 인 태스크만 타임라인에 표시
        // 완료된 블록도 포함 (UI에서 dimmed 처리)
        scheduledTasks:
            tasks.where((t) => t.isScheduled && !t.isAllDay).toList(),
      ),
      onFailure: (f) => throw f,
    );
  }

  /// Dock → Timeline 드래그 완료 시 호출 (3-E)
  Future<void> scheduleTask(
    String taskId,
    DateTime start,
    DateTime end,
  ) async {
    final result = await ref.read(scheduleTaskUseCaseProvider).call(
          ScheduleTaskParams(
            taskId: taskId,
            startDateTime: start,
            endDateTime: end,
          ),
        );
    result.fold(
      onSuccess: (_) {
        ref.invalidateSelf();
        // Dock에서 태스크가 제거되므로 TaskDockViewModel도 갱신
        ref.invalidate(taskDockViewModelProvider);
      },
      onFailure: (f) => state = AsyncError(f, StackTrace.current),
    );
  }

  /// 블록 하단 핸들 드래그 완료 시 호출 (3-F)
  Future<void> resizeTask(String taskId, DateTime newEnd) async {
    final result = await ref.read(updateTaskUseCaseProvider).call(
          UpdateTaskParams(id: taskId, endDateTime: newEnd),
        );
    result.fold(
      onSuccess: (_) => ref.invalidateSelf(),
      onFailure: (f) => state = AsyncError(f, StackTrace.current),
    );
  }

  /// 타임라인 내에서 블록을 이동할 때 호출 (추후 구현)
  Future<void> moveTask(
    String taskId,
    DateTime newStart,
    DateTime newEnd,
  ) async {
    final result = await ref.read(updateTaskUseCaseProvider).call(
          UpdateTaskParams(
            id: taskId,
            startDateTime: newStart,
            endDateTime: newEnd,
          ),
        );
    result.fold(
      onSuccess: (_) => ref.invalidateSelf(),
      onFailure: (f) => state = AsyncError(f, StackTrace.current),
    );
  }

  /// 타임라인 블록의 완료 토글 (3-G)
  Future<void> toggleComplete(String taskId) async {
    final result =
        await ref.read(toggleCompleteUseCaseProvider).call(taskId);
    result.fold(
      onSuccess: (_) {
        ref.invalidateSelf();
        ref.invalidate(taskDockViewModelProvider);
      },
      onFailure: (f) => state = AsyncError(f, StackTrace.current),
    );
  }
}
