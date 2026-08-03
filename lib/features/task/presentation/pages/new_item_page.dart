import 'package:flutter/material.dart';

enum NewItemKind {
  event,
  todo,
}

class NewItemPage extends StatefulWidget {
  const NewItemPage({
    required this.selectedDate,
    required this.onClose,
    super.key,
  });

  final DateTime selectedDate;
  final VoidCallback onClose;

  @override
  State<NewItemPage> createState() => _NewItemPageState();
}

class _NewItemPageState extends State<NewItemPage> {
  static const _navy = Color(0xFF2E4175);

  final _titleController = TextEditingController();
  NewItemKind _kind = NewItemKind.event;

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
      onPopInvoked: (didPop) {
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
                            selected: _kind,
                            onSelected: (kind) => setState(() => _kind = kind),
                          ),
                          const SizedBox(height: 28),
                          const _FieldLabel('제목'),
                          const SizedBox(height: 8),
                          TextField(
                            key: const Key('newItemTitleField'),
                            controller: _titleController,
                            autofocus: false,
                            textInputAction: TextInputAction.done,
                            decoration: InputDecoration(
                              hintText: _kind == NewItemKind.event
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
          TextButton(
            key: const Key('newItemSaveButton'),
            onPressed: null,
            child: const Text('저장'),
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
