import 'package:flutter/material.dart';
import '../services/festivals_data.dart';
import '../services/home_items_store.dart';
import '../theme/contra_theme.dart';
import '../widgets/custom_keyboard.dart';
import '../widgets/long_press.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focused = DateTime.now();
  DateTime _selected = DateTime.now();
  List<CalendarEventItem> _userEvents = [];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final events = await HomeItemsStore.loadEvents();
    if (mounted) setState(() => _userEvents = events);
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  List<CalendarEventItem> _eventsForDay(DateTime d) =>
      _userEvents.where((e) => e.date == _dateKey(d)).toList();

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
    final title = TextEditingController();
    final note = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ContraTheme.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Event on ${_selected.day} ${_monthShort(_selected.month)}',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: ContraTheme.ink,
              ),
            ),
            const SizedBox(height: 14),
            CustomTextField(controller: title, hint: 'Event title'),
            const SizedBox(height: 12),
            CustomTextField(controller: note, hint: 'Notes (optional)'),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: Material(
                color: ContraTheme.green,
                borderRadius: BorderRadius.circular(20),
                child: LongPressInk(
                  onTap: () async {
                    if (title.text.trim().isEmpty) return;
                    _userEvents.add(CalendarEventItem(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      date: _dateKey(_selected),
                      title: title.text.trim(),
                      note: note.text.trim(),
                    ));
                    await HomeItemsStore.saveEvents(_userEvents);
                    if (mounted) {
                      Navigator.of(context).pop();
                      _loadEvents();
                    }
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        'Save event',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 20,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final h = MediaQuery.of(context).size.height;
    final small = h < 660;
    final firstDay = DateTime(_focused.year, _focused.month, 1);
    final daysInMonth = DateTime(_focused.year, _focused.month + 1, 0).day;
    final leadingBlanks = firstDay.weekday - 1;
    final todayIsThisMonth =
        now.year == _focused.year && now.month == _focused.month;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Column(
        children: [
          Row(
            children: [
              _NavIconButton(
                icon: Icons.chevron_left_rounded,
                onTap: () => _changeMonth(-1),
              ),
              Expanded(
                child: Text(
                  '${_focused.year} · ${_monthName(_focused.month)}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: small ? 18 : 22,
                    fontWeight: FontWeight.w700,
                    color: ContraTheme.ink,
                  ),
                ),
              ),
              _NavIconButton(
                icon: Icons.chevron_right_rounded,
                onTap: () => _changeMonth(1),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final d in _weekdays)
                Expanded(
                  child: Text(
                    d,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: small ? 11 : 13,
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
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: small ? 1.0 : 1.1,
              children: [
                for (var i = 0; i < leadingBlanks; i++) const SizedBox(),
                for (var day = 1; day <= daysInMonth; day++)
                  _DayCell(
                    day: day,
                    small: small,
                    isToday: todayIsThisMonth && day == now.day,
                    isSelected: _selected.year == _focused.year &&
                        _selected.month == _focused.month &&
                        _selected.day == day,
                    hasEvents:
                        FestivalsData.forDay(
                                  DateTime(_focused.year, _focused.month, day),
                                ).isNotEmpty ||
                            _eventsForDay(DateTime(_focused.year, _focused.month, day))
                                .isNotEmpty,
                    onTap: () => _selectDay(day),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            flex: 2,
            child: _EventsPanel(
              selected: _selected,
              userEvents: _eventsForDay(_selected),
              onAdd: _addEvent,
              small: small,
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

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
}

String _monthShort(int m) {
  const names = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return names[m - 1];
}

class _EventsPanel extends StatelessWidget {
  final DateTime selected;
  final List<CalendarEventItem> userEvents;
  final VoidCallback onAdd;
  final bool small;
  const _EventsPanel({
    required this.selected,
    required this.userEvents,
    required this.onAdd,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final events = FestivalsData.forDay(selected);
    final upcoming = FestivalsData.upcoming(today, limit: 8);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: ContraTheme.card,
        border: Border.all(color: ContraTheme.border, width: 2),
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
                  events.isNotEmpty || userEvents.isNotEmpty
                      ? '${selected.day} ${_monthShort(selected.month)}'
                      : 'Upcoming events',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: small ? 14 : 16,
                    fontWeight: FontWeight.w700,
                    color: ContraTheme.ink,
                  ),
                ),
              ),
              Material(
                color: ContraTheme.yellow,
                shape: const CircleBorder(),
                child: LongPressInk(
                  onTap: onAdd,
                  customBorder: const CircleBorder(),
                  child: SizedBox(
                    width: 38,
                    height: 38,
                    child: const Icon(Icons.add_rounded,
                        color: Colors.white, size: 24),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: userEvents.isNotEmpty
                ? ListView.separated(
                    itemCount: userEvents.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: ContraTheme.bg),
                    itemBuilder: (context, i) {
                      final e = userEvents[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.event_rounded,
                                size: 20, color: ContraTheme.green),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                e.title,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: small ? 14 : 16,
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
                : events.isNotEmpty
                    ? ListView.separated(
                        itemCount: events.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: ContraTheme.bg),
                        itemBuilder: (context, i) {
                          final f = events[i];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Text(f.emoji,
                                    style: const TextStyle(fontSize: 22)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    f.name,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: small ? 14 : 16,
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
                                fontSize: 15,
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
                                        style: const TextStyle(fontSize: 20)),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        f.name,
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: small ? 13 : 15,
                                          fontWeight: FontWeight.w600,
                                          color: ContraTheme.ink,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${date.day} ${_monthShort(date.month)}',
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 14,
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
}

class _DayCell extends StatelessWidget {
  final int day;
  final bool isToday;
  final bool isSelected;
  final bool hasEvents;
  final VoidCallback onTap;
  final bool small;

  const _DayCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.hasEvents,
    required this.onTap,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final numberStyle = TextStyle(
      fontFamily: 'Poppins',
      fontSize: small ? 13 : 15,
      fontWeight: FontWeight.w600,
      color: isSelected ? Colors.white : ContraTheme.ink,
    );

    return Material(
      color: isSelected ? ContraTheme.blue : ContraTheme.card,
      shape: const CircleBorder(),
      child: LongPressInk(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          decoration: isToday && !isSelected
              ? BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: ContraTheme.blue, width: 2.5),
                )
              : BoxDecoration(
                  shape: BoxShape.circle,
                  color: hasEvents && !isSelected
                      ? ContraTheme.blue.withValues(alpha: 0.12)
                      : null,
                ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$day', style: numberStyle),
              const SizedBox(height: 2),
              if (hasEvents)
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? Colors.white : ContraTheme.green,
                  ),
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
      child: LongPressInk(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: ContraTheme.ink, size: 26),
        ),
      ),
    );
  }
}
