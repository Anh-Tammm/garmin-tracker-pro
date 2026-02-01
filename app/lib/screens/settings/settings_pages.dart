import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http; 

// Imports de vos fichiers
import '../../config/app_config.dart';
import '../../data/globals.dart';
import '../../models/models.dart';

// --- 1. PAGE DÉFINIR OBJECTIFS ---
class PageDefinirObjectifs extends StatefulWidget { const PageDefinirObjectifs({super.key}); @override State<PageDefinirObjectifs> createState() => _PageDefinirObjectifsState(); }
class _PageDefinirObjectifsState extends State<PageDefinirObjectifs> {
  final _semaineCtrl = TextEditingController();
  final _moisCtrl = TextEditingController();
  final _anneeCtrl = TextEditingController();
  final _vmaCtrl = TextEditingController();

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      if(prefs.getDouble('obj_semaine') != null) _semaineCtrl.text = prefs.getDouble('obj_semaine')!.toInt().toString();
      if(prefs.getDouble('obj_mois') != null) _moisCtrl.text = prefs.getDouble('obj_mois')!.toInt().toString();
      if(prefs.getDouble('obj_annee') != null) _anneeCtrl.text = prefs.getDouble('obj_annee')!.toInt().toString();
      if(prefs.getDouble('user_vma') != null) _vmaCtrl.text = prefs.getDouble('user_vma')!.toString();
    });
  }

  Future<void> _save() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (_semaineCtrl.text.isNotEmpty) await prefs.setDouble('obj_semaine', double.parse(_semaineCtrl.text)); else await prefs.remove('obj_semaine');
    if (_moisCtrl.text.isNotEmpty) await prefs.setDouble('obj_mois', double.parse(_moisCtrl.text)); else await prefs.remove('obj_mois');
    if (_anneeCtrl.text.isNotEmpty) await prefs.setDouble('obj_annee', double.parse(_anneeCtrl.text)); else await prefs.remove('obj_annee');
    
    if (_vmaCtrl.text.isNotEmpty) {
      String vmaStr = _vmaCtrl.text.replaceAll(',', '.');
      await prefs.setDouble('user_vma', double.parse(vmaStr));
    } else {
      await prefs.remove('user_vma');
    }
    
    Navigator.pop(context);
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Définir Objectifs & VMA")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("Performances", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo)),
          const SizedBox(height: 10),
          TextField(
            controller: _vmaCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: "Votre VMA (km/h)", border: OutlineInputBorder(), prefixIcon: Icon(Icons.speed), hintText: "Ex: 15.5"),
          ),
          const SizedBox(height: 30),
          const Text("Objectifs de Volume", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo)),
          const SizedBox(height: 10),
          TextField(controller: _semaineCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Hebdo (km)", border: OutlineInputBorder(), prefixIcon: Icon(Icons.calendar_view_week))),
          const SizedBox(height: 15),
          TextField(controller: _moisCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Mensuel (km)", border: OutlineInputBorder(), prefixIcon: Icon(Icons.calendar_month))),
          const SizedBox(height: 15),
          TextField(controller: _anneeCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Annuel (km)", border: OutlineInputBorder(), prefixIcon: Icon(Icons.calendar_today))),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, padding: const EdgeInsets.all(15)),
            child: const Text("SAUVEGARDER")
          )
        ]
      )
    );
  }
}

// --- 2. PAGE PERSONNALISATION ---
class PagePersonnalisation extends StatefulWidget {
  const PagePersonnalisation({super.key});
  @override
  State<PagePersonnalisation> createState() => _PagePersonnalisationState();
}
class _PagePersonnalisationState extends State<PagePersonnalisation> {
  final TextEditingController _titreCtrl = TextEditingController(text: AppConfig.appTitle);
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  final TextEditingController _limitCtrl = TextEditingController(text: "10");
  
  bool _isUpdating = false;
  bool _obscurePassword = true; 

