# Architecture et Fonctionnement du Frontend (Flutter)

Ce document explique comment l'application mobile Flutter a été créée, les commandes utilisées, ses fonctionnalités principales et son fonctionnement global.

## 1. Création du projet Flutter

Le projet mobile a été initialisé avec les outils standards de développement Flutter :

```bash
# 1. Création de l'application de base
flutter create frontend

# 2. Ajout des dépendances principales (Gestion d'état, UI, Intégration)
flutter pub add flutter_bloc          # Gestion d'état
flutter pub add google_mlkit_commons  # Cœur de ML Kit
flutter pub add image_picker          # Sélection de photos/caméra
flutter pub add geolocator            # Pour la localisation GPS
flutter pub add google_maps_flutter   # Affichage des cartes interactives
```

## 2. Fonctionnalités Principales

L'application Flutter est découpée en plusieurs grands modules intelligents :

*   **Intelligence Artificielle Générative (Chatbot) :**
    *   Un assistant virtuel interactif capable de discuter avec l'utilisateur.
    *   Supporte des modèles locaux (Mistral, Llama via Ollama) et cloud (Gemini, GPT).
    *   Intègre la commande vocale (Speech-to-Text), la reconnaissance d'image pour cuisiner (Image Labeling), le scan de documents (OCR), et l'analyse émotionnelle (Face Detection).
*   **Vision par Ordinateur (Google ML Kit) :**
    *   Lecture de codes-barres (QR, EAN).
    *   Détection d'objets et suivi en temps réel.
    *   Reconnaissance faciale (Détection de sourires, inclinaison de la tête).
*   **Traitement du Langage Naturel (NLP) :**
    *   Traduction hors-ligne et détection de la langue.
    *   Extraction d'entités (Dates, adresses, numéros de téléphone) depuis un texte scanné.
*   **Module DataHub / Géolocalisation :**
    *   Utilisation du GPS et de la puce de géolocalisation.
    *   Système de recommandations de lieux à proximité (Restaurants, Lieux touristiques) avec *Google Maps*.

## 3. Comment ça fonctionne en arrière-plan ?

1.  **L'Architecture (BLoC) :** L'application utilise le pattern BLoC (Business Logic Component). Lorsque vous cliquez sur un bouton (par exemple "Envoyer un message" ou "Scanner une photo"), un *Event* est lancé. Le BLoC traite cet événement, communique avec les API ou le hardware, et émet un nouvel *State* (État) pour mettre à jour l'interface (UI).
2.  **Le ML Kit (100% Local) :** Contrairement à une API classique, toutes les fonctionnalités de reconnaissance d'image et de texte (Vision & NLP) tournent directement sur le processeur du téléphone. Les images ne quittent jamais l'appareil, garantissant la confidentialité et une vitesse maximale même sans réseau.
3.  **Communication avec le Backend :**
    *   Lorsque l'utilisateur interagit avec l'IA Générative, le téléphone envoie une requête HTTP (via des classes *Services* et des bibliothèques comme `http` ou `dio`) au backend Django.
    *   Le backend traite la demande via Ollama ou Gemini, puis renvoie la réponse au format JSON, que Flutter affiche dans l'interface de chat sous forme de bulle.
4.  **Matériel Natif :** Le `AndroidManifest.xml` (Android) et le `Info.plist` (iOS) ont été configurés pour accorder à l'application l'accès aux permissions "Caméra", "Microphone", et "Localisation".
