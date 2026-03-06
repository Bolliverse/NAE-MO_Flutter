// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task_dock_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$TaskDockState {
// hasTime == false && !isCompleted
  List<Task> get unscheduledTasks =>
      throw _privateConstructorUsedError; // isCompleted == true (오늘 날짜 기준 스케줄된 완료 태스크)
  List<Task> get completedTasks => throw _privateConstructorUsedError;
  bool get isCompletedExpanded => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  Failure? get failure => throw _privateConstructorUsedError;

  /// Create a copy of TaskDockState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TaskDockStateCopyWith<TaskDockState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TaskDockStateCopyWith<$Res> {
  factory $TaskDockStateCopyWith(
          TaskDockState value, $Res Function(TaskDockState) then) =
      _$TaskDockStateCopyWithImpl<$Res, TaskDockState>;
  @useResult
  $Res call(
      {List<Task> unscheduledTasks,
      List<Task> completedTasks,
      bool isCompletedExpanded,
      bool isLoading,
      Failure? failure});
}

/// @nodoc
class _$TaskDockStateCopyWithImpl<$Res, $Val extends TaskDockState>
    implements $TaskDockStateCopyWith<$Res> {
  _$TaskDockStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TaskDockState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? unscheduledTasks = null,
    Object? completedTasks = null,
    Object? isCompletedExpanded = null,
    Object? isLoading = null,
    Object? failure = freezed,
  }) {
    return _then(_value.copyWith(
      unscheduledTasks: null == unscheduledTasks
          ? _value.unscheduledTasks
          : unscheduledTasks // ignore: cast_nullable_to_non_nullable
              as List<Task>,
      completedTasks: null == completedTasks
          ? _value.completedTasks
          : completedTasks // ignore: cast_nullable_to_non_nullable
              as List<Task>,
      isCompletedExpanded: null == isCompletedExpanded
          ? _value.isCompletedExpanded
          : isCompletedExpanded // ignore: cast_nullable_to_non_nullable
              as bool,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      failure: freezed == failure
          ? _value.failure
          : failure // ignore: cast_nullable_to_non_nullable
              as Failure?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TaskDockStateImplCopyWith<$Res>
    implements $TaskDockStateCopyWith<$Res> {
  factory _$$TaskDockStateImplCopyWith(
          _$TaskDockStateImpl value, $Res Function(_$TaskDockStateImpl) then) =
      __$$TaskDockStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<Task> unscheduledTasks,
      List<Task> completedTasks,
      bool isCompletedExpanded,
      bool isLoading,
      Failure? failure});
}

/// @nodoc
class __$$TaskDockStateImplCopyWithImpl<$Res>
    extends _$TaskDockStateCopyWithImpl<$Res, _$TaskDockStateImpl>
    implements _$$TaskDockStateImplCopyWith<$Res> {
  __$$TaskDockStateImplCopyWithImpl(
      _$TaskDockStateImpl _value, $Res Function(_$TaskDockStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of TaskDockState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? unscheduledTasks = null,
    Object? completedTasks = null,
    Object? isCompletedExpanded = null,
    Object? isLoading = null,
    Object? failure = freezed,
  }) {
    return _then(_$TaskDockStateImpl(
      unscheduledTasks: null == unscheduledTasks
          ? _value._unscheduledTasks
          : unscheduledTasks // ignore: cast_nullable_to_non_nullable
              as List<Task>,
      completedTasks: null == completedTasks
          ? _value._completedTasks
          : completedTasks // ignore: cast_nullable_to_non_nullable
              as List<Task>,
      isCompletedExpanded: null == isCompletedExpanded
          ? _value.isCompletedExpanded
          : isCompletedExpanded // ignore: cast_nullable_to_non_nullable
              as bool,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      failure: freezed == failure
          ? _value.failure
          : failure // ignore: cast_nullable_to_non_nullable
              as Failure?,
    ));
  }
}

/// @nodoc

class _$TaskDockStateImpl implements _TaskDockState {
  const _$TaskDockStateImpl(
      {final List<Task> unscheduledTasks = const [],
      final List<Task> completedTasks = const [],
      this.isCompletedExpanded = false,
      this.isLoading = true,
      this.failure})
      : _unscheduledTasks = unscheduledTasks,
        _completedTasks = completedTasks;

// hasTime == false && !isCompleted
  final List<Task> _unscheduledTasks;
// hasTime == false && !isCompleted
  @override
  @JsonKey()
  List<Task> get unscheduledTasks {
    if (_unscheduledTasks is EqualUnmodifiableListView)
      return _unscheduledTasks;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_unscheduledTasks);
  }

// isCompleted == true (오늘 날짜 기준 스케줄된 완료 태스크)
  final List<Task> _completedTasks;
// isCompleted == true (오늘 날짜 기준 스케줄된 완료 태스크)
  @override
  @JsonKey()
  List<Task> get completedTasks {
    if (_completedTasks is EqualUnmodifiableListView) return _completedTasks;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_completedTasks);
  }

  @override
  @JsonKey()
  final bool isCompletedExpanded;
  @override
  @JsonKey()
  final bool isLoading;
  @override
  final Failure? failure;

  @override
  String toString() {
    return 'TaskDockState(unscheduledTasks: $unscheduledTasks, completedTasks: $completedTasks, isCompletedExpanded: $isCompletedExpanded, isLoading: $isLoading, failure: $failure)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TaskDockStateImpl &&
            const DeepCollectionEquality()
                .equals(other._unscheduledTasks, _unscheduledTasks) &&
            const DeepCollectionEquality()
                .equals(other._completedTasks, _completedTasks) &&
            (identical(other.isCompletedExpanded, isCompletedExpanded) ||
                other.isCompletedExpanded == isCompletedExpanded) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.failure, failure) || other.failure == failure));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_unscheduledTasks),
      const DeepCollectionEquality().hash(_completedTasks),
      isCompletedExpanded,
      isLoading,
      failure);

  /// Create a copy of TaskDockState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TaskDockStateImplCopyWith<_$TaskDockStateImpl> get copyWith =>
      __$$TaskDockStateImplCopyWithImpl<_$TaskDockStateImpl>(this, _$identity);
}

abstract class _TaskDockState implements TaskDockState {
  const factory _TaskDockState(
      {final List<Task> unscheduledTasks,
      final List<Task> completedTasks,
      final bool isCompletedExpanded,
      final bool isLoading,
      final Failure? failure}) = _$TaskDockStateImpl;

// hasTime == false && !isCompleted
  @override
  List<Task> get unscheduledTasks; // isCompleted == true (오늘 날짜 기준 스케줄된 완료 태스크)
  @override
  List<Task> get completedTasks;
  @override
  bool get isCompletedExpanded;
  @override
  bool get isLoading;
  @override
  Failure? get failure;

  /// Create a copy of TaskDockState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TaskDockStateImplCopyWith<_$TaskDockStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
