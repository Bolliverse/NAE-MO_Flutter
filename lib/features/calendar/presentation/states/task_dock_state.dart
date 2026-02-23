import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nae_mo/core/errors/failure.dart';
import 'package:nae_mo/features/task/domain/entities/task.dart';

part 'task_dock_state.freezed.dart';

@freezed
class TaskDockState with _$TaskDockState {
  const factory TaskDockState({
    // hasTime == false && !isCompleted
    @Default([]) List<Task> unscheduledTasks,
    // isCompleted == true (오늘 날짜 기준 스케줄된 완료 태스크)
    @Default([]) List<Task> completedTasks,
    @Default(false) bool isCompletedExpanded,
    @Default(true) bool isLoading,
    Failure? failure,
  }) = _TaskDockState;
}
