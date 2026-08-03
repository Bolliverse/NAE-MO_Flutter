import 'package:flutter/material.dart';
import 'package:nae_mo/features/calendar/domain/entities/today_overview.dart';

const dailyCalendarHourExtent = 80.0;
const dailyCalendarTimelineHeight = dailyCalendarHourExtent * 24;

const _neutralAccent = Color(0xFFB4B4B4);
const _lineColor = Color(0xFFE2E2E2);

class DailyCalendarPinned extends StatelessWidget {
  const DailyCalendarPinned({
    super.key,
    required this.entries,
    required this.isCompact,
  });

  final List<TodayEntry> entries;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: isCompact
          ? _CompactPinnedCalendar(entries: entries)
          : _ExpandedPinnedCalendar(entries: entries),
    );
  }
}

class _ExpandedPinnedCalendar extends StatelessWidget {
  const _ExpandedPinnedCalendar({required this.entries});

  final List<TodayEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.expand();

    return SingleChildScrollView(
      primary: false,
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < entries.length; index++) ...[
            _AllDayBar(entry: entries[index]),
            if (index != entries.length - 1) const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}

class _AllDayBar extends StatelessWidget {
  const _AllDayBar({required this.entry});

  final TodayEntry entry;

  @override
  Widget build(BuildContext context) {
    final color = _entryColor(entry);
    return Semantics(
      label: '${entry.task.title}, 종일',
      child: Container(
        key: Key('dailyCalendarAllDay-${entry.task.id}'),
        height: 38,
        width: double.infinity,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          entry.task.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _foregroundFor(color),
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}

class _CompactPinnedCalendar extends StatelessWidget {
  const _CompactPinnedCalendar({required this.entries});

  static const _visibleCount = 3;
  final List<TodayEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.expand();
    final visible = entries.take(_visibleCount).toList(growable: false);
    final overflow = entries.length - visible.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < visible.length; index++) ...[
            Container(
              key: Key('dailyCalendarCompactAllDay-$index'),
              height: 24,
              width: double.infinity,
              decoration: BoxDecoration(
                color: _entryColor(visible[index]),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            if (index != visible.length - 1) const SizedBox(height: 4),
          ],
          if (overflow > 0) ...[
            const SizedBox(height: 6),
            _OverflowBadge(
              key: const Key('dailyCalendarPinnedOverflow'),
              count: overflow,
            ),
          ],
        ],
      ),
    );
  }
}

class DailyCalendarTimeline extends StatelessWidget {
  const DailyCalendarTimeline({
    super.key,
    required this.entries,
    required this.isCompact,
  });

  final List<TodayEntry> entries;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final groups = _groupEntries(entries);
    return SizedBox(
      key: const Key('dailyCalendarTimelineSurface'),
      height: dailyCalendarTimelineHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned.fill(child: ColoredBox(color: Colors.white)),
          for (var hour = 0; hour <= 24; hour++) ...[
            Positioned(
              top: _lineTop(hour),
              left: isCompact ? 0 : 48,
              right: 0,
              height: 1,
              child: ColoredBox(
                key: Key('dailyCalendarHourLine-$hour'),
                color: _lineColor,
              ),
            ),
            if (!isCompact)
              Positioned(
                top: _labelTop(hour),
                left: 8,
                width: 32,
                child: Text(
                  '$hour',
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF333333),
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
          ],
          for (final group in groups)
            if (isCompact)
              _CompactEventGroup(group: group)
            else
              ..._expandedEvents(context, group),
        ],
      ),
    );
  }

  List<Widget> _expandedEvents(BuildContext context, _TimedGroup group) {
    return [
      for (var index = 0; index < group.entries.length; index++)
        Positioned(
          top: group.entries[index].startMinute / 60 * dailyCalendarHourExtent,
          left: 54 + index * 4,
          right: 8 + (group.entries.length - index - 1) * 4,
          height: group.entries[index].durationMinutes /
              60 *
              dailyCalendarHourExtent,
          child: _ExpandedEventBlock(entry: group.entries[index].entry),
        ),
    ];
  }
}

class _ExpandedEventBlock extends StatelessWidget {
  const _ExpandedEventBlock({required this.entry});

  final TodayEntry entry;

