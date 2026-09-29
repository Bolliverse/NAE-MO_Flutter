import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nae_mo/core/providers/selected_date_provider.dart';
import 'package:nae_mo/features/calendar/domain/entities/month_overview.dart';
import 'package:nae_mo/features/calendar/domain/entities/today_overview.dart';
import 'package:nae_mo/features/calendar/domain/usecases/get_month_overview_use_case.dart';

const _navy = Color(0xFF2E4175);
const _muted = Color(0xFF667085);
const _line = Color(0xFFE4E7EC);

final monthOverviewProvider =
    FutureProvider.autoDispose<MonthOverview>((ref) async {
  final month = ref.watch(selectedDateProvider.select(monthStartFor));
  final result = await ref.watch(getMonthOverviewUseCaseProvider)(month);
  if (result.failure != null) throw result.failure!;
  return result.data!;
});

class MonthViewPage extends ConsumerStatefulWidget {
  const MonthViewPage({super.key});

  @override
  ConsumerState<MonthViewPage> createState() => _MonthViewPageState();
}

class _MonthViewPageState extends ConsumerState<MonthViewPage> {
  DateTime? _lastTappedDate;

  void _moveMonth(DateTime selected, int offset) {
    final target = DateTime(selected.year, selected.month + offset);
    final lastDay = DateTime(target.year, target.month + 1, 0).day;
    setState(() => _lastTappedDate = null);
    ref.read(selectedDateProvider.notifier).select(
          DateTime(target.year, target.month, math.min(selected.day, lastDay)),
        );
  }

  void _selectDate(DateTime date) {
    if (_lastTappedDate == date) {
      context.go('/calendar/today');
      return;
    }
    setState(() => _lastTappedDate = date);
    ref.read(selectedDateProvider.notifier).select(date);
  }

  @override
  Widget build(BuildContext context) {
    final selected = localCalendarDay(ref.watch(selectedDateProvider));
    final today = localCalendarDay(DateTime.now());
    final overview = ref.watch(monthOverviewProvider);

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
                      key: const Key('monthPrevious'),
                      tooltip: '이전 달',
                      onPressed: () => _moveMonth(selected, -1),
                      icon: const Icon(Icons.chevron_left)),
                  Expanded(
                      child: Semantics(
                          header: true,
                          liveRegion: true,
                          child: Text('${selected.year}년 ${selected.month}월',
                              key: const Key('monthTitle'),
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                      color: const Color(0xFF202124),
                                      fontWeight: FontWeight.w700)))),
                  IconButton(
                      key: const Key('monthNext'),
                      tooltip: '다음 달',
                      onPressed: () => _moveMonth(selected, 1),
                      icon: const Icon(Icons.chevron_right)),
                ])),
            Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                    key: const Key('monthToday'),
                    onPressed: () {
                      setState(() => _lastTappedDate = null);
                      ref.read(selectedDateProvider.notifier).goToToday();
                    },
                    style: TextButton.styleFrom(foregroundColor: _navy),
                    child: const Text('오늘'))),
            const Divider(height: 1, color: _line),
            Expanded(
                child: overview.when(
              skipLoadingOnRefresh: false,
              skipLoadingOnReload: false,
              loading: () => const Center(
                  child: CircularProgressIndicator(
                      color: _navy, semanticsLabel: '월간 일정 불러오는 중')),
              error: (_, __) => Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('월간 일정을 불러오지 못했습니다.'),
                TextButton(
                    key: const Key('monthRetry'),
                    onPressed: () => ref.invalidate(monthOverviewProvider),
                    style: TextButton.styleFrom(foregroundColor: _navy),
                    child: const Text('다시 시도')),
              ])),
              data: (month) => LayoutBuilder(
                  builder: (context, constraints) => Column(children: [
                        const _Weekdays(),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: constraints.maxHeight * 0.58,
                          ),
                          child: SingleChildScrollView(
                            child: _MonthGrid(
                              overview: month,
                              selected: selected,
                              today: today,
                              onSelectDate: _selectDate,
                            ),
                          ),
                        ),
                        const Divider(height: 1, color: _line),
                        Expanded(
                            child: _Preview(
                          day: month.day(selected.day),
                          onOpen: () => context.go('/calendar/today'),
                        )),
                      ])),
            )),
          ])),
    ));
  }
}

