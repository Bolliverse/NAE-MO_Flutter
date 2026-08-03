import 'package:flutter_test/flutter_test.dart';
import 'package:nae_mo/features/calendar/domain/entities/today_overview.dart';
import 'package:nae_mo/features/calendar/presentation/states/today_state.dart';

void main() {
  final overview = TodayOverview(
    date: DateTime(2026, 8, 3),
    overdueTodos: const [],
    allDayEvents: const [],
    timelineItems: const [],
    untimedTodos: const [],
    completedTodos: const [],
  );

  group('TodayState', () {
    test('defaults collapsible sections and pending todo IDs', () {
      final state = TodayState(overview: overview);

      expect(state.overview, same(overview));
      expect(state.isOverdueExpanded, isFalse);
      expect(state.isCompletedExpanded, isFalse);
      expect(state.pendingTodoIds, isEmpty);
    });

    test('copyWith changes only requested fields and freezes pending IDs', () {
      final state = TodayState(
        overview: overview,
        isCompletedExpanded: true,
      );
      final pendingTodoIds = <String>{'todo-1'};

      final updated = state.copyWith(
        isOverdueExpanded: true,
        pendingTodoIds: pendingTodoIds,
      );
      pendingTodoIds.add('todo-2');

      expect(updated.overview, same(overview));
      expect(updated.isOverdueExpanded, isTrue);
      expect(updated.isCompletedExpanded, isTrue);
      expect(updated.pendingTodoIds, {'todo-1'});
      expect(
        () => updated.pendingTodoIds.add('todo-3'),
        throwsUnsupportedError,
      );
    });
  });
}
