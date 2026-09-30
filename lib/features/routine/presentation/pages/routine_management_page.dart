import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nae_mo/core/errors/failure.dart';
import 'package:nae_mo/core/utils/result.dart';
import 'package:nae_mo/features/routine/domain/entities/routine_definition.dart';
import 'package:nae_mo/features/routine/domain/entities/routine_rule.dart';
import 'package:nae_mo/features/routine/domain/usecases/routine_use_cases.dart';
import 'package:nae_mo/features/task/domain/entities/task.dart';
import 'package:nae_mo/features/task/presentation/widgets/new_item_category_input.dart';
import 'package:uuid/uuid.dart';

typedef RoutineLoader = Future<Result<List<RoutineDefinition>>> Function();
typedef RoutineCreator = Future<Result<RoutineDefinition>> Function(
  RoutineDefinition routine,
);

const _navy = Color(0xFF2E4175);
const _border = Color(0xFFE4E7EC);
const _muted = Color(0xFF667085);

class RoutineManagementPage extends ConsumerStatefulWidget {
  const RoutineManagementPage({
    required this.initialDate,
    required this.onClose,
    this.loader,
    this.creator,
    this.categoryLoader,
    super.key,
  });

  final DateTime initialDate;
  final VoidCallback onClose;
  final RoutineLoader? loader;
  final RoutineCreator? creator;
  final NewItemCategoryLoader? categoryLoader;

  @override
  ConsumerState<RoutineManagementPage> createState() =>
      _RoutineManagementPageState();
}

class _RoutineManagementPageState extends ConsumerState<RoutineManagementPage> {
  List<RoutineDefinition>? _routines;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_load);
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _routines = null;
        _failed = false;
      });
    }
    Result<List<RoutineDefinition>> result;
    try {
      result =
          await (widget.loader ?? ref.read(getRoutinesUseCaseProvider).call)();
    } catch (_) {
      result = fail(const CacheFailure('routine load failed'));
    }
    if (!mounted) return;
    setState(() {
      _failed = result.failure != null;
      _routines = result.data;
    });
  }

  Future<void> _showCreate() async {
    final create =
        widget.creator ?? ref.read(createRoutineUseCaseProvider).call;
    final saved = await showModalBottomSheet<RoutineDefinition>(
      context: context,
      backgroundColor: Colors.white,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _CreateRoutineSheet(
        initialDate: widget.initialDate,
        create: create,
        categoryLoader: widget.categoryLoader,
      ),
    );
    if (!mounted || saved == null) return;
    setState(() => _routines = [...?_routines, saved]);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) widget.onClose();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
            child: Center(
                child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(children: [
            SizedBox(
                height: 64,
                child: Row(children: [
                  IconButton(
                      key: const Key('routineCloseButton'),
                      onPressed: widget.onClose,
                      tooltip: '닫기',
                      icon: const Icon(Icons.close_rounded)),
                  Expanded(
                      child: Text('루틴 관리',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700))),
                ])),
            const Divider(height: 1, color: _border),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Text('루틴 규칙을 저장합니다. 날짜별 항목 생성은 다음 단계에서 제공됩니다.',
                  style: TextStyle(color: _muted, fontSize: 12)),
            ),
            Expanded(
                child: _failed
                    ? Center(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                        const Text('루틴을 불러오지 못했습니다.'),
                        TextButton(
                            key: const Key('routineRetryButton'),
                            onPressed: _load,
                            style: TextButton.styleFrom(foregroundColor: _navy),
                            child: const Text('다시 시도')),
                      ]))
                    : _routines == null
                        ? const Center(
                            child: CircularProgressIndicator(
                                key: Key('routineLoading'), color: _navy))
                        : _routines!.isEmpty
                            ? const Center(
                                child: Text('아직 루틴이 없습니다.',
                                    key: Key('routineEmptyState'),
                                    style: TextStyle(color: _muted)))
                            : ListView.separated(
                                key: const Key('routineList'),
                                padding:
                                    const EdgeInsets.fromLTRB(20, 18, 20, 20),
                                itemCount: _routines!.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1, color: _border),
                                itemBuilder: (context, index) =>
                                    _RoutineRow(routine: _routines![index]),
                              )),
            if (_routines != null)
              Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: FilledButton.icon(
                    key: const Key('routineAddButton'),
                    onPressed: _showCreate,
                    style: FilledButton.styleFrom(
                        backgroundColor: _navy,
                        minimumSize: const Size.fromHeight(52)),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('새 루틴'),
                  )),
          ]),
        ))),
      ),
    );
  }
}

