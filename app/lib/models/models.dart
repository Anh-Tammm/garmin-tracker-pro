import 'package:flutter/material.dart'; // Nécessaire pour les Colors
import '../config/app_config.dart';     // Nécessaire car Seance utilise AppConfig

// 1. UserProfile
class UserProfile {
  final double vo2Max;
  final String status;
  final int load;
  final int readiness;

  UserProfile({required this.vo2Max, required this.status, required this.load, required this.readiness});

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      vo2Max: (json['vo2Max'] ?? 0).toDouble(),
      status: json['status'] ?? "Inconnu",
      load: json['load'] ?? 0,
      readiness: json['readiness'] ?? 0,
    );
  }
  
  String get statusTraduit {
    if (status.contains("MAINTAIN")) return "Maintien";
    if (status.contains("PRODUCTIVE")) return "Productif";
    if (status.contains("PEAKING")) return "Pic de forme";
    if (status.contains("RECOVERY")) return "Récupération";
    if (status.contains("STRAIN")) return "Fatigue";
    return status;
  }
  Color get statusColor {
    if (status.contains("PRODUCTIVE") || status.contains("PEAKING")) return Colors.green;
    if (status.contains("MAINTAIN")) return Colors.blue;
    if (status.contains("STRAIN")) return Colors.orange;
    return Colors.grey;
  }
  Color get readinessColor {
    if (readiness >= 75) return Colors.green;
    if (readiness >= 50) return Colors.orange;
    return Colors.red;
  }
}

// 2. PlanSession
class PlanSession {
  String id;
  DateTime date;
  String type; 
  String title;
  String? description;
  bool isCompleted;

  PlanSession({required this.id, required this.date, required this.type, required this.title, this.description, this.isCompleted = false});

  Map<String, dynamic> toJson() => {'id': id, 'date': date.toIso8601String(), 'type': type, 'title': title, 'description': description, 'isCompleted': isCompleted};
  factory PlanSession.fromJson(Map<String, dynamic> json) => PlanSession(id: json['id'], date: DateTime.parse(json['date']), type: json['type'], title: json['title'], description: json['description'], isCompleted: json['isCompleted'] ?? false);
}

// 3. TrainingPlan
class TrainingPlan {
  String raceName;
  DateTime raceDate;
  int totalWeeks;
  List<PlanSession> sessions;

  TrainingPlan({required this.raceName, required this.raceDate, required this.totalWeeks, required this.sessions});

  Map<String, dynamic> toJson() => {'raceName': raceName, 'raceDate': raceDate.toIso8601String(), 'totalWeeks': totalWeeks, 'sessions': sessions.map((s) => s.toJson()).toList()};
  factory TrainingPlan.fromJson(Map<String, dynamic> json) => TrainingPlan(raceName: json['raceName'], raceDate: DateTime.parse(json['raceDate']), totalWeeks: json['totalWeeks'], sessions: (json['sessions'] as List).map((s) => PlanSession.fromJson(s)).toList());
}

// 4. RaceEvent
class RaceEvent {
  String id; String nom; DateTime date; String type; int colorValue;
  RaceEvent({required this.id, required this.nom, required this.date, required this.type, required this.colorValue});
  Map<String, dynamic> toJson() => {'id': id, 'nom': nom, 'date': date.toIso8601String(), 'type': type, 'colorValue': colorValue};
  factory RaceEvent.fromJson(Map<String, dynamic> json) => RaceEvent(id: json['id'], nom: json['nom'], date: DateTime.parse(json['date']), type: json['type'], colorValue: json['colorValue']);
  int get joursRestants {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(date.year, date.month, date.day);
    return eventDay.difference(today).inDays;
  }
}

