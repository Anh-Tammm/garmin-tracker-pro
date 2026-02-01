import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
// Imports de vos fichiers
import '../../models/models.dart';
import '../../widgets/custom_widgets.dart'; // Pour RowStat

class PageDetailStatsSwipable extends StatefulWidget { 
  final List<Seance> allSeances; 
  const PageDetailStatsSwipable({super.key, required this.allSeances}); 
  @override State<PageDetailStatsSwipable> createState() => _PageDetailStatsSwipableState(); 
}

class _PageDetailStatsSwipableState extends State<PageDetailStatsSwipable> { 
  final PageController _controller = PageController(initialPage: 0); 
  
  @override 
  Widget build(BuildContext context) { 
    return Scaffold(
      appBar: AppBar(title: const Text("Analyses")), 
      body: PageView(
        controller: _controller, 
        children: [
          _PageChiffres(allSeances: widget.allSeances), 
          _PageGraphiqueStrava(allSeances: widget.allSeances)
        ]
      )
    ); 
  } 
}

// --- SOUS-PAGE 1 : CHIFFRES ---
class _PageChiffres extends StatefulWidget {
  final List<Seance> allSeances;
  const _PageChiffres({required this.allSeances});

  @override
  State<_PageChiffres> createState() => _PageChiffresState();
}

class _PageChiffresState extends State<_PageChiffres> {
  int _selectedYear = DateTime.now().year;

  String _formatDuree(int minutes) => "${minutes ~/ 60}h${(minutes % 60).toString().padLeft(2, '0')}";

  @override
  Widget build(BuildContext context) {
    if (widget.allSeances.isEmpty) return const Center(child: Text("Pas de données"));

    final now = DateTime.now();
    
    Set<int> years = widget.allSeances.map((s) => s.date.year).toSet();
    years.add(now.year); 
    List<int> sortedYears = years.toList()..sort((a, b) => b.compareTo(a)); 

    // 1. Calcul Forme Actuelle (4 dernières semaines)
    final date4SemainesAvant = now.subtract(const Duration(days: 28));
    final seancesLast4Weeks = widget.allSeances.where((s) => s.date.isAfter(date4SemainesAvant)).toList();
    double totalKmLast4Weeks = seancesLast4Weeks.fold(0, (sum, s) => sum + s.distanceKm);
    int totalMinLast4Weeks = seancesLast4Weeks.fold(0, (sum, s) => sum + s.dureeTotaleMinutes);
    double avgStravaHebdo = totalKmLast4Weeks / 4;

    // 2. Calcul Bilan Annuel
    final seancesSelectedYear = widget.allSeances.where((s) => s.date.year == _selectedYear).toList();
    double totalKmYear = seancesSelectedYear.fold(0, (sum, s) => sum + s.distanceKm);
    int totalMinYear = seancesSelectedYear.fold(0, (sum, s) => sum + s.dureeTotaleMinutes);
    int countYear = seancesSelectedYear.length;

    double semainesEcoulees = 52.0;
    if (_selectedYear == now.year) {
      int days = now.difference(DateTime(now.year, 1, 1)).inDays;
      if(days < 1) days = 1;
      semainesEcoulees = days / 7.0;
    }
    double avgYearHebdoKm = totalKmYear / semainesEcoulees;
    double avgYearHebdoSess = countYear / semainesEcoulees;

    // 3. Totaux Carrière
    double totalCarriere = widget.allSeances.fold(0, (sum, s) => sum + s.distanceKm);
    int totalMinCarriere = widget.allSeances.fold(0, (sum, s) => sum + s.dureeTotaleMinutes);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSection("Forme Actuelle (4 dernières sem.)", [
          RowStat("Moyenne Hebdo", "${avgStravaHebdo.toStringAsFixed(1)} km / sem"),
          RowStat("Total 4 semaines", "${totalKmLast4Weeks.toStringAsFixed(1)} km"),
          RowStat("Temps 4 semaines", _formatDuree(totalMinLast4Weeks)),
        ]),
        
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Bilan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
                  DropdownButton<int>(
                    value: _selectedYear,
                    items: sortedYears.map((y) => DropdownMenuItem(value: y, child: Text("$y", style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                    onChanged: (v) { if(v!=null) setState(() => _selectedYear = v); },
                    underline: Container(),
                    isDense: true,
                  )
                ],
              ),
              const Divider(),
              RowStat("Distance Totale", "${totalKmYear.toStringAsFixed(0)} km"),
              RowStat("Temps Total", _formatDuree(totalMinYear)),
              RowStat("Nombre de sorties", "$countYear"),
              const Divider(),
              RowStat("Moyenne Hebdo $_selectedYear", "${avgYearHebdoKm.toStringAsFixed(1)} km"),
              RowStat("Sorties / semaine", avgYearHebdoSess.toStringAsFixed(1)),
            ],
          ),
        ),

        const SizedBox(height: 20),

        _buildSection("Total Carrière", [
          RowStat("Kilométrage cumulé", "${totalCarriere.toStringAsFixed(0)} km"),
          RowStat("Temps cumulé", _formatDuree(totalMinCarriere)),
          RowStat("Nombre total d'activités", "${widget.allSeances.length}"),
        ]),
      ]
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)), const Divider(), ...children])
    );
  }
}

