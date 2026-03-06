// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_dock_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$taskDockViewModelHash() => r'e0b7e1197b773f108490a614c1c969ba5b033327';

/// Task Dock 상태를 관리한다.
/// - unscheduledTasks: 미배정 태스크 (hasTime=false, isCompleted=false)
/// - completedTasks: 오늘 날짜 기준 완료된 태스크
/// - isCompletedExpanded: 완료 섹션 펼침 여부 (동기 토글)
///
/// 동기 토글(isCompletedExpanded)이 필요하므로 Notifier<TaskDockState>를 사용.
///
/// Copied from [TaskDockViewModel].
@ProviderFor(TaskDockViewModel)
final taskDockViewModelProvider =
    AutoDisposeNotifierProvider<TaskDockViewModel, TaskDockState>.internal(
  TaskDockViewModel.new,
  name: r'taskDockViewModelProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$taskDockViewModelHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$TaskDockViewModel = AutoDisposeNotifier<TaskDockState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
