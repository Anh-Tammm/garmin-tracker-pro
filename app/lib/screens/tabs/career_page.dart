import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../models/models.dart';

class PageCareer extends StatefulWidget { 
  const PageCareer({super.key}); 
  @override State<PageCareer> createState() => _PageCareerState(); 
}

class _PageCareerState extends State<PageCareer> {
  List<RaceResult> results = [];
  
  @override void initState() { super.initState(); _loadResults(); }
  
  Future<void> _loadResults() async { 
    SharedPreferences prefs = await SharedPreferences.getInstance(); 
    List<String> list = prefs.getStringList('saved_results') ?? []; 
    setState(() { 
      results = list.map((e) => RaceResult.fromJson(json.decode(e))).toList(); 
      results.sort((a, b) => b.date.compareTo(a.date)); 
    }); 
  }
  
  Future<void> _saveResults() async { 
    SharedPreferences prefs = await SharedPreferences.getInstance(); 
    results.sort((a, b) => b.date.compareTo(a.date)); 
    List<String> list = results.map((e) => json.encode(e.toJson())).toList(); 
    await prefs.setStringList('saved_results', list); 
    setState(() {}); 
  }
  
  void _openResultDialog({RaceResult? resultToEdit}) {
    final _nomCtrl = TextEditingController(text: resultToEdit?.nom ?? "");
    final _rankCtrl = TextEditingController(text: resultToEdit?.rank?.toString() ?? "");
    final _hCtrl = TextEditingController(text: resultToEdit != null ? resultToEdit.chrono.inHours.toString() : "0");
    final _mCtrl = TextEditingController(text: resultToEdit != null ? (resultToEdit.chrono.inMinutes % 60).toString() : "");
    final _sCtrl = TextEditingController(text: resultToEdit != null ? (resultToEdit.chrono.inSeconds % 60).toString() : "");
    DateTime _selectedDate = resultToEdit?.date ?? DateTime.now();
    String _type = resultToEdit?.type ?? "10km";
    
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setStateDialog) { 
      return AlertDialog(
        title: Text(resultToEdit == null ? "Nouveau Résultat" : "Modifier Résultat"), 
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButton<String>(value: _type, isExpanded: true, items: ["5km", "10km", "20km", "Semi", "Marathon"].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(), onChanged: (v) => setStateDialog(() => _type = v!)), 
          TextField(controller: _nomCtrl, decoration: const InputDecoration(labelText: "Nom course")), 
          const SizedBox(height: 10), 
          ListTile(title: Text("Date : ${DateFormat('dd/MM/yyyy').format(_selectedDate)}"), trailing: const Icon(Icons.calendar_today), onTap: () async { DateTime? d = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2000), lastDate: DateTime.now()); if (d != null) setStateDialog(() => _selectedDate = d); }), 
          const SizedBox(height: 10), 
          const Text("Chrono", style: TextStyle(fontWeight: FontWeight.bold)), 
          Row(children: [Expanded(child: TextField(controller: _hCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(suffixText: "h"))), const SizedBox(width: 5), Expanded(child: TextField(controller: _mCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(suffixText: "m"))), const SizedBox(width: 5), Expanded(child: TextField(controller: _sCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(suffixText: "s")))]), 
          const SizedBox(height: 10), 
          TextField(controller: _rankCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Classement (Optionnel)"))
        ])), 
        actions: [
          if(resultToEdit != null) TextButton(onPressed: () { results.removeWhere((r) => r.id == resultToEdit.id); _saveResults(); Navigator.pop(ctx); }, child: const Text("Supprimer", style: TextStyle(color: Colors.red))), 
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")), 
          ElevatedButton(onPressed: () { if (_mCtrl.text.isNotEmpty && _sCtrl.text.isNotEmpty) { Duration d = Duration(hours: int.tryParse(_hCtrl.text)??0, minutes: int.tryParse(_mCtrl.text)??0, seconds: int.tryParse(_sCtrl.text)??0); int? rk = _rankCtrl.text.isNotEmpty ? int.tryParse(_rankCtrl.text) : null; if(resultToEdit != null) { resultToEdit.nom = _nomCtrl.text; resultToEdit.date = _selectedDate; resultToEdit.type = _type; resultToEdit.chrono = d; resultToEdit.rank = rk; } else { results.add(RaceResult(id: DateTime.now().toString(), nom: _nomCtrl.text.isEmpty ? "Course" : _nomCtrl.text, date: _selectedDate, type: _type, chrono: d, rank: rk)); } _saveResults(); Navigator.pop(ctx); } }, child: const Text("Enregistrer"))
        ]
      ); 
    }));
  }
  
  RaceResult? _getRecord(String type) { var filter = results.where((r) => r.type == type).toList(); if (filter.isEmpty) return null; filter.sort((a, b) => a.chrono.compareTo(b.chrono)); return filter.first; }
  
  Widget _buildRecordRow(String type) { 
    RaceResult? r = _getRecord(type); 
    return InkWell(
      onTap: () { Navigator.push(context, MaterialPageRoute(builder: (c) => PageRaceHistory(type: type, allResults: results, onEdit: _openResultDialog))); }, 
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16), 
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))), 
        child: Row(children: [
          SizedBox(width: 85, child: Text(type, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))), 
          Expanded(child: r == null ? const Text("-", style: TextStyle(color: Colors.grey)) : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(r.chronoFormate, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo)), Text("${r.allure}/km • ${r.nom} (${r.date.year})", style: TextStyle(color: Colors.grey.shade600, fontSize: 12))])), 
          const Icon(Icons.chevron_right, color: Colors.grey)
        ])
      )
    ); 
  }
  
  @override 
  Widget build(BuildContext context) { 
    return Scaffold(
      floatingActionButton: FloatingActionButton(onPressed: () => _openResultDialog(), backgroundColor: Colors.indigo, child: const Icon(Icons.add, color: Colors.white)), 
      body: ListView(children: [
        const Padding(padding: EdgeInsets.all(16), child: Text("Records Personnels", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))), 
        _buildRecordRow("5km"), 
        _buildRecordRow("10km"), 
        _buildRecordRow("20km"), 
        _buildRecordRow("Semi"), 
        _buildRecordRow("Marathon"), 
        const SizedBox(height: 100)
      ])
    ); 
  }
}

