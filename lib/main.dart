import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'DataRepository.dart'; // CHANGÉ

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.language});

  final String language;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  late String currentLanguage;
  Map<String, dynamic> texts = {};

  Future<Map<String, dynamic>> loadLanguageFile(String langCode) async {
    String data = await rootBundle.loadString('assets/lang/$langCode.json');
    return jsonDecode(data);
  }

  String translate(String key) {
    return (texts[key] ?? "").toString();
  }

  @override
  void initState() {
    super.initState();
    currentLanguage = widget.language;
    loadLanguageFile(currentLanguage).then((value) {
      if (!mounted) return;
      setState(() {
        texts = value;
      });
    });

    // CHANGÉ : on remplit les champs avec les données du repository
    firstNameController.text = DataRepository.firstName;
    lastNameController.text = DataRepository.lastName;
    phoneController.text = DataRepository.phone;
    emailController.text = DataRepository.email;

    // CHANGÉ : à chaque changement de texte, on sauvegarde
    firstNameController.addListener(() {
      DataRepository.firstName = firstNameController.text;
      DataRepository.saveData();
    });
    lastNameController.addListener(() {
      DataRepository.lastName = lastNameController.text;

      DataRepository.saveData();

    });
    phoneController.addListener(() {
      DataRepository.phone = phoneController.text;
      DataRepository.saveData();
    });
    emailController.addListener(() {
      DataRepository.email = emailController.text;
      DataRepository.saveData();
    });
  }

  Future<void> _switchLanguage() async {
    String newLang = currentLanguage == "EN" ? "FR" : "EN";
    Map<String, dynamic> loadedTexts = await loadLanguageFile(newLang);

    if (!mounted) return;
    setState(() {
      currentLanguage = newLang;
      texts = loadedTexts;
    });
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> _launch(String scheme, String value) async {
    if (value.isEmpty) return;

    final Uri uri = Uri(scheme: scheme, path: value);
    final bool opened = await launchUrl(uri);

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(translate("cannotOpen"))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(translate("profileTitle")),
        actions: [
          TextButton(
            onPressed: _switchLanguage,
            child: Text(
              translate("switch"),
              style: const TextStyle(fontSize: 18),
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
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: lastNameController,
              decoration: InputDecoration(
                labelText: translate("lastName"),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Flexible(
                  child: TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: translate("phone"),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _launch('tel', phoneController.text),
                  child: const Icon(Icons.phone),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _launch('sms', phoneController.text),
                  child: const Icon(Icons.sms),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Flexible(
                  child: TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: translate("email"),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _launch('mailto', emailController.text),
                  child: const Icon(Icons.mail),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}