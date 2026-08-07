import 'package:flutter/material.dart';
import 'package:nae_mo/features/task/presentation/states/new_item_schedule_draft.dart';

typedef NewItemTimePicker = Future<TimeOfDay?> Function(
  BuildContext context,
  TimeOfDay initialTime,
);

class NewItemPage extends StatefulWidget {
  const NewItemPage({
    required this.selectedDate,
    required this.onClose,
    this.timePicker,
    super.key,
  });

  final DateTime selectedDate;
  final VoidCallback onClose;
  final NewItemTimePicker? timePicker;

  @override
  State<NewItemPage> createState() => _NewItemPageState();
}

class _NewItemPageState extends State<NewItemPage> {
  static const _navy = Color(0xFF2E4175);

  final _titleController = TextEditingController();
  NewItemScheduleDraft _draft = const NewItemScheduleDraft();

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final date = widget.selectedDate.toLocal();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) widget.onClose();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                children: [
                  _Header(onClose: widget.onClose),
                  const Divider(height: 1, color: Color(0xFFE4E7EC)),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _FieldLabel('날짜'),
                          const SizedBox(height: 8),
                          _FixedDate(date: date),
                          const SizedBox(height: 28),
                          const _FieldLabel('종류'),
                          const SizedBox(height: 8),
                          _KindSelector(
                            selected: _draft.kind,
                            onSelected: (kind) => setState(
                              () => _draft = _draft.withKind(kind),
                            ),
                          ),
                          const SizedBox(height: 28),
                          const _FieldLabel('제목'),
                          const SizedBox(height: 8),
                          Semantics(
                            key: const Key('newItemTitleSemantics'),
                            label: '제목',
                            textField: true,
                            child: TextField(
                              key: const Key('newItemTitleField'),
                              controller: _titleController,
                              autofocus: false,
                              textInputAction: TextInputAction.done,
                              decoration: InputDecoration(
                                hintText: _draft.kind == NewItemKind.event
                                    ? '일정 제목'
                                    : 'Todo 제목',
                                filled: true,
                                fillColor: Colors.white,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFD0D5DD),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: _navy,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          const _FieldLabel('시간'),
                          const SizedBox(height: 8),
                          _TimeModeSelector(
                            kind: _draft.kind,
                            selected: _draft.activeMode,
                            onSelected: (mode) => setState(
                              () => _draft = _draft.withMode(mode),
                            ),
                          ),
                          if (_draft.showsTimeFields) ...[
                            const SizedBox(height: 12),
                            _TimeRangeFields(
                              startTime: _draft.startTime,
                              endTime: _draft.endTime,
                              error: _draft.timeRangeError,
                              onSelectStart: () => _selectTime(isStart: true),
                              onSelectEnd: () => _selectTime(isStart: false),
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
        ),
      ),
    );
  }

  Future<void> _selectTime({required bool isStart}) async {
    final current = isStart ? _draft.startTime : _draft.endTime;
    final initial = current ??
        (isStart ? TimeOfDay.now() : _draft.startTime ?? TimeOfDay.now());
    final selected = await (widget.timePicker ?? _showTimePicker)(
      context,
      initial,
    );
    if (!mounted || selected == null) return;

    setState(() {
      _draft = isStart
          ? _draft.withStartTime(selected)
          : _draft.withEndTime(selected);
    });
  }

  Future<TimeOfDay?> _showTimePicker(
    BuildContext context,
    TimeOfDay initialTime,
  ) {
    return showTimePicker(context: context, initialTime: initialTime);
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Row(
        children: [
          IconButton(
            key: const Key('newItemCloseButton'),
            onPressed: onClose,
            tooltip: '닫기',
            constraints: const BoxConstraints.tightFor(width: 56, height: 56),
            icon: const Icon(Icons.close_rounded),
          ),
          Expanded(
            child: Text(
              '새 항목 추가',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: const Color(0xFF202124),
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const TextButton(
            key: Key('newItemSaveButton'),
            onPressed: null,
            child: Text('저장'),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _FixedDate extends StatelessWidget {
  const _FixedDate({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '선택 날짜 ${date.year}년 ${date.month}월 ${date.day}일',
      readOnly: true,
      child: ExcludeSemantics(
        child: Container(
          key: const Key('newItemSelectedDate'),
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFD0D5DD)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 20,
                color: Color(0xFF667085),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${date.year}년 ${date.month}월 ${date.day}일',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF202124),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KindSelector extends StatelessWidget {
  const _KindSelector({required this.selected, required this.onSelected});

  final NewItemKind selected;
  final ValueChanged<NewItemKind> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _KindButton(
            key: const Key('newItemEventKind'),
            label: '일정',
            selected: selected == NewItemKind.event,
            onTap: () => onSelected(NewItemKind.event),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _KindButton(
            key: const Key('newItemTodoKind'),
            label: 'Todo',
            selected: selected == NewItemKind.todo,
            onTap: () => onSelected(NewItemKind.todo),
          ),
        ),
      ],
    );
  }
}

class _KindButton extends StatelessWidget {
  const _KindButton({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF2E4175);

    return Semantics(
      label: label,
      button: true,
      selected: selected,
      onTap: onTap,
      child: ExcludeSemantics(
        child: Material(
          color: selected ? navy : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: selected ? navy : const Color(0xFFD0D5DD),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: Center(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color:
                            selected ? Colors.white : const Color(0xFF344054),
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeModeSelector extends StatelessWidget {
  const _TimeModeSelector({
    required this.kind,
    required this.selected,
    required this.onSelected,
  });

  final NewItemKind kind;
  final NewItemTimeMode selected;
  final ValueChanged<NewItemTimeMode> onSelected;

  @override
  Widget build(BuildContext context) {
    final options = switch (kind) {
      NewItemKind.event => const [
          _TimeModeOption(
            key: Key('newItemTimedMode'),
            label: '시간 지정',
            mode: NewItemTimeMode.timed,
          ),
          _TimeModeOption(
            key: Key('newItemAllDayMode'),
            label: '종일',
            mode: NewItemTimeMode.allDay,
          ),
        ],
      NewItemKind.todo => const [
          _TimeModeOption(
            key: Key('newItemUntimedMode'),
            label: '시간 없음',
            mode: NewItemTimeMode.untimed,
          ),
          _TimeModeOption(
            key: Key('newItemTimedMode'),
            label: '시간 지정',
            mode: NewItemTimeMode.timed,
          ),
        ],
    };

    return Row(
      children: [
        for (var index = 0; index < options.length; index++) ...[
          if (index > 0) const SizedBox(width: 10),
          Expanded(
            child: _KindButton(
              key: options[index].key,
              label: options[index].label,
              selected: selected == options[index].mode,
              onTap: () => onSelected(options[index].mode),
            ),
          ),
        ],
      ],
    );
  }
}

@immutable
class _TimeModeOption {
  const _TimeModeOption({
    required this.key,
    required this.label,
    required this.mode,
  });

  final Key key;
  final String label;
  final NewItemTimeMode mode;
}

class _TimeRangeFields extends StatelessWidget {
  const _TimeRangeFields({
    required this.startTime,
    required this.endTime,
    required this.error,
    required this.onSelectStart,
    required this.onSelectEnd,
  });

  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final String? error;
  final VoidCallback onSelectStart;
  final VoidCallback onSelectEnd;

  @override
  Widget build(BuildContext context) {
    final startButton = _TimePickerButton(
      key: const Key('newItemStartTimeButton'),
      label: '시작',
      value: startTime,
      onTap: onSelectStart,
    );
    final endButton = _TimePickerButton(
      key: const Key('newItemEndTimeButton'),
      label: '종료',
      value: endTime,
      onTap: onSelectEnd,
    );
    final useColumn = MediaQuery.textScalerOf(context).scale(1) > 1.4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (useColumn) ...[
          startButton,
          const SizedBox(height: 10),
          endButton,
        ] else
          Row(
            children: [
              Expanded(child: startButton),
              const SizedBox(width: 10),
              Expanded(child: endButton),
            ],
          ),
        if (error != null) ...[
          const SizedBox(height: 8),
          Semantics(
            liveRegion: true,
            child: Text(
              error!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFB42318),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ],
    );
  }
}

class _TimePickerButton extends StatelessWidget {
  const _TimePickerButton({
    required this.label,
    required this.value,
    required this.onTap,
    super.key,
  });

  final String label;
  final TimeOfDay? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final displayValue = value == null ? '선택' : _formatTime(value!);

    return Semantics(
      label: '$label 시간 $displayValue',
      button: true,
      onTap: onTap,
      child: ExcludeSemantics(
        child: Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFD0D5DD)),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: const Color(0xFF667085),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      displayValue,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: const Color(0xFF202124),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final period = time.hour < 12 ? '오전' : '오후';
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    return '$period $hour:$minute';
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: const Color(0xFF475467),
            fontWeight: FontWeight.w700,
          ),
    );
  }
}
