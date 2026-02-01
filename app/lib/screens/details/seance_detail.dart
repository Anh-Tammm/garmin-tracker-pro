import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../models/models.dart';
import '../../config/app_config.dart';
import '../../data/globals.dart';

class PageDetailSeance extends StatefulWidget {
  final Seance seance;
  const PageDetailSeance({super.key, required this.seance});
  @override State<PageDetailSeance> createState() => _PageDetailSeanceState();
}

class _PageDetailSeanceState extends State<PageDetailSeance> {
  final PageController _pageController = PageController();
  int _currentPage = 0; // 0 = Analyse, 1 = Tableau

  bool masquerRepos = false;
  Set<int> selectedIndices = {};
  double? userVma;
  
  // Variables pour l'annotation
  String? selectedGrade;
  final TextEditingController _paceCtrl = TextEditingController();
  final TextEditingController _commentCtrl = TextEditingController();

  @override void initState() { super.initState(); _loadVma(); _loadAnnotation(); }

  Future<void> _loadVma() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() { userVma = prefs.getDouble('user_vma'); });
  }

  void _loadAnnotation() {
    if (userAnnotations.containsKey(widget.seance.id)) {
      var data = userAnnotations[widget.seance.id];
      setState(() {
        selectedGrade = data['grade'];
        _paceCtrl.text = data['pace'] ?? "";
        _commentCtrl.text = data['comment'] ?? "";
      });
    }
  }

  Future<void> _saveAnnotation() async {
    Map<String, dynamic> data = {'grade': selectedGrade, 'pace': _paceCtrl.text, 'comment': _commentCtrl.text};
    if (data['grade'] == null && data['pace'] == "" && data['comment'] == "") {
      userAnnotations.remove(widget.seance.id);
    } else {
      userAnnotations[widget.seance.id] = data;
    }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_annotations', json.encode(userAnnotations));
  }

  @override
  void dispose() {
    _saveAnnotation();
    super.dispose();
  }

  // Fonction locale pour formater les axes du graphique
  String _formatLabel(double value) { 
    double vAbs = value.abs(); 
    if (AppConfig.useSpeedKmH) return vAbs.toStringAsFixed(1); 
    int m = vAbs.toInt(); 
    int s = ((vAbs - m) * 60).round(); 
    return "$m'${s.toString().padLeft(2, '0')}\""; 
  }

  @override
  Widget build(BuildContext context) {
    // 1. Calcul des données si pas de tours
    if (widget.seance.listeTours.isEmpty) {
      Color couleurGraph = widget.seance.couleurType;
      return Scaffold(
        appBar: AppBar(title: Text(widget.seance.titre), backgroundColor: couleurGraph, foregroundColor: Colors.white),
        body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.warning_amber_rounded, size: 50, color: Colors.grey), const SizedBox(height: 20), Text("Pas de détail des tours disponible", style: TextStyle(color: Colors.grey.shade600)), const SizedBox(height: 10), Text("${widget.seance.distanceKm} km en ${widget.seance.dureeFormatee}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))]))
      );
    }

    List<Intervalle> toursAffiches = masquerRepos ? widget.seance.listeTours.where((t) => !t.estRepos).toList() : widget.seance.listeTours;
    Color couleurGraph = widget.seance.couleurType;

    // 2. Préparation du Graphique
    List<FlSpot> points = [];
    double distanceCumulee = 0;
    double maxY = -1000; double minY = 1000;
    if (toursAffiches.isNotEmpty) {
      points.add(FlSpot(0, toursAffiches[0].valeurGraphique));
      for (var tour in toursAffiches) {
        double distKm = tour.distanceMetres / 1000.0;
        double val = tour.valeurGraphique;
        if(val > maxY) maxY = val; if(val < minY) minY = val;
        points.add(FlSpot(distanceCumulee, val));
        distanceCumulee += distKm;
        points.add(FlSpot(distanceCumulee, val));
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.seance.titre, style: const TextStyle(fontSize: 18)),
            Text(DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(widget.seance.date), style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        backgroundColor: couleurGraph, 
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: _currentPage == 0 ? Colors.white : Colors.white38)),
                const SizedBox(width: 8),
                Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: _currentPage == 1 ? Colors.white : Colors.white38)),
              ],
            ),
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (i) => setState(() => _currentPage = i),
        children: [
          
          // Page 1 analyse
          SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: Colors.grey.shade50,
                  child: Column(children: [
                    Row(children: [
                      const Text("Note : ", style: TextStyle(fontWeight: FontWeight.bold)), const SizedBox(width: 10),
                      Expanded(child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: ["A", "B", "C", "D", "E"].map((grade) {
                        bool isSelected = selectedGrade == grade;
                        Color c = Colors.grey; if (grade == 'A') c = Colors.green; if (grade == 'B') c = Colors.lightGreen; if (grade == 'C') c = Colors.amber; if (grade == 'D') c = Colors.deepOrange; if (grade == 'E') c = Colors.red;
                        return GestureDetector(onTap: () => setState(() => selectedGrade = isSelected ? null : grade), child: CircleAvatar(radius: 16, backgroundColor: isSelected ? c : Colors.grey.shade200, child: Text(grade, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontWeight: FontWeight.bold))));
                      }).toList()))
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [Expanded(child: TextField(controller: _paceCtrl, decoration: const InputDecoration(labelText: "Allure clé", isDense: true, border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8))))]),
                    const SizedBox(height: 8),
                    TextField(controller: _commentCtrl, decoration: const InputDecoration(labelText: "Commentaire", isDense: true, border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)), maxLines: 2, minLines: 1),
                  ]),
                ),
                const Divider(height: 1),
                
                // Stats Rapides
                Padding(padding: const EdgeInsets.all(16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(widget.seance.dureeFormatee, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), Text("${widget.seance.distanceKm} km", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), Text("${widget.seance.bpmMoyenSeance} bpm", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))])),
                
                // Graphique
                if (toursAffiches.isNotEmpty) SizedBox(height: 250, child: Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 0), child: InteractiveViewer(child: LineChart(LineChartData(minX: 0, maxX: distanceCumulee, maxY: maxY + (maxY - minY) * 0.1 + 0.5, minY: minY - (maxY - minY) * 0.1 - 0.5, lineTouchData: LineTouchData(touchSpotThreshold: 50, handleBuiltInTouches: true, touchTooltipData: LineTouchTooltipData(fitInsideHorizontally: true, fitInsideVertically: true, getTooltipItems: (touchedSpots) => touchedSpots.map((spot) => LineTooltipItem(_formatLabel(spot.y), const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))).toList())), titlesData: FlTitlesData(show: true, topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 45, getTitlesWidget: (v, m) => Text(_formatLabel(v), style: const TextStyle(fontSize: 10)))), bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 1, getTitlesWidget: (v, m) => Text("${v.toInt()}k", style: const TextStyle(fontSize: 10)))), rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false))), gridData: FlGridData(show: false), borderData: FlBorderData(show: false), lineBarsData: [LineChartBarData(spots: points, isCurved: false, color: couleurGraph, barWidth: 2, dotData: FlDotData(show: false), belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [couleurGraph.withOpacity(0.4), couleurGraph.withOpacity(0.0)], begin: Alignment.topCenter, end: Alignment.bottomCenter)))]))))),
                
                const SizedBox(height: 30),
                // Les deux points discrets
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey.shade600)),
                    const SizedBox(width: 8),
                    Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey.shade300)),
                ]),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // Page 2 tableau
          Column(
            children: [
              SwitchListTile(activeColor: couleurGraph, title: Text("Masquer les repos (< ${AppConfig.seuilReposKmH} km/h)"), value: masquerRepos, onChanged: (v) => setState(() => masquerRepos = v)),
              const Divider(height: 1),
              
              // Tableau de données
              Expanded(child: SingleChildScrollView(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(columnSpacing: 15, headingRowColor: MaterialStateProperty.all(Colors.grey.shade100), columns: const [ DataColumn(label: Text("#")), DataColumn(label: Text("Dist")), DataColumn(label: Text("Tps")), DataColumn(label: Text("Allure")), DataColumn(label: Text("Vit")), DataColumn(label: Text("FC")) ], rows: toursAffiches.asMap().entries.map((entry) { int idx = entry.key; Intervalle t = entry.value; return DataRow(selected: selectedIndices.contains(idx), onSelectChanged: (val) { setState(() { if(val == true) selectedIndices.add(idx); else selectedIndices.remove(idx); }); }, color: MaterialStateProperty.resolveWith((states) { if(selectedIndices.contains(idx)) return couleurGraph.withOpacity(0.2); if(!t.estRepos) return couleurGraph.withOpacity(0.05); return null; }), cells: [ DataCell(Text("${t.numero}")), DataCell(Text("${t.distanceMetres}")), DataCell(Text(t.tempsFormate, style: TextStyle(fontWeight: !t.estRepos?FontWeight.bold:FontWeight.normal))), DataCell(Text(t.allureMinKm)), DataCell(Text(t.vitesseKmH)), DataCell(Text("${t.bpmMoyen}")) ]); }).toList())))),
              
              // Barre de résumé en bas
              if(selectedIndices.isNotEmpty) Container(padding: const EdgeInsets.all(16), color: couleurGraph.withOpacity(0.1), child: Builder(builder: (context) {
                double sumDist = 0; double sumTime = 0; double sumHR = 0; int countHR = 0;
                for(int i in selectedIndices) { if(i < toursAffiches.length) { sumDist += toursAffiches[i].distanceMetres; sumTime += toursAffiches[i].tempsSecondes; if(toursAffiches[i].bpmMoyen > 0) { sumHR += toursAffiches[i].bpmMoyen; countHR++; } } }
                double avgSpeed = sumTime > 0 ? (sumDist/1000)/(sumTime/3600) : 0;
                int avgPaceSec = sumDist > 0 ? ((sumTime/60) / (sumDist/1000) * 60).round() : 0;
                int m = avgPaceSec ~/ 60; int s = avgPaceSec % 60;
                int avgHR = countHR > 0 ? (sumHR / countHR).round() : 0;
                String vmaInfo = ""; if (userVma != null && userVma! > 0) { double p = (avgSpeed / userVma!) * 100; vmaInfo = " (${p.toStringAsFixed(1)}%)"; }
                return Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [Text("Moy. Sélection :", style: TextStyle(fontWeight: FontWeight.bold, color: couleurGraph)), Text("${avgSpeed.toStringAsFixed(1)} km/h$vmaInfo", style: const TextStyle(fontWeight: FontWeight.bold))]), const SizedBox(height: 5), Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [Text("$m'${s.toString().padLeft(2,'0')}\" /km"), Text("$avgHR bpm")])]);
              }))
            ],
          ),
        ],
      ),
    );
  }
}
