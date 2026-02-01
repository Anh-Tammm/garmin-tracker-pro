import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/models.dart';
import '../../data/globals.dart';
import '../../config/app_config.dart';
import '../../widgets/custom_widgets.dart';

// --- 1. PAGE PRINCIPALE BIBLIOTHÈQUE ---
class PageLibrary extends StatefulWidget {
  const PageLibrary({super.key});
  @override State<PageLibrary> createState() => _PageLibraryState();
}

class _PageLibraryState extends State<PageLibrary> with AutomaticKeepAliveClientMixin {
  String? selectedTag;
  List<String> idsSelectionnes = [];
  double? userVma;
  bool modeSelection = false;

  @override bool get wantKeepAlive => true;
  @override void initState() { super.initState(); _loadVma(); }
  Future<void> _loadVma() async { SharedPreferences prefs = await SharedPreferences.getInstance(); setState(() { userVma = prefs.getDouble('user_vma'); }); }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    List<Seance> listeFiltrable = List.from(mesDonnees);
    listeFiltrable.sort((a,b) => b.date.compareTo(a.date));
    List<String> tagsDisponibles = mesDonnees.expand((s) => s.tags).toSet().toList()..sort();
    if (selectedTag != null) { listeFiltrable = listeFiltrable.where((s) => s.tags.contains(selectedTag)).toList(); }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Bibliothèque", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        centerTitle: false,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        toolbarHeight: 45,
        actions: [
          TextButton.icon(
            onPressed: () { setState(() { modeSelection = !modeSelection; if (!modeSelection) idsSelectionnes.clear(); }); },
            icon: Icon(modeSelection ? Icons.check : Icons.compare_arrows, color: Colors.indigo, size: 18),
            label: Text(modeSelection ? "OK" : "Comparer", style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 12)),
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(children: [
          Container(height: 40, margin: const EdgeInsets.symmetric(vertical: 4), child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), children: [Padding(padding: const EdgeInsets.only(right: 8), child: ActionChip(label: const Text("Tout", style: TextStyle(fontSize: 11)), visualDensity: VisualDensity.compact, backgroundColor: selectedTag == null ? Colors.indigo : Colors.grey.shade200, labelStyle: TextStyle(color: selectedTag == null ? Colors.white : Colors.black, fontSize: 11), onPressed: () => setState(() => selectedTag = null))), ...tagsDisponibles.map((tag) => Padding(padding: const EdgeInsets.only(right: 8), child: ActionChip(label: Text(tag, style: const TextStyle(fontSize: 11)), visualDensity: VisualDensity.compact, backgroundColor: selectedTag == tag ? Colors.indigo : Colors.grey.shade200, labelStyle: TextStyle(color: selectedTag == tag ? Colors.white : Colors.black, fontSize: 11), onPressed: () => setState(() => selectedTag = tag))))])),
          const Divider(height: 1),
          
          Expanded(child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: listeFiltrable.length, 
            itemBuilder: (context, index) { 
              final s = listeFiltrable[index]; 
              final isSelected = idsSelectionnes.contains(s.id); 
              return SeanceCard( // Attention: SeanceCard (sans le _)
                seance: s,
                isSelected: isSelected,
                isLibrary: true, 
                selectionMode: modeSelection, 
                onSelectionChanged: (val) { setState(() { if (isSelected) idsSelectionnes.remove(s.id); else idsSelectionnes.add(s.id); }); },
              ); 
            }
          )),
        ]),
      
      bottomSheet: idsSelectionnes.isNotEmpty ? Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5, offset: const Offset(0,-2))]), child: Column(mainAxisSize: MainAxisSize.min, children: [
            Builder(builder: (context) {
              var selectedSeances = mesDonnees.where((s) => idsSelectionnes.contains(s.id)).toList();
              double totalDist = 0; double totalHours = 0; for(var s in selectedSeances) { totalDist += s.distanceKm; totalHours += s.dureeTotaleMinutes / 60.0; }
              double avgSpeed = totalHours > 0 ? totalDist / totalHours : 0;
              String vmaText = ""; if (userVma != null && userVma! > 0) { double percent = (avgSpeed / userVma!) * 100; vmaText = " • ${percent.toStringAsFixed(1)}% VMA"; }
              return Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("${selectedSeances.length} sél.", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), Text("Moy: ${avgSpeed.toStringAsFixed(1)} km/h$vmaText", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, fontSize: 12))]));
            }),
            Row(children: [IconButton(icon: const Icon(Icons.close, color: Colors.red, size: 20), padding: EdgeInsets.zero, constraints: const BoxConstraints(), onPressed: () => setState(() { idsSelectionnes.clear(); modeSelection = false; })), Expanded(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [const SizedBox(width: 10), ElevatedButton.icon(icon: const Icon(Icons.show_chart, size: 14), label: const Text("Graph", style: TextStyle(fontSize: 11)), style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 8), minimumSize: const Size(0, 32)), onPressed: () { final selected = mesDonnees.where((s) => idsSelectionnes.contains(s.id)).toList(); Navigator.push(context, MaterialPageRoute(builder: (c) => PageComparaisonGraphique(seancesAComparer: selected))); }), const SizedBox(width: 8), ElevatedButton.icon(icon: const Icon(Icons.table_chart, size: 14), label: const Text("Tours", style: TextStyle(fontSize: 11)), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.indigo, side: const BorderSide(color: Colors.indigo), padding: const EdgeInsets.symmetric(horizontal: 8), minimumSize: const Size(0, 32)), onPressed: () { final selected = mesDonnees.where((s) => idsSelectionnes.contains(s.id)).toList(); Navigator.push(context, MaterialPageRoute(builder: (c) => PageComparaisonTableau(seancesAComparer: selected))); })]))) ])])) : null,
    );
  }
}

