import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nae_mo/core/providers/selected_date_provider.dart';

class WeekViewPage extends ConsumerWidget {
  const WeekViewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(selectedDateProvider);
    final weekStart = _weekStart(date);
    final weekEnd = weekStart.add(const Duration(days: 6));

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.view_week,
            size: 48,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            '${DateFormat('M월 d일', 'ko').format(weekStart)}'
            ' ~ '
            '${DateFormat('M월 d일', 'ko').format(weekEnd)}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Week View\nPhase 6에서 구현됩니다.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }

  DateTime _weekStart(DateTime date) {
    // 월요일 기준
    final diff = date.weekday - 1;
    return date.subtract(Duration(days: diff));
  }
}
