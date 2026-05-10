# Architecture et Fonctionnement du Backend (Django)

Ce document détaille la manière dont le serveur API Django a été conçu, ses fonctionnalités clés et son flux de données avec le frontend mobile.

## 1. Création du projet Django

Le projet serveur a été initialisé via un environnement virtuel avec Python de la manière suivante :

```bash
# 1. Création de l'environnement Python
python -m venv backend/.venv
# Activation sous Windows PowerShell :
backend\.venv\Scripts\Activate.ps1

# 2. Installation des bibliothèques fondamentales
pip install django
pip install djangorestframework     # Création d'APIs REST
pip install django-cors-headers     # Accepter les requêtes du mobile
pip install python-dotenv           # Gérer les clés API (API Google, etc.)

# 3. Initialiser le projet et les applications de domaine
django-admin startproject config backend
cd backend
python manage.py startapp apps.generative
python manage.py startapp apps.datahub
python manage.py startapp apps.vision
python manage.py startapp apps.nlp
python manage.py startapp apps.users
```

## 2. Fonctionnalités Principales

Le Backend agit comme le "cerveau déporté" et la mémoire de l'application :

*   **API d'Intelligence Artificielle Générative (Generative App) :**
    *   Sert de routeur (proxy) pour contacter de grands modèles de langage.
    *   **LLMs Locaux :** Il transmet les prompts complexes vers un serveur Ollama local tournant Mistral 7B ou Llama 3.
    *   **LLMs Cloud :** Il envoie les requêtes vers l'API Google Gemini si sélectionné.
    *   Fournit les endpoints de chat (`POST /api/generative/chat/message/`) et garde un historique (SQLite).
*   **Module de Données et Cartographie (DataHub App) :**
    *   Connecté à l'API **Google Places (New API)** et **Google Maps**.
    *   Reçoit les coordonnées GPS envoyées par Flutter et recherche en toute transparence (via `searchNearby`) des restaurants, hôtels, ou lieux d'intérêts.
    *   Gère le système de calcul de distances géographiques (Haversine) et des catégories.
*   **Système Vision et NLP (Modules Serveurs) :**
    *   Des terminaux pour interagir avec des modèles de Machine Learning plus lourds (si Flutter ne les gère pas en local).
    *   Persistance d'images, de textes traduits et d'historique de détection.

## 3. Comment ça fonctionne en arrière-plan ?

1.  **L'Architecture (Django REST Framework) :**
    *   Le backend suit le modèle Modèle-Vue-Contrôleur (MVC, ou MVT dans Django).
    *   `urls.py` définit les portes d'entrée (ex: `/api/generative/...`).
    *   `views.py` (ou `APIView`) reçoit la requête du téléphone (JSON), extrait par exemple : le modèle choisi (Mistral), la position GPS, et le texte de l'utilisateur.
    *   `serializers.py` valide la structure et la sécurité des données reçues avant traitement.
2.  **Traitement Avancé (Prompt Engineering + RAG léger) :**
    *   Lorsqu'un utilisateur demande une recommandation géographique dans le chat Flutter, l'endpoint `views.py` (dans `apps.generative`) intercepte cela.
    *   Le backend appelle d'abord l'API Google Places (`DataHub`), récupère une liste JSON des meilleurs lieux proches avec leurs notes et adresses.
    *   Il injecte ensuite cette liste brute dans un prompt "système" secret (ex: `Tu es un guide. Voici des lieux: [Lieu A, Lieu B]. Fais une recommandation.`).
    *   Enfin, le backend appelle Mistral (via `http://localhost:11434/api/generate`) ou Gemini pour rédiger la réponse finale très proprement, et la renvoyer au smartphone en quelques secondes.
3.  **Base de Données et Stockage :**
    *   Le backend utilise une base relationnelle (gérée par l'ORM Django) pour stocker les profils utilisateurs, les identifiants de sessions de discussion et les lieux déjà recherchés (pour éviter des requêtes Google API inutiles et de la facturation).
    *   Les commandes de migration consolident le schéma de données :
        `python manage.py makemigrations` et `python manage.py migrate`.
