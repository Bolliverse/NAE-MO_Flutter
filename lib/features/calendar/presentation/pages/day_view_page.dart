import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nae_mo/core/providers/selected_date_provider.dart';

class DayViewPage extends ConsumerWidget {
  const DayViewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(selectedDateProvider);

    return Row(
      children: [
        // Task Dock — Phase 3에서 구현
        _TaskDockPlaceholder(),
        const VerticalDivider(width: 1),
        // Timeline — Phase 3에서 구현
        Expanded(
          child: _TimelinePlaceholder(date: date),
        ),
      ],
    );
  }
}

class _TaskDockPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Task Dock',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Phase 3\n구현 예정',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelinePlaceholder extends StatelessWidget {
  final DateTime date;
  const _TimelinePlaceholder({required this.date});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_today,
            size: 48,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            DateFormat('yyyy년 M월 d일 (E)', 'ko').format(date),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Day View Timeline\nPhase 3에서 구현됩니다.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }
}