// --- 2. PAGE COMPARAISON TABLEAU ---
class PageComparaisonTableau extends StatefulWidget {
  final List<Seance> seancesAComparer;
  const PageComparaisonTableau({super.key, required this.seancesAComparer});
  @override State<PageComparaisonTableau> createState() => _PageComparaisonTableauState();
}
class _PageComparaisonTableauState extends State<PageComparaisonTableau> {
  bool onlyFastLaps = false;

  @override
  Widget build(BuildContext context) {
    List<Seance> liste = List.from(widget.seancesAComparer);
    liste.sort((a,b) => b.date.compareTo(a.date));

    int maxTours = 0;
    for(var s in liste) { if(s.listeTours.length > maxTours) maxTours = s.listeTours.length; }

    List<DataColumn> colonnes = [const DataColumn(label: Text("#", style: TextStyle(fontStyle: FontStyle.italic)))];
    for(var s in liste) {
      colonnes.add(DataColumn(label: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(DateFormat('dd/MM').format(s.date), style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(s.titre.length > 15 ? "${s.titre.substring(0,12)}..." : s.titre, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      )));
    }

    List<DataRow> lignes = [];
    for(int i = 0; i < maxTours; i++) {
      if (onlyFastLaps) {
        bool isInterestingRow = false;
        for(var s in liste) {
          if (i < s.listeTours.length) {
            if (s.listeTours[i].vitesseDouble >= 12.0) { isInterestingRow = true; break; }
          }
        }
        if (!isInterestingRow) continue; 
      }

      List<DataCell> cellules = [DataCell(Text("${i+1}"))];
      
      for(var s in liste) {
        if (i < s.listeTours.length) {
          final tour = s.listeTours[i];
          bool isFast = tour.vitesseDouble >= 12.0;
          Color textColor = (onlyFastLaps || isFast) ? Colors.black : Colors.grey;
          String vitessePrecise = tour.vitesseDouble.toStringAsFixed(1); 

          cellules.add(DataCell(
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tour.tempsFormate, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                Text("${tour.allureMinKm} • $vitessePrecise km/h", style: TextStyle(fontSize: 11, color: textColor)),
              ],
            )
          ));
        } else {
          cellules.add(const DataCell(Text("-")));
        }
      }
      lignes.add(DataRow(
        cells: cellules, 
        color: MaterialStateProperty.resolveWith((states) => i % 2 == 0 ? Colors.grey.shade50 : Colors.white)
      ));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Comparaison par Tour"),
        actions: [
          IconButton(
            icon: Icon(onlyFastLaps ? Icons.flash_on : Icons.flash_off),
            color: onlyFastLaps ? Colors.orange : Colors.grey,
            tooltip: "Masquer les tours lents (> 5'/km)",
            onPressed: () => setState(() => onlyFastLaps = !onlyFastLaps),
          )
        ],
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 20,
            headingRowHeight: 50,
            dataRowMinHeight: 50,
            dataRowMaxHeight: 60,
            columns: colonnes,
            rows: lignes,
          ),
        ),
      ),
    );
  }
}

