class AppConfig {
  static String appTitle = "My Dashboard";
  
  // --- CONFIGURATION GITHUB (À REMPLIR PAR L'UTILISATEUR) ---
  // Remplacez par votre nom d'utilisateur GitHub
  static const String githubUser = "Anh-Tammm"; 
  
  // Remplacez par le nom de votre dépôt backend (ex: garmin-hub-backend)
  static const String githubRepo = "garmin-tracker-pro"; 
  
  // Remplacez par votre Token
  static const String githubToken = "token"; 
  
  // --- URLS GÉNÉRÉES AUTOMATIQUEMENT (Ne pas toucher) ---
  static String get urlJson => "https://api.github.com/repos/$githubUser/$githubRepo/contents/backend/mes_seances.json";
  static String get urlConfig => "https://api.github.com/repos/$githubUser/$githubRepo/contents/garmin_config.json";
  static String get urlWorkflow => "https://api.github.com/repos/$githubUser/$githubRepo/actions/workflows/update_garmin.yml/dispatches";

  // ... (Garde tes autres booléens showVO2 etc.) ...
  static bool showVO2 = true;
  static bool showStatus = true;
  static bool showLoad = true;
  static bool showReadiness = true;
  static bool showStats = true;
  static bool useSpeedKmH = true; 
  static double maxPaceDisplay = 8.0; 
  static double seuilReposKmH = 8.0;
  static double seuilDebutVMA = 12.0;
  static bool showLastSessionImpact = true;
}
