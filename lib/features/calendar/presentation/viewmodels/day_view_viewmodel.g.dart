// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'day_view_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$dayViewViewModelHash() => r'd09d44ee7f0a2c785111bd7b0477e438933930be';

/// 타임라인에 표시되는 스케줄된 태스크 상태를 관리한다.
/// build()가 AsyncNotifier로 동작 — 날짜 변경 시 자동 재조회.
///
/// Copied from [DayViewViewModel].
@ProviderFor(DayViewViewModel)
final dayViewViewModelProvider =
    AutoDisposeAsyncNotifierProvider<DayViewViewModel, DayViewState>.internal(
  DayViewViewModel.new,
  name: r'dayViewViewModelProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$dayViewViewModelHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$DayViewViewModel = AutoDisposeAsyncNotifier<DayViewState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