// --- 3. PAGE LISTE PAR TAG ---
class PageListeParTag extends StatefulWidget { final String tagSelectionne; const PageListeParTag({super.key, required this.tagSelectionne}); @override State<PageListeParTag> createState() => _PageListeParTagState(); }
class _PageListeParTagState extends State<PageListeParTag> { List<String> idsSelectionnes = []; bool modeComparaison = false; @override Widget build(BuildContext context) { final seances = mesDonnees.where((s) => s.tags.contains(widget.tagSelectionne)).toList(); seances.sort((a,b) => b.date.compareTo(a.date)); return Scaffold(appBar: AppBar(title: Text(widget.tagSelectionne), actions: [ if (modeComparaison && idsSelectionnes.isNotEmpty) IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => setState(() => idsSelectionnes.clear())), IconButton(icon: Icon(modeComparaison ? Icons.check : Icons.compare_arrows), onPressed: () { if (modeComparaison && idsSelectionnes.isNotEmpty) { final selected = seances.where((s) => idsSelectionnes.contains(s.id)).toList(); Navigator.push(context, MaterialPageRoute(builder: (c) => PageComparaisonGraphique(seancesAComparer: selected))); } setState(() => modeComparaison = !modeComparaison); }) ]), body: Column(children: [if (modeComparaison) Container(color: Colors.orange.shade100, padding: const EdgeInsets.all(10), child: Text("Sélectionnez les séances (${idsSelectionnes.length})")), Expanded(child: ListView.builder(itemCount: seances.length, itemBuilder: (c, i) { final s = seances[i]; return SeanceCard(seance: s, selectionMode: modeComparaison, isSelected: idsSelectionnes.contains(s.id), onSelectionChanged: (val) => setState(() => val! ? idsSelectionnes.add(s.id) : idsSelectionnes.remove(s.id))); }))])); } }

// --- 4. FONCTION HELPER ---
String formatYAxisLabel(double value) { double vAbs = value.abs(); if (AppConfig.useSpeedKmH) return vAbs.toStringAsFixed(1); int m = vAbs.toInt(); int s = ((vAbs - m) * 60).round(); return "$m'${s.toString().padLeft(2, '0')}\""; }

// --- 5. PAGE COMPARAISON GRAPHIQUE ---
class PageComparaisonGraphique extends StatelessWidget { final List<Seance> seancesAComparer; const PageComparaisonGraphique({super.key, required this.seancesAComparer}); Color getColor(int i) => [Colors.blue, Colors.red, Colors.green, Colors.purple, Colors.orange][i % 5]; @override Widget build(BuildContext context) { double maxY = -1000; double minY = 1000; for(var s in seancesAComparer) { for(var t in s.listeTours) { double val = t.valeurGraphique; if(val > maxY) maxY = val; if(val < minY) minY = val; }} return Scaffold(appBar: AppBar(title: const Text("Comparatif (Aligné)")), body: Padding(padding: const EdgeInsets.all(16.0), child: Column(children: [Text(AppConfig.useSpeedKmH ? "Vitesse (km/h)" : "Allure (min/km)", style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 10), Wrap(spacing: 6, runSpacing: 4, children: seancesAComparer.asMap().entries.map((e) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: getColor(e.key).withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: getColor(e.key), width: 1)), child: Text("${e.value.titre} (${e.value.date.day}/${e.value.date.month})", style: TextStyle(fontSize: 10, color: getColor(e.key), fontWeight: FontWeight.bold)))).toList()), Expanded(child: InteractiveViewer(child: LineChart(LineChartData(minX: 0, maxY: maxY + (maxY - minY) * 0.15 + 1.0, minY: minY - (maxY - minY) * 0.1 - 0.5, lineTouchData: LineTouchData(touchSpotThreshold: 50, handleBuiltInTouches: true, touchTooltipData: LineTouchTooltipData(fitInsideHorizontally: true, fitInsideVertically: true, getTooltipItems: (touchedSpots) => touchedSpots.map((spot) => LineTooltipItem(formatYAxisLabel(spot.y), TextStyle(color: spot.bar.color, fontWeight: FontWeight.bold))).toList())), titlesData: FlTitlesData(topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 45, getTitlesWidget: (v, m) => Text(formatYAxisLabel(v), style: const TextStyle(fontSize: 10)))), bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 1, getTitlesWidget: (v, m) => Text("${v.toInt()}k", style: const TextStyle(fontSize: 10)))), rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false))), lineBarsData: seancesAComparer.asMap().entries.map((e) { final seance = e.value; final tours = seance.listeTours; int indexDebutEffort = 0; for(int i=0; i<tours.length; i++) { if (tours[i].vitesseDouble > AppConfig.seuilDebutVMA) { indexDebutEffort = i; break; } } List<FlSpot> points = []; double distanceRelative = 0; for (int i = indexDebutEffort; i < tours.length; i++) { double distKm = tours[i].distanceMetres / 1000.0; double val = tours[i].valeurGraphique; points.add(FlSpot(distanceRelative, val)); distanceRelative += distKm; points.add(FlSpot(distanceRelative, val)); } return LineChartBarData(spots: points, color: getColor(e.key), belowBarData: BarAreaData(show: true, color: getColor(e.key).withOpacity(0.1)), dotData: FlDotData(show: false), barWidth: 2); }).toList()))))]))); } }