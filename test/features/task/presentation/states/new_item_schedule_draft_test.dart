import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nae_mo/features/task/presentation/states/new_item_schedule_draft.dart';

void main() {
  group('NewItemScheduleDraft', () {
    test('starts timed for events and untimed for todos', () {
      const eventDraft = NewItemScheduleDraft();
      const todoDraft = NewItemScheduleDraft(kind: NewItemKind.todo);

      expect(eventDraft.activeMode, NewItemTimeMode.timed);
      expect(eventDraft.showsTimeFields, isTrue);
      expect(todoDraft.activeMode, NewItemTimeMode.untimed);
      expect(todoDraft.showsTimeFields, isFalse);
    });

    test('keeps independent event and todo modes when kind changes', () {
      final draft = const NewItemScheduleDraft()
          .withMode(NewItemTimeMode.allDay)
          .withKind(NewItemKind.todo)
          .withMode(NewItemTimeMode.timed)
          .withKind(NewItemKind.event);

      expect(draft.activeMode, NewItemTimeMode.allDay);
      expect(
        draft.withKind(NewItemKind.todo).activeMode,
        NewItemTimeMode.timed,
      );
    });

    test('keeps selected times while the active mode hides them', () {
      final draft = const NewItemScheduleDraft()
          .withStartTime(const TimeOfDay(hour: 9, minute: 30))
          .withEndTime(const TimeOfDay(hour: 10, minute: 30))
          .withMode(NewItemTimeMode.allDay);

      expect(draft.showsTimeFields, isFalse);
      expect(draft.startTime, const TimeOfDay(hour: 9, minute: 30));
      expect(draft.endTime, const TimeOfDay(hour: 10, minute: 30));
      expect(
        draft.withMode(NewItemTimeMode.timed).startTime,
        const TimeOfDay(hour: 9, minute: 30),
      );
    });

    test('rejects equal or decreasing complete time ranges', () {
      final draft = const NewItemScheduleDraft()
          .withStartTime(const TimeOfDay(hour: 10, minute: 0));

      expect(draft.timeRangeError, isNull);
      expect(
        draft.withEndTime(const TimeOfDay(hour: 10, minute: 0)).timeRangeError,
        '종료 시간은 시작 시간보다 늦어야 합니다.',
      );
      expect(
        draft.withEndTime(const TimeOfDay(hour: 9, minute: 30)).timeRangeError,
        '종료 시간은 시작 시간보다 늦어야 합니다.',
      );
      expect(
        draft.withEndTime(const TimeOfDay(hour: 10, minute: 30)).timeRangeError,
        isNull,
      );
    });

    test('does not report a hidden time range as an error', () {
      final draft = const NewItemScheduleDraft()
          .withStartTime(const TimeOfDay(hour: 10, minute: 0))
          .withEndTime(const TimeOfDay(hour: 9, minute: 30))
          .withMode(NewItemTimeMode.allDay);

      expect(draft.timeRangeError, isNull);
    });
  });
}
