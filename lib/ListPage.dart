import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'AppDatabase.dart';

class ListPage extends StatefulWidget {
  const ListPage({super.key});

  @override
  State<ListPage> createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  late AppDatabase db;
  List<ContactRow> _contacts = [];

  String currentLanguage = "EN";
  Map<String, dynamic> texts = {};

  // Charger JSON
  Future<Map<String, dynamic>> loadLanguageFile(String langCode) async {
    String data = await rootBundle.loadString('assets/lang/$langCode.json');
    return jsonDecode(data);
  }

  // Fonction de traduction
  String translate(String key) {
    return (texts[key] ?? "").toString();
  }

  @override
  void initState() {
    super.initState();

    db = AppDatabase();

    // Charger EN par défaut
    loadLanguageFile("EN").then((value) {
      setState(() {
        texts = value;
      });
    });
    _loadContacts();
  }

  // Changer la langue
  void _switchLanguage() async {
    String newLang = currentLanguage == "EN" ? "FR" : "EN";
    Map<String, dynamic> loadedTexts = await loadLanguageFile(newLang);

    setState(() {
      currentLanguage = newLang;
      texts = loadedTexts;
    });
  }

  //++lab07methode qui sert a aller chercher tous les contacts dans SQLite
  //et les mettre dans la liste-contacts pour les afficher a lecran
  Future<void> _loadContacts() async {
    final contacts = await db.getAllContacts().get();
    print('CONTACTS EN BASE: ${contacts.length}'); // AJOUTÉ
    setState(() {
      _contacts = contacts;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(translate("contactList")),
        actions: [
          TextButton(
            onPressed: _switchLanguage,
            child: Text(
              translate("switch"),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: firstNameController,
              decoration: InputDecoration(
                labelText: translate("firstName"),
              ),
            ),

            TextField(
              controller: lastNameController,
              decoration: InputDecoration(
                labelText: translate("lastName"),
              ),
            ),

            TextField(
              controller: phoneNumberController,
              decoration: InputDecoration(
                labelText: translate("phoneNumber"),
              ),
            ),

            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: translate("email"),
              ),
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () async {
                await db.saveContact(
                  firstNameController.text,
                  lastNameController.text,
                  phoneNumberController.text,
                  emailController.text,
                );
                await _loadContacts();
                firstNameController.clear();
                lastNameController.clear();
                phoneNumberController.clear();
                emailController.clear();
              },

              child: Text(translate("enter")),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: _contacts.isEmpty
                  ? Center(child: Text(translate("noContacts")))
                  : ListView.builder(
                itemCount: _contacts.length,
                itemBuilder: (context, index) {
                  final contact = _contacts[index];

                  return ListTile(
                    title: Text(
                      '${contact.firstName} ${contact.lastName}',
                    ),
                    subtitle: Text(
                      '${translate("phoneNumber")}: ${contact.phone}\n'
                          '${translate("email")}: ${contact.email}',
                    ),
                    onLongPress: () {
                      showDialog(
                        context: context,
                        builder: (dialogContext) {
                          return AlertDialog(
                            title: Text(translate("deleteContact")),
                            content: Text(translate("deleteConfirm")),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(dialogContext);
                                },
                                child: Text(translate("no")),
                              ),
                              TextButton(
                                onPressed: () async {
                                  await db.deleteContact(contact.id);
                                  await _loadContacts();
                                  Navigator.pop(dialogContext);
                                },
                                child: Text(translate("yes")),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    phoneNumberController.dispose();
    emailController.dispose();
    db.close();
    super.dispose();
  }
}