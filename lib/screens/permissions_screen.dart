import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/phone_services.dart';
import '../theme/contra_theme.dart';

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

  Future<void> _askCamera() async {
    await Permission.camera.request();
    _refresh();
  }

  Future<void> _askPhotos() async {
    await Permission.photos.request();
    _refresh();
  }

  Future<void> _askVideos() async {
    await Permission.videos.request();
    _refresh();
  }

  Future<void> _askContacts() async {
    await Permission.contacts.request();
    _refresh();
  }

  Future<void> _askPhone() async {
    await Permission.phone.request();
    _refresh();
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
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
                  child: InkWell(
                    onTap: () => PhoneServices.requestDefaultLauncher(),
                    borderRadius: BorderRadius.circular(18),
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
          SizedBox(
            width: double.infinity,
            child: Material(
              color: ContraTheme.teal,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: widget.onContinue,
                borderRadius: BorderRadius.circular(20),
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