import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import '../services/home_items_store.dart';
import '../services/phone_services.dart';
import '../theme/contra_theme.dart';
import '../widgets/custom_keyboard.dart';
import '../widgets/long_tap.dart';

class HomeApp {
  final IconData icon;
  final Color color;
  final String name;
  final String subtitle;
  final VoidCallback onTap;

  const HomeApp({
    required this.icon,
    required this.color,
    required this.name,
    required this.subtitle,
    required this.onTap,
  });
}

class LauncherScreen extends StatefulWidget {
  final void Function(int) onOpen;
  const LauncherScreen({super.key, required this.onOpen});

  @override
  State<LauncherScreen> createState() => _LauncherScreenState();
}

class _LauncherScreenState extends State<LauncherScreen> {
  List<AddedApp> _apps = [];
  List<QuickContact> _quick = [];
  final Map<String, Uint8List> _appIcons = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final apps = await HomeItemsStore.loadApps();
    final quick = await HomeItemsStore.loadQuickContacts();
    if (!mounted) return;
    setState(() {
      _apps = apps;
      _quick = quick;
      _loading = false;
    });
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Poppins')),
      duration: const Duration(seconds: 2),
    ));
  }

  List<HomeApp> _defaultApps() {
    return [
      HomeApp(
        icon: Icons.call_rounded,
        color: ContraTheme.green,
        name: 'Call',
        subtitle: 'Dial or pick a contact',
        onTap: () => widget.onOpen(1),
      ),
      HomeApp(
        icon: Icons.photo_camera_rounded,
        color: ContraTheme.blue,
        name: 'Camera',
        subtitle: 'Take a photo or video',
        onTap: () => widget.onOpen(2),
      ),
      HomeApp(
        icon: Icons.calendar_month_rounded,
        color: ContraTheme.teal,
        name: 'Calendar',
        subtitle: 'See the days and date',
        onTap: () => widget.onOpen(3),
      ),
      HomeApp(
        icon: Icons.calculate_rounded,
        color: ContraTheme.purple,
        name: 'Calculator',
        subtitle: 'Add, subtract, divide',
        onTap: () => widget.onOpen(4),
      ),
      HomeApp(
        icon: Icons.photo_library_rounded,
        color: ContraTheme.yellow,
        name: 'Gallery',
        subtitle: 'View your photos & videos',
        onTap: () => widget.onOpen(5),
      ),
      HomeApp(
        icon: Icons.settings_rounded,
        color: ContraTheme.ink,
        name: 'Settings',
        subtitle: 'Phone settings',
        onTap: () => PhoneServices.openSettings(),
      ),
    ];
  }

  void _openAddSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: ContraTheme.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add to home screen',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: ContraTheme.ink,
              ),
            ),
            const SizedBox(height: 14),
            _AddOptionRow(
              icon: Icons.apps_rounded,
              color: ContraTheme.blue,
              title: 'Add an app',
              subtitle: 'YouTube, WhatsApp and more',
              onTap: () {
                Navigator.of(context).pop();
                _openAppPicker();
              },
            ),
            const SizedBox(height: 10),
            _AddOptionRow(
              icon: Icons.person_add_rounded,
              color: ContraTheme.teal,
              title: 'Add a quick dial',
              subtitle: 'Alex with his photo, calls on tap',
              onTap: () {
                Navigator.of(context).pop();
                _openQuickDialSheet();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAppPicker() async {
    final installed = await PhoneServices.getInstalledApps();
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.9,
        child: Container(
          decoration: const BoxDecoration(
            color: ContraTheme.bg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choose an app',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: ContraTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: installed.isEmpty
                        ? const Center(
                            child: Text(
                              'No apps found',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                color: ContraTheme.muted,
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: installed.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, i) {
                              final app = installed[i];
                              return Material(
                                color: ContraTheme.card,
                                borderRadius: BorderRadius.circular(16),
                                elevation: 1,
                                child: LongTap(
                                  onActivate: () async {
                                    final icon = await PhoneServices.getAppIcon(
                                        app.package);
                                    if (!mounted) return;
                                    setState(() {
                                      _apps.add(AddedApp(
                                          name: app.name,
                                          package: app.package));
                                      if (icon != null) {
                                        _appIcons[app.package] = icon;
                                      }
                                    });
                                    await HomeItemsStore.saveApps(_apps);
                                    if (mounted) {
                                      Navigator.of(context).pop();
                                      _toast('${app.name} added');
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 10),
                                    child: Row(
                                      children: [
                                        _LetterTile(
                                          name: app.name,
                                          color: Colors.greenAccent.shade700,
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Text(
                                            app.name,
                                            style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              color: ContraTheme.ink,
                                            ),
                                          ),
                                        ),
                                        const Icon(Icons.add_circle_rounded,
                                            color: ContraTheme.teal,
                                            size: 28),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
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

  Future<String?> _pickPhoto() async {
    final photos = await Permission.photos.isGranted;
    final videos = await Permission.videos.isGranted;
    if (!photos && !videos) {
      await PhotoManager.requestPermissionExtend();
    }
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
    );
    if (albums.isEmpty) return null;
    final assets =
        await albums.first.getAssetListPaged(page: 0, size: 100);
    if (assets.isEmpty) return null;

    final picked = await showModalBottomSheet<AssetEntity>(
      context: context,
      backgroundColor: ContraTheme.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final width = MediaQuery.of(sheetContext).size.width;
        final tile = (width - 16 - 12 * 3) / 3;
        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 12),
                child: Text("Pick a photo",
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: ContraTheme.ink)),
              ),
              SizedBox(
                height: 320,
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemCount: assets.length,
                  itemBuilder: (context, i) => FutureBuilder<Uint8List?>(
                    future: assets[i]
                        .thumbnailDataWithSize(ThumbnailSize(240, 240)),
                    builder: (context, snap) {
                      final data = snap.data;
                      if (data == null) return const SizedBox.shrink();
                      return LongTap(
                        onActivate: () =>
                            Navigator.of(sheetContext).pop(assets[i]),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(data, fit: BoxFit.cover),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (picked == null) return null;
    final file = await picked.originFile;
    if (file == null) return null;
    final dir = await getApplicationDocumentsDirectory();
    final imgDir = Directory('${dir.path}/quick_photos');
    await imgDir.create(recursive: true);
    final dest =
        '${imgDir.path}/photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
    try {
      await file.copy(dest);
      return dest;
    } catch (_) {
      return null;
    }
  }

  Future<void> _openQuickDialSheet() async {
    final nameController = TextEditingController();
    final numberController = TextEditingController();
    String? photoPath;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ContraTheme.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: StatefulBuilder(
          builder: (sheetContext, setSheetState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add a quick dial',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: ContraTheme.ink,
                ),
              ),
              const SizedBox(height: 14),
              Material(
                color: ContraTheme.card,
                borderRadius: BorderRadius.circular(16),
                elevation: 1,
                child: LongTap(
                  onActivate: () async {
                    final path = await _pickPhoto();
                    if (path != null && mounted) {
                      setSheetState(() => photoPath = path);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        if (photoPath == null)
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: ContraTheme.teal,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.person_add_rounded,
                                color: Colors.white, size: 30),
                          )
                        else
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.file(
                              File(photoPath!),
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                            ),
                          ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            photoPath == null
                                ? 'Tap to choose a photo'
                                : 'Change photo',
                            style: const TextStyle(
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
                ),
              ),
              const SizedBox(height: 10),
              CustomTextField(
                controller: nameController,
                hint: 'Name (eg. Alex)',
              ),
              const SizedBox(height: 10),
              CustomTextField(
                controller: numberController,
                hint: 'Phone number',
                numeric: true,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: Material(
                  color: ContraTheme.green,
                  borderRadius: BorderRadius.circular(20),
                  child: LongTap(
                    onActivate: () async {
                      final name = nameController.text.trim();
                      final number = numberController.text.trim();
                      if (name.isEmpty || number.isEmpty) {
                        _toast('Enter a name and a number');
                        return;
                      }
                      setState(() {
                        _quick.add(QuickContact(
                            name: name,
                            number: number,
                            photoPath: photoPath));
                      });
                      await HomeItemsStore.saveQuickContacts(_quick);
                      if (mounted) {
                        Navigator.of(context).pop();
                        _toast('$name added');
                      }
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'Add to home',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 21,
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
        ),
      ),
    );
  }

  Future<void> _callQuick(QuickContact c) async {
    final status = await Permission.phone.request();
    if (!status.isGranted) {
      _toast('Phone permission needed to call');
      return;
    }
    final error = await PhoneServices.placeCall(c.number);
    if (error != null) _toast(error);
  }

  Future<void> _launchAddedApp(AddedApp app) async {
    final error = await PhoneServices.launchApp(app.package);
    if (error != null) _toast(error);
  }

  @override
  Widget build(BuildContext context) {
    final defaults = _defaultApps();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Home Screen',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: ContraTheme.ink,
                  ),
                ),
              ),
              Material(
                color: ContraTheme.teal,
                shape: const CircleBorder(),
                elevation: 2,
                shadowColor: const Color(0x22000000),
                child: LongTap(
                  onActivate: _openAddSheet,
                  child: const SizedBox(
                    width: 58,
                    height: 58,
                    child: Icon(Icons.add_rounded, color: Colors.white, size: 34),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    itemCount: defaults.length + _apps.length + _quick.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      if (i < defaults.length) {
                        final app = defaults[i];
                        return _AppRow(
                          color: app.color,
                          leading: Icon(app.icon, size: 34, color: Colors.white),
                          name: app.name,
                          subtitle: app.subtitle,
                          onTap: app.onTap,
                        );
                      }
                      final addedIndex = i - defaults.length;
                      if (addedIndex < _apps.length) {
                        final app = _apps[addedIndex];
                        final icon = _appIcons[app.package];
                        return _AppRow(
                          color: ContraTheme.blue,
                          leading: icon != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.memory(
                                    icon,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : _LetterTile(name: app.name, color: Colors.white),
                          name: app.name,
                          subtitle: 'App installed on your phone',
                          onTap: () => _launchAddedApp(app),
                        );
                      }
                      final quickIndex = addedIndex - _apps.length;
                      final quick = _quick[quickIndex];
                      return _AppRow(
                        color: ContraTheme.teal,
                        leading: quick.photoPath != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.file(
                                  File(quick.photoPath!),
                                  fit: BoxFit.cover,
                                ),
                              )
                            : _LetterTile(name: quick.name, color: Colors.white),
                        name: quick.name,
                        subtitle: 'Call ${quick.name} with one tap',
                        onTap: () => _callQuick(quick),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _AddOptionRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AddOptionRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: ContraTheme.ink,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: ContraTheme.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: ContraTheme.muted, size: 26),
            ],
          ),
        ),
      ),
    );
  }
}

class _LetterTile extends StatelessWidget {
  final String name;
  final Color color;
  const _LetterTile({required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 60,
      child: Center(
        child: Text(
          name.isEmpty ? '?' : name[0].toUpperCase(),
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _AppRow extends StatelessWidget {
  final Color color;
  final Widget leading;
  final String name;
  final String subtitle;
  final VoidCallback onTap;

  const _AppRow({
    required this.color,
    required this.leading,
    required this.name,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ContraTheme.card,
      borderRadius: BorderRadius.circular(18),
      elevation: 2,
      shadowColor: const Color(0x22000000),
      child: LongTap(
        onActivate: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          // Icon takes 1/3 of the card, name takes 2/3
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: Container(
                  height: 60,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(child: leading),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: ContraTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: ContraTheme.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}