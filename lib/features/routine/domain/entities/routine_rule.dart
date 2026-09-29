import 'package:nae_mo/core/errors/failure.dart';

enum RoutineFrequency { daily, weekly, monthly, yearly, custom }

enum RoutineIntervalUnit { day, week, month, year }

enum RoutineCreationMode { automatic, manual }

/// A calendar rule, independent of the Event/Todo template that will use it.
class RoutineRule {
  RoutineRule({
    required this.id,
    required this.startDate,
    required this.frequency,
    required this.creationMode,
    this.endDate,
    this.interval = 1,
    this.customUnit,
    Set<int> weekdays = const {},
  }) : weekdays = Set.unmodifiable(weekdays);

  final String id;
  final DateTime startDate;
  final DateTime? endDate;
  final RoutineFrequency frequency;
  final RoutineCreationMode creationMode;
  final int interval;
  final RoutineIntervalUnit? customUnit;
  final Set<int> weekdays;

  ValidationFailure? validate() {
    if (id.trim().isEmpty) {
      return const ValidationFailure('루틴 ID가 필요합니다.');
    }
    if (!_isLocalMidnight(startDate) ||
        (endDate != null && !_isLocalMidnight(endDate!))) {
      return const ValidationFailure('루틴 날짜는 현지 자정이어야 합니다.');
    }
    if (endDate != null && endDate!.isBefore(startDate)) {
      return const ValidationFailure('종료일은 시작일보다 빠를 수 없습니다.');
    }
    if (endDate == null && creationMode == RoutineCreationMode.automatic) {
      return const ValidationFailure('종료일 없는 루틴은 수동 추가만 가능합니다.');
    }
    if (interval < 1 ||
        (frequency != RoutineFrequency.custom && interval != 1)) {
      return const ValidationFailure('사용자 정의 간격은 1 이상이어야 합니다.');
    }
    if ((frequency == RoutineFrequency.custom) != (customUnit != null)) {
      return const ValidationFailure('사용자 정의 반복에는 간격 단위가 필요합니다.');
    }
    final unit = switch (frequency) {
      RoutineFrequency.daily => RoutineIntervalUnit.day,
      RoutineFrequency.weekly => RoutineIntervalUnit.week,
      RoutineFrequency.monthly => RoutineIntervalUnit.month,
      RoutineFrequency.yearly => RoutineIntervalUnit.year,
      RoutineFrequency.custom => customUnit!,
    };
    if (weekdays.any((day) => day < DateTime.monday || day > DateTime.sunday)) {
      return const ValidationFailure('반복 요일은 월요일부터 일요일까지 선택해 주세요.');
    }
    if (unit != RoutineIntervalUnit.week && weekdays.isNotEmpty) {
      return const ValidationFailure('요일 선택은 주간 반복에서만 사용할 수 있습니다.');
    }
    return null;
  }
}

bool _isLocalMidnight(DateTime date) =>
    !date.isUtc &&
    date.hour == 0 &&
    date.minute == 0 &&
    date.second == 0 &&
    date.millisecond == 0 &&
    date.microsecond == 0;
