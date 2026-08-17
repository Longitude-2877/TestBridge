import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/phone_services.dart';
import '../theme/contra_theme.dart';
import '../widgets/long_press.dart';

class SystemTopBar extends StatefulWidget {
  const SystemTopBar({super.key});

  @override
  State<SystemTopBar> createState() => _SystemTopBarState();
}

class _SystemTopBarState extends State<SystemTopBar> {
  late final Battery _battery;
  DateTime _now = DateTime.now();
  int _batteryLevel = 100;
  bool _charging = false;
  bool _flashOn = false;
  Timer? _ticker;
  StreamSubscription<BatteryState>? _batterySub;

  @override
  void initState() {
    super.initState();
    _battery = Battery();
    _refreshBattery();
    _batterySub = _battery.onBatteryStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _charging = state == BatteryState.charging ||
              state == BatteryState.full;
        });
      }
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  Future<void> _refreshBattery() async {
    try {
      final level = await _battery.batteryLevel;
      if (mounted) setState(() => _batteryLevel = level);
    } catch (_) {}
  }

  Future<void> _toggleFlash() async {
    final on = !_flashOn;
    final ok = await PhoneServices.setFlashlight(on);
    if (ok && mounted) setState(() => _flashOn = on);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _batterySub?.cancel();
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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(
        color: ContraTheme.card,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.schedule, size: 28, color: ContraTheme.ink),
              const SizedBox(width: 6),
              Text(
                _time12(),
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: ContraTheme.ink,
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Requirement 4: a light icon near the battery that toggles the torch.
              Material(
                color: _flashOn ? ContraTheme.yellow : ContraTheme.card,
                shape: const CircleBorder(),
                child: LongPressInk(
                  onTap: _toggleFlash,
                  customBorder: const CircleBorder(),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(
                      _flashOn
                          ? Icons.flashlight_on_rounded
                          : Icons.flashlight_off_rounded,
                      size: 26,
                      color: _flashOn ? Colors.white : ContraTheme.ink,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _BatteryIndicator(level: _batteryLevel, charging: _charging),
              const SizedBox(width: 6),
              // Requirement 3: green lightning when charging.
              if (_charging)
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: ContraTheme.green,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: ContraTheme.green.withValues(alpha: 0.7),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.bolt_rounded,
                      size: 22, color: Colors.white),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BatteryIndicator extends StatelessWidget {
  final int level;
  final bool charging;
  const _BatteryIndicator({required this.level, this.charging = false});

  @override
  Widget build(BuildContext context) {
    final litSegments = level >= 66
        ? 3
        : level >= 33
            ? 2
            : 1;
    // Requirement 3: when charging, the fill turns green.
    final segmentColor = charging
        ? ContraTheme.green
        : litSegments == 3
            ? ContraTheme.green
            : litSegments == 2
                ? ContraTheme.yellow
                : ContraTheme.red;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Requirement 4: larger battery icon.
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++)
              Container(
                width: 18,
                height: 32,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: i < litSegments ? segmentColor : ContraTheme.card,
                  border: Border.all(color: ContraTheme.border, width: 2),
                  borderRadius: BorderRadius.circular(5),
                  boxShadow: i < litSegments
                      ? [
                          BoxShadow(
                            color: segmentColor.withValues(alpha: 0.6),
                            blurRadius: 6,
                          ),
                        ]
                      : null,
                ),
              ),
          ],
        ),
        const SizedBox(width: 4),
        Container(
          width: 8,
          height: 14,
          decoration: BoxDecoration(
            color: ContraTheme.ink,
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(3)),
          ),
        ),
      ],
    );
  }
}

class SystemBottomBar extends StatefulWidget {
  final VoidCallback onHome;
  final VoidCallback onBack;
  final VoidCallback onSos;
  const SystemBottomBar({
    super.key,
    required this.onHome,
    required this.onBack,
    required this.onSos,
  });

  @override
  State<SystemBottomBar> createState() => _SystemBottomBarState();
}

class _SystemBottomBarState extends State<SystemBottomBar> {
  int _homePressCount = 0;
  DateTime _lastHomePress = DateTime.fromMillisecondsSinceEpoch(0);
  static const _windowMs = 5000;
  static const _exitCount = 7;

  void _onHomeTap() {
    final now = DateTime.now();
    if (now.difference(_lastHomePress).inMilliseconds > _windowMs) {
      _homePressCount = 0;
    }
    _lastHomePress = now;
    _homePressCount++;

    if (_homePressCount >= _exitCount) {
      HapticFeedback.heavyImpact();
      PhoneServices.exitLauncher();
      return;
    }
    widget.onHome();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Requirement 5: SOS (left) | Home (middle) | Back (right).
          _NavButton(
            icon: Icons.warning_rounded,
            label: 'SOS',
            color: ContraTheme.red,
            onTap: widget.onSos,
          ),
          _NavButton(
            icon: Icons.home_rounded,
            label: 'Home',
            onTap: _onHomeTap,
          ),
          _NavButton(
            icon: Icons.arrow_back_rounded,
            label: 'Back',
            onTap: widget.onBack,
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _NavButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final fg = color ?? ContraTheme.ink;
    return Material(
      color: color ?? ContraTheme.card,
      shape: const CircleBorder(),
      child: LongPressInk(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 28, color: color == null ? fg : Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: color == null ? fg : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
