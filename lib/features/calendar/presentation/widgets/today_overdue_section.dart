import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nae_mo/features/calendar/domain/entities/today_overview.dart';

class TodayOverdueSection extends StatelessWidget {
  final List<TodayEntry> entries;
  final bool isExpanded;
  final Set<String> pendingTodoIds;
  final VoidCallback onToggleExpanded;
  final ValueChanged<String> onToggleTodo;

  const TodayOverdueSection({
    super.key,
    required this.entries,
    required this.isExpanded,
    required this.pendingTodoIds,
    required this.onToggleExpanded,
    required this.onToggleTodo,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final oldestDate = entries
        .map((entry) => entry.task.targetDate)
        .reduce((oldest, date) => date.isBefore(oldest) ? date : oldest);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: Material(
        color: colors.errorContainer.withAlpha(92),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: onToggleExpanded,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '지난 할 일',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: colors.onErrorContainer,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${entries.length}개 · 가장 오래된 ${_date(oldestDate)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onErrorContainer.withAlpha(190),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: colors.onErrorContainer,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (isExpanded) ...[
              Divider(
                height: 1,
                color: colors.onErrorContainer.withAlpha(30),
              ),
              for (final entry in entries)
                _OverdueTodoRow(
                  entry: entry,
                  isPending: pendingTodoIds.contains(entry.task.id),
                  onToggleTodo: onToggleTodo,
                ),
            ],
          ],
        ),
      ),
    );
  }

  static String _date(DateTime value) {
    final normalized = DateTime(value.year, value.month, value.day);
    return DateFormat('M월 d일', 'ko').format(normalized);
  }
}

class _OverdueTodoRow extends StatelessWidget {
  final TodayEntry entry;
  final bool isPending;
  final ValueChanged<String> onToggleTodo;

  const _OverdueTodoRow({
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
        ? colors.onSurfaceVariant
        : Color(category.color).withAlpha(255);

    return Semantics(
      key: Key('todayEntry-${entry.task.id}'),
      container: true,
      excludeSemantics: true,
      label:
          '${entry.task.title}, ${TodayOverdueSection._date(entry.task.targetDate)}',
      checked: entry.task.isCompleted,
      enabled: !isPending,
      onTap: isPending ? null : () => onToggleTodo(entry.task.id),
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: colors.onErrorContainer.withAlpha(20)),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: Checkbox(
                key: Key('todayTodoCheckbox-${entry.task.id}'),
                value: entry.task.isCompleted,
                onChanged:
                    isPending ? null : (_) => onToggleTodo(entry.task.id),
                activeColor: accent,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
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
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 6,
                      runSpacing: 2,
                      children: [
                        Text(
                          TodayOverdueSection._date(entry.task.targetDate),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        if (category != null)
                          Text(
                            category.name,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
