import 'package:flutter/material.dart';
import '../services/calendar_events_store.dart';
import '../services/festivals_data.dart';
import '../theme/contra_theme.dart';
import '../widgets/custom_keyboard.dart';
import '../widgets/long_tap.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focused = DateTime.now();
  DateTime _selected = DateTime.now();
  Map<String, List<String>> _events = {};

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  String _monthShort(int m) => _months[m - 1];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final events = await CalendarEventsStore.load();
    if (mounted) setState(() => _events = events);
  }

  void _changeMonth(int delta) {
    setState(() {
      _focused = DateTime(_focused.year, _focused.month + delta, 1);
    });
  }

  void _selectDay(int day) {
    setState(() {
      _selected = DateTime(_focused.year, _focused.month, day);
    });
  }

  Future<void> _addEvent() async {
    final controller = TextEditingController();
    final key = CalendarEventsStore.dayKey(_selected);
    final saved = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ContraTheme.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add event on '
              '${_selected.day} ${_monthShort(_selected.month)}',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: ContraTheme.ink,
              ),
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: controller,
              hint: 'Event name (eg. Doctor visit)',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Material(
                    color: ContraTheme.card,
                    borderRadius: BorderRadius.circular(18),
                    child: LongTap(
                      onActivate: () => Navigator.of(sheetContext).pop(),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Center(
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: ContraTheme.ink,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Material(
                    color: ContraTheme.teal,
                    borderRadius: BorderRadius.circular(18),
                    child: LongTap(
                      onActivate: () {
                        final name = controller.text.trim();
                        if (name.isEmpty) {
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(const SnackBar(
                              content:
                                  Text('Type an event name first',
                                      style: TextStyle(
                                          fontFamily: 'Poppins')),
                              duration: Duration(seconds: 2),
                            ));
                          return;
                        }
                        Navigator.of(sheetContext).pop(name);
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Center(
                          child: Text(
                            'Save',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (saved != null && saved.trim().isNotEmpty) {
      setState(() {
        _events.putIfAbsent(key, () => []).add(saved.trim());
      });
      await CalendarEventsStore.save(_events);
    }
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstDay = DateTime(_focused.year, _focused.month, 1);
    final daysInMonth = DateTime(_focused.year, _focused.month + 1, 0).day;
    final leadingBlanks = firstDay.weekday - 1;

    final todayIsThisMonth =
        now.year == _focused.year && now.month == _focused.month;

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Column(
        children: [
          Row(
            children: [
              _NavIconButton(
                icon: Icons.chevron_left_rounded,
                onTap: () => _changeMonth(-1),
              ),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${_focused.year} · ${_monthName(_focused.month)}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: ContraTheme.ink,
                    ),
                  ),
                ),
              ),
              _NavIconButton(
                icon: Icons.chevron_right_rounded,
                onTap: () => _changeMonth(1),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final d in _weekdays)
                Expanded(
                  child: Text(
                    d,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: ContraTheme.muted,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            flex: 3,
            child: GridView.count(
              crossAxisCount: 7,
              mainAxisSpacing: 3,
              crossAxisSpacing: 3,
              children: [
                for (var i = 0; i < leadingBlanks; i++) const SizedBox(),
                for (var day = 1; day <= daysInMonth; day++)
                  _DayCell(
                    day: day,
                    isToday: todayIsThisMonth && day == now.day,
                    isSelected: _selected.year == _focused.year &&
                        _selected.month == _focused.month &&
                        _selected.day == day,
                    hasEvents: FestivalsData.forDay(
                              DateTime(_focused.year, _focused.month, day),
                            ).isNotEmpty ||
                        _events[
                                CalendarEventsStore.dayKey(DateTime(
                                    _focused.year, _focused.month, day))] !=
                            null,
                    onTap: () => _selectDay(day),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            flex: 2,
            child: _EventsPanel(
              selected: _selected,
              events: _events[CalendarEventsStore.dayKey(_selected)] ?? const [],
              onAdd: _addEvent,
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(int m) {
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return names[m - 1];
  }
}

class _EventsPanel extends StatelessWidget {
  final DateTime selected;
  final List<String> events;
  final VoidCallback onAdd;
  const _EventsPanel({
    required this.selected,
    required this.events,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final festivals = FestivalsData.forDay(selected);
    final upcoming = FestivalsData.upcoming(today, limit: 8);
    final hasContent = festivals.isNotEmpty || events.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: ContraTheme.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  hasContent
                      ? '${selected.day} ${_monthShort(selected.month)}'
                      : 'Upcoming events',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: ContraTheme.ink,
                  ),
                ),
              ),
              Material(
                color: ContraTheme.teal,
                shape: const CircleBorder(),
                elevation: 1,
                child: LongTap(
                  onActivate: onAdd,
                  child: const SizedBox(
                    width: 34,
                    height: 34,
                    child: Icon(Icons.add_rounded,
                        color: Colors.white, size: 22),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: hasContent
                ? ListView.separated(
                    itemCount: festivals.length + events.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: ContraTheme.bg),
                    itemBuilder: (context, i) {
                      if (i < events.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              const Icon(Icons.event_rounded,
                                  color: ContraTheme.teal, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  events[i],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: ContraTheme.ink,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      final f = festivals[i - events.length];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Text(f.emoji,
                                style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                f.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: ContraTheme.ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  )
                : upcoming.isEmpty
                    ? const Center(
                        child: Text(
                          'Nothing special on this day',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: ContraTheme.muted,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: upcoming.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: ContraTheme.bg),
                        itemBuilder: (context, i) {
                          final (date, f) = upcoming[i];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              children: [
                                Text(f.emoji,
                                    style: const TextStyle(fontSize: 18)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    f.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: ContraTheme.ink,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${date.day} ${_monthShort(date.month)}',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: ContraTheme.muted,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  static String _monthShort(int m) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return names[m - 1];
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final bool isToday;
  final bool isSelected;
  final bool hasEvents;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.hasEvents,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final numberStyle = TextStyle(
      fontFamily: 'Poppins',
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: isSelected ? Colors.white : ContraTheme.ink,
    );

    return Material(
      color: isSelected ? ContraTheme.teal : ContraTheme.card,
      shape: const CircleBorder(),
      child: LongTap(
        onActivate: onTap,
        child: Container(
          decoration: isToday && !isSelected
              ? BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: ContraTheme.teal, width: 2.5),
                )
              : BoxDecoration(
                  shape: BoxShape.circle,
                  color: hasEvents && !isSelected
                      ? ContraTheme.teal.withValues(alpha: 0.12)
                      : null,
                ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('$day', style: numberStyle),
              ),
              const SizedBox(height: 2),
              if (hasEvents)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? Colors.white : ContraTheme.green,
                      ),
                    ),
                  ],
                )
              else
                const SizedBox(height: 5),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ContraTheme.card,
      shape: const CircleBorder(),
      elevation: 1,
      child: LongTap(
        onActivate: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, color: ContraTheme.ink, size: 24),
        ),
      ),
    );
  }
}