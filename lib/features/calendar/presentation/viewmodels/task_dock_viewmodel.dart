import 'package:nae_mo/core/providers/selected_date_provider.dart';
import 'package:nae_mo/core/utils/result.dart';
import 'package:nae_mo/features/calendar/presentation/states/task_dock_state.dart';
import 'package:nae_mo/features/task/domain/usecases/create_task_use_case.dart';
import 'package:nae_mo/features/task/domain/usecases/get_tasks_use_case.dart';
import 'package:nae_mo/features/task/domain/usecases/get_unscheduled_tasks_use_case.dart';
import 'package:nae_mo/features/task/domain/usecases/params/create_task_params.dart';
import 'package:nae_mo/features/task/domain/usecases/toggle_complete_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'task_dock_viewmodel.g.dart';

/// Task Dock 상태를 관리한다.
/// - unscheduledTasks: 미배정 태스크 (hasTime=false, isCompleted=false)
/// - completedTasks: 오늘 날짜 기준 완료된 태스크
/// - isCompletedExpanded: 완료 섹션 펼침 여부 (동기 토글)
///
/// 동기 토글(isCompletedExpanded)이 필요하므로 Notifier<TaskDockState>를 사용.
@riverpod
class TaskDockViewModel extends _$TaskDockViewModel {
  @override
  TaskDockState build() {
    final date = ref.watch(selectedDateProvider);
    // build()는 동기 반환 → 비동기 로드는 microtask로 스케줄
    Future.microtask(() => _load(date));
    return const TaskDockState(isLoading: true);
  }

  Future<void> _load(DateTime date) async {
    final unscheduledResult =
        await ref.read(getUnscheduledTasksUseCaseProvider).call();
    final scheduledResult =
        await ref.read(getTasksUseCaseProvider).call(date);

    // 두 쿼리 모두 성공해야 상태 업데이트
    unscheduledResult.fold(
      onSuccess: (unscheduled) {
        scheduledResult.fold(
          onSuccess: (scheduled) {
            state = state.copyWith(
              unscheduledTasks: unscheduled,
              completedTasks:
                  scheduled.where((t) => t.isCompleted).toList(),
              isLoading: false,
              failure: null,
            );
          },
          onFailure: (f) =>
              state = state.copyWith(isLoading: false, failure: f),
        );
      },
      onFailure: (f) =>
          state = state.copyWith(isLoading: false, failure: f),
    );
  }

  /// 완료 섹션 펼치기/접기 — 동기, DB 조회 없음
  void toggleCompletedSection() {
    state =
        state.copyWith(isCompletedExpanded: !state.isCompletedExpanded);
  }

  /// Dock 아이템 완료 토글 (3-G)
  Future<void> toggleComplete(String taskId) async {
    final result =
        await ref.read(toggleCompleteUseCaseProvider).call(taskId);
    result.fold(
      onSuccess: (_) {
        final date = ref.read(selectedDateProvider);
        Future.microtask(() => _load(date));
      },
      onFailure: (f) => state = state.copyWith(failure: f),
    );
  }

  /// QuickAddInput에서 태스크 생성 (3-I)
  Future<void> createTask(String title) async {
    final result = await ref.read(createTaskUseCaseProvider).call(
          CreateTaskParams(title: title, hasTime: false),
        );
    result.fold(
      onSuccess: (_) {
        final date = ref.read(selectedDateProvider);
        Future.microtask(() => _load(date));
      },
      onFailure: (f) => state = state.copyWith(failure: f),
    );
  }
}
