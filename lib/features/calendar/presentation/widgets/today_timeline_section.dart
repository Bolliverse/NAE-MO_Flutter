import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nae_mo/features/calendar/domain/entities/today_overview.dart';
import 'package:nae_mo/features/task/domain/entities/task.dart';

class TodayTimelineSection extends StatelessWidget {
  final List<TodayEntry> entries;
  final Set<String> pendingTodoIds;
  final ValueChanged<String> onToggleTodo;

  const TodayTimelineSection({
    super.key,
    required this.entries,
    required this.pendingTodoIds,
    required this.onToggleTodo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '일정',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '시간이 정해진 일정이 없어요.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            )
          else
            for (var index = 0; index < entries.length; index++) ...[
              _TimelineRow(
                entry: entries[index],
                isPending: pendingTodoIds.contains(entries[index].task.id),
                onToggleTodo: onToggleTodo,
              ),
              if (index != entries.length - 1) const SizedBox(height: 6),
            ],
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final TodayEntry entry;
  final bool isPending;
  final ValueChanged<String> onToggleTodo;

  const _TimelineRow({
    required this.entry,
    required this.isPending,
    required this.onToggleTodo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final category = entry.category;
    final accent = category == null
        ? colors.outline
        : Color(category.color).withAlpha(255);
    final tint = Color.alphaBlend(
      accent.withAlpha(category == null ? 10 : 20),
      colors.surface,
    );
    final usesLargeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final timeColumnWidth = usesLargeText ? 72.0 : 56.0;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: timeColumnWidth,
            child: Padding(
              padding: const EdgeInsets.only(top: 10, right: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (entry.task.startDateTime case final start?)
                    Text(
                      _time(start),
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  if (entry.task.endDateTime case final end?) ...[
                    const SizedBox(height: 2),
                    Text(
                      _time(end),
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(
            width: 16,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Positioned(
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 1,
                    color: colors.outlineVariant,
                  ),
                ),
                Positioned(
                  top: 15,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Container(
              key: Key('todayEntry-${entry.task.id}'),
              constraints: const BoxConstraints(minHeight: 64),
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(12),
                border: Border(
                  left: BorderSide(color: accent, width: 3),
                ),
              ),
              child: Row(
                children: [
                  if (entry.task.kind == TaskKind.todo)
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: Checkbox(
                        key: Key('todayTodoCheckbox-${entry.task.id}'),
                        value: entry.task.isCompleted,
                        onChanged: isPending
                            ? null
                            : (_) => onToggleTodo(entry.task.id),
                        activeColor: accent,
                      ),
                    )
                  else
                    const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 8, 10, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            entry.task.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (category != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              category.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: accent,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _time(DateTime value) {
    return DateFormat('HH:mm', 'ko').format(value);
  }
}
