import 'package:flutter/material.dart';
import 'package:projet/config/app_config.dart';
import 'package:projet/models/models.dart';
import 'package:projet/screens/details/stats_page.dart';
import 'package:projet/widgets/custom_widgets.dart';
import '../../data/globals.dart';

class DashboardTab extends StatefulWidget {
  final DateTime? derniereSynchro;
  const DashboardTab({super.key, required this.derniereSynchro});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> with AutomaticKeepAliveClientMixin {
  @override bool get wantKeepAlive => true;

  Map<String, dynamic> totalStats = {"km": 0.0, "minutes": 0};
  Map<String, dynamic> semStats = {"km": 0.0, "minutes": 0};
  Map<String, dynamic> moisStats = {"km": 0.0, "minutes": 0};
  Map<String, dynamic> anneeStats = {"km": 0.0, "minutes": 0};
  List<Seance> fluxActivites = [];
  
  double lastSessionKmWeek = 0;
  double lastSessionKmMonth = 0;
  double lastSessionKmYear = 0;

  @override void initState() { super.initState(); _calculerDonnees(); }

  @override
  void didUpdateWidget(DashboardTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.derniereSynchro != oldWidget.derniereSynchro) _calculerDonnees();
  }

  void _calculerDonnees() {
    final now = DateTime.now();
    Map<String, dynamic> calc(List<Seance> liste) {
      double km = liste.fold(0.0, (sum, item) => sum + item.distanceKm);
      int minutes = liste.fold(0, (sum, item) => sum + item.dureeTotaleMinutes);
      return {"km": km, "minutes": minutes};
    }

    // 1. IDENTIFICATION DERNIERE SEANCE
    Seance? lastSeance;
    bool isToday = false; // Par défaut faux

    if (mesDonnees.isNotEmpty) {
      List<Seance> temp = List.from(mesDonnees)..sort((a,b) => b.date.compareTo(a.date));
      lastSeance = temp.first;
      
      // VÉRIFICATION : Est-ce que c'est aujourd'hui ?
      if (lastSeance.date.year == now.year && 
          lastSeance.date.month == now.month && 
          lastSeance.date.day == now.day) {
        isToday = true;
      }
    }

    // 2. CALCULS CLASSIQUES
    totalStats = calc(mesDonnees);

    final dateDuLundi = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final seancesSemaine = mesDonnees.where((s) => s.date.isAfter(dateDuLundi) || s.date.isAtSameMomentAs(dateDuLundi)).toList();
    semStats = calc(seancesSemaine);
    
    // IMPACT SEMAINE (Seulement si c'est aujourd'hui)
    lastSessionKmWeek = isToday ? lastSeance!.distanceKm : 0;

    final debutMois = DateTime(now.year, now.month, 1);
    final seancesMois = mesDonnees.where((s) => s.date.isAfter(debutMois) || s.date.isAtSameMomentAs(debutMois)).toList();
    moisStats = calc(seancesMois);
    
    // IMPACT MOIS (Seulement si c'est aujourd'hui)
    lastSessionKmMonth = isToday ? lastSeance!.distanceKm : 0;

    final debutAnnee = DateTime(now.year, 1, 1);
    final seancesAnnee = mesDonnees.where((s) => s.date.isAfter(debutAnnee) || s.date.isAtSameMomentAs(debutAnnee)).toList();
    anneeStats = calc(seancesAnnee);
    
    // IMPACT ANNÉE (Seulement si c'est aujourd'hui)
    lastSessionKmYear = isToday ? lastSeance!.distanceKm : 0;

    fluxActivites = List<Seance>.from(mesDonnees)..sort((a, b) => b.date.compareTo(a.date));
    if (fluxActivites.length > 20) fluxActivites = fluxActivites.sublist(0, 20);

    if(mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          // PROFIL
          if (monProfil != null)
            Container(
              margin: const EdgeInsets.all(16), 
              padding: const EdgeInsets.all(20), 
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]), 
              child: Column(
                children: [
                  if(AppConfig.showReadiness) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start, 
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                          children: [
                            const Text("PRÉPARATION", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)), 
                            Text(monProfil!.readiness == 0 ? "?/100" : "${monProfil!.readiness}/100", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))
                          ]
                        ), 
                        const SizedBox(height: 5), 
                        BarrePreparation(percentage: (monProfil!.readiness == 0 ? 0 : monProfil!.readiness) / 100.0)
                      ]
                    ), 
                    const SizedBox(height: 20)
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start, 
                        children: [
                          if(AppConfig.showStatus) ...[
                            Text(monProfil!.statusTraduit.toUpperCase(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: monProfil!.statusColor)), 
                            Text("Statut", style: TextStyle(fontSize: 10, color: Colors.grey.shade600))
                          ]
                        ]
                      ), 
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end, 
                        children: [
                          if(AppConfig.showVO2) Text("VO2 ${monProfil!.vo2Max}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)), 
                          if(AppConfig.showLoad) Text("Charge: ${monProfil!.load}", style: TextStyle(fontSize: 10, color: Colors.grey.shade600))
                        ]
                      )
                    ]
                  ),
                ]
              )
            ),
          
          if(AppConfig.showStats)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: Column(children: [
                  Row(children: [
                    Expanded(child: GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => PageDetailStatsSwipable(allSeances: mesDonnees))), child: MiniStatCard("Total", "${totalStats['km'].toStringAsFixed(0)} km", _formatDuree(totalStats['minutes']), Colors.blue, isClickable: true))),
                    const SizedBox(width: 6),
                    Expanded(child: MiniStatCard("Semaine", "${semStats['km'].toStringAsFixed(1)} km", _formatDuree(semStats['minutes']), Colors.green)),
                    const SizedBox(width: 6),
                    Expanded(child: MiniStatCard("Mois", "${moisStats['km'].toStringAsFixed(0)} km", _formatDuree(moisStats['minutes']), Colors.orange)),
                    const SizedBox(width: 6),
                    Expanded(child: MiniStatCard("Année", "${anneeStats['km'].toStringAsFixed(0)} km", _formatDuree(anneeStats['minutes']), Colors.purple)),
                  ]),
                  if (objectifSemaine > 0 || objectifMois > 0 || objectifAnnee > 0) ...[
                     const SizedBox(height: 15),
                     if (objectifSemaine > 0) ProgressBarObjectif(titre: "Obj. Semaine", current: semStats['km'], target: objectifSemaine, color: Colors.green, precisionPercent: 1, lastSessionImpact: lastSessionKmWeek),
                     if (objectifMois > 0) ProgressBarObjectif(titre: "Obj. Mois", current: moisStats['km'], target: objectifMois, color: Colors.orange, precisionPercent: 2, lastSessionImpact: lastSessionKmMonth),
                     if (objectifAnnee > 0) ProgressBarObjectif(titre: "Obj. Année", current: anneeStats['km'], target: objectifAnnee, color: Colors.purple, precisionPercent: 2, lastSessionImpact: lastSessionKmYear),
                  ]
                ])),
          
          const Padding(padding: EdgeInsets.fromLTRB(16, 20, 16, 0), child: Text("Prochaines Courses", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          const EventsListWidget(),
          const Padding(padding: EdgeInsets.fromLTRB(16, 10, 16, 10), child: Text("Activités Récentes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: fluxActivites.length, itemBuilder: (context, index) => SeanceCard(seance: fluxActivites[index])),
          const SizedBox(height: 50),
        ]
      ),
    );
  }
  String _formatDuree(int minutes) => "${minutes ~/ 60}h${(minutes % 60).toString().padLeft(2, '0')}";
}

