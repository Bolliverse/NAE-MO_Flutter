import 'package:flutter_test/flutter_test.dart';
import 'package:nae_mo/features/task/domain/entities/task.dart';

void main() {
  test('distinguishes event tasks from todo tasks', () {
    final date = DateTime(2026, 7, 31);
    final event = Task(
      id: 'event',
      title: 'meeting',
      kind: TaskKind.event,
      targetDate: date,
      isCompleted: false,
      hasTime: false,
      isAllDay: true,
      isRecurring: false,
      createdAt: date,
    );

    expect(event.isEvent, isTrue);
    expect(event.isTodo, isFalse);
  });
}
