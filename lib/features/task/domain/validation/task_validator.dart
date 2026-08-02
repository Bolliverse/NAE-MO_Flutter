import 'package:nae_mo/core/errors/failure.dart';
import 'package:nae_mo/features/task/domain/entities/task.dart';

class TaskDraft {
  final TaskKind kind;
  final DateTime targetDate;
  final bool isCompleted;
  final bool hasTime;
  final DateTime? startDateTime;
  final DateTime? endDateTime;
  final bool isAllDay;

  const TaskDraft({
    required this.kind,
    required this.targetDate,
    required this.isCompleted,
    required this.hasTime,
    required this.startDateTime,
    required this.endDateTime,
    required this.isAllDay,
  });
}

abstract final class TaskValidator {
  static ValidationFailure? validate(TaskDraft draft) {
    final targetDate = draft.targetDate;
    if (targetDate.isUtc ||
        targetDate.hour != 0 ||
        targetDate.minute != 0 ||
        targetDate.second != 0 ||
        targetDate.millisecond != 0 ||
        targetDate.microsecond != 0) {
      return const ValidationFailure('대상 날짜는 자정으로 정규화되어야 합니다.');
    }

    if (draft.isAllDay && draft.kind != TaskKind.event) {
      return const ValidationFailure('종일 항목은 일정만 사용할 수 있습니다.');
    }

    if (draft.kind == TaskKind.event && draft.isCompleted) {
      return const ValidationFailure('일정은 완료 상태를 사용할 수 없습니다.');
    }

    if (draft.kind == TaskKind.event && !draft.hasTime && !draft.isAllDay) {
      return const ValidationFailure('일정은 시간 또는 종일 설정이 필요합니다.');
    }

    if (draft.isAllDay &&
        (draft.startDateTime != null || draft.endDateTime != null)) {
      return const ValidationFailure('종일 항목은 시간 범위를 사용할 수 없습니다.');
    }

    final startDateTime = draft.startDateTime;
    final endDateTime = draft.endDateTime;
    if (draft.hasTime && (startDateTime == null || endDateTime == null)) {
      return const ValidationFailure('시간 지정 항목은 시작과 종료 시각이 필요합니다.');
    }

    if (!draft.hasTime && (startDateTime != null || endDateTime != null)) {
      return const ValidationFailure('시간 미지정 항목은 시작과 종료 시각을 가질 수 없습니다.');
    }

    if (startDateTime != null &&
        endDateTime != null &&
        !endDateTime.isAfter(startDateTime)) {
      return const ValidationFailure('종료 시각은 시작 시각보다 늦어야 합니다.');
    }

    if (startDateTime != null) {
      final localStart = startDateTime.toLocal();
      if (localStart.year != targetDate.year ||
          localStart.month != targetDate.month ||
          localStart.day != targetDate.day) {
        return const ValidationFailure('시작 시각의 날짜는 대상 날짜와 같아야 합니다.');
      }
    }

    return null;
  }
}
