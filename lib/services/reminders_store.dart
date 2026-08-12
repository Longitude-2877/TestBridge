import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PillReminder {
  final int id;
  String name;
  int colorIndex;
  int hour;
  int minute;
  List<bool> days; // 7 entries, Mon..Sun
  bool enabled;

  PillReminder({
    required this.id,
    required this.name,
    this.colorIndex = 0,
    this.hour = 9,
    this.minute = 0,
    List<bool>? days,
    this.enabled = true,
  }) : days = days ?? List.filled(7, true);

  Map<String, dynamic> toJson() => {
        'id': id,
        'n': name,
        'c': colorIndex,
        'h': hour,
        'm': minute,
        'd': days,
        'e': enabled,
      };

  static PillReminder fromJson(Map<String, dynamic> m) => PillReminder(
        id: (m['id'] as num?)?.toInt() ?? 0,
        name: (m['n'] as String?) ?? '',
        colorIndex: (m['c'] as num?)?.toInt() ?? 0,
        hour: (m['h'] as num?)?.toInt() ?? 9,
        minute: (m['m'] as num?)?.toInt() ?? 0,
        days: ((m['d'] as List?) ?? List.filled(7, true))
            .map((e) => e == true)
            .toList(),
        enabled: (m['e'] as bool?) ?? true,
      );
}

class AlarmItem {
  final int id;
  String label;
  int hour;
  int minute;
  List<bool> days;
  bool enabled;

  AlarmItem({
    required this.id,
    required this.label,
    this.hour = 7,
    this.minute = 0,
    List<bool>? days,
    this.enabled = true,
  }) : days = days ?? List.filled(7, true);

  Map<String, dynamic> toJson() => {
        'id': id,
        'n': label,
        'h': hour,
        'm': minute,
        'd': days,
        'e': enabled,
      };

  static AlarmItem fromJson(Map<String, dynamic> m) => AlarmItem(
        id: (m['id'] as num?)?.toInt() ?? 0,
        label: (m['n'] as String?) ?? '',
        hour: (m['h'] as num?)?.toInt() ?? 7,
        minute: (m['m'] as num?)?.toInt() ?? 0,
        days: ((m['d'] as List?) ?? List.filled(7, true))
            .map((e) => e == true)
            .toList(),
        enabled: (m['e'] as bool?) ?? true,
      );
}

class RemindersStore {
  static const _pillsKey = 'pill_reminders';
  static const _alarmsKey = 'alarm_items';

  static Future<List<PillReminder>> loadPills() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pillsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => PillReminder.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> savePills(List<PillReminder> pills) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _pillsKey, jsonEncode(pills.map((p) => p.toJson()).toList()));
  }

  static Future<List<AlarmItem>> loadAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_alarmsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => AlarmItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveAlarms(List<AlarmItem> alarms) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _alarmsKey, jsonEncode(alarms.map((a) => a.toJson()).toList()));
  }
}