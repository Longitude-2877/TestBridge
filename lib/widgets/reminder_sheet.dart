import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/contra_theme.dart';
import 'custom_keyboard.dart';
import 'long_tap.dart';

class ReminderResult {
  final String name;
  final int hour;
  final int minute;
  final List<bool> days;
  final int colorIndex;
  final bool deleted;
  ReminderResult({
    required this.name,
    required this.hour,
    required this.minute,
    required this.days,
    this.colorIndex = 0,
    this.deleted = false,
  });
}

const pillColors = [
  ContraTheme.red,
  ContraTheme.yellow,
  ContraTheme.green,
  ContraTheme.blue,
  ContraTheme.purple,
  ContraTheme.teal,
];

const daysReadable = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String dayNamesSummary(List<bool> days) {
  const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  if (days.every((d) => d)) return 'Every day';
  final s = [
    for (var i = 0; i < 7; i++)
      if (days[i]) names[i],
  ];
  return s.isEmpty ? 'No days' : s.join(' ');
}

String time12(int hour, int minute) {
  var h = hour % 12;
  if (h == 0) h = 12;
  final m = minute.toString().padLeft(2, '0');
  return '$h:$m ${hour >= 12 ? 'PM' : 'AM'}';
}

/// Shared edit form for pill reminders and alarms.
Future<ReminderResult?> showReminderSheet(
  BuildContext context, {
  required String title,
  required String name,
  required int hour,
  required int minute,
  required List<bool> days,
  int colorIndex = 0,
  bool pickColor = false,
  bool showDelete = false,
}) {
  return showModalBottomSheet<ReminderResult>(
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
      child: StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          final nameController = TextEditingController(text: name);
          var selHour = hour;
          var selMinute = minute;
          var selDays = List<bool>.from(days);
          var selColor = colorIndex;

          Future<void> pickTime() async {
            final t = await showTimePicker(
              context: context,
              initialTime: TimeOfDay(hour: selHour, minute: selMinute),
              helpText: 'Pick the time',
            );
            if (t != null) {
              setSheetState(() {
                selHour = t.hour;
                selMinute = t.minute;
              });
            }
          }

          Widget dayRow(int i) {
            return LongTap(
              onActivate: () =>
                  setSheetState(() => selDays[i] = !selDays[i]),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color:
                          selDays[i] ? ContraTheme.teal : Colors.transparent,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                        color: selDays[i]
                            ? ContraTheme.teal
                            : ContraTheme.muted,
                        width: 2,
                      ),
                    ),
                    child: selDays[i]
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 18)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    daysReadable[i],
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: ContraTheme.ink,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: ContraTheme.ink,
                ),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: nameController,
                hint: 'Name (eg. Morning pills)',
              ),
              const SizedBox(height: 12),
              Material(
                color: ContraTheme.card,
                borderRadius: BorderRadius.circular(16),
                child: LongTap(
                  onActivate: pickTime,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule_rounded,
                            color: ContraTheme.teal, size: 26),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            time12(selHour, selMinute),
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: ContraTheme.ink,
                            ),
                          ),
                        ),
                        const Text(
                          'Set time',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: ContraTheme.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (pickColor) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    for (var i = 0; i < pillColors.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: LongTap(
                          onActivate: () => setSheetState(() => selColor = i),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: pillColors[i],
                              shape: BoxShape.circle,
                              border: selColor == i
                                  ? Border.all(
                                      color: ContraTheme.ink, width: 3)
                                  : null,
                            ),
                            child: selColor == i
                                ? const Icon(Icons.check_rounded,
                                    color: Colors.white, size: 18)
                                : null,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 22,
                runSpacing: 10,
                children: [for (var i = 0; i < 7; i++) dayRow(i)],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (showDelete) ...[
                    Expanded(
                      child: Material(
                        color: ContraTheme.red,
                        borderRadius: BorderRadius.circular(18),
                        child: LongTap(
                          onActivate: () => Navigator.of(sheetContext).pop(
                              ReminderResult(
                                  name: '',
                                  hour: selHour,
                                  minute: selMinute,
                                  days: selDays,
                                  colorIndex: selColor,
                                  deleted: true)),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Center(
                              child: Text(
                                'Delete',
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
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Material(
                      color: ContraTheme.card,
                      borderRadius: BorderRadius.circular(18),
                      child: LongTap(
                        onActivate: () =>
                            Navigator.of(sheetContext).pop(null),
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
                  const SizedBox(width: 10),
                  Expanded(
                    child: Material(
                      color: ContraTheme.teal,
                      borderRadius: BorderRadius.circular(18),
                      child: LongTap(
                        onActivate: () {
                          final n = nameController.text.trim();
                          if (n.isEmpty) {
                            HapticFeedback.mediumImpact();
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(const SnackBar(
                                content: Text('Type a name first',
                                    style:
                                        TextStyle(fontFamily: 'Poppins')),
                                duration: Duration(seconds: 2),
                              ));
                            return;
                          }
                          Navigator.of(sheetContext).pop(ReminderResult(
                            name: n,
                            hour: selHour,
                            minute: selMinute,
                            days: selDays,
                            colorIndex: selColor,
                          ));
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
          );
        },
      ),
    ),
  );
}