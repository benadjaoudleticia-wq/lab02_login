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
  final TextEditingController firstNameController =
  TextEditingController();

  final TextEditingController lastNameController =
  TextEditingController();

  final TextEditingController phoneNumberController =
  TextEditingController();

  final TextEditingController emailController =
  TextEditingController();

  late AppDatabase db;

  List<ContactRow> _contacts = [];

  ContactRow? selectedItem;

  String currentLanguage = "EN";

  Map<String, dynamic> texts = {};

  // Charger JSON
  Future<Map<String, dynamic>> loadLanguageFile(
      String langCode) async {
    String data =
    await rootBundle.loadString('assets/lang/$langCode.json');

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

    loadLanguageFile("EN").then((value) {
      setState(() {
        texts = value;
      });
    });

    _loadContacts();
  }

  // Changer de langue
  void _switchLanguage() async {
    String newLang =
    currentLanguage == "EN" ? "FR" : "EN";

    Map<String, dynamic> loadedTexts =
    await loadLanguageFile(newLang);

    setState(() {
      currentLanguage = newLang;
      texts = loadedTexts;
    });
  }

  // Charger les contacts
  Future<void> _loadContacts() async {
    final contacts = await db.getAllContacts().get();

    print('CONTACTS EN BASE: ${contacts.length}');

    setState(() {
      _contacts = contacts;
    });
  }

  // PAGE DE DETAILS
  Widget detailsPage() {
    final item = selectedItem;

    if (item != null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Text(
              '${item.firstName} ${item.lastName}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            Text(
              '${translate("phoneNumber")}: ${item.phone}',
            ),

            Text(
              '${translate("email")}: ${item.email}',
            ),

            Text(
              'ID: ${item.id}',
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    await db.deleteContact(item.id);

                    await _loadContacts();

                    setState(() {
                      selectedItem = null;
                    });
                  },
                  child: Text(
                    translate("delete"),
                  ),
                ),

                const SizedBox(width: 16),

                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedItem = null;
                    });
                  },
                  child: Text(
                    translate("close"),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      return const Center(
        child: Text(
          "Select a contact",
          style: TextStyle(
            fontSize: 20,
            color: Colors.grey,
          ),
        ),
      );
    }
  }

  // LISTE + FORMULAIRE
  Widget listPage() {
    return Padding(
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
            child: Text(
              translate("enter"),
            ),
          ),

          const SizedBox(height: 16),

          Expanded(
            child: _contacts.isEmpty
                ? Center(
              child: Text(
                translate("noContacts"),
              ),
            )
                : ListView.builder(
              itemCount: _contacts.length,
              itemBuilder:
                  (context, index) {
                final contact =
                _contacts[index];

                return ListTile(
                  title: Text(
                    '${contact.firstName} ${contact.lastName}',
                  ),
                  subtitle: Text(
                    '${translate("phoneNumber")}: ${contact.phone}\n'
                        '${translate("email")}: ${contact.email}',
                  ),

                  onTap: () {
                    setState(() {
                      selectedItem =
                          contact;
                    });

                    print(
                      'SELECTED: ${contact.id}',
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // RESPONSIVE LAYOUT
  Widget reactiveLayout() {
    var size =
        MediaQuery.of(context).size;

    var height = size.height;
    var width = size.width;

    if ((width > height) &&
        (width > 720)) {
      return Row(
        children: [
          Expanded(
            flex: 2,
            child: listPage(),
          ),
          Expanded(
            flex: 3,
            child: detailsPage(),
          ),
        ],
      );
    } else {
      if (selectedItem == null) {
        return listPage();
      } else {
        return detailsPage();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          translate("contactList"),
        ),
        actions: [
          TextButton(
            onPressed: _switchLanguage,
            child: Text(
              translate("switch"),
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),

      body: reactiveLayout(),
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