import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Every button in the app requires a ~500ms long press so accidental taps
/// do nothing. A quick tap shows a "Press longer" notice; a successful
/// long press gives haptic feedback and runs [onActivate].
class LongTap extends StatelessWidget {
  final Widget child;
  final VoidCallback onActivate;
  final Duration duration;

  const LongTap({
    super.key,
    required this.child,
    required this.onActivate,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(
            content: Text('Press longer',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 16)),
            duration: Duration(milliseconds: 900),
          ));
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        onActivate();
      },
      child: child,
    );
  }
}