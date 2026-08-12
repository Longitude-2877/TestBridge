import 'dart:async';
import 'package:flutter/material.dart';
import '../services/notifier_service.dart';
import '../services/reminders_store.dart';
import '../theme/contra_theme.dart';
import '../widgets/long_tap.dart';
import '../widgets/reminder_sheet.dart';

class PillsScreen extends StatefulWidget {
  final VoidCallback onClose;
  const PillsScreen({super.key, required this.onClose});

  @override
  State<PillsScreen> createState() => _PillsScreenState();
}

class _PillsScreenState extends State<PillsScreen> {
  List<PillReminder> _pills = [];
  List<String> _dueNow = [];
  Timer? _checker;

  @override
  void initState() {
    super.initState();
    _load();
    _checker = Timer.periodic(const Duration(seconds: 30), (_) => _checkDue());
  }

  @override
  void dispose() {
    _checker?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final pills = await RemindersStore.loadPills();
    if (mounted) setState(() => _pills = pills);
    _checkDue();
  }

  void _checkDue() {
    if (!mounted) return;
    final now = DateTime.now();
    final due = [
      for (final p in _pills)
        if (p.enabled &&
            p.hour == now.hour &&
            p.minute == now.minute &&
            p.days[now.weekday - 1])
          p.name,
    ];
    setState(() => _dueNow = due);
  }

  Future<void> _addPill() async {
    final result = await showReminderSheet(
      context,
      title: 'Add a pill',
      name: '',
      hour: 9,
      minute: 0,
      days: List.filled(7, true),
      pickColor: true,
    );
    if (result == null || result.deleted) return;
    final pill = PillReminder(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      name: result.name,
      hour: result.hour,
      minute: result.minute,
      days: result.days,
      colorIndex: result.colorIndex,
    );
    setState(() => _pills.add(pill));
    await RemindersStore.savePills(_pills);
    await _schedule(pill);
  }

  Future<void> _editPill(PillReminder pill) async {
    final result = await showReminderSheet(
      context,
      title: 'Edit pill',
      name: pill.name,
      hour: pill.hour,
      minute: pill.minute,
      days: pill.days,
      colorIndex: pill.colorIndex,
      pickColor: true,
      showDelete: true,
    );
    if (result == null) return;
    if (result.deleted) {
      await Notifier.cancel(pill.id);
      setState(() => _pills.removeWhere((p) => p.id == pill.id));
      await RemindersStore.savePills(_pills);
      return;
    }
    setState(() {
      pill
        ..name = result.name
        ..hour = result.hour
        ..minute = result.minute
        ..days = result.days
        ..colorIndex = result.colorIndex;
    });
    await RemindersStore.savePills(_pills);
    await _schedule(pill);
  }

  Future<void> _schedule(PillReminder p) async {
    if (p.enabled) {
      await Notifier.scheduleDaily(
        id: p.id,
        title: '💊 Time for ${p.name}',
        body: 'Take your ${p.name} now',
        channelId: 'pill_reminders',
        channelName: 'Pill reminders',
        hour: p.hour,
        minute: p.minute,
        days: p.days,
      );
    } else {
      await Notifier.cancel(p.id);
    }
  }

  Future<void> _togglePill(PillReminder p) async {
    setState(() => p.enabled = !p.enabled);
    await RemindersStore.savePills(_pills);
    await _schedule(p);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Pill Timer',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: ContraTheme.ink,
                      ),
                    ),
                  ),
                  Material(
                    color: ContraTheme.teal,
                    shape: const CircleBorder(),
                    elevation: 2,
                    child: LongTap(
                      onActivate: _addPill,
                      child: const SizedBox(
                        width: 58,
                        height: 58,
                        child: Icon(Icons.add_rounded,
                            color: Colors.white, size: 34),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: _pills.isEmpty
                    ? const Center(
                        child: Text(
                          'No pills yet.\nPress + to add a pill reminder.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: ContraTheme.muted,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _pills.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final p = _pills[i];
                          final color = pillColors[p.colorIndex %
                              pillColors.length];
                          return Material(
                            color: ContraTheme.card,
                            borderRadius: BorderRadius.circular(18),
                            elevation: 1,
                            child: LongTap(
                              onActivate: () => _editPill(p),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 14,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color:
                                            p.enabled ? color : Colors.grey,
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p.name,
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 19,
                                              fontWeight: FontWeight.w700,
                                              color: p.enabled
                                                  ? ContraTheme.ink
                                                  : ContraTheme.muted,
                                              decoration: p.enabled
                                                  ? null
                                                  : TextDecoration
                                                      .lineThrough,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${time12(p.hour, p.minute)} · '
                                            '${dayNamesSummary(p.days)}',
                                            style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: ContraTheme.muted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Material(
                                      color: p.enabled
                                          ? ContraTheme.green
                                          : ContraTheme.muted,
                                      shape: const CircleBorder(),
                                      child: LongTap(
                                        onActivate: () => _togglePill(p),
                                        child: const SizedBox(
                                          width: 44,
                                          height: 44,
                                          child: Icon(
                                              Icons.power_settings_new_rounded,
                                              color: Colors.white,
                                              size: 24),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        if (_dueNow.isNotEmpty)
          Positioned(
            top: 70,
            left: 10,
            right: 10,
            child: Material(
              color: ContraTheme.teal,
              borderRadius: BorderRadius.circular(20),
              elevation: 6,
              shadowColor: const Color(0x44000000),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Row(
                  children: [
                    const Icon(Icons.medication_rounded,
                        color: Colors.white, size: 34),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Time for ${_dueNow.join(', ')}!',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    LongTap(
                      onActivate: () => setState(() => _dueNow = []),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 28),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}