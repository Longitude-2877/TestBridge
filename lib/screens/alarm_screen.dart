import 'package:flutter/material.dart';
import '../services/home_items_store.dart';
import '../theme/contra_theme.dart';
import '../widgets/custom_keyboard.dart';
import '../widgets/long_press.dart';

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  List<AlarmItem> _alarms = [];
  static const _dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final alarms = await HomeItemsStore.loadAlarms();
    if (mounted) setState(() => _alarms = alarms);
  }

  Future<void> _save() async => HomeItemsStore.saveAlarms(_alarms);

  Future<void> _addAlarm() async {
    final label = TextEditingController();
    String time = '07:00';
    List<bool> days = List.filled(7, false);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ContraTheme.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
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
              const Text(
                'Add an alarm',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: ContraTheme.ink,
                ),
              ),
              const SizedBox(height: 14),
              CustomTextField(controller: label, hint: 'Alarm label'),
              const SizedBox(height: 12),
              Material(
                color: ContraTheme.card,
                borderRadius: BorderRadius.circular(18),
                child: LongPressInk(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: ctx,
                      initialTime: const TimeOfDay(hour: 7, minute: 0),
                    );
                    if (picked != null) {
                      setSheet(() =>
                          time = '${picked.hour.toString().padLeft(2, '0')}:'
                              '${picked.minute.toString().padLeft(2, '0')}');
                    }
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time_rounded,
                            color: ContraTheme.red),
                        const SizedBox(width: 12),
                        Text(
                          'Time: $time',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: ContraTheme.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text('Repeat on',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: ContraTheme.ink)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 0; i < 7; i++)
                    Material(
                      color: ContraTheme.card,
                      shape: const CircleBorder(),
                      child: LongPressInk(
                        onTap: () => setSheet(() => days[i] = !days[i]),
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: days[i]
                              ? const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: ContraTheme.red,
                                )
                              : null,
                          child: Center(
                            child: Text(
                              _dayLabels[i],
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: days[i]
                                    ? Colors.white
                                    : ContraTheme.ink,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: Material(
                  color: ContraTheme.red,
                  borderRadius: BorderRadius.circular(20),
                  child: LongPressInk(
                    onTap: () {
                      if (label.text.trim().isEmpty) return;
                      _alarms.add(AlarmItem(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        label: label.text.trim(),
                        time: time,
                        days: days,
                        enabled: true,
                      ));
                      _save();
                      Navigator.of(context).pop();
                      _load();
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'Save alarm',
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
      ),
    );
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
                color: ContraTheme.red,
                shape: const CircleBorder(),
                elevation: 2,
                child: LongPressInk(
                  onTap: _addAlarm,
                  customBorder: const CircleBorder(),
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
          const SizedBox(height: 16),
          Expanded(
            child: _alarms.isEmpty
                ? const Center(
                    child: Text(
                      'No alarms yet.\nTap + to add one!',
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
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final a = _alarms[i];
                      final daysOn = a.days.where((d) => d).length;
                      return Material(
                        color: ContraTheme.card,
                        borderRadius: BorderRadius.circular(18),
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      a.label,
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: ContraTheme.ink,
                                      ),
                                    ),
                                    Text(
                                      '${a.time}  ·  ${daysOn == 7 ? 'Every day' : daysOn == 0 ? 'Once' : '$daysOn days/week'}',
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
                                    : ContraTheme.card,
                                shape: const CircleBorder(),
                                child: LongPressInk(
                                  onTap: () {
                                    _alarms[i] = AlarmItem(
                                      id: a.id,
                                      label: a.label,
                                      time: a.time,
                                      days: a.days,
                                      enabled: !a.enabled,
                                    );
                                    _save();
                                    _load();
                                  },
                                  customBorder: const CircleBorder(),
                                  child: SizedBox(
                                    width: 56,
                                    height: 56,
                                    child: Icon(
                                      a.enabled
                                          ? Icons.alarm_on_rounded
                                          : Icons.alarm_off_rounded,
                                      color: a.enabled
                                          ? Colors.white
                                          : ContraTheme.muted,
                                      size: 30,
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