class _RoutineRow extends StatelessWidget {
  const _RoutineRow({required this.routine});
  final RoutineDefinition routine;
  @override
  Widget build(BuildContext context) {
    final rule = routine.rule;
    final frequency = _frequencyName(rule.frequency);
    final mode =
        rule.creationMode == RoutineCreationMode.manual ? '수동 추가' : '자동 추가';
    return Semantics(
      key: Key('routineRow-${routine.id}'),
      container: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(routine.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF202124), fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
              '${routine.kind == TaskKind.event ? '일정' : 'Todo'} · $frequency · $mode',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: _muted)),
        ]),
      ),
    );
  }
}

String _frequencyName(RoutineFrequency frequency) => switch (frequency) {
      RoutineFrequency.daily => '매일',
      RoutineFrequency.weekly => '매주',
      RoutineFrequency.monthly => '매월',
      RoutineFrequency.yearly => '매년',
      RoutineFrequency.custom => '사용자 정의',
    };

class _CreateRoutineSheet extends ConsumerStatefulWidget {
  const _CreateRoutineSheet({
    required this.initialDate,
    required this.create,
    this.categoryLoader,
  });
  final DateTime initialDate;
  final RoutineCreator create;
  final NewItemCategoryLoader? categoryLoader;

  @override
  ConsumerState<_CreateRoutineSheet> createState() =>
      _CreateRoutineSheetState();
}

class _CreateRoutineSheetState extends ConsumerState<_CreateRoutineSheet> {
  final _title = TextEditingController();
  final _interval = TextEditingController(text: '2');
  TaskKind _kind = TaskKind.todo;
  String? _categoryId;
  late DateTime _start;
  DateTime? _end;
  RoutineFrequency _frequency = RoutineFrequency.daily;
  RoutineIntervalUnit _unit = RoutineIntervalUnit.day;
  final _weekdays = <int>{};
  bool _timed = false;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _saving = false;
  bool _failed = false;

  bool get _showsWeekdays =>
      _frequency == RoutineFrequency.weekly ||
      (_frequency == RoutineFrequency.custom &&
          _unit == RoutineIntervalUnit.week);

  RoutineDefinition _draft(String id) {
    final start = _start.toLocal();
    final end = _end?.toLocal();
    return RoutineDefinition(
      rule: RoutineRule(
        id: id,
        startDate: DateTime(start.year, start.month, start.day),
        endDate: end == null ? null : DateTime(end.year, end.month, end.day),
        frequency: _frequency,
        creationMode: RoutineCreationMode.manual,
        interval: _frequency == RoutineFrequency.custom
            ? int.tryParse(_interval.text.trim()) ?? 0
            : 1,
        customUnit: _frequency == RoutineFrequency.custom ? _unit : null,
        weekdays: _showsWeekdays ? _weekdays : const {},
      ),
      title: _title.text.trim(),
      kind: _kind,
      categoryId: _categoryId,
      hasTime: _timed,
      isAllDay: _kind == TaskKind.event && !_timed,
      startMinute: _timed && _startTime != null
          ? _startTime!.hour * 60 + _startTime!.minute
          : null,
      endMinute: _timed && _endTime != null
          ? _endTime!.hour * 60 + _endTime!.minute
          : null,
    );
  }

