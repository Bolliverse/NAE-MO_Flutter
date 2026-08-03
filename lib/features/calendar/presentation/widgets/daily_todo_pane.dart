import 'package:flutter/material.dart';
import 'package:nae_mo/features/calendar/domain/entities/today_overview.dart';
import 'package:nae_mo/features/calendar/presentation/widgets/daily_calendar_pane.dart';

const _neutralAccent = Color(0xFFB4B4B4);
const _lineColor = Color(0xFFE2E2E2);

class DailyTodoPinned extends StatelessWidget {
  const DailyTodoPinned({
    super.key,
    required this.entries,
    required this.selectedDate,
    required this.isCompact,
    required this.pendingTodoIds,
    required this.onToggleTodo,
  });

  final List<TodayEntry> entries;
  final DateTime selectedDate;
  final bool isCompact;
  final Set<String> pendingTodoIds;
  final ValueChanged<String> onToggleTodo;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: isCompact
          ? _CompactPinnedTodo(entries: entries)
          : _ExpandedPinnedTodo(
              entries: entries,
              selectedDate: selectedDate,
              pendingTodoIds: pendingTodoIds,
              onToggleTodo: onToggleTodo,
            ),
    );
  }
}

class _ExpandedPinnedTodo extends StatelessWidget {
  const _ExpandedPinnedTodo({
    required this.entries,
    required this.selectedDate,
    required this.pendingTodoIds,
    required this.onToggleTodo,
  });

  final List<TodayEntry> entries;
  final DateTime selectedDate;
  final Set<String> pendingTodoIds;
  final ValueChanged<String> onToggleTodo;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.expand();

    return SingleChildScrollView(
      primary: false,
      padding: const EdgeInsets.fromLTRB(6, 2, 8, 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < entries.length; index++) ...[
            _TodoRow(
              entry: entries[index],
              isPending: pendingTodoIds.contains(entries[index].task.id),
              onToggleTodo: onToggleTodo,
              metadata: _pinnedMetadata(entries[index], selectedDate),
            ),
            if (index != entries.length - 1)
              const Divider(height: 1, indent: 50, color: _lineColor),
          ],
        ],
      ),
    );
  }
}

class _CompactPinnedTodo extends StatelessWidget {
  const _CompactPinnedTodo({required this.entries});

  static const _visibleCount = 3;
  final List<TodayEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.expand();
    final visible = entries.take(_visibleCount).toList(growable: false);
    final overflow = entries.length - visible.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
      child: Stack(
        children: [
          for (var index = 0; index < visible.length; index++)
            Positioned(
              top: index * 9,
              left: index * 3,
              right: (visible.length - index - 1) * 3,
              height: 32,
              child: Container(
                key: Key('dailyTodoCompactPinned-$index'),
                decoration: BoxDecoration(
                  color: _entryColor(visible[index]),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: visible[index].task.isCompleted
                    ? const Icon(Icons.check, size: 18, color: Colors.white)
                    : null,
              ),
            ),
          if (overflow > 0)
            Positioned(
              top: visible.length * 9 + 36,
              left: 0,
              right: 0,
              height: 24,
              child: _OverflowBadge(
                key: const Key('dailyTodoPinnedOverflow'),
                count: overflow,
              ),
            ),
        ],
      ),
    );
  }
}

class DailyTodoTimeline extends StatelessWidget {
  const DailyTodoTimeline({
    super.key,
    required this.entries,
    required this.isCompact,
    required this.pendingTodoIds,
    required this.onToggleTodo,
  });

  final List<TodayEntry> entries;
  final bool isCompact;
  final Set<String> pendingTodoIds;
  final ValueChanged<String> onToggleTodo;

