import 'package:nae_mo/core/errors/failure.dart';
import 'package:nae_mo/features/routine/domain/entities/routine_rule.dart';
import 'package:nae_mo/features/task/domain/entities/task.dart';

/// A persisted template. Its rule produces dates; it does not itself create Tasks.
class RoutineDefinition {
  const RoutineDefinition({
    required this.rule,
    required this.title,
    required this.kind,
    this.categoryId,
    this.hasTime = false,
    this.isAllDay = false,
    this.startMinute,
    this.endMinute,
  });

  final RoutineRule rule;
  final String title;
  final TaskKind kind;
  final String? categoryId;
  final bool hasTime;
  final bool isAllDay;
  final int? startMinute;
  final int? endMinute;

  String get id => rule.id;

  ValidationFailure? validate() {
    final ruleFailure = rule.validate();
    if (ruleFailure != null) return ruleFailure;
    if (title.trim().isEmpty) {
      return const ValidationFailure('루틴 제목을 입력해 주세요.');
    }
    if (kind == TaskKind.todo && isAllDay) {
      return const ValidationFailure('Todo 루틴은 종일로 설정할 수 없습니다.');
    }
    if (kind == TaskKind.event && !isAllDay && !hasTime) {
      return const ValidationFailure('일정 루틴은 시간 또는 종일 설정이 필요합니다.');
    }
    if (isAllDay && hasTime) {
      return const ValidationFailure('종일 루틴에는 시간을 지정할 수 없습니다.');
    }
    if (hasTime) {
      final start = startMinute;
      final end = endMinute;
      if (start == null ||
          end == null ||
          start < 0 ||
          start >= 1440 ||
          end <= start ||
          end > 1440) {
        return const ValidationFailure('시작·종료 시간을 확인해 주세요.');
      }
    } else if (startMinute != null || endMinute != null) {
      return const ValidationFailure('시간 없는 루틴에는 시간 범위를 지정할 수 없습니다.');
    }
    return null;
  }
}
