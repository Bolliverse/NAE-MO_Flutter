import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nae_mo/core/providers/selected_date_provider.dart';
import 'package:nae_mo/features/calendar/domain/entities/today_overview.dart';
import 'package:nae_mo/features/calendar/domain/entities/week_overview.dart';
import 'package:nae_mo/features/calendar/domain/usecases/get_week_overview_use_case.dart';

final weekOverviewProvider =
    FutureProvider.autoDispose<WeekOverview>((ref) async {
  final start = ref.watch(selectedDateProvider.select(weekStartFor));
  final result = await ref.watch(getWeekOverviewUseCaseProvider)(start);
  if (result.failure != null) throw result.failure!;
  return result.data!;
});

class WeekViewPage extends ConsumerWidget {
  const WeekViewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedDateProvider).toLocal();
    final start = weekStartFor(selected);
    final end = calendarDayOffset(start, 6);
    final overview = ref.watch(weekOverviewProvider);
    final today = DateTime.now();
    void move(int days) => ref
        .read(selectedDateProvider.notifier)
        .select(calendarDayOffset(selected, days));
    final range = start.year == end.year
        ? '${start.year}년 ${start.month}/${start.day} – ${end.month}/${end.day}'
        : '${start.year}/${start.month}/${start.day} – ${end.year}/${end.month}/${end.day}';

    return Center(
        child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720),
      child: ColoredBox(
          color: Colors.white,
          child: Column(children: [
            Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Row(children: [
                  IconButton(
                      key: const Key('weekPrevious'),
                      tooltip: '이전 주',
                      onPressed: () => move(-7),
                      icon: const Icon(Icons.chevron_left)),
                  Expanded(
                      child: Semantics(
                          header: true,
                          liveRegion: true,
                          child: Text(range,
                              key: const Key('weekRange'),
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700)))),
                  IconButton(
                      key: const Key('weekNext'),
                      tooltip: '다음 주',
                      onPressed: () => move(7),
                      icon: const Icon(Icons.chevron_right)),
                ])),
            Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                    key: const Key('weekToday'),
                    onPressed: () =>
                        ref.read(selectedDateProvider.notifier).goToToday(),
                    style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF2E4175)),
                    child: const Text('오늘'))),
            const Divider(height: 1, color: Color(0xFFE4E7EC)),
            Expanded(
                child: overview.when(
              skipLoadingOnRefresh: false,
              skipLoadingOnReload: false,
              loading: () => const Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFF2E4175),
                      semanticsLabel: '주간 일정 불러오는 중')),
              error: (_, __) => Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('주간 일정을 불러오지 못했습니다.'),
                TextButton(
                    key: const Key('weekRetry'),
                    onPressed: () => ref.invalidate(weekOverviewProvider),
                    style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF2E4175)),
                    child: const Text('다시 시도')),
              ])),
              data: (week) => ListView.separated(
                key: const Key('weekDays'),
                padding: const EdgeInsets.only(bottom: 100),
                itemCount: week.days.length,
                separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    indent: 20,
                    endIndent: 20,
                    color: Color(0xFFEEEEEE)),
                itemBuilder: (context, index) {
                  final day = week.days[index];
                  return _DayRow(
                      day: day,
                      isToday: _sameDate(day.date, today),
                      isSelected: _sameDate(day.date, selected),
                      onTap: () {
                        ref
                            .read(selectedDateProvider.notifier)
                            .select(day.date);
                        context.go('/calendar/today');
                      });
                },
              ),
            )),
          ])),
    ));
  }
}

bool _sameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

class _DayRow extends StatelessWidget {
  const _DayRow(
      {required this.day,
      required this.isToday,
      required this.isSelected,
      required this.onTap});
  final WeekDaySummary day;
  final bool isToday;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final date = day.date;
    final tags = [if (isToday) '오늘', if (isSelected) '선택'];
    return Semantics(
      key: Key('weekDay-${date.year}-${date.month}-${date.day}'),
      button: true,
      selected: isSelected,
      label:
          '${date.month}월 ${date.day}일 ${weekdays[date.weekday - 1]}요일, ${tags.join(', ')}',
      child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(
                  width: 60,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${date.month}/${date.day}',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF202124))),
                        Text(weekdays[date.weekday - 1],
                            style: const TextStyle(color: Color(0xFF667085))),
                        if (tags.isNotEmpty)
                          Text(tags.join(' · '),
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF2E4175),
                                  fontWeight: FontWeight.w600)),
                      ])),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    for (final event in day.events) _EntrySummary(entry: event),
                    if (day.firstTodo != null)
                      _EntrySummary(entry: day.firstTodo!),
                    if (day.eventCount == 0 && day.todoCount == 0)
                      const Text('—',
                          style: TextStyle(color: Color(0xFF98A2B3))),
                    if (day.eventCount > 0 || day.todoCount > 0)
                      Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                              [
                                if (day.eventCount > 0) '일정 ${day.eventCount}',
                                if (day.todoCount > 0)
                                  'Todo ${day.completedTodoCount}/${day.todoCount} 완료',
                              ].join(' · '),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: const Color(0xFF667085)))),
                  ])),
              const Icon(Icons.chevron_right,
                  size: 18, color: Color(0xFF98A2B3)),
            ]),
          )),
    );
  }
}

class _EntrySummary extends StatelessWidget {
  const _EntrySummary({required this.entry});
  final TodayEntry entry;

  @override
  Widget build(BuildContext context) {
    final task = entry.task;
    final color = Color(entry.category?.color ?? 0xFF98A2B3).withAlpha(255);
    String time(DateTime date) {
      final local = date.toLocal();
      return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    }

    final prefix = task.isAllDay
        ? '종일 '
        : task.hasTime && task.startDateTime != null
            ? '${time(task.startDateTime!)}${task.endDateTime == null ? '' : '–${time(task.endDateTime!)}'} '
            : '';
    return Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
                padding: const EdgeInsets.only(top: 5, right: 8),
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: task.isTodo ? BoxShape.rectangle : BoxShape.circle,
                    color: task.isTodo ? Colors.white : color,
                    border:
                        task.isTodo ? Border.all(color: color, width: 2) : null,
                  ),
                )),
            Expanded(
                child: Text('$prefix${task.title}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: const Color(0xFF202124)))),
          ],
        ));
  }
}