// 5. RaceResult
class RaceResult {
  String id; String nom; DateTime date; String type; Duration chrono; int? rank;
  RaceResult({required this.id, required this.nom, required this.date, required this.type, required this.chrono, this.rank});
  Map<String, dynamic> toJson() => {'id': id, 'nom': nom, 'date': date.toIso8601String(), 'type': type, 'chronoSec': chrono.inSeconds, 'rank': rank};
  factory RaceResult.fromJson(Map<String, dynamic> json) => RaceResult(id: json['id'], nom: json['nom'], date: DateTime.parse(json['date']), type: json['type'], chrono: Duration(seconds: json['chronoSec']), rank: json['rank']);
  double get distanceKm { switch(type) { case "5km": return 5.0; case "10km": return 10.0; case "20km": return 20.0; case "Semi": return 21.1; case "Marathon": return 42.195; default: return 0.0; } }
  String get chronoFormate { String twoDigits(int n) => n.toString().padLeft(2, "0"); return "${chrono.inHours > 0 ? '${chrono.inHours}:' : ''}${twoDigits(chrono.inMinutes.remainder(60))}:${twoDigits(chrono.inSeconds.remainder(60))}"; }
  String get allure { if (distanceKm == 0) return "-"; int totalSeconds = chrono.inSeconds; double secPerKm = totalSeconds / distanceKm; int m = secPerKm ~/ 60; int s = (secPerKm % 60).round(); return "$m'${s.toString().padLeft(2, '0')}\""; }
}

// 6. Intervalle
class Intervalle {
  final int numero; final int tempsSecondes; final int distanceMetres; final int bpmMoyen;
  Intervalle(this.numero, this.tempsSecondes, this.distanceMetres, this.bpmMoyen);
  factory Intervalle.fromJson(Map<String, dynamic> json) => Intervalle(json['numero']??0, json['tempsSecondes']??0, json['distanceMetres']??0, json['bpmMoyen']??0);
  double get vitesseDouble => tempsSecondes == 0 ? 0.0 : (distanceMetres / 1000) / (tempsSecondes / 3600);
  double get valeurGraphique { if (AppConfig.useSpeedKmH) return vitesseDouble; if (vitesseDouble == 0) return 0; double allure = 60 / vitesseDouble; if (allure > AppConfig.maxPaceDisplay) allure = AppConfig.maxPaceDisplay; return -allure; }
  String get vitesseKmH => vitesseDouble.toStringAsFixed(1);
  bool get estRepos => vitesseDouble < AppConfig.seuilReposKmH;
  String get tempsFormate { int m = tempsSecondes ~/ 60; int s = tempsSecondes % 60; return m > 0 ? "$m:${s.toString().padLeft(2, '0')}" : "${s}s"; }
  String get allureMinKm { if (distanceMetres == 0) return "-"; double min = (tempsSecondes / 60) / (distanceMetres / 1000); int m = min.toInt(); int s = ((min - m) * 60).round(); return "$m'${s.toString().padLeft(2, '0')}\""; }
}

// 7. Seance
class Seance {
  final String id; 
  final DateTime date; 
  final double distanceKm; 
  final int dureeTotaleMinutes; 
  List<String> tags; 
  final String titre; 
  final int bpmMoyenSeance; 
  final List<Intervalle> listeTours;

  Seance({
    required this.id, 
    required this.date, 
    required this.distanceKm, 
    required this.dureeTotaleMinutes, 
    required this.tags, 
    required this.titre, 
    required this.bpmMoyenSeance, 
    required this.listeTours
  });

  // --- REGEX STATIQUES (Performance) ---
  static final RegExp _regexIntensite = RegExp(r'\s\d+/\d+'); // ex: 100/105
  static final RegExp _regexPourcent = RegExp(r'\s\d+%');      // ex: 95%
  // Détection 10x300, 5x2km, 10 x 400m
  static final RegExp _regexIntervalle = RegExp(r'(\d+)\s*x\s*(\d+)\s*(km|m)?');
  static final RegExp _regexKmIso = RegExp(r'\b([1-9][0-9]?)([.,]5)?\s?km\b');

  // --- GETTER NETTOYÉ (Pour l'analyse de récurrence) ---
  String get titreNettoye {
    String t = titre;
    // 1. Enlever la ville
    if (t.contains("-")) {
      t = t.split("-").last;
    }
    // 2. Enlever les intensités
    t = t.replaceAll(_regexIntensite, ''); 
    t = t.replaceAll(_regexPourcent, '');
    return t.trim();
  }

