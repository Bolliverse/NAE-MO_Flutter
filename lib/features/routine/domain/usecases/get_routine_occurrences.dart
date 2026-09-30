import 'package:nae_mo/core/errors/failure.dart';
import 'package:nae_mo/core/utils/result.dart';
import 'package:nae_mo/features/routine/domain/entities/routine_rule.dart';

class RoutineOccurrence {
  const RoutineOccurrence({
    required this.routineId,
    required this.date,
    required this.requiresConfirmation,
  });

  final String routineId;
  final DateTime date;

  /// Manual candidates are virtual until the user confirms one.
  final bool requiresConfirmation;
}

/// Calculates dates only. It never writes a Task or materializes a candidate.
class GetRoutineOccurrences {
  const GetRoutineOccurrences();

  Result<List<RoutineOccurrence>> call(
    RoutineRule rule, {
    required DateTime from,
    required DateTime through,
    Set<DateTime> alreadyAdded = const {},
  }) {
    final validation = rule.validate();
    if (validation != null) return fail(validation);

    final firstRequested = _dateOnly(from);
    final lastRequested = _dateOnly(through);
    if (lastRequested.isBefore(firstRequested)) {
      return fail(const ValidationFailure('조회 종료일은 시작일보다 빠를 수 없습니다.'));
    }

    final first = firstRequested.isBefore(rule.startDate)
        ? rule.startDate
        : firstRequested;
    final last = rule.endDate != null && lastRequested.isAfter(rule.endDate!)
        ? rule.endDate!
        : lastRequested;
    if (first.isAfter(last)) return success(const []);

    final excluded = alreadyAdded.map(_dateOnly).toSet();
    final occurrences = <RoutineOccurrence>[];
    for (var date = first;
        !date.isAfter(last);
        date = DateTime(date.year, date.month, date.day + 1)) {
      if (!_matches(rule, date) || excluded.contains(date)) continue;
      occurrences.add(RoutineOccurrence(
        routineId: rule.id,
        date: date,
        requiresConfirmation: rule.creationMode == RoutineCreationMode.manual,
      ));
    }
    return success(List.unmodifiable(occurrences));
  }
}

bool _matches(RoutineRule rule, DateTime date) {
  final unit = switch (rule.frequency) {
    RoutineFrequency.daily => RoutineIntervalUnit.day,
    RoutineFrequency.weekly => RoutineIntervalUnit.week,
    RoutineFrequency.monthly => RoutineIntervalUnit.month,
    RoutineFrequency.yearly => RoutineIntervalUnit.year,
    RoutineFrequency.custom => rule.customUnit!,
  };
  final interval = rule.interval;
  final start = rule.startDate;
  return switch (unit) {
    RoutineIntervalUnit.day => _daysBetween(start, date) % interval == 0,
    RoutineIntervalUnit.week => rule.weekdays.isEmpty
        ? date.weekday == start.weekday &&
            _weeksBetween(start, date) % interval == 0
        : rule.weekdays.contains(date.weekday) &&
            _weeksBetween(start, date) % interval == 0,
    RoutineIntervalUnit.month => _monthsBetween(start, date) % interval == 0 &&
        date.day == _clampedDay(start.day, date.year, date.month),
    RoutineIntervalUnit.year => (date.year - start.year) % interval == 0 &&
        date.month == start.month &&
        date.day == _clampedDay(start.day, date.year, date.month),
  };
}

DateTime _dateOnly(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}

int _daysBetween(DateTime first, DateTime last) => DateTime.utc(
      last.year,
      last.month,
      last.day,
    ).difference(DateTime.utc(first.year, first.month, first.day)).inDays;

int _weeksBetween(DateTime first, DateTime last) {
  final firstMonday =
      DateTime(first.year, first.month, first.day - first.weekday + 1);
  final lastMonday =
      DateTime(last.year, last.month, last.day - last.weekday + 1);
  return _daysBetween(firstMonday, lastMonday) ~/ 7;
}

int _monthsBetween(DateTime first, DateTime last) =>
    (last.year - first.year) * 12 + last.month - first.month;

int _clampedDay(int originalDay, int year, int month) {
  final lastDay = DateTime(year, month + 1, 0).day;
  return originalDay < lastDay ? originalDay : lastDay;
}
