import 'package:nae_mo/features/calendar/domain/entities/today_overview.dart';

class TodayState {
  final TodayOverview overview;
  final bool isOverdueExpanded;
  final bool isCompletedExpanded;
  final Set<String> pendingTodoIds;

  TodayState({
    required this.overview,
    this.isOverdueExpanded = false,
    this.isCompletedExpanded = false,
    Set<String> pendingTodoIds = const {},
  }) : pendingTodoIds = Set.unmodifiable(pendingTodoIds);

  TodayState copyWith({
    TodayOverview? overview,
    bool? isOverdueExpanded,
    bool? isCompletedExpanded,
    Set<String>? pendingTodoIds,
  }) {
    return TodayState(
      overview: overview ?? this.overview,
      isOverdueExpanded: isOverdueExpanded ?? this.isOverdueExpanded,
      isCompletedExpanded: isCompletedExpanded ?? this.isCompletedExpanded,
      pendingTodoIds: Set.unmodifiable(
        pendingTodoIds ?? this.pendingTodoIds,
      ),
    );
  }
}
