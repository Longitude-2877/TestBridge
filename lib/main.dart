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
import 'services/phone_services.dart';
import 'theme/contra_theme.dart';
import 'widgets/permanent_overlay.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
  ));
  await WakelockPlus.enable();
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
  int _screen = 0; // 0 home, 1 dialer, 2 camera
  bool _showPermissions = true;
  Timer? _immersiveTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
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

  Future<void> _checkPermissions() async {
    final camera = await Permission.camera.isGranted;
    final photos = await Permission.photos.isGranted;
    final videos = await Permission.videos.isGranted;
    final contacts = await Permission.contacts.isGranted;
    final phone = await Permission.phone.isGranted;
    if (mounted) {
      setState(() {
        _showPermissions = !(camera && photos && videos && contacts && phone);
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _enforceImmersiveMode();
      _checkPermissions();
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

  Future<void> _exitViaPlatform() async {
    await PhoneServices.exitLauncher();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: ContraTheme.bg,
        body: SafeArea(
          child: Column(
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
                        _ => const GalleryScreen(),
                      },
              ),
              SystemBottomBar(
                onHome: () => _show(0),
                onBack: () {
                  if (_screen != 0) _show(0);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
