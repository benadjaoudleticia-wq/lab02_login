//on diit a dart quon veut utiliser du code qui vient dune autre
import 'ProfilePage.dart';
import 'dart:convert'; // pour lire le JSON
import 'package:flutter/services.dart'; // pour charger les fichiers dans assets
import 'package:flutter/material.dart';
//library ajouter pour que mon application puisse sauvgarder les donnees , lab4
import 'package:encrypted_shared_preferences/encrypted_shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

// StatelessWidget means na pas detat qui change  donc myapp aussi
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  //  the root of my application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

//StatefulWidget cest un widget qui a un etat qui peut changer var qui bougent
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

//this class controlle myhomepage
class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController loginController = TextEditingController(); // read/modifier
  final TextEditingController passwordController = TextEditingController();

  String currentLanguage = "EN";
  String imageSource = "assets/question-mark.webp";

  // ici on va stocker les textes du fichier JSON
  Map<String, dynamic> texts = {};

  // fonction pour charger un fichier JSON dans assets/lang/
  Future<Map<String, dynamic>> loadLanguageFile(String langCode) async {
    String data = await rootBundle.loadString('assets/lang/$langCode.json');
    return jsonDecode(data);
  }

  // charger EN.json au démarrage
  @override
  void initState() {
    super.initState();
    loadLanguageFile("EN").then((value) {
      setState(() {
        texts = value;
      });
    }).catchError((error) {
      print("Erreur de chargement JSON : $error");
    }).whenComplete(() {
      _loadSavedLogin(); //appel de ma fonction ajouter pour charger les donner sauvgarder ,lab4
    });
  }
//function to save the data from the log in lab4
  void _loadSavedLogin() async {
    final prefs = EncryptedSharedPreferences();
    String? savedUser = await prefs.getString("username");
    String? savedPass = await prefs.getString("password");

    if (savedUser != null && savedUser.isNotEmpty && savedPass != null && savedPass.isNotEmpty) {
      loginController.text = savedUser;
      passwordController.text = savedPass;

      // lancer le Snackbar apres que la page soit prete
      Future.delayed(Duration.zero, () {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(texts["savedLoaded"] ?? "Saved login info loaded")),
        );
      });
    }
  }

  Future<void> _showSaveDialog() {
    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(texts["dialogTitle"] ?? "Save Login Info"),
        content: Text(texts["dialogContent"] ?? "Would you like to save your username and password?"),
        actions: [
          TextButton(
            child: Text(texts["no"] ?? "No"),
            onPressed: () async {
              final prefs = EncryptedSharedPreferences();
              await prefs.clear(); //efacer les donnees
              Navigator.pop(dialogContext);
            },
          ),
          TextButton(
            child: Text(texts["yes"] ?? "Yes"),
            onPressed: () async {
              final prefs = EncryptedSharedPreferences();
              await prefs.setString("username", loginController.text);
              await prefs.setString("password", passwordController.text);

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(texts["saved"] ?? "Login info saved")),
              );

              Navigator.pop(dialogContext);
            },
          ),
        ],
      ),
    );
  }

  //methode of building homepage
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),

        //  Buton for switch lang
        actions: [
          TextButton(
            onPressed: () async {
              String newLang = currentLanguage == "EN" ? "FR" : "EN";

              //  le fichier JSON correspondant
              Map<String, dynamic> loadedTexts =
              await loadLanguageFile(newLang);

              setState(() {
                currentLanguage = newLang;
                texts = loadedTexts;
              });
            },
            child: Text(
              texts["switch"] ?? "",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 16),

            //  LOGIN
            TextField(
              controller: loginController,
              decoration: InputDecoration(
                labelText: texts["login"] ?? "",
              ),
            ),

            const SizedBox(height: 16),

            //  PASSWORD
            TextField(
              controller: passwordController,
              obscureText: true, //cache le texte
              decoration: InputDecoration(
                labelText: texts["password"] ?? "",
              ),
            ),

            const SizedBox(height: 16),

            // BOUTON LOGIN
            ElevatedButton(
              onPressed: () async {
                String password = passwordController.text;

                if (password == "ASDF") {
                  setState(() {
                    imageSource = "assets/light-bulb.webp";
                  });

                  await _showSaveDialog();

                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("${texts["welcome"] ?? "Welcome Back"} ${loginController.text}")), // CHANGÉ
                  );

                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfilePage(language: currentLanguage)), // CHANGÉ
                  );
                } else {
                  setState(() {
                    imageSource = "assets/stop-sign.png";
                  });
                }
              },
              child: Text(texts["connect"] ?? ""),
            ),

            const SizedBox(height: 16),

            // IMAGE
            SizedBox(
              width: 300,
              height: 300,
              child: Image.asset(imageSource),
            ),
          ],
        ),
      ),
    );
  }
}