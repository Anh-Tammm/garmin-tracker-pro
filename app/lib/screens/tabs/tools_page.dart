import 'package:flutter/material.dart';

class PageOutils extends StatefulWidget {
  const PageOutils({super.key});
  @override State<PageOutils> createState() => _PageOutilsState();
}

class _PageOutilsState extends State<PageOutils> {
  // 0 = Calculer Temps, 1 = Calculer Distance, 2 = Calculer Allure
  int _modeCalcul = 0; 

  // Contrôleurs
  final TextEditingController _distKmCtrl = TextEditingController();
  final TextEditingController _heureCtrl = TextEditingController();
  final TextEditingController _minCtrl = TextEditingController();
  final TextEditingController _secCtrl = TextEditingController();
  final TextEditingController _allureMinCtrl = TextEditingController();
  final TextEditingController _allureSecCtrl = TextEditingController();

  String _resultat = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Calculateur"), backgroundColor: Colors.white, surfaceTintColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // SÉLECTEUR DE MODE
            Container(
              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _buildTabItem("Temps", 0),
                  _buildTabItem("Distance", 1),
                  _buildTabItem("Allure", 2),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // CHAMP DISTANCE (Visible si mode 0 ou 2)
            if (_modeCalcul != 1) ...[
              _buildSectionHeader(Icons.straighten, "Distance"),
              Row(
                children: [
                  Expanded(child: _buildInput(_distKmCtrl, "km", isDecimal: true)),
                  const SizedBox(width: 10),
                  // Boutons rapides
                  Wrap(spacing: 5, children: [
                    _buildQuickDistChip("5km", "5"),
                    _buildQuickDistChip("10km", "10"),
                    _buildQuickDistChip("Semi", "21.1"),
                    _buildQuickDistChip("Mara", "42.195"),
                  ])
                ],
              ),
              const SizedBox(height: 20),
            ],

            // CHAMP TEMPS (Visible si mode 1 ou 2)
            if (_modeCalcul != 0) ...[
              _buildSectionHeader(Icons.timer_outlined, "Temps"),
              Row(children: [
                Expanded(child: _buildInput(_heureCtrl, "h")),
                const SizedBox(width: 10),
                Expanded(child: _buildInput(_minCtrl, "min")),
                const SizedBox(width: 10),
                Expanded(child: _buildInput(_secCtrl, "sec")),
              ]),
              const SizedBox(height: 20),
            ],

            // CHAMP ALLURE (Visible si mode 0 ou 1)
            if (_modeCalcul != 2) ...[
              _buildSectionHeader(Icons.speed, "Allure"),
              Row(children: [
                Expanded(child: _buildInput(_allureMinCtrl, "min")),
                const Text(" : ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                Expanded(child: _buildInput(_allureSecCtrl, "sec")),
                const SizedBox(width: 10),
                const Text("/km", style: TextStyle(color: Colors.grey))
              ]),
              const SizedBox(height: 20),
            ],

            const Divider(height: 40),

            // BOUTON CALCULER
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _calculer,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text("CALCULER", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),

            const SizedBox(height: 30),

            // RÉSULTAT
            if (_resultat.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.indigo.shade100)),
                child: Column(
                  children: [
                    Text(_getLabelResultat(), style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Text(_resultat, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.indigo)),
                  ],
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(String label, int index) {
    bool isSelected = _modeCalcul == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() { _modeCalcul = index; _resultat = ""; }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: isSelected ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(10), boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)] : []),
          child: Center(child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.indigo : Colors.grey))),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [Icon(icon, size: 18, color: Colors.grey), const SizedBox(width: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))]));
  }

  Widget _buildInput(TextEditingController ctrl, String suffix, {bool isDecimal = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
      textAlign: TextAlign.center,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      decoration: InputDecoration(suffixText: suffix, contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300))),
    );
  }

  Widget _buildQuickDistChip(String label, String val) {
    return GestureDetector(
      onTap: () => setState(() => _distKmCtrl.text = val),
      child: Chip(label: Text(label, style: const TextStyle(fontSize: 10)), visualDensity: VisualDensity.compact, backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade300))),
    );
  }

  String _getLabelResultat() {
    switch (_modeCalcul) { case 0: return "Temps estimé"; case 1: return "Distance estimée"; case 2: return "Allure nécessaire"; default: return ""; }
  }

  void _calculer() {
    FocusScope.of(context).unfocus(); // Fermer clavier
    
    double dist = double.tryParse(_distKmCtrl.text.replaceAll(',', '.')) ?? 0;
    
    int h = int.tryParse(_heureCtrl.text) ?? 0;
    int m = int.tryParse(_minCtrl.text) ?? 0;
    int s = int.tryParse(_secCtrl.text) ?? 0;
    int totalTimeSec = (h * 3600) + (m * 60) + s;

    int paceM = int.tryParse(_allureMinCtrl.text) ?? 0;
    int paceS = int.tryParse(_allureSecCtrl.text) ?? 0;
    int totalPaceSec = (paceM * 60) + paceS;

    setState(() {
      if (_modeCalcul == 0) { // On cherche le TEMPS (Dist x Allure)
        if (dist > 0 && totalPaceSec > 0) {
          int resultSec = (dist * totalPaceSec).round();
          int rh = resultSec ~/ 3600;
          int rm = (resultSec % 3600) ~/ 60;
          int rs = resultSec % 60;
          _resultat = "${rh > 0 ? '${rh}h ' : ''}${rm}m ${rs}s";
        }
      } else if (_modeCalcul == 1) { // On cherche la DISTANCE (Temps / Allure)
        if (totalTimeSec > 0 && totalPaceSec > 0) {
          double resultKm = totalTimeSec / totalPaceSec;
          _resultat = "${resultKm.toStringAsFixed(2)} km";
        }
      } else if (_modeCalcul == 2) { // On cherche l'ALLURE (Temps / Dist)
        if (totalTimeSec > 0 && dist > 0) {
          int resultPaceSec = (totalTimeSec / dist).round();
          int pm = resultPaceSec ~/ 60;
          int ps = resultPaceSec % 60;
          _resultat = "$pm'${ps.toString().padLeft(2, '0')}\" /km";
        }
      }
    });
  }
}