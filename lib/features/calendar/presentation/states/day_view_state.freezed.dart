// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'day_view_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$DayViewState {
  DateTime get date =>
      throw _privateConstructorUsedError; // hasTime == true && !isAllDay — 완료된 블록 포함
  List<Task> get scheduledTasks => throw _privateConstructorUsedError;

  /// Create a copy of DayViewState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DayViewStateCopyWith<DayViewState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DayViewStateCopyWith<$Res> {
  factory $DayViewStateCopyWith(
          DayViewState value, $Res Function(DayViewState) then) =
      _$DayViewStateCopyWithImpl<$Res, DayViewState>;
  @useResult
  $Res call({DateTime date, List<Task> scheduledTasks});
}

/// @nodoc
class _$DayViewStateCopyWithImpl<$Res, $Val extends DayViewState>
    implements $DayViewStateCopyWith<$Res> {
  _$DayViewStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DayViewState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? scheduledTasks = null,
  }) {
    return _then(_value.copyWith(
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      scheduledTasks: null == scheduledTasks
          ? _value.scheduledTasks
          : scheduledTasks // ignore: cast_nullable_to_non_nullable
              as List<Task>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DayViewStateImplCopyWith<$Res>
    implements $DayViewStateCopyWith<$Res> {
  factory _$$DayViewStateImplCopyWith(
          _$DayViewStateImpl value, $Res Function(_$DayViewStateImpl) then) =
      __$$DayViewStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({DateTime date, List<Task> scheduledTasks});
}

/// @nodoc
class __$$DayViewStateImplCopyWithImpl<$Res>
    extends _$DayViewStateCopyWithImpl<$Res, _$DayViewStateImpl>
    implements _$$DayViewStateImplCopyWith<$Res> {
  __$$DayViewStateImplCopyWithImpl(
      _$DayViewStateImpl _value, $Res Function(_$DayViewStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of DayViewState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? scheduledTasks = null,
  }) {
    return _then(_$DayViewStateImpl(
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      scheduledTasks: null == scheduledTasks
          ? _value._scheduledTasks
          : scheduledTasks // ignore: cast_nullable_to_non_nullable
              as List<Task>,
    ));
  }
}

/// @nodoc

class _$DayViewStateImpl implements _DayViewState {
  const _$DayViewStateImpl(
      {required this.date, required final List<Task> scheduledTasks})
      : _scheduledTasks = scheduledTasks;

  @override
  final DateTime date;
// hasTime == true && !isAllDay — 완료된 블록 포함
  final List<Task> _scheduledTasks;
// hasTime == true && !isAllDay — 완료된 블록 포함
  @override
  List<Task> get scheduledTasks {
    if (_scheduledTasks is EqualUnmodifiableListView) return _scheduledTasks;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_scheduledTasks);
  }

  @override
  String toString() {
    return 'DayViewState(date: $date, scheduledTasks: $scheduledTasks)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DayViewStateImpl &&
            (identical(other.date, date) || other.date == date) &&
            const DeepCollectionEquality()
                .equals(other._scheduledTasks, _scheduledTasks));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, date, const DeepCollectionEquality().hash(_scheduledTasks));

  /// Create a copy of DayViewState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DayViewStateImplCopyWith<_$DayViewStateImpl> get copyWith =>
      __$$DayViewStateImplCopyWithImpl<_$DayViewStateImpl>(this, _$identity);
}

abstract class _DayViewState implements DayViewState {
  const factory _DayViewState(
      {required final DateTime date,
      required final List<Task> scheduledTasks}) = _$DayViewStateImpl;

  @override
  DateTime get date; // hasTime == true && !isAllDay — 완료된 블록 포함
  @override
  List<Task> get scheduledTasks;

  /// Create a copy of DayViewState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DayViewStateImplCopyWith<_$DayViewStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