// --- SOUS-PAGE 2 : GRAPHIQUE ---
class _PageGraphiqueStrava extends StatefulWidget {
  final List<Seance> allSeances;
  const _PageGraphiqueStrava({required this.allSeances});

  @override
  State<_PageGraphiqueStrava> createState() => _PageGraphiqueStravaState();
}

class _PageGraphiqueStravaState extends State<_PageGraphiqueStrava> {
  int _weeksToDisplay = 12;

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = screenWidth - 48; 
    double barWidth = chartWidth / _weeksToDisplay;
    barWidth += 0.5;

    final Map<int, double> kmParSemaine = {};
    final now = DateTime.now();
    final currentMonday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    for (int i = 0; i < _weeksToDisplay; i++) kmParSemaine[i] = 0.0;
    
    double totalKmPeriode = 0;
    int totalMinutesPeriode = 0;

    for (var s in widget.allSeances) {
      final differenceEnJours = currentMonday.difference(s.date).inDays;
      if (differenceEnJours < 0) { kmParSemaine[0] = (kmParSemaine[0] ?? 0) + s.distanceKm; } 
      else {
        int semaineIndex = (differenceEnJours ~/ 7);
        if (s.date.isBefore(currentMonday)) semaineIndex = semaineIndex + 1;
        if (semaineIndex < _weeksToDisplay && semaineIndex >= 0) {
          kmParSemaine[semaineIndex] = (kmParSemaine[semaineIndex] ?? 0) + s.distanceKm;
          totalKmPeriode += s.distanceKm;
          totalMinutesPeriode += s.dureeTotaleMinutes;
        }
      }
    }

    List<BarChartGroupData> barGroups = [];
    double maxVal = 0;
    for (int i = _weeksToDisplay - 1; i >= 0; i--) {
      double km = kmParSemaine[i] ?? 0;
      if (km > maxVal) maxVal = km;
      int xIndex = (_weeksToDisplay - 1) - i;
      
      barGroups.add(
        BarChartGroupData(
          x: xIndex,
          barRods: [
            BarChartRodData(
              toY: km,
              color: km > 0 ? Colors.indigo : Colors.transparent,
              width: barWidth,
              borderRadius: BorderRadius.zero,
              backDrawRodData: BackgroundBarChartRodData(show: true, toY: maxVal * 1.1, color: Colors.grey.shade100),
            )
          ]
        )
      );
    }

    int h = totalMinutesPeriode ~/ 60; int m = totalMinutesPeriode % 60;
    String dureeTotale = "${h}h${m.toString().padLeft(2, '0')}";

    double intervalAxis = 4;
    if (_weeksToDisplay > 20) intervalAxis = 6;
    if (_weeksToDisplay > 40) intervalAxis = 9;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DropdownButton<int>(
                value: _weeksToDisplay,
                items: const [DropdownMenuItem(value: 12, child: Text("12 dernières semaines")), DropdownMenuItem(value: 26, child: Text("6 derniers mois")), DropdownMenuItem(value: 52, child: Text("1 dernière année"))],
                onChanged: (v) { if(v != null) setState(() => _weeksToDisplay = v); },
                underline: Container(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo), icon: const Icon(Icons.keyboard_arrow_down, color: Colors.indigo),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text("${totalKmPeriode.toStringAsFixed(0)} km", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)), const Text(" • ", style: TextStyle(color: Colors.grey)), Text(dureeTotale, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.grey))]),
          const SizedBox(height: 30),
          Expanded(
            child: BarChart(
              BarChartData(
                maxY: maxVal * 1.2,
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: intervalAxis, 
                      getTitlesWidget: (val, meta) {
                        int index = val.toInt();
                        if (index >= 0 && index < _weeksToDisplay) {
                          int semaineReverse = (_weeksToDisplay - 1) - index;
                          DateTime dateLundi = currentMonday.subtract(Duration(days: semaineReverse * 7));
                          return Padding(padding: const EdgeInsets.only(top: 8.0), child: Text("${dateLundi.day}/${dateLundi.month}", style: const TextStyle(fontSize: 10, color: Colors.grey)));
                        }
                        return const Text("");
                      }
                    )
                  )
                ),
                barTouchData: BarTouchData(touchTooltipData: BarTouchTooltipData(getTooltipItem: (group, groupIndex, rod, rodIndex) { return BarTooltipItem("${rod.toY.toStringAsFixed(1)} km", const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)); })),
                barGroups: barGroups,
              )
            )
          ), 
          const SizedBox(height: 50)
        ]
      )
    );
  }
}