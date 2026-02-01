import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Pour les mini graphiques
import 'package:intl/intl.dart';        // Pour les dates
import 'dart:convert';                  // Pour json
import 'package:shared_preferences/shared_preferences.dart'; // Pour EventsListWidget

import '../models/models.dart';
import '../config/app_config.dart';
import '../data/globals.dart'; // Pour userAnnotations et mesDonnees

import '../screens/details/seance_detail.dart'; 

// Barre de préparation
class BarrePreparation extends StatelessWidget {
  final double percentage;
  
  const BarrePreparation({super.key, required this.percentage});
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Stack(
        children: [
          Container(
            height: 12, 
            width: constraints.maxWidth, 
            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10))
          ),
          ClipRect(
            child: Align(
              alignment: Alignment.centerLeft, 
              widthFactor: percentage.clamp(0.0, 1.0),
              child: Container(
                height: 12, 
                width: constraints.maxWidth, 
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10), 
                  gradient: const LinearGradient(colors: [Colors.red, Colors.orange, Colors.yellow, Colors.green])
                )
              )
            )
          ),
        ],
      );
    });
  }
}

// Les petits stats en haut
class MiniStatCard extends StatelessWidget {
  final String titre, valeur, sousValeur;
  final Color color;
  final bool isClickable;
  
  const MiniStatCard(this.titre, this.valeur, this.sousValeur, this.color, {super.key, this.isClickable = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: isClickable ? Border.all(color: color.withOpacity(0.3)) : null
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(valeur, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          ),
          Text(sousValeur, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color.withOpacity(0.7))),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(titre, style: TextStyle(color: color.withOpacity(0.8), fontSize: 11)),
              if(isClickable) Padding(padding: const EdgeInsets.only(left: 4), child: Icon(Icons.bar_chart, size: 12, color: color))
            ]
          )
        ]
      )
    );
  }
}

// L'avancement de l'objectif
class ProgressBarObjectif extends StatelessWidget {
  final String titre;
  final double current;
  final double target;
  final Color color;
  final int precisionPercent;
  final double lastSessionImpact;

