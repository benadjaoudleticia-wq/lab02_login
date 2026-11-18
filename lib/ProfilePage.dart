import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'DataRepository.dart';
import 'ListPage.dart'; // AJOUT POUR LAB 6

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.language,
    required this.username,
  });

  final String language;
  final String username;

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

  // Load JSON language file
  Future<Map<String, dynamic>> loadLanguageFile(String langCode) async {
    String data = await rootBundle.loadString('assets/lang/$langCode.json');
    return jsonDecode(data);
  }

  // Translation function
  String translate(String key) {
    return (texts[key] ?? "").toString();
  }

  @override
  void initState() {
    super.initState();

    currentLanguage = widget.language;

    // Load language text
    loadLanguageFile(currentLanguage).then((value) {
      if (!mounted) return;
      setState(() {
        texts = value;
      });
    });

    // Load saved profile data
    DataRepository.loadData().then((_) {
      if (!mounted) return;

      firstNameController.text = DataRepository.firstName;
      lastNameController.text = DataRepository.lastName;
      phoneController.text = DataRepository.phone;
      emailController.text = DataRepository.email;
    });

    // Auto-save listeners
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

  // Switch language
  Future<void> _switchLanguage() async {
    String newLang = currentLanguage == "EN" ? "FR" : "EN";
    Map<String, dynamic> loadedTexts = await loadLanguageFile(newLang);

    if (!mounted) return;
    setState(() {
      currentLanguage = newLang;
      texts = loadedTexts;
    });
  }

  // Launch tel, sms, mailto
  Future<void> _launch(String scheme, String value) async {
    if (value.isEmpty) return;

    final Uri uri = Uri(scheme: scheme, path: value);
    final bool opened = await launchUrl(uri);

    if (!opened && mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(translate("cannotOpenTitle")),
          content: Text(translate("cannotOpen")),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(translate("ok")),
            ),
          ],
        ),
      );
    }
  }

  @override
  //pour liberer la memoir et vider tout
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
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
              style: const TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const SizedBox(height: 16),

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

                // EMAIL BUTTON
                ElevatedButton(
                  onPressed: () async {
                    final email = emailController.text;

                    if (email.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Email address is empty")),
                      );
                      return;
                    }

                    final Uri gmailUri = Uri.parse(
                        "https://mail.google.com/mail/?view=cm&fs=1&to=$email"
                    );

                    if (await canLaunchUrl(gmailUri)) {
                      await launchUrl(gmailUri);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Cannot open Gmail")),
                      );
                    }
                  },
                  child: const Icon(Icons.mail),
                ),
              ],
            ),

            // BOUTON AU MILIEU
            const SizedBox(height: 30),

            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ListPage(),
                    ),
                  );
                },
                child: Text(
                  translate("contactList"),
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}
