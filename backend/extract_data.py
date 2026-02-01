import json
import os
import re
from garminconnect import Garmin
from datetime import date, timedelta

# --- 1. CONFIGURATION & CONNEXION ---
DEFAULT_LIMIT = 10
LIMIT_NEW_ACTIVITIES = DEFAULT_LIMIT
EMAIL = ""
PASSWORD = ""

print("📂 Lecture de la configuration...")

# 1. On essaie de lire le fichier déposé par l'appli
if os.path.exists("garmin_config.json"):
    try:
        with open("garmin_config.json", "r") as f:
            creds = json.load(f)
            EMAIL = creds.get("email", "")
            PASSWORD = creds.get("password", "")
            # NOUVEAU : On lit la limite demandée par l'appli
            if "limit" in creds:
                LIMIT_NEW_ACTIVITIES = int(creds["limit"])
                print(f"📥 Limite d'import définie par l'appli : {LIMIT_NEW_ACTIVITIES}")
            else:
                print(f"ℹ️ Pas de limite dans la config, utilisation défaut : {LIMIT_NEW_ACTIVITIES}")
                
            print("✅ Identifiants trouvés dans garmin_config.json")
    except Exception as e:
        print(f"⚠️ Erreur lecture fichier config : {e}")

# 2. Si ça échoue, on regarde les variables d'environnement (Ancienne méthode)
if not EMAIL or not PASSWORD:
    EMAIL = os.environ.get("GARMIN_EMAIL")
    PASSWORD = os.environ.get("GARMIN_PASSWORD")

if not EMAIL or not PASSWORD:
    print("❌ ERREUR FATALE : Aucun identifiant trouvé (ni fichier, ni secrets).")
    exit(1)

print(f"🔌 Connexion compte : {EMAIL[:3]}***")
try:
    client = Garmin(EMAIL, PASSWORD)
    client.login()
    print("✅ Connexion réussie.")
except Exception as e:
    print(f"❌ ÉCHEC CONNEXION : {e}")
    print("Arrêt immédiat pour ne pas écraser les données existantes.")
    exit(1) # Sécurité : On s'arrête là si le mot de passe est faux

# --- 2. RECUPERATION DONNÉES ---
# On prépare une structure vide ou on charge l'ancien si on veut (ici on repart à neuf comme demandé)
# Mais pour éviter les trous, on va quand même charger l'ancien pour récupérer l'historique
ancien_data = {"profil": {}, "seances": []}
ids_existants = set()

if os.path.exists("mes_seances.json"):
    try:
        with open("mes_seances.json", "r", encoding="utf-8") as f:
            content = f.read()
            if content.strip():
                ancien_data = json.loads(content)
                for s in ancien_data.get("seances", []): ids_existants.add(s["id"])
    except: pass

print("❤️ Récupération Santé...")
user_metrics = ancien_data.get("profil", {})
today = date.today()
dates = [(today + timedelta(days=1)).isoformat(), today.isoformat()]

# Readiness
for d in dates:
    try:
        r = client.get_training_readiness(d)
        val = 0
        if isinstance(r, dict) and 'score' in r: val = r['score']
        elif isinstance(r, list) and len(r) > 0: val = r[-1].get('score', 0)
        
        if val > 0:
            user_metrics['readiness'] = val
            break
    except: pass

# Statut Entrainement
for d in dates:
    try:
        s = client.get_training_status(d)
        if s and 'mostRecentTrainingStatus' in s:
            data = s['mostRecentTrainingStatus']['latestTrainingStatusData']
            k = list(data.keys())[0]
            user_metrics['status'] = data[k].get('trainingStatusFeedbackPhrase', '')
            if 'mostRecentVO2Max' in s:
                user_metrics['vo2Max'] = round(s['mostRecentVO2Max']['generic'].get('vo2MaxPreciseValue', 0), 1)
            if 'acuteTrainingLoadDTO' in data[k]:
                user_metrics['load'] = int(data[k]['acuteTrainingLoadDTO'].get('dailyTrainingLoadAcute', 0))
            break
    except: pass

# Activités
print(f"🏃 Récupération Activités...")
try:
    activities = client.get_activities(0, LIMIT_NEW_ACTIVITIES)
    nouvelles_seances = []
    
    for activity in activities:
        if activity["activityType"]["typeKey"] != "running": continue
        if str(activity["activityId"]) in ids_existants: continue
        
        print(f"🆕 Ajout : {activity['activityName']}")
        
        splits = []
        try:
            sp = client.get_activity_splits(str(activity["activityId"]))
            if sp: splits = sp.get('lapSplits', sp.get('lapDTOs', []))
        except: pass

        tours = []
        for i, lap in enumerate(splits):
            if lap.get("distance", 0) > 10:
                tours.append({
                    "numero": i+1,
                    "tempsSecondes": int(lap.get("duration", 0)),
                    "distanceMetres": int(lap.get("distance", 0)),
                    "bpmMoyen": int(lap.get("averageHR", 0))
                })

        nouvelles_seances.append({
            "id": str(activity["activityId"]),
            "date": activity["startTimeLocal"],
            "titre": activity["activityName"],
            "distanceKm": round(activity["distance"] / 1000, 2),
            "dureeMinutes": round(activity["duration"] / 60),
            "bpmMoyen": int(activity.get("averageHR", 0)),
            "tags": [], 
            "tours": tours
        })
        
    # Fusion et Sauvegarde
    liste_finale = ancien_data.get("seances", []) + nouvelles_seances
    liste_finale.sort(key=lambda x: x['date'], reverse=True)
    
    final_data = { "profil": user_metrics, "seances": liste_finale }
    
    # Mode 'w' : On Ecrase tout le fichier (Remise à neuf propre)
    with open("mes_seances.json", "w", encoding="utf-8") as f:
        json.dump(final_data, f, indent=4)
        
    print("✅ Sauvegarde terminée.")

except Exception as e:
    print(f"❌ Erreur lors du traitement : {e}")
    exit(1)
