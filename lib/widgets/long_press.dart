import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/home_items_store.dart';

/// Global, live activation-gesture setting.
/// Values: 'tap' (normal tap), 'double' (double tap), 'long' (press & hold).
class ActivationMode {
  static String value = 'long';
  static final List<VoidCallback> _listeners = [];

  static Future<void> load() async {
    value = await HomeItemsStore.activationMode();
  }

  static void set(String mode) {
    value = mode;
    for (final l in _listeners) l();
  }

  static void addListener(VoidCallback l) => _listeners.add(l);
  static void removeListener(VoidCallback l) => _listeners.remove(l);
}

/// A drop-in replacement for [InkWell] whose activation gesture is chosen by
/// [ActivationMode]:
///  - 'long'   : hold ~0.2s to open (short tap shows a hint)
///  - 'double' : double tap to open (single tap shows a hint)
///  - 'tap'    : a normal tap opens immediately
class LongPressInk extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final ShapeBorder? customBorder;

  const LongPressInk({
    required this.child,
    this.onTap,
    this.borderRadius,
    this.customBorder,
    super.key,
  });

  @override
  State<LongPressInk> createState() => _LongPressInkState();
}

class _LongPressInkState extends State<LongPressInk> {
  Timer? _timer;
  bool _fired = false;
  // Requirement: long press is now ~0.2s.
  static const _longDuration = Duration(milliseconds: 200);

  void _activate() {
    if (widget.onTap == null) return;
    HapticFeedback.mediumImpact();
    widget.onTap!.call();
  }

  void _hint(BuildContext context, String msg) {
    if (widget.onTap == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(
              fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mode = ActivationMode.value;

    if (mode == 'tap') {
      return InkWell(
        onTap: widget.onTap == null ? null : _activate,
        borderRadius: widget.borderRadius,
        customBorder: widget.customBorder,
        child: widget.child,
      );
    }

    if (mode == 'double') {
      return InkWell(
        onTap: () => _hint(context, 'Double tap to open'),
        onDoubleTap: _activate,
        borderRadius: widget.borderRadius,
        customBorder: widget.customBorder,
        child: widget.child,
      );
    }

    // 'long' — custom 0.2s press.
    return InkWell(
      onTapDown: (_) {
        _fired = false;
        _timer = Timer(_longDuration, () {
          _fired = true;
          _activate();
        });
      },
      onTapUp: (_) {
        _timer?.cancel();
        _timer = null;
      },
      onTapCancel: () {
        _timer?.cancel();
        _timer = null;
      },
      onTap: () {
        if (!_fired) _hint(context, 'Press and hold to open');
      },
      borderRadius: widget.borderRadius,
      customBorder: widget.customBorder,
      child: widget.child,
    );
  }
}
