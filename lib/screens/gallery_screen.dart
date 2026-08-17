import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';
import '../theme/contra_theme.dart';
import '../widgets/long_press.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<AssetEntity>? _assets;
  bool _error = false;
  Widget? _viewer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final photos = await Permission.photos.isGranted;
    final videos = await Permission.videos.isGranted;
    var mediaOk = photos || videos;
    // Photo access (needed to delete media) — only prompts once; afterwards
    // it returns instantly without asking again.
    if (!mediaOk) {
      mediaOk =
          (await PhotoManager.requestPermissionExtend()).hasAccess;
    }
    if (!mediaOk) {
      if (mounted) setState(() => _error = true);
      return;
    }
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      onlyAll: true,
    );
    if (albums.isEmpty) {
      setState(() => _assets = []);
      return;
    }
    final assets = await albums.first.getAssetListPaged(page: 0, size: 200);
    final sorted = [...assets]..sort((a, b) =>
        b.createDateTime.compareTo(a.createDateTime));
    if (mounted) setState(() => _assets = sorted);
  }

  Future<void> _open(AssetEntity asset) async {
    if (asset.type == AssetType.video) {
      setState(() {
        _viewer = _VideoViewer(
          asset: asset,
          onExit: (deleted) => setState(() {
            _viewer = null;
            if (deleted) _load();
          }),
        );
      });
    } else {
      final file = await asset.originFile;
      if (file == null || !mounted) return;
      setState(() {
        _viewer = _PhotoViewer(
          asset: asset,
          file: file,
          onExit: (deleted) => setState(() {
            _viewer = null;
            if (deleted) _load();
          }),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gallery',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: ContraTheme.ink,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _viewer != null
                ? _viewer!
                : _error
                ? const Center(
                    child: Text(
                      'Photos permission is needed.\nAllow it in the popup and come back.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: ContraTheme.muted,
                      ),
                    ),
                  )
                : _assets == null
                    ? const Center(child: CircularProgressIndicator())
                    : _assets!.isEmpty
                        ? const Center(
                            child: Text(
                              'No photos or videos yet.\nTake one with the camera!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: ContraTheme.muted,
                              ),
                            ),
                          )
                        : GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              // Requirement 9: larger photo / video previews.
                              crossAxisCount: 2,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                            ),
                            itemCount: _assets!.length,
                            itemBuilder: (context, i) {
                              final asset = _assets![i];
                              return _GalleryTile(
                                asset: asset,
                                onTap: () => _open(asset),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _GalleryTile extends StatefulWidget {
  final AssetEntity asset;
  final VoidCallback onTap;
  const _GalleryTile({required this.asset, required this.onTap});

  @override
  State<_GalleryTile> createState() => _GalleryTileState();
}

class _GalleryTileState extends State<_GalleryTile> {
  Uint8List? _thumb;

  @override
  void initState() {
    super.initState();
    _loadThumb();
  }

  Future<void> _loadThumb() async {
    final bytes = await widget.asset.thumbnailDataWithSize(
      const ThumbnailSize(600, 600),
    );
    if (mounted) setState(() => _thumb = bytes);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ContraTheme.card,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      child: LongPressInk(
        onTap: widget.onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_thumb != null)
              Image.memory(_thumb!, fit: BoxFit.cover)
            else
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            if (widget.asset.type == AssetType.video)
              const Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.play_circle_fill_rounded,
                      color: Colors.white, size: 28),
                ),
              ),
            if (widget.asset.type != AssetType.video)
              const Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.photo_rounded, color: Colors.white, size: 20),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PhotoViewer extends StatefulWidget {
  final AssetEntity asset;
  final File file;
  final void Function(bool deleted) onExit;
  const _PhotoViewer({
    required this.asset,
    required this.file,
    required this.onExit,
  });

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Delete this photo?',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 16)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    color: ContraTheme.red)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await PhotoManager.requestPermissionExtend();
      try {
        final failed =
            await PhotoManager.editor.deleteWithIds([widget.asset.id]);
        if (failed.isEmpty && mounted) widget.onExit(true);
        return;
      } catch (e) {
        debugPrint('delete photo failed: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not delete this photo',
                style: TextStyle(fontFamily: 'Poppins')),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              child: Image.file(widget.file, fit: BoxFit.contain),
            ),
          ),
          Positioned(
            left: 16,
            top: 12,
            child: _CloseButton(onTap: () => widget.onExit(false)),
          ),
          Positioned(
            right: 16,
            top: 12,
            child: _DeleteButton(onTap: _confirmDelete),
          ),
        ],
      ),
    );
  }
}

class _VideoViewer extends StatefulWidget {
  final AssetEntity asset;
  final void Function(bool deleted) onExit;
  const _VideoViewer({required this.asset, required this.onExit});

  @override
  State<_VideoViewer> createState() => _VideoViewerState();
}

class _VideoViewerState extends State<_VideoViewer> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final file = await widget.asset.originFile;
    if (file == null || !mounted) return;
    final controller = VideoPlayerController.file(file);
    _controller = controller;
    await controller.initialize();
    if (mounted) setState(() {});
    await controller.play();
    controller.setLooping(true);
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Delete this video?',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 16)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    color: ContraTheme.red)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await PhotoManager.requestPermissionExtend();
      try {
        final failed =
            await PhotoManager.editor.deleteWithIds([widget.asset.id]);
        if (failed.isEmpty && mounted) widget.onExit(true);
        return;
      } catch (e) {
        debugPrint('delete video failed: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not delete this video',
                style: TextStyle(fontFamily: 'Poppins')),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
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
      body: Stack(
        children: [
          Positioned.fill(
            child: _controller != null && _controller!.value.isInitialized
                ? Center(
                    child: AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: VideoPlayer(_controller!),
                    ),
                  )
                : const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
          ),
          Positioned(
            left: 16,
            top: 12,
            child: _CloseButton(onTap: () => widget.onExit(false)),
          ),
          Positioned(
            right: 16,
            top: 12,
            child: _DeleteButton(onTap: _confirmDelete),
          ),
        ],
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      shape: const CircleBorder(),
      child: LongPressInk(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 42,
          height: 42,
          child: Icon(Icons.close_rounded, color: Colors.white, size: 26),
        ),
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  final VoidCallback onTap;
  const _DeleteButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      shape: const CircleBorder(),
      child: LongPressInk(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 42,
          height: 42,
          child: Icon(Icons.delete_rounded, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}