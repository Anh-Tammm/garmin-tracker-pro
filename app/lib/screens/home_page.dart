import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../config/app_config.dart';
import '../data/globals.dart';
import '../models/models.dart';

// Import des onglets
import 'tabs/dashboard_tab.dart';
import 'tabs/library_page.dart';
import 'tabs/planning_page.dart';
import 'tabs/career_page.dart';
import 'tabs/tools_page.dart';

// Import des réglages
import 'settings/settings_pages.dart';

class PageAccueil extends StatefulWidget { const PageAccueil({super.key}); @override State<PageAccueil> createState() => _PageAccueilState(); }

class _PageAccueilState extends State<PageAccueil> with TickerProviderStateMixin {
  bool chargementInitialTermine = false;
  bool _isSyncing = false;
  DateTime? derniereSynchro;
  
  late AnimationController _progressController;
  
  Future<void> chargerDonneesReseau() async {
    // Utilisation de AppConfig.urlJson
    String urlNoCache = "${AppConfig.urlJson}?t=${DateTime.now().millisecondsSinceEpoch}";
    try { 
      final response = await http.get(
        Uri.parse(urlNoCache), 
        // Utilisation de AppConfig.githubToken
        headers: {"Authorization": "token ${AppConfig.githubToken}", "Accept": "application/vnd.github.v3.raw"}
      ); 
      if (response.statusCode == 200) { 
        final Map<String, dynamic> data = json.decode(utf8.decode(response.bodyBytes)); 
        _mettreAJourIntelligente(data, source : "RESEAU"); 
      } 
    } catch (e) { 
      print("Erreur réseau : $e"); 
    }
  }
 

  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override 
  void initState() { 
    super.initState(); 
    _progressController = AnimationController(vsync: this, duration: const Duration(seconds: 60));
    _chargerDonneesGlobales(); 
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _chargerDonneesGlobales() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        objectifSemaine = prefs.getDouble('obj_semaine') ?? 0;
        objectifMois = prefs.getDouble('obj_mois') ?? 0;
        objectifAnnee = prefs.getDouble('obj_annee') ?? 0;
        String? notesJson = prefs.getString('user_annotations');
        if (notesJson != null) userAnnotations = json.decode(notesJson);
      });
      
      await _chargerLocalBackup();
      await chargerDonneesReseau();
      
    } catch (e) {
      print("Erreur globale : $e");
    } finally {
      if (!chargementInitialTermine && mounted) {
        setState(() => chargementInitialTermine = true);
      }
    }
  }

  Future<void> _chargerLocalBackup() async {
    try { 
      final String reponse = await rootBundle.loadString('assets/mes_seances.json'); 
      final Map<String, dynamic> data = json.decode(reponse); 
      _mettreAJourIntelligente(data, source: "LOCAL"); 
    } catch (e) { 
      print("Pas de fichier local ou erreur: $e"); 
    }
  }

  void _mettreAJourIntelligente(Map<String, dynamic> data, {required String source}) {
    if (!mounted) return;
    
    try {
      setState(() {
        if (data.containsKey("profil")) { 
          monProfil = UserProfile.fromJson(data["profil"]); 
        } else if (source == "RESEAU") { 
          monProfil = null; 
        }
        
        if (data.containsKey("seances")) { 
          var nouvellesSeances = (data["seances"] as List).map((j) => Seance.fromJson(j)).toList(); 
          
          // Logique Tags
          Map<String, int> compteurTitres = {};
          for (var s in nouvellesSeances) {
            String t = s.titreNettoye;
            compteurTitres[t] = (compteurTitres[t] ?? 0) + 1;
          }

          RegExp patternIntervalleSimple = RegExp(r'^\d+\s*x\s*\d+\s*(m|km)?$');

          for (var s in nouvellesSeances) {
            String t = s.titreNettoye;
            if ((compteurTitres[t] ?? 0) > 1) {
              bool isRedondant = patternIntervalleSimple.hasMatch(t.toLowerCase());
              bool isGeneric = t.length < 3 || t.toLowerCase().contains("course à pied");

              if (!isRedondant && !isGeneric && !s.tags.contains(t)) {
                s.tags.add(t);
              }
            }
          }

          if (nouvellesSeances.isNotEmpty) mesDonnees = nouvellesSeances; 
        }
        
        if (source == "RESEAU") derniereSynchro = DateTime.now();
        if (source == "LOCAL") chargementInitialTermine = true;
      });
    } catch (e) {
      print("Erreur update: $e");
    }
  }
  
  Future<void> _declencherMiseAJourDistante() async {
    setState(() { _isSyncing = true; });
    _progressController.reset();
    _progressController.forward();
    
    try {
      final response = await http.post(
        Uri.parse(AppConfig.urlWorkflow),
        headers: { 
          "Authorization": "token ${AppConfig.githubToken}", 
          "Accept": "application/vnd.github.v3+json", 
          "Content-Type": "application/json" 
        },
        body: json.encode({"ref": "main"})
      );
      if (response.statusCode != 204) throw Exception("Code ${response.statusCode}");
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur : $e"), backgroundColor: Colors.red));
      _progressController.stop();
      if(mounted) setState(() => _isSyncing = false);
    }
  
  }
 
  @override
  Widget build(BuildContext context) {
    if (!chargementInitialTermine && mesDonnees.isEmpty) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    
    return Scaffold(
      drawer: Drawer(
        child: Column(children: [
          const SizedBox(height: 50),
          ListTile(leading: const Icon(Icons.track_changes), title: const Text('Définir Objectifs'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (c) => const PageDefinirObjectifs())).then((v) => _chargerDonneesGlobales()); }),
          ListTile(leading: const Icon(Icons.tune), title: const Text('Personnaliser Interface'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (c) => const PagePersonnalisation())).then((v) => setState((){})); }),
          ListTile(leading: const Icon(Icons.settings_input_component), title: const Text('Réglages Seuils'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (c) => const PageReglagesSeuils())).then((v) => setState((){})); }),
          ListTile(leading: const Icon(Icons.label), title: const Text('Gérer les Tags'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (c) => const PageGestionTags())).then((v) => setState((){})); }),
        ]),
      ),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppConfig.appTitle, style: const TextStyle(fontSize: 18)),
            if (derniereSynchro != null)
              Text("MàJ : ${DateFormat('HH:mm').format(derniereSynchro!)}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
        backgroundColor: Colors.white, 
        surfaceTintColor: Colors.white,
        bottom: _isSyncing 
          ? PreferredSize(preferredSize: const Size.fromHeight(4), child: AnimatedBuilder(animation: _progressController, builder: (context, child) => LinearProgressIndicator(value: _progressController.value, minHeight: 4, backgroundColor: Colors.transparent, color: Colors.indigo)))
          : null,
        actions: [
          IconButton(icon: const Icon(Icons.sync, color: Colors.indigo), onPressed: _declencherMiseAJourDistante),
          const SizedBox(width: 10),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (idx) => setState(() => _currentIndex = idx),
        children: [
          RefreshIndicator(onRefresh: chargerDonneesReseau, color: Colors.indigo, child: DashboardTab(derniereSynchro: derniereSynchro)),
          const PageLibrary(),
          const PagePlanning(), 
          const PageCareer(),
          const PageOutils(), 
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed, 
        selectedItemColor: Colors.indigo,
        onTap: (idx) => _pageController.animateToPage(idx, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Accueil"),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: "Biblio"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: "Planning"),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: "Carrière"),
          BottomNavigationBarItem(icon: Icon(Icons.calculate), label: "Outils"),
        ],
      ),
    );
  }
}
