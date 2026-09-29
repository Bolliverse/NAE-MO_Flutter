import 'package:flutter_test/flutter_test.dart';
import 'package:nae_mo/core/errors/failure.dart';
import 'package:nae_mo/features/routine/domain/entities/routine_rule.dart';
import 'package:nae_mo/features/routine/domain/usecases/get_routine_occurrences.dart';

void main() {
  const getOccurrences = GetRoutineOccurrences();

  test('bounded daily automatic rule includes start and end dates', () {
    final rule = _rule(
      start: DateTime(2026, 9, 18),
      end: DateTime(2026, 9, 20),
      mode: RoutineCreationMode.automatic,
    );
    final result = getOccurrences(
      rule,
      from: DateTime(2026, 9, 1),
      through: DateTime(2026, 10, 1),
    );
    expect(result.failure, isNull);
    expect(_dates(result.data!), [
      DateTime(2026, 9, 18),
      DateTime(2026, 9, 19),
      DateTime(2026, 9, 20),
    ]);
    expect(
        result.data!.every((occurrence) =>
            occurrence.routineId == 'routine-1' &&
            !occurrence.requiresConfirmation),
        isTrue);
    expect(() => result.data!.clear(), throwsUnsupportedError);
  });

  test(
      'unbounded manual rule yields virtual candidates without persisting them',
      () {
    final rule = _rule(start: DateTime(2026, 9, 18));
    final first = getOccurrences(rule,
        from: DateTime(2026, 9, 17), through: DateTime(2026, 9, 20));
    final reopened = getOccurrences(rule,
        from: DateTime(2026, 9, 17), through: DateTime(2026, 9, 20));
    expect(_dates(first.data!), _dates(reopened.data!));
    expect(_dates(first.data!), [
      DateTime(2026, 9, 18),
      DateTime(2026, 9, 19),
      DateTime(2026, 9, 20),
    ]);
    expect(first.data!.every((occurrence) => occurrence.requiresConfirmation),
        isTrue);
    final confirmed = getOccurrences(rule,
        from: DateTime(2026, 9, 17),
        through: DateTime(2026, 9, 20),
        alreadyAdded: {DateTime(2026, 9, 19, 13)});
    expect(_dates(confirmed.data!),
        [DateTime(2026, 9, 18), DateTime(2026, 9, 20)]);
  });

  test('weekly rule supports all seven weekdays including weekends', () {
    final rule = _rule(
      start: DateTime(2026, 9, 16),
      frequency: RoutineFrequency.weekly,
      weekdays: {1, 2, 3, 4, 5, 6, 7},
    );
    final result = getOccurrences(rule,
        from: DateTime(2026, 9, 14), through: DateTime(2026, 9, 22));
    expect(_dates(result.data!), [
      for (var day = 16; day <= 22; day++) DateTime(2026, 9, day),
    ]);
    expect(_dates(result.data!).contains(DateTime(2026, 9, 19)), isTrue);
    expect(_dates(result.data!).contains(DateTime(2026, 9, 20)), isTrue);
  });

  test('weekly default repeats the original weekday across months', () {
    final rule =
        _rule(start: DateTime(2026, 9, 30), frequency: RoutineFrequency.weekly);
    expect(
        _dates(getOccurrences(rule,
                from: DateTime(2026, 9, 28), through: DateTime(2026, 10, 15))
            .data!),
        [
          DateTime(2026, 9, 30),
          DateTime(2026, 10, 7),
          DateTime(2026, 10, 14),
        ]);
  });

  test('custom interval supports day and anchored multi-week cadence', () {
    final everyOtherDay = _rule(
        start: DateTime(2026, 9, 30),
        frequency: RoutineFrequency.custom,
        interval: 2,
        customUnit: RoutineIntervalUnit.day);
    expect(
        _dates(getOccurrences(everyOtherDay,
                from: DateTime(2026, 9, 30), through: DateTime(2026, 10, 6))
            .data!),
        [
          DateTime(2026, 9, 30),
          DateTime(2026, 10, 2),
          DateTime(2026, 10, 4),
          DateTime(2026, 10, 6),
        ]);
    final alternateWeeks = _rule(
        start: DateTime(2026, 9, 16),
        frequency: RoutineFrequency.custom,
        interval: 2,
        customUnit: RoutineIntervalUnit.week,
        weekdays: {DateTime.monday, DateTime.friday});
    expect(
        _dates(getOccurrences(alternateWeeks,
                from: DateTime(2026, 9, 14), through: DateTime(2026, 10, 4))
            .data!),
        [
          DateTime(2026, 9, 18),
          DateTime(2026, 9, 28),
          DateTime(2026, 10, 2),
        ]);
  });

  test('monthly and yearly recurrence clamp invalid day to month end', () {
    final monthly = _rule(
        start: DateTime(2026, 1, 31), frequency: RoutineFrequency.monthly);
    expect(
        _dates(getOccurrences(monthly,
                from: DateTime(2026, 1), through: DateTime(2026, 4, 30))
            .data!),
        [
          DateTime(2026, 1, 31),
          DateTime(2026, 2, 28),
          DateTime(2026, 3, 31),
          DateTime(2026, 4, 30),
        ]);
    final alternateMonths = _rule(
        start: DateTime(2026, 1, 31),
        frequency: RoutineFrequency.custom,
        interval: 2,
        customUnit: RoutineIntervalUnit.month);
    expect(
        _dates(getOccurrences(alternateMonths,
                from: DateTime(2026, 1), through: DateTime(2026, 5, 31))
            .data!),
        [
          DateTime(2026, 1, 31),
          DateTime(2026, 3, 31),
          DateTime(2026, 5, 31),
        ]);
    final leapDay =
        _rule(start: DateTime(2024, 2, 29), frequency: RoutineFrequency.yearly);
    expect(
        _dates(getOccurrences(leapDay,
                from: DateTime(2024, 1), through: DateTime(2028, 12, 31))
            .data!),
        [
          DateTime(2024, 2, 29),
          DateTime(2025, 2, 28),
          DateTime(2026, 2, 28),
          DateTime(2027, 2, 28),
          DateTime(2028, 2, 29),
        ]);
    final alternateYears = _rule(
        start: DateTime(2024, 2, 29),
        frequency: RoutineFrequency.custom,
        interval: 2,
        customUnit: RoutineIntervalUnit.year);
    expect(
        _dates(getOccurrences(alternateYears,
                from: DateTime(2024, 1), through: DateTime(2028, 12, 31))
            .data!),
        [
          DateTime(2024, 2, 29),
          DateTime(2026, 2, 28),
          DateTime(2028, 2, 29),
        ]);
  });

  test('bounds and excluded dates work for dates outside the requested range',
      () {
    final rule =
        _rule(start: DateTime(2026, 9, 18), end: DateTime(2026, 9, 21));
    expect(
        _dates(getOccurrences(rule,
            from: DateTime(2026, 9, 20, 12),
            through: DateTime(2026, 10, 4),
            alreadyAdded: {DateTime(2026, 9, 20)}).data!),
        [DateTime(2026, 9, 21)]);
    expect(
        getOccurrences(rule,
                from: DateTime(2026, 10), through: DateTime(2026, 10, 2))
            .data,
        isEmpty);
  });

  test('invalid rules and reversed query windows return validation failures',
      () {
    final invalid = [
      _rule(
          start: DateTime(2026, 9, 18),
          end: null,
          mode: RoutineCreationMode.automatic),
      _rule(start: DateTime.utc(2026, 9, 18)),
      _rule(start: DateTime(2026, 9, 18, 9)),
      _rule(start: DateTime(2026, 9, 18), end: DateTime(2026, 9, 17)),
      _rule(
          start: DateTime(2026, 9, 18),
          frequency: RoutineFrequency.custom,
          interval: 0,
          customUnit: RoutineIntervalUnit.day),
      _rule(start: DateTime(2026, 9, 18), frequency: RoutineFrequency.custom),
      _rule(
          start: DateTime(2026, 9, 18),
          frequency: RoutineFrequency.weekly,
          weekdays: {0, 8}),
      _rule(start: DateTime(2026, 9, 18), weekdays: {1}),
      _rule(
          start: DateTime(2026, 9, 18),
          frequency: RoutineFrequency.daily,
          interval: 2),
    ];
    for (final rule in invalid) {
      expect(
          getOccurrences(rule,
                  from: DateTime(2026, 9), through: DateTime(2026, 10))
              .failure,
          isA<ValidationFailure>());
    }
    expect(
        getOccurrences(_rule(start: DateTime(2026, 9, 18)),
                from: DateTime(2026, 10, 2), through: DateTime(2026, 10, 1))
            .failure,
        isA<ValidationFailure>());
  });

  test('rule weekday inputs and returned occurrences cannot be mutated', () {
    final weekdays = <int>{DateTime.saturday, DateTime.sunday};
    final rule = _rule(
        start: DateTime(2026, 9, 18),
        frequency: RoutineFrequency.weekly,
        weekdays: weekdays);
    weekdays.clear();
    expect(rule.weekdays, {DateTime.saturday, DateTime.sunday});
    expect(() => rule.weekdays.add(DateTime.monday), throwsUnsupportedError);
    final dates = getOccurrences(rule,
            from: DateTime(2026, 9, 18), through: DateTime(2026, 9, 20))
        .data!;
    expect(_dates(dates), [DateTime(2026, 9, 19), DateTime(2026, 9, 20)]);
  });
}

List<DateTime> _dates(List<RoutineOccurrence> values) =>
    values.map((occurrence) => occurrence.date).toList();

RoutineRule _rule({
  required DateTime start,
  DateTime? end,
  RoutineFrequency frequency = RoutineFrequency.daily,
  RoutineCreationMode mode = RoutineCreationMode.manual,
  int interval = 1,
  RoutineIntervalUnit? customUnit,
  Set<int> weekdays = const {},
}) =>
    RoutineRule(
      id: 'routine-1',
      startDate: start,
      endDate: end,
      frequency: frequency,
      creationMode: mode,
      interval: interval,
      customUnit: customUnit,
      weekdays: weekdays,
    );