  Future<void> _updateGarminCredentials() async {
    setState(() { _isUpdating = true; });
    try {
      // 1. Récupérer le SHA
      final getResponse = await http.get(
        Uri.parse(AppConfig.urlConfig), 
        headers: {
          "Authorization": "token ${AppConfig.githubToken}", 
          "Accept": "application/vnd.github.v3+json",
        },
      );

      String? currentSha;
      if (getResponse.statusCode == 200) {
        final data = json.decode(getResponse.body);
        currentSha = data['sha'];
      }

      // 2. Préparer le contenu
      final newContent = base64.encode(utf8.encode(json.encode({
        "email": _emailCtrl.text,
        "password": _passCtrl.text,
        "limit": int.tryParse(_limitCtrl.text) ?? 10
      })));

      // 3. Envoyer la mise à jour (PUT)
      final putResponse = await http.put(
        Uri.parse(AppConfig.urlConfig), 
        headers: {
          "Authorization": "token ${AppConfig.githubToken}", 
          "Accept": "application/vnd.github.v3+json",
          "Content-Type": "application/json",
        },
        body: json.encode({
          "message": "Update credentials from App",
          "content": newContent,
          "sha": currentSha
        }),
      );

      if (putResponse.statusCode == 200 || putResponse.statusCode == 201) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Config mise à jour ! Le serveur va redémarrer."), backgroundColor: Colors.green));
      } else {
        throw Exception("Erreur GitHub: ${putResponse.statusCode}");
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur : $e"), backgroundColor: Colors.red));
    } finally {
      if(mounted) setState(() { _isUpdating = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Personnaliser")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("Identifiants Garmin", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, fontSize: 18)),
          const Text("Permet au serveur de récupérer vos données.", style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 15),
          TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: "Email Garmin", border: OutlineInputBorder(), prefixIcon: Icon(Icons.email))),
          const SizedBox(height: 10),
          TextField(
            controller: _passCtrl,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: "Mot de passe", 
              border: const OutlineInputBorder(), 
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              )
            ),
          ),
          const SizedBox(height: 10),
          TextField(controller: _limitCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Nombre de séances à récupérer", border: OutlineInputBorder(), prefixIcon: Icon(Icons.history), helperText: "Mettre 10 pour le quotidien. Mettre 2000 pour tout récupérer.")),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _isUpdating ? null : _updateGarminCredentials,
            icon: _isUpdating ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save),
            label: const Text("Mettre à jour sur le serveur"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, padding: const EdgeInsets.all(15)),
          ),

          const Divider(height: 40),

          const Text("Interface", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
          TextField(controller: _titreCtrl, decoration: const InputDecoration(labelText: "Nom de l'application"), onChanged: (v) => AppConfig.appTitle = v),
          const SizedBox(height: 20),
          
          const Text("Affichage Profil", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
          SwitchListTile(title: const Text("Afficher Statut"), value: AppConfig.showStatus, onChanged: (v) => setState(() => AppConfig.showStatus = v)),
          SwitchListTile(title: const Text("Afficher VO2 Max"), value: AppConfig.showVO2, onChanged: (v) => setState(() => AppConfig.showVO2 = v)),
          SwitchListTile(title: const Text("Afficher Charge"), value: AppConfig.showLoad, onChanged: (v) => setState(() => AppConfig.showLoad = v)),
          SwitchListTile(title: const Text("Afficher Préparation"), value: AppConfig.showReadiness, onChanged: (v) => setState(() => AppConfig.showReadiness = v)),
          
          const Divider(),
          
          const Text("Affichage Données", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
          SwitchListTile(title: const Text("Afficher Bloc Statistiques"), value: AppConfig.showStats, onChanged: (v) => setState(() => AppConfig.showStats = v)),
          SwitchListTile(
            title: const Text("Visualiser impact dernière séance"), 
            subtitle: const Text("Colore la progression récente en plus clair"),
            value: AppConfig.showLastSessionImpact, 
            onChanged: (v) => setState(() => AppConfig.showLastSessionImpact = v)
          ),
          
          const Divider(),

          const Text("Graphiques", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
          RadioListTile<bool>(title: const Text("Vitesse (km/h)"), value: true, groupValue: AppConfig.useSpeedKmH, onChanged: (v) => setState(() => AppConfig.useSpeedKmH = v!)),
          RadioListTile<bool>(title: const Text("Allure (min/km)"), value: false, groupValue: AppConfig.useSpeedKmH, onChanged: (v) => setState(() => AppConfig.useSpeedKmH = v!)),
          
          if (!AppConfig.useSpeedKmH) ...[
            const SizedBox(height: 10),
            Text("Plafond d'allure : ${AppConfig.maxPaceDisplay.toInt()}'/km", style: TextStyle(color: Colors.grey[700], fontSize: 12)),
            Slider(min: 5, max: 15, divisions: 10, label: "${AppConfig.maxPaceDisplay.toInt()}'00\"", value: AppConfig.maxPaceDisplay, onChanged: (v) => setState(() => AppConfig.maxPaceDisplay = v)),
          ],
          
          const SizedBox(height: 50),
        ],
      ),
    );
  }
}