class _Weekdays extends StatelessWidget {
  const _Weekdays();
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(children: [
          for (final weekday in ['월', '화', '수', '목', '금', '토', '일'])
            Expanded(
                child: Text(weekday,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: _muted))),
        ]),
      );
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid(
      {required this.overview,
      required this.selected,
      required this.today,
      required this.onSelectDate});
  final MonthOverview overview;
  final DateTime selected;
  final DateTime today;
  final ValueChanged<DateTime> onSelectDate;

  @override
  Widget build(BuildContext context) {
    final offset = overview.start.weekday - 1;
    final rows = (offset + overview.days.length + 6) ~/ 7;
    final gridStart =
        DateTime(overview.start.year, overview.start.month, 1 - offset);
    return Padding(
      key: const Key('monthGrid'),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(children: [
        for (var row = 0; row < rows; row++)
          Row(children: [
            for (var column = 0; column < 7; column++)
              Expanded(
                  child: _DayCell(
                date: DateTime(gridStart.year, gridStart.month,
                    gridStart.day + row * 7 + column),
                overview: overview,
                selected: selected,
                today: today,
                onSelect: onSelectDate,
              )),
          ]),
      ]),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell(
      {required this.date,
      required this.overview,
      required this.selected,
      required this.today,
      required this.onSelect});
  final DateTime date;
  final MonthOverview overview;
  final DateTime selected;
  final DateTime today;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final inMonth =
        date.year == overview.start.year && date.month == overview.start.month;
    final isSelected = date == selected;
    final isToday = date == today;
    final markers =
        inMonth ? overview.day(date.day).markers : <MonthCategoryMarker>[];
    return Semantics(
      key: Key('monthDay-${date.year}-${date.month}-${date.day}'),
      button: inMonth,
      enabled: inMonth,
      selected: isSelected,
      label: '${date.year}년 ${date.month}월 ${date.day}일'
          '${isToday ? ', 오늘' : ''}'
          '${markers.isEmpty ? '' : ', ${markers.map(_markerDescription).join(', ')}'}',
      onTap: inMonth ? () => onSelect(date) : null,
      child: ExcludeSemantics(
          child: Material(
        color: Colors.white,
        child: InkWell(
          onTap: inMonth ? () => onSelect(date) : null,
          child: Container(
            height: MediaQuery.textScalerOf(context).scale(1) > 1.3 ? 100 : 64,
            margin: const EdgeInsets.all(2),
            padding: const EdgeInsets.fromLTRB(4, 3, 4, 3),
            decoration: BoxDecoration(
              border: isSelected ? Border.all(color: _navy, width: 1.5) : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(children: [
              Text('${date.day}',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected || isToday
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: inMonth
                          ? const Color(0xFF202124)
                          : const Color(0xFFB4B8C0))),
              const SizedBox(height: 3),
              Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 3,
                  runSpacing: 3,
                  children: [
                    for (var index = 0; index < markers.length; index++)
                      _Marker(
                          key: Key(
                              'monthMarker-${date.year}-${date.month}-${date.day}-$index'),
                          marker: markers[index])
                  ]),
            ]),
          ),
        ),
      )),
    );
  }
}

String _markerDescription(MonthCategoryMarker marker) {
  final name = marker.category?.name ?? '카테고리 없음';
  final shape = switch (marker.shape) {
    MonthMarkerShape.event => '일정',
    MonthMarkerShape.todo => 'Todo',
    MonthMarkerShape.mixed => '일정과 Todo',
  };
  return '$name $shape${marker.isChecked ? ', Todo 완료' : ''}';
}

class _Marker extends StatelessWidget {
  const _Marker({required this.marker, super.key});
  final MonthCategoryMarker marker;

  @override
  Widget build(BuildContext context) {
    final color = Color(marker.category?.color ?? 0xFF98A2B3).withAlpha(255);
    final isDiamond = marker.shape == MonthMarkerShape.todo;
    final shape = marker.shape == MonthMarkerShape.event
        ? BoxShape.circle
        : BoxShape.rectangle;
    return Transform.rotate(
      angle: isDiamond ? math.pi / 4 : 0,
      child: Container(
        width: 13,
        height: 13,
        decoration: BoxDecoration(
            color: color,
            shape: shape,
            borderRadius: shape == BoxShape.rectangle && !isDiamond
                ? BorderRadius.circular(3)
                : null),
        child: marker.isChecked
            ? Transform.rotate(
                angle: isDiamond ? -math.pi / 4 : 0,
                child: Icon(Icons.check,
                    size: 11,
                    color: ThemeData.estimateBrightnessForColor(color) ==
                            Brightness.dark
                        ? Colors.white
                        : Colors.black))
            : null,
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.day, required this.onOpen});
  final MonthDaySummary day;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final visible = day.entries.take(3).toList();
    return Padding(
      key: const Key('monthPreview'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(
              child: Text('${day.date.month}월 ${day.date.day}일',
                  key: const Key('monthPreviewDate'),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700))),
          TextButton(
              key: const Key('monthOpenDay'),
              onPressed: onOpen,
              style: TextButton.styleFrom(foregroundColor: _navy),
              child: const Text('일력 보기')),
        ]),
        Expanded(
            child: ListView(children: [
          if (visible.isEmpty)
            const Padding(
                padding: EdgeInsets.only(top: 20),
                child: Text('이 날짜에는 일정과 Todo가 없습니다.',
                    style: TextStyle(color: _muted))),
          for (final entry in visible) _PreviewRow(entry: entry),
          if (day.entries.length > visible.length)
            Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('외 ${day.entries.length - visible.length}개',
                    style: const TextStyle(color: _muted))),
        ])),
      ]),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.entry});
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
        ? '종일 · '
        : task.hasTime && task.startDateTime != null
            ? '${time(task.startDateTime!)}${task.endDateTime == null ? '' : '–${time(task.endDateTime!)}'} · '
            : '';
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(children: [
        Container(width: 3, height: 32, color: color),
        const SizedBox(width: 10),
        Expanded(
            child: Text('$prefix${task.title}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: const Color(0xFF202124),
                    decoration: task.isTodo && task.isCompleted
                        ? TextDecoration.lineThrough
                        : null))),
      ]),
    );
  }
}
