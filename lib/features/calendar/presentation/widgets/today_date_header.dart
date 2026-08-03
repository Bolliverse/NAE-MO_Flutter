import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TodayDateHeader extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onPrevious;
  final VoidCallback onToday;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onSelectDate;

  const TodayDateHeader({
    super.key,
    required this.selectedDate,
    required this.onPrevious,
    required this.onToday,
    required this.onNext,
    required this.onSelectDate,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedDate = _normalize(selectedDate);
    final dates = List.generate(
      7,
      (index) => DateTime(
        normalizedDate.year,
        normalizedDate.month,
        normalizedDate.day + index - 3,
      ),
    );
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        DateFormat('yyyy년 M월', 'ko').format(normalizedDate),
                        maxLines: 1,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        DateFormat('d일 EEEE', 'ko').format(normalizedDate),
                        maxLines: 1,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    key: const Key('todayPreviousDate'),
                    onPressed: onPrevious,
                    tooltip: '이전 날',
                    icon: const Icon(Icons.chevron_left),
                  ),
                  TextButton(
                    key: const Key('todayGoToToday'),
                    onPressed: onToday,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    child: const Text('오늘'),
                  ),
                  IconButton(
                    key: const Key('todayNextDate'),
                    onPressed: onNext,
                    tooltip: '다음 날',
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final date in dates)
                Expanded(
                  child: _DateButton(
                    date: date,
                    isSelected: date == normalizedDate,
                    onPressed: () => onSelectDate(_normalize(date)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static DateTime _normalize(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}

class _DateButton extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final VoidCallback onPressed;

  const _DateButton({
    required this.date,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final foregroundColor = isSelected ? colors.surface : colors.onSurface;

    return Semantics(
      key: Key('todayDate-${_dateKey(date)}'),
      container: true,
      button: true,
      selected: isSelected,
      label: DateFormat('yyyy년 M월 d일 EEEE', 'ko').format(date),
      excludeSemantics: true,
      child: Material(
        color: isSelected ? colors.onSurface : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 48,
              minHeight: 48,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('E', 'ko').format(date),
                    maxLines: 1,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isSelected
                          ? foregroundColor
                          : colors.onSurfaceVariant,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${date.day}',
                    maxLines: 1,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: foregroundColor,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