// --- 3. PAGE RÉGLAGES SEUILS ---
class PageReglagesSeuils extends StatefulWidget { const PageReglagesSeuils({super.key}); @override State<PageReglagesSeuils> createState() => _PageReglagesSeuilsState(); }
class _PageReglagesSeuilsState extends State<PageReglagesSeuils> { 
  @override Widget build(BuildContext context) { 
    return Scaffold(
      appBar: AppBar(title: const Text("Réglages")), 
      body: ListView(
        padding: const EdgeInsets.all(16), 
        children: [
          const Text("Seuil de Repos", style: TextStyle(fontWeight: FontWeight.bold)), 
          const Text("En dessous de cette vitesse, le tour est considéré comme du repos.", style: TextStyle(color: Colors.grey, fontSize: 12)), 
          Row(children: [Expanded(child: Slider(value: AppConfig.seuilReposKmH, min: 4, max: 15, divisions: 22, label: "${AppConfig.seuilReposKmH} km/h", onChanged: (v) => setState(() => AppConfig.seuilReposKmH = v))), Text("${AppConfig.seuilReposKmH} km/h")]), 
          const Divider(), 
          const Text("Seuil Alignement Comparaison", style: TextStyle(fontWeight: FontWeight.bold)), 
          Row(children: [Expanded(child: Slider(value: AppConfig.seuilDebutVMA, min: 8, max: 22, divisions: 28, label: "${AppConfig.seuilDebutVMA} km/h", onChanged: (v) => setState(() => AppConfig.seuilDebutVMA = v))), Text("${AppConfig.seuilDebutVMA} km/h")])
        ]
      )
    ); 
  } 
}

// --- 4. PAGE GESTION TAGS ---
class PageGestionTags extends StatefulWidget { const PageGestionTags({super.key}); @override State<PageGestionTags> createState() => _PageGestionTagsState(); }
class _PageGestionTagsState extends State<PageGestionTags> { 
  final List<String> tagsDisponibles = ["VMA", "Fractionné", "Endurance", "Sortie Longue", "Spécifique", "Prépa 10km", "Prépa Semi", "Seuil", "Piste"]; 
  
  @override Widget build(BuildContext context) { 
    final liste = List<Seance>.from(mesDonnees)..sort((a,b) => b.date.compareTo(a.date)); 
    return Scaffold(
      appBar: AppBar(title: const Text("Modifier les Tags")), 
      body: ListView.builder(
        itemCount: liste.length, 
        itemBuilder: (context, index) { 
          final s = liste[index]; 
          return Card(child: ListTile(title: Text(s.titre, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text("Tags: ${s.tags.join(', ')}"), trailing: const Icon(Icons.edit, color: Colors.indigo), onTap: () => _afficherDialogueModification(s))); 
        }
      )
    ); 
  } 
  
  void _afficherDialogueModification(Seance seance) { 
    showDialog(context: context, builder: (context) { 
      return StatefulBuilder(builder: (context, setStateDialog) { 
        return AlertDialog(
          title: Text(seance.titre), 
          content: SizedBox(width: double.maxFinite, child: ListView(shrinkWrap: true, children: tagsDisponibles.map((tag) { final estCoche = seance.tags.contains(tag); return CheckboxListTile(title: Text(tag), value: estCoche, activeColor: Colors.indigo, onChanged: (val) { setStateDialog(() { if (val == true) { seance.tags.add(tag); } else { seance.tags.remove(tag); } }); setState(() {}); }); }).toList())), 
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Fermer"))]
        ); 
      }); 
    }); 
  } 
}