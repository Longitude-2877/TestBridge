import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/phone_services.dart';
import '../theme/contra_theme.dart';
import '../widgets/custom_keyboard.dart';
import '../widgets/long_tap.dart';

class ContactsScreen extends StatefulWidget {
  final void Function(Contact contact)? onSelected;
  const ContactsScreen({super.key, this.onSelected});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  List<Contact>? _contacts;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final status = await Permission.contacts.request();
    if (!status.isGranted) {
      setState(() => _error = true);
      return;
    }
    final list = await PhoneServices.getContacts();
    setState(() => _contacts = list);
  }

  Future<void> _callContact(Contact c) async {
    final status = await Permission.phone.request();
    if (!status.isGranted) return;
    if (!mounted) return;
    final error = await PhoneServices.placeCall(c.number);
    if (error != null && mounted) _toast(error);
  }

  Future<void> _addContact() async {
    final nameController = TextEditingController();
    final numberController = TextEditingController();

    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ContraTheme.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add a contact',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: ContraTheme.ink,
              ),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: nameController,
              hint: 'Contact name',
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: numberController,
              hint: 'Phone number',
              numeric: true,
            ),
            const SizedBox(height: 20),
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
                    final error =
                        await PhoneServices.addContact(name, number);
                    if (error == null) {
                      Navigator.of(context).pop(true);
                      _toast('Contact saved');
                      _load();
                    } else {
                      _toast(error);
                    }
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 18),
                    child: Center(
                      child: Text(
                        'Save contact',
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
      ),
    );
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Poppins')),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Contacts',
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
                  onActivate: _addContact,
                  child: const SizedBox(
                    width: 64,
                    height: 64,
                    child: Icon(Icons.person_add_rounded,
                        color: Colors.white, size: 36),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _error
                ? const Center(
                    child: Text(
                      'Contacts permission is needed.\nAllow it in the popup and come back.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: ContraTheme.muted,
                      ),
                    ),
                  )
                : _contacts == null
                    ? const Center(child: CircularProgressIndicator())
                    : _contacts!.isEmpty
                        ? const Center(
                            child: Text(
                              'No contacts yet.\nTap the + to add one!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: ContraTheme.muted,
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: _contacts!.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              final c = _contacts![i];
                              return Material(
                                color: ContraTheme.card,
                                borderRadius: BorderRadius.circular(20),
                                elevation: 1,
                                child: LongTap(
                                  onActivate: () {
                                    final selected = widget.onSelected;
                                    if (selected != null) {
                                      selected(c);
                                    } else {
                                      _callContact(c);
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 24,
                                          backgroundColor: ContraTheme.teal,
                                          child: Text(
                                            c.name.isEmpty
                                                ? '?'
                                                : c.name[0].toUpperCase(),
                                            style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 20,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                c.name.isEmpty
                                                    ? 'Unknown'
                                                    : c.name,
                                                style: const TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600,
                                                  color: ContraTheme.ink,
                                                ),
                                              ),
                                              Text(
                                                c.number,
                                                style: const TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w500,
                                                  color: ContraTheme.muted,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          Icons.call_rounded,
                                          color: ContraTheme.green,
                                          size: 28,
                                        ),
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
    );
  }
}