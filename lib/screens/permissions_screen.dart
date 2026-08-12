import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/home_items_store.dart';
import '../services/phone_services.dart';
import '../theme/contra_theme.dart';
import '../widgets/long_tap.dart';

class PermissionsScreen extends StatefulWidget {
  final VoidCallback onContinue;
  const PermissionsScreen({super.key, required this.onContinue});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  bool _camera = false;
  bool _photos = false;
  bool _videos = false;
  bool _contacts = false;
  bool _phone = false;
  bool _skipNextTime = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final camera = await Permission.camera.isGranted;
    final photos = await Permission.photos.isGranted;
    final videos = await Permission.videos.isGranted;
    final contacts = await Permission.contacts.isGranted;
    final phone = await Permission.phone.isGranted;
    if (mounted) {
      setState(() {
        _camera = camera;
        _photos = photos;
        _videos = videos;
        _contacts = contacts;
        _phone = phone;
      });
    }
  }

  Future<void> _askPermission(Permission p) async {
    final status = await p.request();
    if (status.isGranted) {
      await _refresh();
      return;
    }
    if (status.isPermanentlyDenied) {
      if (mounted) {
        _toast('Android blocked this. Press and hold to open Settings');
      }
      await openAppSettings();
      return;
    }
    await _refresh();
    if (mounted) {
      _toast('Not allowed yet - press and hold the card to try again');
    }
  }

  Future<void> _askCamera() => _askPermission(Permission.camera);

  Future<void> _askPhotos() => _askPermission(Permission.photos);

  Future<void> _askVideos() => _askPermission(Permission.videos);

  Future<void> _askContacts() => _askPermission(Permission.contacts);

  Future<void> _askPhone() => _askPermission(Permission.phone);

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Poppins')),
        duration: const Duration(seconds: 2),
      ));
  }

  Widget _permCard({
    required IconData icon,
    required Color color,
    required String title,
    required bool granted,
    required VoidCallback onTap,
  }) {
    return Material(
      color: ContraTheme.card,
      borderRadius: BorderRadius.circular(18),
      elevation: 1,
      child: LongTap(
        onActivate: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: granted ? ContraTheme.green : color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: ContraTheme.ink,
                  ),
                ),
              ),
              Icon(
                granted ? Icons.check_circle_rounded : Icons.lock_rounded,
                color: granted ? ContraTheme.green : ContraTheme.muted,
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome!',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: ContraTheme.ink,
            ),
          ),
          const Text(
            'Tap each item to allow it.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: ContraTheme.muted,
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: ListView(
              children: [
                _permCard(
                  icon: Icons.photo_camera_rounded,
                  color: ContraTheme.blue,
                  title: 'Camera',
                  granted: _camera,
                  onTap: _askCamera,
                ),
                const SizedBox(height: 8),
                _permCard(
                  icon: Icons.photo_library_rounded,
                  color: ContraTheme.yellow,
                  title: 'Photos',
                  granted: _photos,
                  onTap: _askPhotos,
                ),
                const SizedBox(height: 8),
                _permCard(
                  icon: Icons.videocam_rounded,
                  color: ContraTheme.purple,
                  title: 'Videos',
                  granted: _videos,
                  onTap: _askVideos,
                ),
                const SizedBox(height: 8),
                _permCard(
                  icon: Icons.contacts_rounded,
                  color: ContraTheme.teal,
                  title: 'Contacts',
                  granted: _contacts,
                  onTap: _askContacts,
                ),
                const SizedBox(height: 8),
                _permCard(
                  icon: Icons.call_rounded,
                  color: ContraTheme.green,
                  title: 'Phone calls',
                  granted: _phone,
                  onTap: _askPhone,
                ),
                const SizedBox(height: 8),
                Material(
                  color: ContraTheme.card,
                  borderRadius: BorderRadius.circular(18),
                  elevation: 1,
                  child: LongTap(
                    onActivate: () => PhoneServices.requestDefaultLauncher(),
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Icon(Icons.home_rounded,
                              color: ContraTheme.teal, size: 30),
                          SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'Make this the default launcher',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: ContraTheme.ink,
                              ),
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded,
                              color: ContraTheme.muted, size: 26),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          LongTap(
            onActivate: () => setState(() => _skipNextTime = !_skipNextTime),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: _skipNextTime
                        ? ContraTheme.green
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: _skipNextTime
                          ? ContraTheme.green
                          : ContraTheme.muted,
                      width: 2,
                    ),
                  ),
                  child: _skipNextTime
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 20)
                      : null,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Don't show this screen again',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: ContraTheme.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: Material(
              color: ContraTheme.teal,
              borderRadius: BorderRadius.circular(20),
              child: LongTap(
                onActivate: () async {
                  await HomeItemsStore.savePermissionsSkipped(_skipNextTime);
                  if (mounted) widget.onContinue();
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      'Continue',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}