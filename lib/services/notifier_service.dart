import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Schedules daily notifications for pill reminders and alarms.
class Notifier {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    try {
      tzdata.initializeTimeZones();
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      );
      await _plugin.initialize(settings);
      final android =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
    } catch (_) {}
  }

  /// Cancel all scheduled notifications for a reminder [id].
  static Future<void> cancel(int id) async {
    for (var i = 0; i < 7; i++) {
      await _plugin.cancel(id * 10 + i);
    }
  }

  static Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required String channelId,
    required String channelName,
    required int hour,
    required int minute,
    required List<bool> days,
  }) async {
    await cancel(id);
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: 'Reminders for pills and alarms',
        importance: Importance.max,
        priority: Priority.high,
      ),
    );
    for (var i = 0; i < 7; i++) {
      if (!days[i]) continue;
      final next = _nextOccurrence(i, hour, minute);
      await _plugin.zonedSchedule(
        id * 10 + i,
        title,
        body,
        next,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  /// Next [weekdayIndex] (0 = Monday) on or after now, in the phone's own
  /// local time (converted to an instant so it fires at the right moment).
  static tz.TZDateTime _nextOccurrence(
      int weekdayIndex, int hour, int minute) {
    final now = DateTime.now();
    var candidate = DateTime(now.year, now.month, now.day, hour, minute);
    while (candidate.weekday - 1 != weekdayIndex ||
        candidate.isBefore(now)) {
      candidate = candidate.add(const Duration(days: 1));
    }
    final utc = candidate.toUtc();
    return tz.TZDateTime(tz.UTC, utc.year, utc.month, utc.day, utc.hour,
        utc.minute);
  }
}