import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/home_page.dart'; 
void main() async {
  // Initialisation de Flutter
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialisation des formats de date (pour le Français)
  await initializeDateFormatting('fr_FR', null);
  
  // Lancement de l'app
  runApp(const MonAppliRunning());
}

class MonAppliRunning extends StatelessWidget {
  const MonAppliRunning({super.key});

  @override 
  Widget build(BuildContext context) { 
    return MaterialApp(
      debugShowCheckedModeBanner: false, 
      theme: ThemeData(
        useMaterial3: true, 
        colorSchemeSeed: Colors.indigo, 
        scaffoldBackgroundColor: Colors.grey.shade50
      ), 
      home: const PageAccueil() 
    ); 
  }
}