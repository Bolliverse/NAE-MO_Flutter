import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nae_mo/features/calendar/presentation/states/day_view_state.dart';
import 'package:nae_mo/features/calendar/presentation/states/task_dock_state.dart';
import 'package:nae_mo/features/calendar/presentation/viewmodels/day_view_viewmodel.dart';
import 'package:nae_mo/features/calendar/presentation/viewmodels/task_dock_viewmodel.dart';

class DayViewPage extends ConsumerWidget {
  const DayViewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dayAsync = ref.watch(dayViewViewModelProvider);
    final dockState = ref.watch(taskDockViewModelProvider);

    return Column(
      children: [
        // AllDayEventBar — 3-H에서 구현
        Expanded(
          child: Row(
            children: [
              // Task Dock — 3-D에서 실제 위젯으로 교체
              _TaskDockPlaceholder(state: dockState),
              const VerticalDivider(width: 1),
              // Timeline — 3-B에서 실제 위젯으로 교체
              Expanded(
                child: dayAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Text(
                      '데이터를 불러올 수 없습니다.\n$e',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  data: (data) => _TimelinePlaceholder(state: data),
                ),
              ),
            ],
          ),
        ),
        // QuickAddInput — 3-I에서 구현
      ],
    );
  }
}

// ── Task Dock 임시 플레이스홀더 (3-D에서 교체) ──────────────────
class _TaskDockPlaceholder extends StatelessWidget {
  final TaskDockState state;
  const _TaskDockPlaceholder({required this.state});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Text(
              'Task Dock',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ),
          const Divider(height: 1),
          if (state.isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (state.failure != null)
            Expanded(
              child: Center(
                child: Text(
                  '오류 발생',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: Center(
                child: Text(
                  '미배정: ${state.unscheduledTasks.length}\n완료: ${state.completedTasks.length}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Timeline 임시 플레이스홀더 (3-B에서 교체) ───────────────────
class _TimelinePlaceholder extends StatelessWidget {
  final DayViewState state;
  const _TimelinePlaceholder({required this.state});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_today,
            size: 48,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            DateFormat('yyyy년 M월 d일 (E)', 'ko').format(state.date),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            '스케줄된 태스크: ${state.scheduledTasks.length}개\nTimeline — 3-B에서 구현됩니다.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }
}
