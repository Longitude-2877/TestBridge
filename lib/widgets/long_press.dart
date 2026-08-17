import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A drop-in replacement for [InkWell] that treats a *long press* (≈0.5s) as
/// the activation gesture, and shows a hint on a normal (short) tap so that
/// accidental taps do not trigger anything.
///
/// Replace `InkWell(onTap: ...)` with `LongPressInk(onTap: ...)` everywhere
/// except the on-screen keyboard (which must stay quick-tappable).
class LongPressInk extends StatelessWidget {
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

  void _onShortTap(BuildContext context) {
    if (onTap == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Press and hold to open',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _onLongPress() {
    if (onTap == null) return;
    HapticFeedback.mediumImpact();
    onTap!.call();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap == null ? null : () => _onShortTap(context),
      onLongPress: onTap == null ? null : _onLongPress,
      borderRadius: borderRadius,
      customBorder: customBorder,
      child: child,
    );
  }
}
