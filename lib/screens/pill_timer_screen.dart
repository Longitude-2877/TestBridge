import 'package:flutter/material.dart';
import '../services/home_items_store.dart';
import '../theme/contra_theme.dart';
import '../widgets/custom_keyboard.dart';
import '../widgets/long_press.dart';

class PillTimerScreen extends StatefulWidget {
  const PillTimerScreen({super.key});

  @override
  State<PillTimerScreen> createState() => _PillTimerScreenState();
}

class _PillTimerScreenState extends State<PillTimerScreen> {
  List<PillReminder> _pills = [];

  static const _colors = [
    ContraTheme.yellow,
    ContraTheme.blue,
    ContraTheme.green,
    ContraTheme.red,
  ];
  static const _dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final pills = await HomeItemsStore.loadPills();
    if (mounted) setState(() => _pills = pills);
  }

  Future<void> _save() async => HomeItemsStore.savePills(_pills);

  Color _color(int i) => _colors[i % _colors.length];

  Future<void> _addPill() async {
    final name = TextEditingController();
    String time = '09:00';
    int colorIndex = 0;
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
                'Add a pill reminder',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: ContraTheme.ink,
                ),
              ),
              const SizedBox(height: 14),
              CustomTextField(controller: name, hint: 'Medicine name'),
              const SizedBox(height: 12),
              Material(
                color: ContraTheme.card,
                borderRadius: BorderRadius.circular(18),
                child: LongPressInk(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: ctx,
                      initialTime: const TimeOfDay(hour: 9, minute: 0),
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
                            color: ContraTheme.blue),
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
              const Text('Colour code',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: ContraTheme.ink)),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (var i = 0; i < _colors.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Material(
                        color: _colors[i],
                        shape: const CircleBorder(),
                        child: LongPressInk(
                          onTap: () => setSheet(() => colorIndex = i),
                          customBorder: const CircleBorder(),
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: colorIndex == i
                                ? const Icon(Icons.check_rounded,
                                    color: Colors.white)
                                : null,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              const Text('Days',
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
                        onTap: () =>
                            setSheet(() => days[i] = !days[i]),
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: days[i]
                              ? BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _colors[colorIndex],
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
                  color: ContraTheme.green,
                  borderRadius: BorderRadius.circular(20),
                  child: LongPressInk(
                    onTap: () {
                      if (name.text.trim().isEmpty) return;
                      _pills.add(PillReminder(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: name.text.trim(),
                        time: time,
                        colorIndex: colorIndex,
                        days: days,
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
                          'Save reminder',
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

  void _toast(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(m, style: const TextStyle(fontFamily: 'Poppins')),
      duration: const Duration(seconds: 2),
    ));
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
                color: ContraTheme.green,
                shape: const CircleBorder(),
                elevation: 2,
                child: LongPressInk(
                  onTap: _addPill,
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
            child: _pills.isEmpty
                ? const Center(
                    child: Text(
                      'No pill reminders yet.\nTap + to add one!',
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
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final p = _pills[i];
                      final daysOn =
                          p.days.where((d) => d).length;
                      return Material(
                        color: ContraTheme.card,
                        borderRadius: BorderRadius.circular(18),
                        elevation: 1,
                        child: LongPressInk(
                          onTap: () {
                            _pills.removeAt(i);
                            _save();
                            _load();
                          },
                          borderRadius: BorderRadius.circular(18),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: _color(p.colorIndex),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.medication_rounded,
                                      color: Colors.white, size: 26),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.name,
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: ContraTheme.ink,
                                        ),
                                      ),
                                      Text(
                                        '${p.time}  ·  ${daysOn == 7 ? 'Every day' : daysOn == 0 ? 'Once' : '$daysOn days/week'}',
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