  bool get _canSave => !_saving && _draft('preview').validate() == null;

  @override
  void initState() {
    super.initState();
    final local = widget.initialDate.toLocal();
    _start = DateTime(local.year, local.month, local.day);
    _title.addListener(_onInputChanged);
    _interval.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _title
      ..removeListener(_onInputChanged)
      ..dispose();
    _interval
      ..removeListener(_onInputChanged)
      ..dispose();
    super.dispose();
  }

  void _onInputChanged() {
    if (mounted) setState(() => _failed = false);
  }

  void _set(VoidCallback update) => setState(() {
        update();
        _failed = false;
      });

  Future<void> _chooseDate({required bool end}) async {
    final initial = end ? _end ?? _start : _start;
    final selected = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime(1900),
        lastDate: DateTime(2100),
        builder: (context, child) => Theme(
              data: Theme.of(context).copyWith(
                  colorScheme:
                      Theme.of(context).colorScheme.copyWith(primary: _navy)),
              child: child!,
            ));
    if (!mounted || selected == null) return;
    _set(() {
      if (end) {
        _end = selected;
      } else {
        _start = selected;
      }
    });
  }

  Future<void> _chooseTime({required bool end}) async {
    final selected = await showTimePicker(
        context: context,
        initialTime: end
            ? _endTime ?? const TimeOfDay(hour: 10, minute: 0)
            : _startTime ?? const TimeOfDay(hour: 9, minute: 0),
        builder: (context, child) => Theme(
              data: Theme.of(context).copyWith(
                  colorScheme:
                      Theme.of(context).colorScheme.copyWith(primary: _navy)),
              child: child!,
            ));
    if (!mounted || selected == null) return;
    _set(() {
      if (end) {
        _endTime = selected;
      } else {
        _startTime = selected;
      }
    });
  }

  Future<void> _save() async {
    if (!_canSave) return;
    final routine = _draft(const Uuid().v4());
    _set(() => _saving = true);
    Result<RoutineDefinition> result;
    try {
      result = await widget.create(routine);
    } catch (_) {
      result = fail(const CacheFailure('routine create failed'));
    }
    if (!mounted) return;
    if (result.isSuccess) {
      Navigator.of(context).pop(result.data!);
      return;
    }
    setState(() {
      _saving = false;
      _failed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final available = MediaQuery.sizeOf(context).height -
        MediaQuery.viewInsetsOf(context).bottom;
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: _navy,
              surface: Colors.white,
              surfaceTint: Colors.transparent,
            ),
      ),
      child: PopScope(
        canPop: !_saving,
        child: SizedBox(
          key: const Key('routineCreateSheet'),
          height: available * .92,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            child: Column(children: [
              Row(children: [
                Expanded(
                    child: Text('새 루틴',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700))),
                IconButton(
                    key: const Key('routineCreateCloseButton'),
                    onPressed:
                        _saving ? null : () => Navigator.of(context).pop(),
                    tooltip: '닫기',
                    icon: const Icon(Icons.close_rounded)),
              ]),
              Expanded(
                child: AbsorbPointer(
                    absorbing: _saving,
                    child: SingleChildScrollView(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                          const SizedBox(height: 16),
                          const _Label('종류'),
                          const SizedBox(height: 8),
                          Row(children: [
                            Expanded(
                                child: _SelectButton(
                                    key: const Key('routineTodoKind'),
                                    title: 'Todo',
                                    selected: _kind == TaskKind.todo,
                                    onTap: () =>
                                        _set(() => _kind = TaskKind.todo))),
                            const SizedBox(width: 8),
                            Expanded(
                                child: _SelectButton(
                                    key: const Key('routineEventKind'),
                                    title: '일정',
                                    selected: _kind == TaskKind.event,
                                    onTap: () =>
                                        _set(() => _kind = TaskKind.event))),
                          ]),
                          const SizedBox(height: 20),
                          const _Label('제목'),
                          const SizedBox(height: 8),
                          TextField(
                              key: const Key('routineTitleField'),
                              controller: _title,
                              decoration:
                                  const InputDecoration(hintText: '루틴 이름')),
                          const SizedBox(height: 20),
                          const _Label('카테고리'),
                          const SizedBox(height: 8),
                          NewItemCategoryInput(
                              loader: widget.categoryLoader,
                              selectedId: _categoryId,
                              onSelected: (id) => _set(() => _categoryId = id)),
                          const SizedBox(height: 20),
                          const _Label('반복'),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<RoutineFrequency>(
                            key: const Key('routineFrequency'),
                            value: _frequency,
                            items: [
                              for (final frequency in RoutineFrequency.values)
                                DropdownMenuItem(
                                    value: frequency,
                                    child: Text(_frequencyName(frequency)))
                            ],
                            onChanged: (value) {
                              if (value != null) _set(() => _frequency = value);
                            },
                          ),
                          if (_frequency == RoutineFrequency.custom) ...[
                            const SizedBox(height: 12),
                            Row(children: [
                              Expanded(
                                  child: TextField(
                                key: const Key('routineInterval'),
                                controller: _interval,
                                keyboardType: TextInputType.number,
                                decoration:
                                    const InputDecoration(labelText: '간격'),
                              )),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: DropdownButtonFormField<
                                      RoutineIntervalUnit>(
                                key: const Key('routineIntervalUnit'),
                                value: _unit,
                                items: [
                                  for (final unit in RoutineIntervalUnit.values)
                                    DropdownMenuItem(
                                        value: unit,
                                        child: Text(switch (unit) {
                                          RoutineIntervalUnit.day => '일마다',
                                          RoutineIntervalUnit.week => '주마다',
                                          RoutineIntervalUnit.month => '개월마다',
                                          RoutineIntervalUnit.year => '년마다',
                                        }))
                                ],
                                onChanged: (value) {
                                  if (value != null) _set(() => _unit = value);
                                },
                              )),
                            ]),
                            if ((int.tryParse(_interval.text.trim()) ?? 0) < 1)
                              const Text('간격은 1 이상의 숫자로 입력해 주세요.',
                                  style: TextStyle(
                                      color: Color(0xFFB42318), fontSize: 12)),
                          ],
                          if (_showsWeekdays) ...[
                            const SizedBox(height: 12),
                            Wrap(spacing: 6, runSpacing: 4, children: [
                              for (var day = DateTime.monday;
                                  day <= DateTime.sunday;
                                  day++)
                                FilterChip(
                                  key: Key('routineWeekday-$day'),
                                  label: Text([
                                    '월',
                                    '화',
                                    '수',
                                    '목',
                                    '금',
                                    '토',
                                    '일'
                                  ][day - 1]),
                                  selected: _weekdays.contains(day),
                                  selectedColor: _navy,
                                  checkmarkColor: Colors.white,
                                  labelStyle: TextStyle(
                                      color: _weekdays.contains(day)
                                          ? Colors.white
                                          : const Color(0xFF202124)),
                                  onSelected: (selected) => _set(() {
                                    if (selected) {
                                      _weekdays.add(day);
                                    } else {
                                      _weekdays.remove(day);
                                    }
                                  }),
                                ),
                            ]),
                            if (_weekdays.isEmpty)
                              const Text('요일을 고르지 않으면 시작일의 요일에 반복합니다.',
                                  style:
                                      TextStyle(fontSize: 12, color: _muted)),
                          ],
                          const SizedBox(height: 20),
                          const _Label('기간'),
                          const SizedBox(height: 8),
                          OutlinedButton(
                              key: const Key('routineStartDate'),
                              onPressed: () => _chooseDate(end: false),
                              child: Text(
                                  '시작일 ${_start.year}.${_start.month}.${_start.day}')),
                          Row(children: [
                            Expanded(
                                child: OutlinedButton(
                                    key: const Key('routineEndDate'),
                                    onPressed: () => _chooseDate(end: true),
                                    child: Text(_end == null
                                        ? '종료일 없음'
                                        : '종료일 ${_end!.year}.${_end!.month}.${_end!.day}'))),
                            if (_end != null)
                              IconButton(
                                  key: const Key('routineClearEndDate'),
                                  tooltip: '종료일 지우기',
                                  onPressed: () => _set(() {
                                        _end = null;
                                      }),
                                  icon: const Icon(Icons.close_rounded)),
                          ]),
                          if (_end != null && _end!.isBefore(_start))
                            const Text('종료일은 시작일보다 빠를 수 없습니다.',
                                style: TextStyle(
                                    color: Color(0xFFB42318), fontSize: 12)),
                          const SizedBox(height: 20),
                          const _Label('추가 방식'),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                                '수동 추가 규칙으로 저장됩니다. 후보 표시와 자동 추가는 후속 기능입니다.',
                                style: TextStyle(fontSize: 12, color: _muted)),
                          ),
                          const SizedBox(height: 16),
                          const _Label('시간'),
                          SwitchListTile(
                              key: const Key('routineTimedSwitch'),
                              contentPadding: EdgeInsets.zero,
                              title: Text(_kind == TaskKind.event
                                  ? '시간 지정 (끄면 종일)'
                                  : '시간 지정 (끄면 시간 없음)'),
                              value: _timed,
                              onChanged: (value) => _set(() => _timed = value)),
                          if (_timed)
                            Row(children: [
                              Expanded(
                                  child: OutlinedButton(
                                      key: const Key('routineStartTime'),
                                      onPressed: () => _chooseTime(end: false),
                                      child: Text(_startTime == null
                                          ? '시작 선택'
                                          : _startTime!.format(context)))),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: OutlinedButton(
                                      key: const Key('routineEndTime'),
                                      onPressed: () => _chooseTime(end: true),
                                      child: Text(_endTime == null
                                          ? '종료 선택'
                                          : _endTime!.format(context)))),
                            ]),
                          if (_timed &&
                              (_startTime == null ||
                                  _endTime == null ||
                                  (_startTime!.hour * 60 +
                                          _startTime!.minute) >=
                                      (_endTime!.hour * 60 + _endTime!.minute)))
                            const Text('종료 시각은 시작 시각보다 늦어야 합니다.',
                                style: TextStyle(
                                    color: Color(0xFFB42318), fontSize: 12)),
                          const SizedBox(height: 24),
                        ]))),
              ),
              if (_failed)
                Semantics(
                    key: const Key('routineCreateError'),
                    liveRegion: true,
                    child: const Text('루틴을 저장하지 못했습니다. 다시 시도해 주세요.',
                        style: TextStyle(color: Color(0xFFB42318)))),
              FilledButton(
                  key: const Key('routineCreateButton'),
                  onPressed: _canSave ? _save : null,
                  style: FilledButton.styleFrom(
                      backgroundColor: _navy,
                      minimumSize: const Size.fromHeight(52)),
                  child: _saving
                      ? const Row(mainAxisSize: MainAxisSize.min, children: [
                          SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2)),
                          SizedBox(width: 8),
                          Text('저장 중')
                        ])
                      : const Text('루틴 저장')),
            ]),
          ),
        ),
      ),
    );
  }
}

class _SelectButton extends StatelessWidget {
  const _SelectButton(
      {required this.title,
      required this.selected,
      required this.onTap,
      super.key});
  final String title;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
            backgroundColor: selected ? _navy : Colors.white,
            foregroundColor: selected ? Colors.white : const Color(0xFF202124),
            minimumSize: const Size.fromHeight(52)),
        child: Text(title),
      );
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: const Color(0xFF475467), fontWeight: FontWeight.w700));
}
