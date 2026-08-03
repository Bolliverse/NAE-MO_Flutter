import 'package:flutter/material.dart';

enum DailyGlobalAction {
  add,
  routine,
  category,
  settings,
}

class ExpandableMenuFab extends StatefulWidget {
  const ExpandableMenuFab({required this.onSelected, super.key});

  final ValueChanged<DailyGlobalAction> onSelected;

  @override
  State<ExpandableMenuFab> createState() => _ExpandableMenuFabState();
}

class _ExpandableMenuFabState extends State<ExpandableMenuFab>
    with SingleTickerProviderStateMixin {
  static const _navy = Color(0xFF2E4175);
  static const _menuItems = <_GlobalMenuItem>[
    _GlobalMenuItem(
      action: DailyGlobalAction.add,
      keyName: 'globalAddAction',
      label: '새 항목 추가',
      icon: Icons.add_rounded,
    ),
    _GlobalMenuItem(
      action: DailyGlobalAction.routine,
      keyName: 'globalRoutineAction',
      label: '루틴 관리',
      icon: Icons.repeat_rounded,
    ),
    _GlobalMenuItem(
      action: DailyGlobalAction.category,
      keyName: 'globalCategoryAction',
      label: '카테고리 관리',
      icon: Icons.palette_outlined,
    ),
    _GlobalMenuItem(
      action: DailyGlobalAction.settings,
      keyName: 'globalSettingsAction',
      label: '설정',
      icon: Icons.settings_outlined,
    ),
  ];

  bool _isOpen = false;

  void _toggle() {
    setState(() => _isOpen = !_isOpen);
  }

  void _close() {
    if (_isOpen) setState(() => _isOpen = false);
  }

  void _select(DailyGlobalAction action) {
    _close();
    widget.onSelected(action);
  }

  @override
  Widget build(BuildContext context) {
    return TapRegion(
      onTapOutside: (_) => _close(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            reverseDuration: const Duration(milliseconds: 120),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SizeTransition(
                sizeFactor: animation,
                axisAlignment: 1,
                child: child,
              ),
            ),
            child: _isOpen
                ? Padding(
                    key: const Key('globalActionsMenu'),
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (final item in _menuItems) ...[
                          _ActionButton(
                            item: item,
                            color: _navy,
                            onTap: () => _select(item.action),
                          ),
                          if (item != _menuItems.last)
                            const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          Semantics(
            key: const Key('calendarGlobalMenuButton'),
            label: _isOpen ? '메뉴 닫기' : '메뉴 열기',
            button: true,
            onTap: _toggle,
            child: ExcludeSemantics(
              child: Material(
                color: _navy,
                elevation: 7,
                shadowColor: Colors.black45,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: _toggle,
                  child: SizedBox.square(
                    dimension: 60,
                    child: AnimatedRotation(
                      turns: _isOpen ? 0.25 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: Icon(
                        _isOpen ? Icons.close_rounded : Icons.menu_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.item,
    required this.color,
    required this.onTap,
  });

  final _GlobalMenuItem item;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: Key(item.keyName),
      label: item.label,
      button: true,
      onTap: onTap,
      child: ExcludeSemantics(
        child: Material(
          color: Colors.white,
          elevation: 4,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFFE4E7EC)),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48, maxWidth: 300),
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: const Color(0xFF202124),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox.square(
                      dimension: 48,
                      child: ColoredBox(
                        color: color,
                        child: Icon(item.icon, color: Colors.white, size: 23),
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
}

class _GlobalMenuItem {
  const _GlobalMenuItem({
    required this.action,
    required this.keyName,
    required this.label,
    required this.icon,
  });

  final DailyGlobalAction action;
  final String keyName;
  final String label;
  final IconData icon;
}