  const ProgressBarObjectif({
    super.key,
    required this.titre, 
    required this.current, 
    required this.target, 
    required this.color, 
    this.precisionPercent = 0,
    this.lastSessionImpact = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    double percent = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    
    double previousKm = current - lastSessionImpact;
    if (previousKm < 0) previousKm = 0;
    double previousPercent = target > 0 ? (previousKm / target).clamp(0.0, 1.0) : 0.0;
    
    bool showImpact = AppConfig.showLastSessionImpact && lastSessionImpact > 0;

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(titre, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              Text(
                "${(percent * 100).toStringAsFixed(precisionPercent)}% (${current.toStringAsFixed(1)} / ${target.toStringAsFixed(0)} km)", 
                style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            height: 10,
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(5)),
            child: Stack(
              children: [
                FractionallySizedBox(
                  widthFactor: percent,
                  child: Container(
                    decoration: BoxDecoration(
                      color: showImpact ? color.withOpacity(0.4) : color, 
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
                if (showImpact && previousPercent > 0)
                  FractionallySizedBox(
                    widthFactor: previousPercent,
                    child: Container(
                      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(5)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Ligne statistique
class RowStat extends StatelessWidget { 
  final String label, value; 
  const RowStat(this.label, this.value, {super.key}); 
  @override Widget build(BuildContext context) { 
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0), 
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, 
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700)), 
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
        ]
      )
    ); 
  } 
}

// Mini graphique dans les séances
class MiniGraphiqueSeance extends StatelessWidget { 
  final List<Intervalle> tours; 
  final Color couleur; 
  const MiniGraphiqueSeance({super.key, required this.tours, required this.couleur}); 
  
  @override Widget build(BuildContext context) { 
    if (tours.isEmpty) return const SizedBox.shrink(); 
    List<FlSpot> points = []; 
    double distanceCumulee = 0; 
    points.add(FlSpot(0, tours[0].valeurGraphique)); 
    for (var tour in tours) { 
      double distKm = tour.distanceMetres / 1000.0; 
      double val = tour.valeurGraphique; 
      points.add(FlSpot(distanceCumulee, val)); 
      distanceCumulee += distKm; 
      points.add(FlSpot(distanceCumulee, val)); 
    } 
    return LineChart(LineChartData(
      minX: 0, maxX: distanceCumulee, 
      titlesData: FlTitlesData(show: false), 
      gridData: FlGridData(show: false), 
      borderData: FlBorderData(show: false), 
      lineTouchData: LineTouchData(enabled: false), 
      lineBarsData: [
        LineChartBarData(
          spots: points, 
          isCurved: false, 
          color: couleur.withOpacity(0.5), 
          barWidth: 1.5, 
          dotData: FlDotData(show: false), 
          belowBarData: BarAreaData(show: true, color: couleur.withOpacity(0.1))
        )
      ]
    )); 
  } 
}

// Carte séance
class SeanceCard extends StatelessWidget {
  final Seance seance;
  final bool isSelected;
  final Function(bool?)? onSelectionChanged;
  final bool selectionMode;
  final bool isLibrary;

  const SeanceCard({
    super.key,
    required this.seance, 
    this.isSelected = false, 
    this.onSelectionChanged, 
    this.selectionMode = false,
    this.isLibrary = false
  });

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic>? noteData = userAnnotations[seance.id];
    String? grade = noteData?['grade'];
    String? keyPace = noteData?['pace'];
    String? comment = noteData?['comment'];

    Color gradeColor = Colors.grey;
    if (grade == 'A') gradeColor = Colors.green;
    if (grade == 'B') gradeColor = Colors.lightGreen;
    if (grade == 'C') gradeColor = Colors.amber;
    if (grade == 'D') gradeColor = Colors.deepOrange;
    if (grade == 'E') gradeColor = Colors.red;

    return Card(
      elevation: 0, 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)), 
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: isLibrary ? 4 : 6), 
      color: isSelected ? Colors.grey.shade100 : Colors.white, 
      child: InkWell(
        onTap: selectionMode 
            ? () => onSelectionChanged!(!isSelected) 
            : () => Navigator.push(context, MaterialPageRoute(builder: (c) => PageDetailSeance(seance: seance))).then((v) { (context as Element).markNeedsBuild(); }), 
        child: Container(
          decoration: BoxDecoration(border: Border(left: BorderSide(color: seance.couleurType, width: 6))), 
          padding: EdgeInsets.all(isLibrary ? 8 : 12), 
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, 
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  if (selectionMode) Checkbox(value: isSelected, onChanged: onSelectionChanged),
                  
                  if (isLibrary) 
                    Padding(
                      padding: const EdgeInsets.only(right: 10, top: 0),
                      child: CircleAvatar(
                        radius: 16, 
                        backgroundColor: grade != null ? gradeColor.withOpacity(0.2) : Colors.grey.shade100,
                        child: grade != null 
                          ? Text(grade, style: TextStyle(fontWeight: FontWeight.bold, color: gradeColor, fontSize: 14))
                          : Icon(Icons.directions_run, color: seance.couleurType, size: 16),
                      ),
                    ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, 
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(seance.titre, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isLibrary ? 14 : 16), maxLines: 1, overflow: TextOverflow.ellipsis)),
                            if (!isLibrary && grade != null)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Container(
                                  width: 24, height: 24,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(color: gradeColor.withOpacity(0.2), shape: BoxShape.circle),
                                  child: Text(grade, style: TextStyle(fontWeight: FontWeight.bold, color: gradeColor, fontSize: 14)),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                "${DateFormat('dd/MM').format(seance.date)} • ${seance.distanceKm} km${isLibrary ? ' • ${seance.allureMoyenneSeance}/km' : ''} • ${seance.dureeFormatee}", 
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (keyPace != null && keyPace.isNotEmpty) ...[
                              const SizedBox(width: 6), 
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.grey.shade300)),
                                child: Text(keyPace, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87)),
                              ),
                            ]
                          ],
                        ),
                      ]
                    ),
                  ),
                ]
              ),
              
              if (comment != null && comment.isNotEmpty) ...[
                const SizedBox(height: 4), 
                Padding(
                  padding: EdgeInsets.only(left: isLibrary ? 42 : 0), 
                  child: Text(
                    comment,
                    style: TextStyle(fontStyle: FontStyle.italic, fontSize: 11, color: Colors.grey.shade700), 
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              ],

              if (!isLibrary && seance.listeTours.isNotEmpty) ...[
                 const SizedBox(height: 8),
                 SizedBox(height: 30, width: double.infinity, child: MiniGraphiqueSeance(tours: seance.listeTours, couleur: seance.couleurType))
              ]
            ]
          )
        )
      )
    );
  }
}

// Evènements
class EventsListWidget extends StatefulWidget { 
  const EventsListWidget({super.key}); 
  @override State<EventsListWidget> createState() => _EventsListWidgetState(); 
}

