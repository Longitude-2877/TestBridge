import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/contra_theme.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _ready = false;
  bool _saving = false;
  bool _isVideo = false;
  bool _recording = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) _toast('Camera permission is needed');
      return;
    }
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      if (mounted) _toast('No camera found');
      return;
    }
    final controller = CameraController(
      cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      ),
      ResolutionPreset.high,
    );
    _controller = controller;
    try {
      await controller.initialize();
      if (mounted) setState(() => _ready = true);
    } catch (e) {
      if (mounted) _toast('Camera failed to start');
    }
  }

  Future<void> _capture() async {
    if (_saving || _controller == null || !_ready) return;

    if (_isVideo) {
      await _toggleRecording();
      return;
    }

    setState(() => _saving = true);
    try {
      final shot = await _controller!.takePicture();
      final access = await Gal.requestAccess();
      if (!access) {
        _toast('Gallery permission is needed to save photos');
        return;
      }
      await Gal.putImage(shot.path);
      if (mounted) _toast('Photo saved to gallery');
    } catch (e) {
      if (mounted) _toast('Could not take photo');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _toggleRecording() async {
    if (_controller == null || !_ready) return;
    try {
      if (_recording) {
        final rec = await _controller!.stopVideoRecording();
        setState(() => _recording = false);
        final access = await Gal.requestAccess();
        if (!access) {
          _toast('Gallery permission is needed to save videos');
          return;
        }
        await Gal.putVideo(rec.path);
        if (mounted) _toast('Video saved to gallery');
      } else {
        await _controller!.startVideoRecording();
        setState(() => _recording = true);
      }
    } catch (e) {
      setState(() => _recording = false);
      if (mounted) _toast('Could not record video');
    }
  }

  void _setMode(bool video) {
    if (_recording) return;
    setState(() => _isVideo = video);
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Poppins')),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    child: _ready && _controller != null
                        ? CameraPreview(_controller!)
                        : const Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ModeButton(
                    icon: Icons.photo_camera_rounded,
                    label: 'Photos',
                    active: !_isVideo,
                    onTap: () => _setMode(false),
                  ),
                  const SizedBox(width: 10),
                  _ModeButton(
                    icon: Icons.videocam_rounded,
                    label: 'Video',
                    active: _isVideo,
                    onTap: () => _setMode(true),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _CaptureButton(
                isVideo: _isVideo,
                recording: _recording,
                saving: _saving,
                onTap: _capture,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ModeButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? ContraTheme.blue : Colors.white70;
    return Material(
      color: active ? Colors.white : Colors.white24,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CaptureButton extends StatelessWidget {
  final bool isVideo;
  final bool recording;
  final bool saving;
  final VoidCallback onTap;
  const _CaptureButton({
    required this.isVideo,
    required this.recording,
    required this.saving,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Widget inner;
    if (saving) {
      inner = const Padding(
        padding: EdgeInsets.all(14),
        child: CircularProgressIndicator(color: ContraTheme.red),
      );
    } else if (recording) {
      inner = Padding(
        padding: const EdgeInsets.all(14),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      );
    } else if (isVideo) {
      inner = const Padding(
        padding: EdgeInsets.all(14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red,
          ),
        ),
      );
    } else {
      inner = const Icon(
        Icons.camera_alt_rounded,
        size: 32,
        color: ContraTheme.ink,
      );
    }

    final ringColor = recording || isVideo ? ContraTheme.red : Colors.white;

    return Material(
      shape: const CircleBorder(),
      color: Colors.white,
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: ringColor, width: 5),
          ),
          child: inner,
        ),
      ),
    );
  }
}