import 'dart:typed_data';
import 'package:flutter/services.dart';

class Contact {
  final String name;
  final String number;
  Contact({required this.name, required this.number});
}

class InstalledAppInfo {
  final String name;
  final String package;
  InstalledAppInfo({required this.name, required this.package});
}

class SmsMessage {
  final int id;
  final String address;
  final String body;
  final int date;
  final bool read;
  final bool incoming;
  SmsMessage({
    required this.id,
    required this.address,
    required this.body,
    required this.date,
    required this.read,
    required this.incoming,
  });
}

class PhoneServices {
  static const _channel = MethodChannel('elders/phone');

  static Future<String?> placeCall(String number) async {
    try {
      return await _channel.invokeMethod<String>('placeCall', number);
    } catch (e) {
      return 'Failed: $e';
    }
  }

  static Future<List<Contact>> getContacts() async {
    final raw =
        await _channel.invokeListMethod<Map<dynamic, dynamic>>('getContacts');
    if (raw == null) return [];
    return raw
        .map((e) => Contact(
              name: (e['name'] as String?) ?? '',
              number: (e['number'] as String?) ?? '',
            ))
        .where((c) => c.number.isNotEmpty)
        .toList();
  }

  static Future<String?> addContact(String name, String number) async {
    try {
      await _channel.invokeMethod<void>(
        'addContact',
        {'name': name, 'number': number},
      );
      return null;
    } catch (e) {
      return 'Failed: $e';
    }
  }

  static Future<void> exitLauncher() async {
    await _channel.invokeMethod<void>('exitLauncher');
  }

  static Future<void> openSettings() async {
    await _channel.invokeMethod<void>('openSettings');
  }

  static Future<void> requestDefaultLauncher() async {
    await _channel.invokeMethod<void>('requestDefaultLauncher');
  }

  static Future<List<InstalledAppInfo>> getInstalledApps() async {
    final raw = await _channel
        .invokeListMethod<Map<dynamic, dynamic>>('getInstalledApps');
    if (raw == null) return [];
    return raw
        .map((e) => InstalledAppInfo(
              name: (e['name'] as String?) ?? '',
              package: (e['package'] as String?) ?? '',
            ))
        .where((a) => a.package.isNotEmpty)
        .toList();
  }

  static Future<Uint8List?> getAppIcon(String package) async {
    try {
      final bytes = await _channel.invokeMethod<Uint8List>('getAppIcon', package);
      return bytes;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> launchApp(String package) async {
    try {
      await _channel.invokeMethod<void>('launchApp', package);
      return null;
    } catch (e) {
      return 'Could not open app';
    }
  }

  static Future<bool> isOverlayAllowed() async {
    try {
      return await _channel.invokeMethod<bool>('isOverlayAllowed') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> requestOverlayPermission() async {
    try {
      await _channel.invokeMethod<void>('requestOverlayPermission');
    } catch (_) {}
  }

  static Future<void> stopOverlay() async {
    try {
      await _channel.invokeMethod<void>('stopOverlay');
    } catch (_) {}
  }

  static Future<String?> sendSms(String number, String text) async {
    try {
      await _channel.invokeMethod<void>(
        'sendSms',
        {'number': number, 'text': text},
      );
      return null;
    } catch (e) {
      return 'Could not send message';
    }
  }

  static Future<List<SmsMessage>> getMessages() async {
    final raw =
        await _channel.invokeListMethod<Map<dynamic, dynamic>>('getMessages');
    if (raw == null) return [];
    return raw
        .map((e) => SmsMessage(
              id: (e['id'] as num?)?.toInt() ?? 0,
              address: (e['address'] as String?) ?? '',
              body: (e['body'] as String?) ?? '',
              date: (e['date'] as num?)?.toInt() ?? 0,
              read: (e['read'] as bool?) ?? true,
              incoming: (e['incoming'] as bool?) ?? true,
            ))
        .toList();
  }

  static Future<List<int>> getUnreadIds() async {
    final raw =
        await _channel.invokeListMethod<dynamic>('getUnreadIds');
    if (raw == null) return [];
    return raw.map((e) => (e as num).toInt()).toList();
  }

  static Future<void> markRead(int id) async {
    try {
      await _channel.invokeMethod<void>('markRead', id);
    } catch (_) {}
  }

  static Future<void> markUnread(int id) async {
    try {
      await _channel.invokeMethod<void>('markUnread', id);
    } catch (_) {}
  }
}