class PageRaceHistory extends StatefulWidget {
  final String type; final List<RaceResult> allResults; final Function({RaceResult? resultToEdit}) onEdit; 
  const PageRaceHistory({super.key, required this.type, required this.allResults, required this.onEdit});
  @override State<PageRaceHistory> createState() => _PageRaceHistoryState();
}

class _PageRaceHistoryState extends State<PageRaceHistory> {
  final PageController _controller = PageController();
  
  @override 
  Widget build(BuildContext context) {
    List<RaceResult> history = widget.allResults.where((r) => r.type == widget.type).toList();
    history.sort((a, b) => b.date.compareTo(a.date)); 
    List<RaceResult> graphData = List.from(history);
    graphData.sort((a, b) => a.date.compareTo(b.date));
    
    return Scaffold(
      appBar: AppBar(title: Text("Historique ${widget.type}")), 
      body: PageView(
        controller: _controller, 
        children: [
          history.isEmpty 
            ? const Center(child: Text("Aucune course de ce type enregistrée")) 
            : ListView.builder(
                itemCount: history.length, 
                itemBuilder: (ctx, i) { 
                  final r = history[i]; 
                  Widget diffWidget = const SizedBox.shrink(); 
                  if (i < history.length - 1) { 
                    final prev = history[i+1]; 
                    int diffSec = r.chrono.inSeconds - prev.chrono.inSeconds; 
                    bool faster = diffSec < 0; 
                    diffWidget = Row(mainAxisSize: MainAxisSize.min, children: [Icon(faster ? Icons.arrow_downward : Icons.arrow_upward, size: 14, color: faster ? Colors.green : Colors.red), Text(" ${diffSec.abs()}s", style: TextStyle(color: faster ? Colors.green : Colors.red, fontSize: 12, fontWeight: FontWeight.bold))]); 
                  } 
                  return GestureDetector(
                    onLongPress: () { Navigator.pop(context); widget.onEdit(resultToEdit: r); }, 
                    child: Card(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), child: ListTile(title: Text(r.chronoFormate, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("${r.nom} • ${DateFormat('dd/MM/yyyy').format(r.date)}"), if(r.rank != null) Text("Classement : #${r.rank}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.indigo))]), trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [Text("${r.allure}/km", style: const TextStyle(color: Colors.grey)), diffWidget])))
                  ); 
                }
              ),
          if(graphData.length > 1) 
            Padding(
              padding: const EdgeInsets.all(16.0), 
              child: Column(children: [
                Text("Évolution Chrono ${widget.type}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo)), 
                const SizedBox(height: 30), 
                Expanded(child: LineChart(LineChartData(gridData: FlGridData(show: false), titlesData: FlTitlesData(topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (val, meta) { int sec = val.abs().toInt(); int h = sec ~/ 3600; int m = (sec % 3600) ~/ 60; if (h > 0) return Text("$h:${m.toString().padLeft(2,'0')}", style: const TextStyle(fontSize: 10)); return Text("$m:${(sec%60).toString().padLeft(2,'0')}", style: const TextStyle(fontSize: 10)); })), bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 1, getTitlesWidget: (val, meta) { int index = val.toInt(); if(index >= 0 && index < graphData.length) { return Padding(padding: const EdgeInsets.only(top:8), child: Text(DateFormat('MM/yy').format(graphData[index].date), style: const TextStyle(fontSize: 10))); } return const Text(""); }))), lineBarsData: [LineChartBarData(spots: graphData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), -e.value.chrono.inSeconds.toDouble())).toList(), isCurved: true, color: Colors.indigo, barWidth: 3, dotData: FlDotData(show: true))]))), 
                const SizedBox(height: 50)
              ])
            ) 
          else 
            const Center(child: Text("Pas assez de données pour le graphique"))
        ]
      )
    );
  }
}