  @override
  Widget build(BuildContext context) {
    final color = _entryColor(entry);
    final foreground = _foregroundFor(color);
    final start = entry.task.startDateTime;
    final end = entry.task.endDateTime;

    return Semantics(
      label: [
        entry.task.title,
        if (start != null) _timeRange(start, end),
      ].join(', '),
      child: Container(
        key: Key('dailyCalendarEvent-${entry.task.id}'),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final textScale = MediaQuery.textScalerOf(context).scale(1);
            final showTime = constraints.maxHeight >= 32 &&
                start != null &&
                textScale <= 1.3;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      entry.task.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: foreground,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ),
                if (showTime)
                  Text(
                    _timeRange(start, end),
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: foreground.withAlpha(210),
                        ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CompactEventGroup extends StatelessWidget {
  const _CompactEventGroup({required this.group});

  static const _visibleCount = 2;
  final _TimedGroup group;

  @override
  Widget build(BuildContext context) {
    final visible = group.entries.take(_visibleCount).toList(growable: false);
    final overflow = group.entries.length - visible.length;
    return Positioned(
      top: group.startMinute / 60 * dailyCalendarHourExtent,
      left: 5,
      right: 5,
      height: group.durationMinutes / 60 * dailyCalendarHourExtent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < visible.length; index++) ...[
            Expanded(
              child: Container(
                key: Key(
                  'dailyCalendarCompactEvent-${visible[index].entry.task.id}',
                ),
                decoration: BoxDecoration(
                  color: _entryColor(visible[index].entry),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
            if (index != visible.length - 1 || overflow > 0)
              const SizedBox(width: 3),
          ],
          if (overflow > 0)
            Expanded(
              child: _OverflowBadge(
                key: Key(
                  'dailyCalendarTimelineOverflow-${group.startMinute}',
                ),
                count: overflow,
              ),
            ),
        ],
      ),
    );
  }
}

class _OverflowBadge extends StatelessWidget {
  const _OverflowBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      constraints: const BoxConstraints(minHeight: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF2E4175),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        '+$count',
        maxLines: 1,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _TimedEntry {
  const _TimedEntry({
    required this.entry,
    required this.startMinute,
    required this.endMinute,
  });

  final TodayEntry entry;
  final int startMinute;
  final int endMinute;

  int get durationMinutes => endMinute - startMinute;
}

class _TimedGroup {
  _TimedGroup({required this.entries});

  final List<_TimedEntry> entries;

  int get startMinute => entries.first.startMinute;
  int get endMinute => entries.fold(
        entries.first.endMinute,
        (latest, entry) => entry.endMinute > latest ? entry.endMinute : latest,
      );
  int get durationMinutes => endMinute - startMinute;
}

List<_TimedGroup> _groupEntries(List<TodayEntry> entries) {
  final timed = entries
      .where((entry) => entry.task.startDateTime != null)
      .map(_toTimedEntry)
      .toList(growable: false)
    ..sort((left, right) {
      final start = left.startMinute.compareTo(right.startMinute);
      return start != 0 ? start : left.endMinute.compareTo(right.endMinute);
    });

  final groups = <_TimedGroup>[];
  for (final entry in timed) {
    if (groups.isEmpty || entry.startMinute >= groups.last.endMinute) {
      groups.add(_TimedGroup(entries: [entry]));
    } else {
      groups.last.entries.add(entry);
    }
  }
  return groups;
}

_TimedEntry _toTimedEntry(TodayEntry entry) {
  final start = entry.task.startDateTime!.toLocal();
  final end = entry.task.endDateTime?.toLocal();
  final startMinute = (start.hour * 60 + start.minute).clamp(0, 1439);
  final requestedEnd =
      end == null ? startMinute + 60 : end.hour * 60 + end.minute;
  final endMinute = requestedEnd.clamp(startMinute + 1, 1440);
  return _TimedEntry(
    entry: entry,
    startMinute: startMinute,
    endMinute: endMinute,
  );
}

Color _entryColor(TodayEntry entry) {
  final category = entry.category;
  return category == null
      ? _neutralAccent
      : Color(category.color).withAlpha(255);
}

Color _foregroundFor(Color background) {
  return ThemeData.estimateBrightnessForColor(background) == Brightness.dark
      ? Colors.white
      : const Color(0xFF111111);
}

double _lineTop(int hour) {
  if (hour == 24) return dailyCalendarTimelineHeight - 1;
  return hour * dailyCalendarHourExtent;
}

double _labelTop(int hour) {
  if (hour == 24) return dailyCalendarTimelineHeight - 24;
  return (hour * dailyCalendarHourExtent - 10).clamp(
    0,
    dailyCalendarTimelineHeight - 24,
  );
}

String _timeRange(DateTime start, DateTime? end) {
  final startText = _time(start);
  if (end == null) return startText;
  return '$startText–${_time(end)}';
}

String _time(DateTime value) {
  final local = value.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}
