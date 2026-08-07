import 'package:flutter/material.dart';
import 'package:nae_mo/features/calendar/domain/entities/today_overview.dart';

class TodayAllDaySection extends StatelessWidget {
  final List<TodayEntry> entries;

  const TodayAllDaySection({
    super.key,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < entries.length; index++) ...[
            if (index > 0) const SizedBox(height: 6),
            _AllDayCard(entry: entries[index]),
          ],
        ],
      ),
    );
  }
}

class _AllDayCard extends StatelessWidget {
  final TodayEntry entry;

  const _AllDayCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final category = entry.category;
    final accent = category == null
        ? colors.onSurfaceVariant
        : Color(category.color).withAlpha(255);
    final tint = Color.alphaBlend(
      accent.withAlpha(category == null ? 12 : 22),
      colors.surface,
    );

    return Container(
      key: Key('todayEntry-${entry.task.id}'),
      constraints: const BoxConstraints(minHeight: 48),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: accent, width: 3),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              entry.task.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (category != null) ...[
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(width: 8),
          Text(
            '종일',
            maxLines: 1,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