class _EventsListWidgetState extends State<EventsListWidget> {
  List<RaceEvent> events = [];
  @override void initState() { super.initState(); _loadEvents(); }
  
  Future<void> _loadEvents() async { 
    SharedPreferences prefs = await SharedPreferences.getInstance(); 
    List<String> list = prefs.getStringList('saved_events') ?? []; 
    setState(() { 
      events = list.map((e) => RaceEvent.fromJson(json.decode(e))).toList(); 
      events.sort((a, b) => a.date.compareTo(b.date)); 
    }); 
  }
  
  Future<void> _saveEvents() async { 
    SharedPreferences prefs = await SharedPreferences.getInstance(); 
    events.sort((a, b) => a.date.compareTo(b.date)); 
    List<String> list = events.map((e) => json.encode(e.toJson())).toList(); 
    await prefs.setStringList('saved_events', list); 
    setState(() {}); 
  }
  
  void _openEventDialog({RaceEvent? eventToEdit}) {
    final _nomCtrl = TextEditingController(text: eventToEdit?.nom ?? "");
    DateTime _selectedDate = eventToEdit?.date ?? DateTime.now().add(const Duration(days: 30));
    String _type = eventToEdit?.type ?? "10km";
    Color _color = eventToEdit != null ? Color(eventToEdit.colorValue) : Colors.blue;
    
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setStateDialog) { 
      return AlertDialog(
        title: Text(eventToEdit == null ? "Ajouter" : "Modifier"), 
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: _nomCtrl, decoration: const InputDecoration(labelText: "Nom")), 
          const SizedBox(height: 10), 
          ListTile(title: Text("Date : ${DateFormat('dd/MM/yyyy').format(_selectedDate)}"), trailing: const Icon(Icons.calendar_today), onTap: () async { DateTime? d = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime.now(), lastDate: DateTime(2030)); if (d != null) setStateDialog(() => _selectedDate = d); }), 
          DropdownButton<String>(value: _type, isExpanded: true, items: ["5km", "10km", "Semi", "Marathon", "Custom"].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(), onChanged: (v) => setStateDialog(() => _type = v!)), 
          const SizedBox(height: 10), 
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple].map((c) => GestureDetector(onTap: () => setStateDialog(() => _color = c), child: CircleAvatar(backgroundColor: c, radius: 15, child: _color == c ? const Icon(Icons.check, color: Colors.white, size: 15) : null))).toList())
        ])), 
        actions: [
          if(eventToEdit != null) TextButton(onPressed: () { events.removeWhere((e) => e.id == eventToEdit.id); _saveEvents(); Navigator.pop(ctx); }, child: const Text("Supprimer", style: TextStyle(color: Colors.red))), 
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")), 
          ElevatedButton(onPressed: () { if (_nomCtrl.text.isNotEmpty) { if (eventToEdit != null) { eventToEdit.nom = _nomCtrl.text; eventToEdit.date = _selectedDate; eventToEdit.type = _type; eventToEdit.colorValue = _color.value; } else { events.add(RaceEvent(id: DateTime.now().toString(), nom: _nomCtrl.text, date: _selectedDate, type: _type, colorValue: _color.value)); } _saveEvents(); Navigator.pop(ctx); } }, child: const Text("Enregistrer"))
        ]
      ); 
    }));
  }
  
  @override 
  Widget build(BuildContext context) { 
    return Column(children: [
      if (events.isEmpty) Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: OutlinedButton.icon(onPressed: () => _openEventDialog(), icon: const Icon(Icons.add, size: 18), label: const Text("Ajouter un évènement"))), 
      ...events.map((e) => GestureDetector(onTap: () => _openEventDialog(eventToEdit: e), child: Card(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), child: Padding(padding: const EdgeInsets.all(12.0), child: Row(children: [CircleAvatar(backgroundColor: Color(e.colorValue), radius: 6), const SizedBox(width: 15), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(e.nom, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Text("${e.type} • ${DateFormat('dd/MM/yyyy').format(e.date)}", style: TextStyle(color: Colors.grey.shade600, fontSize: 13))])), Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: Text("J-${e.joursRestants}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo))) ]))))).toList(), 
      if (events.isNotEmpty) Align(alignment: Alignment.centerRight, child: Padding(padding: const EdgeInsets.only(right: 16), child: TextButton.icon(onPressed: () => _openEventDialog(), icon: const Icon(Icons.add, size: 16), label: const Text("Ajouter"))))
    ]); 
  }
}
