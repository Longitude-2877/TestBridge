import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import '../theme/contra_theme.dart';

/// Custom volume bar: when the hardware volume buttons are pressed, this
/// bar slides in with a big slider, hiding just after the press stops.
/// The native side (MainActivity) consumes the hardware buttons and pushes
/// the new level here, so the system volume UI never shows.
class VolumeBar extends StatefulWidget {
  const VolumeBar({super.key});

  @override
  State<VolumeBar> createState() => _VolumeBarState();
}

class _VolumeBarState extends State<VolumeBar> {
  static const _channel = MethodChannel('elders/volume');

  double _volume = 0.4;
  bool _visible = false;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'volumeChanged' && mounted) {
        final v = (call.arguments as num?)?.toDouble() ?? _volume;
        setState(() {
          _volume = v.clamp(0.0, 1.0);
          _visible = true;
        });
        _armHide();
      }
    });
    _init();
  }

  Future<void> _init() async {
    try {
      final v = await FlutterVolumeController.getVolume();
      _volume = (v ?? 0.4).clamp(0.0, 1.0).toDouble();
      await FlutterVolumeController.updateShowSystemUI(false);
    } catch (_) {}
    FlutterVolumeController.addListener((v) {
      if (!mounted) return;
      setState(() {
        _volume = v.clamp(0.0, 1.0);
        _visible = true;
      });
      _armHide();
    });
  }

  void _armHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _visible = false);
    });
  }

  void _setVolume(double v) {
    setState(() {
      _volume = v;
      _visible = true;
    });
    FlutterVolumeController.setVolume(v);
    _armHide();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    FlutterVolumeController.removeListener();
    _channel.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: AnimatedOpacity(
          opacity: _visible ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: IgnorePointer(
            ignoring: !_visible,
            child: Container(
              width: 280,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: ContraTheme.card,
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 14,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    _volume <= 0
                        ? Icons.volume_off_rounded
                        : _volume < 0.6
                            ? Icons.volume_down_rounded
                            : Icons.volume_up_rounded,
                    color: ContraTheme.teal,
                    size: 30,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: ContraTheme.teal,
                        thumbColor: ContraTheme.teal,
                        inactiveTrackColor: Colors.black12,
                        trackHeight: 8,
                        thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 12),
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 18),
                      ),
                      child: Slider(
                        value: _volume,
                        onChanged: _setVolume,
                      ),
                    ),
                  ),
                  Text(
                    '${(_volume * 100).round()}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: ContraTheme.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
