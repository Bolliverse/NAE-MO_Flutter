import 'package:nae_mo/features/calendar/domain/entities/today_overview.dart';
import 'package:nae_mo/features/routine/domain/usecases/manual_routine_candidates.dart';

class TodayState {
  final TodayOverview overview;
  final bool isOverdueExpanded;
  final bool isCompletedExpanded;
  final Set<String> pendingTodoIds;
  final List<ManualRoutineCandidate> manualRoutineCandidates;
  final Set<String> pendingRoutineIds;

  TodayState({
    required this.overview,
    this.isOverdueExpanded = false,
    this.isCompletedExpanded = false,
    Set<String> pendingTodoIds = const {},
    this.manualRoutineCandidates = const [],
    Set<String> pendingRoutineIds = const {},
  })  : pendingTodoIds = Set.unmodifiable(pendingTodoIds),
        pendingRoutineIds = Set.unmodifiable(pendingRoutineIds);

  TodayState copyWith({
    TodayOverview? overview,
    bool? isOverdueExpanded,
    bool? isCompletedExpanded,
    Set<String>? pendingTodoIds,
    List<ManualRoutineCandidate>? manualRoutineCandidates,
    Set<String>? pendingRoutineIds,
  }) {
    return TodayState(
      overview: overview ?? this.overview,
      isOverdueExpanded: isOverdueExpanded ?? this.isOverdueExpanded,
      isCompletedExpanded: isCompletedExpanded ?? this.isCompletedExpanded,
      pendingTodoIds: Set.unmodifiable(
        pendingTodoIds ?? this.pendingTodoIds,
      ),
      manualRoutineCandidates:
          manualRoutineCandidates ?? this.manualRoutineCandidates,
      pendingRoutineIds: pendingRoutineIds ?? this.pendingRoutineIds,
    );
  }
}
