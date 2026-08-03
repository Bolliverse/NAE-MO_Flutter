import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TodayDateHeader extends StatelessWidget {
  const TodayDateHeader({
    super.key,
    required this.selectedDate,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime selectedDate;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localDate = selectedDate.toLocal();

    return ColoredBox(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        child: Row(
          children: [
            IconButton(
              key: const Key('todayPreviousDate'),
              onPressed: onPrevious,
              tooltip: '이전 날',
              constraints: const BoxConstraints.tightFor(
                width: 48,
                height: 48,
              ),
              icon: const Icon(Icons.chevron_left, size: 30),
            ),
            Expanded(
              child: Semantics(
                header: true,
                label: DateFormat('yyyy년 M월 d일 EEEE', 'ko').format(localDate),
                excludeSemantics: true,
                child: Center(
                  child: Text(
                    DateFormat('M/d').format(localDate),
                    key: const Key('todaySharedDate'),
                    maxLines: 1,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.w400,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.black,
                      decorationThickness: 1,
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              key: const Key('todayNextDate'),
              onPressed: onNext,
              tooltip: '다음 날',
              constraints: const BoxConstraints.tightFor(
                width: 48,
                height: 48,
              ),
              icon: const Icon(Icons.chevron_right, size: 30),
            ),
          ],
        ),
      ),
    );
  }
}
