import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nae_mo/features/task/domain/entities/task.dart';

part 'day_view_state.freezed.dart';

@freezed
class DayViewState with _$DayViewState {
  const factory DayViewState({
    required DateTime date,
    // hasTime == true && !isAllDay — 완료된 블록 포함
    required List<Task> scheduledTasks,
  }) = _DayViewState;
}
