import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/phone_services.dart';
import '../theme/contra_theme.dart';
import '../widgets/long_press.dart';

class LockScreen extends StatefulWidget {
  final VoidCallback onUnlock;
  final VoidCallback onCamera;
  final VoidCallback onSos;
  const LockScreen({
    super.key,
    required this.onUnlock,
    required this.onCamera,
    required this.onSos,
  });

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  DateTime _now = DateTime.now();
  int _level = 100;
  bool _charging = false;
  bool _flash = false;
  final Battery _battery = Battery();
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _refresh();
    _battery.onBatteryStateChanged.listen((s) {
      if (mounted) {
        setState(() =>
            _charging = s == BatteryState.charging || s == BatteryState.full);
      }
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  Future<void> _refresh() async {
    try {
      final l = await _battery.batteryLevel;
      if (mounted) setState(() => _level = l);
    } catch (_) {}
  }

  Future<void> _toggleFlash() async {
    final on = !_flash;
    final ok = await PhoneServices.setFlashlight(on);
    if (ok && mounted) setState(() => _flash = on);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    PhoneServices.setFlashlight(false);
    super.dispose();
  }

  String _time12() {
    final h24 = _now.hour;
    final h12 = h24 == 0 ? 12 : (h24 > 12 ? h24 - 12 : h24);
    final m = _now.minute.toString().padLeft(2, '0');
    final ap = h24 < 12 ? 'AM' : 'PM';
    return '$h12:$m $ap';
  }

  String _date() {
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${days[(_now.weekday - 1) % 7]}, ${_now.day} ${months[_now.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ContraTheme.ink,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Text(
              _time12(),
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 56,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _date(),
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.battery_full_rounded,
                    color: Colors.white70, size: 22),
                const SizedBox(width: 4),
                Text(
                  '$_level%',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
                if (_charging)
                  const Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: Icon(Icons.bolt_rounded,
                        color: ContraTheme.green, size: 20),
                  ),
              ],
            ),
            const Spacer(),
            // Swipe-to-open handle.
            GestureDetector(
              onHorizontalDragEnd: (_) => widget.onUnlock(),
              onTap: widget.onUnlock,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Center(
                  child: Text(
                    'Swipe to open  ›',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: ContraTheme.ink,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _LockButton(
                  icon: Icons.photo_camera_rounded,
                  label: 'Camera',
                  onTap: widget.onCamera,
                ),
                _LockButton(
                  icon: _flash
                      ? Icons.flashlight_on_rounded
                      : Icons.flashlight_off_rounded,
                  label: 'Torch',
                  onTap: _toggleFlash,
                ),
                _LockButton(
                  icon: Icons.warning_rounded,
                  label: 'SOS',
                  color: ContraTheme.red,
                  onTap: widget.onSos,
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _LockButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _LockButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: color ?? Colors.white,
          shape: const CircleBorder(),
          child: LongPressInk(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 64,
              height: 64,
              child: Icon(icon,
                  color: color == null ? ContraTheme.ink : Colors.white,
                  size: 32),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
