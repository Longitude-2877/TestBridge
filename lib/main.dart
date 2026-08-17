import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'screens/calculator_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/dialer_screen.dart';
import 'screens/gallery_screen.dart';
import 'screens/launcher_screen.dart';
import 'screens/permissions_screen.dart';
import 'screens/pill_timer_screen.dart';
import 'screens/alarm_screen.dart';
import 'screens/messages_screen.dart';
import 'screens/lock_screen.dart';
import 'services/phone_services.dart';
import 'services/home_items_store.dart';
import 'theme/contra_theme.dart';
import 'widgets/permanent_overlay.dart';
import 'widgets/volume_overlay.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Keep the launcher in portrait; the horizontal keyboard temporarily
  // switches to landscape and restores this on close.
  unawaited(SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]));
  // Fire-and-forget so a slow/hanging platform call can never block the first
  // frame (which previously caused a grey screen).
  unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky));
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
  ));
  unawaited(WakelockPlus.enable());
  runApp(const ElderLauncherApp());
}

class ElderLauncherApp extends StatelessWidget {
  const ElderLauncherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Elder Launcher',
      debugShowCheckedModeBanner: false,
      theme: ContraTheme.light(),
      home: const LauncherRoot(),
    );
  }
}

class LauncherRoot extends StatefulWidget {
  const LauncherRoot({super.key});

  @override
  State<LauncherRoot> createState() => _LauncherRootState();
}

class _LauncherRootState extends State<LauncherRoot> with WidgetsBindingObserver {
  int _screen = 0; // 0 home, 1 dialer, 2 camera, 3 calendar, 4 calculator,
  // 5 gallery, 6 pills, 7 alarm, 8 messages
  bool _showPermissions = true;
  bool _locked = true;
  Timer? _immersiveTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkSkip();
    _immersiveTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _enforceImmersiveMode();
    });
  }

  @override
  void dispose() {
    _immersiveTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _checkSkip() async {
    final skip = await HomeItemsStore.skipPermissions();
    final camera = await Permission.camera.isGranted;
    final photos = await Permission.photos.isGranted;
    final videos = await Permission.videos.isGranted;
    final contacts = await Permission.contacts.isGranted;
    final phone = await Permission.phone.isGranted;
    if (mounted) {
      setState(() {
        _showPermissions =
            !skip && !(camera && photos && videos && contacts && phone);
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _enforceImmersiveMode();
      // Requirement 17: show the lock screen each time the phone is opened.
      setState(() => _locked = true);
    }
  }

  Future<void> _enforceImmersiveMode() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ));
  }

  void _show(int i) => setState(() => _screen = i);

  void _sos() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Coming Soon!',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w600)),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_locked) {
      return Scaffold(
        body: Stack(
          children: [
            LockScreen(
              onUnlock: () => setState(() => _locked = false),
              onCamera: () => setState(() {
                _locked = false;
                _screen = 2;
              }),
              onSos: _sos,
            ),
            const VolumeOverlay(),
          ],
        ),
      );
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: ContraTheme.bg,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  const SystemTopBar(),
                  Expanded(
                    child: _showPermissions
                        ? PermissionsScreen(
                            onContinue: () =>
                                setState(() => _showPermissions = false),
                          )
                        : switch (_screen) {
                            0 => LauncherScreen(onOpen: (i) => _show(i)),
                            1 => DialerScreen(onClose: () => _show(0)),
                            2 => const CameraScreen(),
                            3 => const CalendarScreen(),
                            4 => const CalculatorScreen(),
                            5 => const GalleryScreen(),
                            6 => const PillTimerScreen(),
                            7 => const AlarmScreen(),
                            _ => const MessagesScreen(),
                          },
                  ),
                  SystemBottomBar(
                    onHome: () => _show(0),
                    onBack: () {
                      if (_screen != 0) _show(0);
                    },
                    onSos: _sos,
                  ),
                ],
              ),
              const VolumeOverlay(),
            ],
          ),
        ),
      ),
    );
  }
}