  factory Seance.fromJson(Map<String, dynamic> json) {
    var listTours = json['tours'] as List? ?? [];
    List<String> rawTags = List<String>.from(json['tags'] ?? []);
    rawTags.remove("Importé");
    
    String titreBrut = (json['titre'] ?? "").toString();
    String titreTraite = titreBrut.contains("-") ? titreBrut.split("-").last.trim() : titreBrut;
    String tAnalysis = titreTraite.toLowerCase();

    // 1. DÉTECTION INTERVALLES (NxDistance) -> Génère tags "300m", "2km"...
    Iterable<Match> matches = _regexIntervalle.allMatches(tAnalysis);
    
    for (var match in matches) {
      if (!rawTags.contains("Fractionné")) rawTags.add("Fractionné");
      
      String distance = match.group(2)!;
      String? unite = match.group(3); 
      
      String tagFinal = "";
      
      if (unite == "km") {
        tagFinal = "${distance}km"; // "5x2km" -> "2km"
      } else {
        // Logique anti "1m" / "2m"
        int distInt = int.tryParse(distance) ?? 0;
        if (unite == "m") {
          tagFinal = "${distance}m";
        } else if (distInt >= 50) {
          // Si pas d'unité mais grand chiffre (10x400) -> "400m"
          tagFinal = "${distance}m";
        }
      }
      
      if (tagFinal.isNotEmpty && !rawTags.contains(tagFinal)) {
        rawTags.add(tagFinal);
      }
    }
    
    // Si contient un "+" (ex: 2x3000 + 3x1000) -> Fractionné
    if (tAnalysis.contains('+') && !rawTags.contains("Fractionné")) {
      rawTags.add("Fractionné");
    }

    // 2. TAGS CLASSIQUES
    if ((tAnalysis.contains("course à pied") || tAnalysis.contains("footing")) && !rawTags.contains("Endurance")) rawTags.add("Endurance");
    if (tAnalysis.contains("sortie longue") && !rawTags.contains("Sortie Longue")) rawTags.add("Sortie Longue");
    
    // Détection km isolés (ex: "Sortie 15km")
    Iterable<Match> matchesKm = _regexKmIso.allMatches(tAnalysis);
    for (var m in matchesKm) { 
      String tag = m.group(0)!.replaceAll(" ", ""); 
      if (!rawTags.contains(tag)) rawTags.add(tag); 
    }

    return Seance(
      id: json['id']?.toString() ?? "0", 
      date: DateTime.parse(json['date']), 
      distanceKm: (json['distanceKm'] ?? 0).toDouble(), 
      dureeTotaleMinutes: json['dureeMinutes'] ?? 0, 
      tags: rawTags, 
      titre: titreBrut, // On garde le titre original pour l'affichage
      bpmMoyenSeance: json['bpmMoyen'] ?? 0, 
      listeTours: listTours.map((i) => Intervalle.fromJson(i)).toList()
    );
  }

  Color get couleurType { 
    if (tags.any((t) => ["VMA", "Fractionné", "Piste"].contains(t))) return Colors.red; 
    if (tags.any((t) => ["Spécifique", "Seuil", "Prépa 10km"].contains(t))) return Colors.orange; 
    if (tags.any((t) => ["Endurance", "Sortie Longue"].contains(t))) return Colors.green; 
    return Colors.blue; 
  }
  
  String get dureeFormatee => "${dureeTotaleMinutes ~/ 60}h${(dureeTotaleMinutes % 60).toString().padLeft(2, '0')}";
  
  String get allureMoyenneSeance { 
    if (distanceKm == 0) return "-"; 
    double allureDecimale = dureeTotaleMinutes / distanceKm; 
    int m = allureDecimale.toInt(); 
    int s = ((allureDecimale - m) * 60).round(); 
    return "$m'${s.toString().padLeft(2, '0')}\""; 
  }
  
  String get vitesseMoyenneKmH { 
    if (dureeTotaleMinutes == 0) return "0.0"; 
    return (distanceKm / (dureeTotaleMinutes / 60)).toStringAsFixed(1); 
  }
}