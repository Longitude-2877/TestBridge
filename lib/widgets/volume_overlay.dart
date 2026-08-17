import 'dart:async';
import 'package:flutter/material.dart';
import '../services/phone_services.dart';
import '../theme/contra_theme.dart';

/// Requirement 12: when the volume buttons are pressed we show our own slider
/// instead of the system one. The native side intercepts the keys and forwards
/// them here via the `elders/volume` channel.
class VolumeOverlay extends StatefulWidget {
  const VolumeOverlay({super.key});

  @override
  State<VolumeOverlay> createState() => _VolumeOverlayState();
}

class _VolumeOverlayState extends State<VolumeOverlay> {
  bool _visible = false;
  double _level = 0.5;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    PhoneServices.volumeChannel.setMethodCallHandler(_onMethod);
    _init();
  }

  Future<void> _init() async {
    _level = await PhoneServices.getVolume();
    if (mounted) setState(() {});
  }

  Future<dynamic> _onMethod(call) async {
    if (call.method == 'key') {
      final dir = (call.arguments as int?) ?? 0;
      _adjust(dir);
    }
    return null;
  }

  void _adjust(int dir) {
    final next = (_level + dir * 0.05).clamp(0.0, 1.0);
    setState(() {
      _level = next;
      _visible = true;
    });
    PhoneServices.setVolume(next);
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _visible = false);
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    PhoneServices.volumeChannel.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    return Positioned(
      top: 90,
      left: 24,
      right: 24,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        elevation: 8,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: ContraTheme.border, width: 2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const Icon(Icons.volume_up_rounded, color: ContraTheme.ink),
              const SizedBox(width: 12),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: ContraTheme.blue,
                    inactiveTrackColor: ContraTheme.ink.withValues(alpha: 0.15),
                    thumbColor: ContraTheme.blue,
                    trackHeight: 8,
                  ),
                  child: Slider(
                    value: _level,
                    onChanged: (v) {
                      setState(() => _level = v);
                      PhoneServices.setVolume(v);
                    },
                  ),
                ),
              ),
              SizedBox(
                width: 42,
                child: Text(
                  '${(_level * 100).round()}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: ContraTheme.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