  @override
  Widget build(BuildContext context) {
    final groups = _groupEntries(entries);
    return SizedBox(
      key: const Key('dailyTodoTimelineSurface'),
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
                key: Key('dailyTodoHourLine-$hour'),
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
              ..._compactEntries(group)
            else
              ..._expandedEntries(group),
        ],
      ),
    );
  }

  List<Widget> _expandedEntries(_TimedGroup group) {
    return [
      for (var index = 0; index < group.entries.length; index++)
        Positioned(
          top: group.entries[index].startMinute / 60 * dailyCalendarHourExtent,
          left: 52,
          right: 8,
          height: 56,
          child: _CompactSlot(
            index: index,
            count: group.entries.length,
            child: _TodoRow(
              key: Key(
                'dailyTodoTimelineEntry-${group.entries[index].entry.task.id}',
              ),
              entry: group.entries[index].entry,
              isPending: pendingTodoIds.contains(
                group.entries[index].entry.task.id,
              ),
              onToggleTodo: onToggleTodo,
              metadata: _time(group.entries[index].entry.task.startDateTime!),
            ),
          ),
        ),
    ];
  }

  List<Widget> _compactEntries(_TimedGroup group) {
    const visibleCount = 2;
    final visible = group.entries.take(visibleCount).toList(growable: false);
    final overflow = group.entries.length - visible.length;
    final slotCount = visible.length + (overflow > 0 ? 1 : 0);

    return [
      for (var index = 0; index < visible.length; index++)
        Positioned(
          top: visible[index].startMinute / 60 * dailyCalendarHourExtent,
          left: 5,
          right: 5,
          height: visible[index].durationMinutes / 60 * dailyCalendarHourExtent,
          child: _CompactSlot(
            index: index,
            count: slotCount,
            child: Container(
              key: Key(
                'dailyTodoCompactTimed-${visible[index].entry.task.id}',
              ),
              decoration: BoxDecoration(
                color: _entryColor(visible[index].entry),
                borderRadius: BorderRadius.circular(5),
              ),
              child: visible[index].entry.task.isCompleted
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ),
        ),
      if (overflow > 0)
        Positioned(
          top: group.startMinute / 60 * dailyCalendarHourExtent,
          left: 5,
          right: 5,
          height: 28,
          child: _CompactSlot(
            index: slotCount - 1,
            count: slotCount,
            child: _OverflowBadge(
              key: Key('dailyTodoTimelineOverflow-${group.startMinute}'),
              count: overflow,
            ),
          ),
        ),
    ];
  }
}

class _TodoRow extends StatelessWidget {
  const _TodoRow({
    super.key,
    required this.entry,
    required this.isPending,
    required this.onToggleTodo,
    required this.metadata,
  });

  final TodayEntry entry;
  final bool isPending;
  final ValueChanged<String> onToggleTodo;
  final String? metadata;

  @override
  Widget build(BuildContext context) {
    final categoryName = entry.category?.name ?? '카테고리 없음';
    final completionName = entry.task.isCompleted ? '완료' : '미완료';
    final textScale = MediaQuery.textScalerOf(context).scale(1);

    return Semantics(
      key: Key('dailyTodoEntry-${entry.task.id}'),
      container: true,
      excludeSemantics: true,
      label: '${entry.task.title}, $categoryName, $completionName',
      checked: entry.task.isCompleted,
      enabled: !isPending,
      onTap: isPending ? null : () => onToggleTodo(entry.task.id),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: isPending ? null : () => onToggleTodo(entry.task.id),
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              _TodoCheck(
                taskId: entry.task.id,
                color: _entryColor(entry),
                isCompleted: entry.task.isCompleted,
                isEnabled: !isPending,
                onTap: () => onToggleTodo(entry.task.id),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.task.title,
                        maxLines: textScale > 1.3 ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: entry.task.isCompleted
                                  ? const Color(0xFF777777)
                                  : const Color(0xFF161616),
                              fontWeight: FontWeight.w600,
                              decoration: entry.task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                      ),
                      if (metadata != null && textScale <= 1.3)
                        Text(
                          metadata!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: const Color(0xFF6F6F6F),
                                  ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodoCheck extends StatelessWidget {
  const _TodoCheck({
    required this.taskId,
    required this.color,
    required this.isCompleted,
    required this.isEnabled,
    required this.onTap,
  });

  final String taskId;
  final Color color;
  final bool isCompleted;
  final bool isEnabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: Key('todayTodoCheckbox-$taskId'),
      child: GestureDetector(
        key: Key('dailyTodoCheckbox-$taskId'),
        behavior: HitTestBehavior.opaque,
        onTap: isEnabled ? onTap : null,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: Opacity(
              opacity: isEnabled ? 1 : .45,
              child: Container(
                key: Key('dailyTodoCheckVisual-$taskId'),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isCompleted ? color : Colors.white,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: color, width: 2.5),
                ),
                child: isCompleted
                    ? const Icon(Icons.check, size: 20, color: Colors.white)
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactSlot extends StatelessWidget {
  const _CompactSlot({
    required this.index,
    required this.count,
    required this.child,
  });

  final int index;
  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var slot = 0; slot < count; slot++) ...[
          Expanded(child: slot == index ? child : const SizedBox.shrink()),
          if (slot != count - 1) const SizedBox(width: 3),
        ],
      ],
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
      end == null ? startMinute + 45 : end.hour * 60 + end.minute;
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

String? _pinnedMetadata(TodayEntry entry, DateTime selectedDate) {
  if (_localDate(entry.task.targetDate).isBefore(_localDate(selectedDate))) {
    final date = entry.task.targetDate.toLocal();
    return '지난 ${date.month}/${date.day}';
  }
  return entry.category?.name;
}

DateTime _localDate(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
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

String _time(DateTime value) {
  final local = value.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}
