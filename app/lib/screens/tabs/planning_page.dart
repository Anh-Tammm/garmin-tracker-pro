import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

// Import de vos modèles (TrainingPlan, PlanSession)
import '../../models/models.dart';

class PagePlanning extends StatefulWidget {
  const PagePlanning({super.key});
  @override State<PagePlanning> createState() => _PagePlanningState();
}

class _PagePlanningState extends State<PagePlanning> {
  TrainingPlan? currentPlan;

  @override void initState() { super.initState(); _loadPlan(); }

  Future<void> _loadPlan() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? jsonStr = prefs.getString('current_plan');
    if (jsonStr != null) { setState(() => currentPlan = TrainingPlan.fromJson(json.decode(jsonStr))); }
  }

  Future<void> _savePlan() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (currentPlan != null) { await prefs.setString('current_plan', json.encode(currentPlan!.toJson())); } else { await prefs.remove('current_plan'); }
    setState(() {});
  }

  String _getDayName(int weekday) { const days = ["Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche"]; return days[weekday - 1]; }

  void _confirmDelete() {
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text("Supprimer le plan ?"), content: const Text("Toutes les séances prévues seront effacées."), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")), TextButton(onPressed: () { setState(() { currentPlan = null; _savePlan(); }); Navigator.pop(ctx); }, child: const Text("Supprimer", style: TextStyle(color: Colors.red)))]));
  }

  void _createPlan() {
    final _nameCtrl = TextEditingController();
    final _weeksCtrl = TextEditingController(text: "8");
    DateTime _raceDate = DateTime.now().add(const Duration(days: 60));
    Map<int, bool> _selectedDays = {0: false, 1: true, 2: false, 3: true, 4: false, 5: false, 6: true};
    Map<int, String> _defaultTypes = {0: "Footing", 1: "VMA", 2: "Footing", 3: "Seuil", 4: "Repos", 5: "Repos", 6: "Sortie Longue"};

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (context, setStateDialog) {
      return AlertDialog(title: const Text("Créer un plan"), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: "Nom de l'objectif")),
              ListTile(title: Text("Date Course : ${DateFormat('dd/MM/yyyy').format(_raceDate)}"), trailing: const Icon(Icons.calendar_today), onTap: () async { DateTime? d = await showDatePicker(context: context, initialDate: _raceDate, firstDate: DateTime.now(), lastDate: DateTime(2030)); if(d!=null) setStateDialog(()=>_raceDate=d); }),
              TextField(controller: _weeksCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Durée (semaines)")),
              const SizedBox(height: 10),
              const Text("Jours d'entraînement :", style: TextStyle(fontWeight: FontWeight.bold)),
              ...List.generate(7, (index) {
                int dayId = index; 
                String dayName = ["Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche"][dayId];
                return Column(children: [
                    CheckboxListTile(title: Text(dayName), value: _selectedDays[dayId], onChanged: (v) => setStateDialog(() => _selectedDays[dayId] = v!)),
                    if (_selectedDays[dayId] == true) Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: DropdownButton<String>(isExpanded: true, value: _defaultTypes[dayId], items: ["Footing", "VMA", "Seuil", "Sortie Longue", "Repos", "Côtes", "Spécifique"].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(), onChanged: (v) => setStateDialog(() => _defaultTypes[dayId] = v!)))
                  ]);
              })
            ])), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")), ElevatedButton(onPressed: () {
            if (_nameCtrl.text.isNotEmpty && _weeksCtrl.text.isNotEmpty) {
              int weeks = int.parse(_weeksCtrl.text);
              List<PlanSession> generatedSessions = [];
              DateTime startDate = _raceDate.subtract(Duration(days: weeks * 7));
              while(startDate.weekday != 1) startDate = startDate.subtract(const Duration(days: 1));
              for (int w = 0; w < weeks; w++) {
                for (int d = 0; d < 7; d++) {
                  if (_selectedDays[d] == true) {
                    DateTime sessionDate = startDate.add(Duration(days: (w * 7) + d));
                    if (sessionDate.isBefore(_raceDate) || sessionDate.isAtSameMomentAs(_raceDate)) {
                      generatedSessions.add(PlanSession(id: "${DateTime.now().millisecondsSinceEpoch}$w$d", date: sessionDate, type: _defaultTypes[d]!, title: _defaultTypes[d]!));
                    }
                  }
                }
              }
              generatedSessions.add(PlanSession(id: "race", date: _raceDate, type: "Course", title: _nameCtrl.text));
              generatedSessions.sort((a,b) => a.date.compareTo(b.date));
              currentPlan = TrainingPlan(raceName: _nameCtrl.text, raceDate: _raceDate, totalWeeks: weeks, sessions: generatedSessions);
              _savePlan();
              Navigator.pop(context);
            }
          }, child: const Text("Générer"))]);
    }));
  }

  void _editSession(PlanSession s) {
    final _titleCtrl = TextEditingController(text: s.title);
    final _descCtrl = TextEditingController(text: s.description ?? "");
    DateTime _date = s.date;
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setStateDialog) {
      return AlertDialog(title: const Text("Modifier séance"), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: "Titre")), TextField(controller: _descCtrl, decoration: const InputDecoration(labelText: "Description (ex: 2x10x200m)")), ListTile(title: Text("Date : ${DateFormat('dd/MM').format(_date)}"), trailing: const Icon(Icons.edit_calendar), onTap: () async { DateTime? d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime(2030)); if(d!=null) setStateDialog(()=>_date=d); })]), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")), ElevatedButton(onPressed: () { setState(() { s.title = _titleCtrl.text; s.description = _descCtrl.text; s.date = _date; }); _savePlan(); Navigator.pop(ctx); }, child: const Text("OK"))]);
    }));
  }

  @override
  Widget build(BuildContext context) {
    if (currentPlan == null) return Center(child: ElevatedButton.icon(onPressed: _createPlan, icon: const Icon(Icons.add), label: const Text("Créer un plan d'entraînement")));
    Map<String, List<PlanSession>> grouped = {};
    if (currentPlan!.sessions.isNotEmpty) {
      DateTime planStart = currentPlan!.sessions.first.date;
      DateTime planStartMonday = planStart.subtract(Duration(days: planStart.weekday - 1));
      for (var s in currentPlan!.sessions) {
        int diffDays = s.date.difference(planStartMonday).inDays;
        int weekNum = (diffDays / 7).floor() + 1;
        String key = "Semaine $weekNum";
        if (!grouped.containsKey(key)) grouped[key] = [];
        grouped[key]!.add(s);
      }
    }
    return Scaffold(
      body: CustomScrollView(slivers: [
          SliverAppBar(title: Text(currentPlan!.raceName), floating: false, pinned: false, snap: false, actions: [IconButton(icon: const Icon(Icons.delete), onPressed: _confirmDelete)]),
          SliverList(delegate: SliverChildBuilderDelegate((context, index) {
                String key = grouped.keys.elementAt(index);
                List<PlanSession> sessions = grouped[key]!;
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16), color: Colors.grey.shade100, child: Text(key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo))),
                    ...sessions.map((s) => Card(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), color: s.date.isBefore(DateTime.now().subtract(const Duration(days: 1))) ? Colors.white.withOpacity(0.6) : Colors.white, child: ListTile(leading: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(DateFormat('dd').format(s.date), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Text(DateFormat('MMM').format(s.date), style: const TextStyle(fontSize: 10))]), title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_getDayName(s.date.weekday).toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)), Text(s.title, style: TextStyle(fontWeight: FontWeight.bold, decoration: s.isCompleted ? TextDecoration.lineThrough : null))]), subtitle: Text(s.description ?? s.type), trailing: Checkbox(value: s.isCompleted, onChanged: (v) => setState(() { s.isCompleted = v!; _savePlan(); })), onLongPress: () => _editSession(s))))
                  ]);
              }, childCount: grouped.keys.length)),
          const SliverToBoxAdapter(child: SizedBox(height: 80))
        ]),
    );
  }
}