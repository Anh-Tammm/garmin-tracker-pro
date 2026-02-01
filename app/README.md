#  Garmin Coach Dashboard

Une application mobile Flutter conçue pour visualiser, analyser et planifier ses entraînements de course à pied.

##  Fonctionnalités

* **Dashboard Complet :** Vue d'ensemble de la forme (Surcharge, Km hebdo, VMA).
* **Analyse Intelligente :** Détection automatique des séances (Fractionné, Endurance, Sortie Longue).
* **Bibliothèque :** Historique filtrable avec système de notation.
* **Outils :** Calculatrice d'allure et de temps de passage.
* **Synchro GitHub :** Vos données restent chez vous (JSON sur GitHub).

## Installation

1. Cloner le projet :
   git clone https://github.com/VOTRE_PSEUDO/garmin-coach-dashboard.git

2. Installer les dépendances :
   flutter pub get

3. Configurer (Voir section Configuration ci-dessous).

4. Lancer :
   flutter run

## Configuration (Indispensable)

1. Ouvrez le fichier `lib/config/app_config.dart`.
2. Remplacez les valeurs suivantes par les vôtres :

   static const String githubUser = "VOTRE_PSEUDO";
   static const String githubRepo = "NOM_REPO_BACKEND";
   static const String githubToken = "VOTRE_TOKEN_ICI";

###  Comment récupérer ces informations ?
**1. githubUser :**
C'est tout simplement votre pseudo GitHub (celui qui apparaît dans l'URL de votre profil).

**2. githubRepo :**
C'est le nom du dépôt où sont stockées vos données JSON (ex: `garmin-hub-backend`).

**3. githubToken :**
L'application a besoin d'une permission pour lire/écrire sur votre dépôt privé.

1. Allez dans les [Paramètres GitHub > Developer Settings > Tokens](https://github.com/settings/tokens).
2. Cliquez sur **Generate new token (classic)**.
3. Donnez un nom (ex: `App Garmin`).
4. **Très Important :** Dans la liste des permissions, cochez la case **`repo`** (Full control of private repositories).
5. Validez et copiez le token généré (il commence par `ghp_...`).

## 👤 Auteur
Projet personnel pour le running.