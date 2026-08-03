import 'package:flutter_test/flutter_test.dart';
import 'package:nae_mo/core/errors/failure.dart';
import 'package:nae_mo/features/task/domain/entities/task.dart';
import 'package:nae_mo/features/task/domain/validation/task_validator.dart';

void main() {
  group('TaskValidator', () {
    test('returns null for a valid default draft', () {
      expect(TaskValidator.validate(_draft()), isNull);
    });

    test('returns null for a valid timed event', () {
      final failure = TaskValidator.validate(
        _draft(
          kind: TaskKind.event,
          hasTime: true,
          startDateTime: DateTime(2026, 7, 31, 9),
          endDateTime: DateTime(2026, 7, 31, 10),
        ),
      );

      expect(failure, isNull);
    });

    test('returns null for a valid all-day event', () {
      final failure = TaskValidator.validate(
        _draft(kind: TaskKind.event, isAllDay: true),
      );

      expect(failure, isNull);
    });

    group('target date', () {
      test('rejects a non-midnight target date', () {
        final failure = TaskValidator.validate(
          _draft(targetDate: DateTime(2026, 7, 31, 1)),
        );

        expect(failure, const ValidationFailure('대상 날짜는 자정으로 정규화되어야 합니다.'));
      });

      test('rejects UTC midnight because target date must be local', () {
        final failure = TaskValidator.validate(
          _draft(targetDate: DateTime.utc(2026, 7, 31)),
        );

        expect(failure, const ValidationFailure('대상 날짜는 자정으로 정규화되어야 합니다.'));
      });

      test('requires every sub-day component to be zero', () {
        final invalidDates = <DateTime>[
          DateTime(2026, 7, 31, 1),
          DateTime(2026, 7, 31, 0, 1),
          DateTime(2026, 7, 31, 0, 0, 1),
          DateTime(2026, 7, 31, 0, 0, 0, 1),
          DateTime(2026, 7, 31, 0, 0, 0, 0, 1),
        ];

        for (final targetDate in invalidDates) {
          expect(
            TaskValidator.validate(_draft(targetDate: targetDate)),
            const ValidationFailure('대상 날짜는 자정으로 정규화되어야 합니다.'),
            reason: '$targetDate must not be accepted as local midnight',
          );
        }
      });

      test('target date validation takes precedence over later rules', () {
        final failure = TaskValidator.validate(
          _draft(
            targetDate: DateTime(2026, 7, 31, 1),
            kind: TaskKind.event,
            isCompleted: true,
          ),
        );

        expect(failure, const ValidationFailure('대상 날짜는 자정으로 정규화되어야 합니다.'));
      });
    });

    test('rejects an all-day todo', () {
      final failure = TaskValidator.validate(_draft(isAllDay: true));

      expect(failure, const ValidationFailure('종일 항목은 일정만 사용할 수 있습니다.'));
    });

    test('rejects a completed event', () {
      final failure = TaskValidator.validate(
        _draft(
          kind: TaskKind.event,
          isCompleted: true,
          isAllDay: true,
        ),
      );

      expect(failure, const ValidationFailure('일정은 완료 상태를 사용할 수 없습니다.'));
    });

    test('rejects an event with neither a time nor all-day status', () {
      final failure = TaskValidator.validate(_draft(kind: TaskKind.event));

      expect(failure, const ValidationFailure('일정은 시간 또는 종일 설정이 필요합니다.'));
    });

    test('event completion validation precedes the event scheduling rule', () {
      final failure = TaskValidator.validate(
        _draft(kind: TaskKind.event, isCompleted: true),
      );

      expect(failure, const ValidationFailure('일정은 완료 상태를 사용할 수 없습니다.'));
    });

    test('rejects a time range on an all-day item', () {
      final failure = TaskValidator.validate(
        _draft(
          kind: TaskKind.event,
          isAllDay: true,
          startDateTime: DateTime(2026, 7, 31, 9),
          endDateTime: DateTime(2026, 7, 31, 10),
        ),
      );

      expect(failure, const ValidationFailure('종일 항목은 시간 범위를 사용할 수 없습니다.'));
    });

    test('returns the first failure when later scheduling rules overlap', () {
      final cases = <({TaskDraft draft, String expectedMessage})>[
        (
          draft: _draft(
            kind: TaskKind.event,
            isAllDay: true,
            hasTime: true,
            startDateTime: DateTime(2026, 7, 31, 9),
          ),
          expectedMessage: '종일 항목은 시간 범위를 사용할 수 없습니다.',
        ),
        (
          draft: _draft(
            kind: TaskKind.event,
            startDateTime: DateTime(2026, 7, 31, 9),
          ),
          expectedMessage: '일정은 시간 또는 종일 설정이 필요합니다.',
        ),
        (
          draft: _draft(
            startDateTime: DateTime(2026, 7, 31, 9),
            endDateTime: DateTime(2026, 7, 31, 9),
          ),
          expectedMessage: '시간 미지정 항목은 시작과 종료 시각을 가질 수 없습니다.',
        ),
      ];

      for (final validationCase in cases) {
        expect(
          TaskValidator.validate(validationCase.draft),
          ValidationFailure(validationCase.expectedMessage),
        );
      }
    });

    test('rejects hasTime true without both timestamps', () {
      final drafts = <TaskDraft>[
        _draft(hasTime: true),
        _draft(
          hasTime: true,
          startDateTime: DateTime(2026, 7, 31, 9),
        ),
        _draft(
          hasTime: true,
          endDateTime: DateTime(2026, 7, 31, 10),
        ),
      ];

      for (final draft in drafts) {
        expect(
          TaskValidator.validate(draft),
          const ValidationFailure('시간 지정 항목은 시작과 종료 시각이 필요합니다.'),
        );
      }
    });

    test('rejects time fields on an untimed item', () {
      final drafts = <TaskDraft>[
        _draft(startDateTime: DateTime(2026, 7, 31, 9)),
        _draft(endDateTime: DateTime(2026, 7, 31, 10)),
        _draft(
          startDateTime: DateTime(2026, 7, 31, 9),
          endDateTime: DateTime(2026, 7, 31, 10),
        ),
      ];

      for (final draft in drafts) {
        expect(
          TaskValidator.validate(draft),
          const ValidationFailure('시간 미지정 항목은 시작과 종료 시각을 가질 수 없습니다.'),
        );
      }
    });

    test('rejects equal or decreasing time ranges', () {
      final start = DateTime(2026, 7, 31, 9);
      final drafts = <TaskDraft>[
        _draft(hasTime: true, startDateTime: start, endDateTime: start),
        _draft(
          hasTime: true,
          startDateTime: start,
          endDateTime: start.subtract(const Duration(minutes: 1)),
        ),
      ];

      for (final draft in drafts) {
        expect(
          TaskValidator.validate(draft),
          const ValidationFailure('종료 시각은 시작 시각보다 늦어야 합니다.'),
        );
      }
    });

    test('rejects a start whose local date differs from targetDate', () {
      final failure = TaskValidator.validate(
        _draft(
          hasTime: true,
          startDateTime: DateTime(2026, 8, 1, 9),
          endDateTime: DateTime(2026, 8, 1, 10),
        ),
      );

      expect(failure, const ValidationFailure('시작 시각의 날짜는 대상 날짜와 같아야 합니다.'));
    });

    test('compares the local date of a UTC start with targetDate', () {
      final localStart = DateTime(2026, 7, 31, 9);
      final failure = TaskValidator.validate(
        _draft(
          hasTime: true,
          startDateTime: localStart.toUtc(),
          endDateTime: localStart.add(const Duration(hours: 1)).toUtc(),
        ),
      );

      expect(failure, isNull);
    });
  });
}

TaskDraft _draft({
  TaskKind kind = TaskKind.todo,
  DateTime? targetDate,
  bool isCompleted = false,
  bool hasTime = false,
  DateTime? startDateTime,
  DateTime? endDateTime,
  bool isAllDay = false,
}) {
  return TaskDraft(
    kind: kind,
    targetDate: targetDate ?? DateTime(2026, 7, 31),
    isCompleted: isCompleted,
    hasTime: hasTime,
    startDateTime: startDateTime,
    endDateTime: endDateTime,
    isAllDay: isAllDay,
  );
}
