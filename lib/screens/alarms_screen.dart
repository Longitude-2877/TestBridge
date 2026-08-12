import 'package:flutter/material.dart';
import '../services/notifier_service.dart';
import '../services/reminders_store.dart';
import '../theme/contra_theme.dart';
import '../widgets/long_tap.dart';
import '../widgets/reminder_sheet.dart';

class AlarmsScreen extends StatefulWidget {
  final VoidCallback onClose;
  const AlarmsScreen({super.key, required this.onClose});

  @override
  State<AlarmsScreen> createState() => _AlarmsScreenState();
}

class _AlarmsScreenState extends State<AlarmsScreen> {
  List<AlarmItem> _alarms = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final alarms = await RemindersStore.loadAlarms();
    if (mounted) setState(() => _alarms = alarms);
  }

  Future<void> _addAlarm() async {
    final result = await showReminderSheet(
      context,
      title: 'Add alarm',
      name: 'Alarm',
      hour: 7,
      minute: 0,
      days: List.filled(7, true),
    );
    if (result == null || result.deleted) return;
    final alarm = AlarmItem(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      label: result.name,
      hour: result.hour,
      minute: result.minute,
      days: result.days,
    );
    setState(() => _alarms.add(alarm));
    await RemindersStore.saveAlarms(_alarms);
    await _schedule(alarm);
  }

  Future<void> _editAlarm(AlarmItem alarm) async {
    final result = await showReminderSheet(
      context,
      title: 'Edit alarm',
      name: alarm.label,
      hour: alarm.hour,
      minute: alarm.minute,
      days: alarm.days,
      showDelete: true,
    );
    if (result == null) return;
    if (result.deleted) {
      await Notifier.cancel(alarm.id);
      setState(() => _alarms.removeWhere((a) => a.id == alarm.id));
      await RemindersStore.saveAlarms(_alarms);
      return;
    }
    setState(() {
      alarm
        ..label = result.name
        ..hour = result.hour
        ..minute = result.minute
        ..days = result.days;
    });
    await RemindersStore.saveAlarms(_alarms);
    await _schedule(alarm);
  }

  Future<void> _schedule(AlarmItem a) async {
    if (a.enabled) {
      await Notifier.scheduleDaily(
        id: a.id,
        title: '⏰ ${a.label}',
        body: a.label == 'Alarm' ? 'Alarm!' : '${a.label} — alarm',
        channelId: 'alarm_clock',
        channelName: 'Alarm clock',
        hour: a.hour,
        minute: a.minute,
        days: a.days,
      );
    } else {
      await Notifier.cancel(a.id);
    }
  }

  Future<void> _toggleAlarm(AlarmItem a) async {
    setState(() => a.enabled = !a.enabled);
    await RemindersStore.saveAlarms(_alarms);
    await _schedule(a);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Alarm',
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
                  onActivate: _addAlarm,
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
            child: _alarms.isEmpty
                ? const Center(
                    child: Text(
                      'No alarms yet.\nPress + to add an alarm.',
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
                    itemCount: _alarms.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final a = _alarms[i];
                      return Material(
                        color: ContraTheme.card,
                        borderRadius: BorderRadius.circular(18),
                        elevation: 1,
                        child: LongTap(
                          onActivate: () => _editAlarm(a),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        time12(a.hour, a.minute),
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 26,
                                          fontWeight: FontWeight.w700,
                                          color: a.enabled
                                              ? ContraTheme.ink
                                              : ContraTheme.muted,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${a.label} · '
                                        '${dayNamesSummary(a.days)}',
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
                                  color: a.enabled
                                      ? ContraTheme.green
                                      : ContraTheme.muted,
                                  shape: const CircleBorder(),
                                  child: LongTap(
                                    onActivate: () => _toggleAlarm(a),
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
    );
  }
}