import 'package:flutter/material.dart';
import 'package:nae_mo/features/calendar/domain/entities/today_overview.dart';

class TodayTodoSection extends StatelessWidget {
  final String title;
  final List<TodayEntry> entries;
  final Set<String> pendingTodoIds;
  final ValueChanged<String> onToggleTodo;
  final String? emptyMessage;
  final bool isCompletedPresentation;
  final bool? isExpanded;
  final VoidCallback? onToggleExpanded;

  const TodayTodoSection({
    super.key,
    required this.title,
    required this.entries,
    required this.pendingTodoIds,
    required this.onToggleTodo,
    this.emptyMessage,
    this.isCompletedPresentation = false,
    this.isExpanded,
    this.onToggleExpanded,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isCollapsible = isExpanded != null && onToggleExpanded != null;
    final showRows = !isCollapsible || isExpanded!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isCollapsible ? onToggleExpanded : null,
              borderRadius: BorderRadius.circular(10),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${entries.length}개',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      if (isCollapsible) ...[
                        const SizedBox(width: 4),
                        Icon(
                          isExpanded! ? Icons.expand_less : Icons.expand_more,
                          color: colors.onSurfaceVariant,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (showRows && entries.isEmpty && emptyMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
              child: Text(
                emptyMessage!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          if (showRows && entries.isNotEmpty) ...[
            const SizedBox(height: 4),
            Material(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var index = 0; index < entries.length; index++) ...[
                    if (index > 0)
                      Divider(
                        height: 1,
                        indent: 52,
                        color: colors.outlineVariant.withAlpha(120),
                      ),
                    _TodoRow(
                      entry: entries[index],
                      isPending: pendingTodoIds.contains(
                        entries[index].task.id,
                      ),
                      isCompletedPresentation: isCompletedPresentation,
                      onToggleTodo: onToggleTodo,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TodoRow extends StatelessWidget {
  final TodayEntry entry;
  final bool isPending;
  final bool isCompletedPresentation;
  final ValueChanged<String> onToggleTodo;

  const _TodoRow({
    required this.entry,
    required this.isPending,
    required this.isCompletedPresentation,
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
    final isShownCompleted = isCompletedPresentation || entry.task.isCompleted;

    return Container(
      key: Key('todayEntry-${entry.task.id}'),
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.only(right: 12),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: Checkbox(
              key: Key('todayTodoCheckbox-${entry.task.id}'),
              value: isShownCompleted,
              onChanged: isPending ? null : (_) => onToggleTodo(entry.task.id),
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
                      color: isShownCompleted
                          ? colors.onSurfaceVariant
                          : colors.onSurface,
                      fontWeight: FontWeight.w600,
                      decoration: isShownCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  if (category != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      category.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            isShownCompleted ? colors.onSurfaceVariant : accent,
                        fontWeight: FontWeight.w500,
                        decoration: isShownCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
