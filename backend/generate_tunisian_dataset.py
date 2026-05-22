import json
import os
import random

import numpy as np
import pandas as pd
import requests
from tqdm import tqdm

# --- 1. CONFIGURATION DES DONNÉES TUNISIENNES ---
VILLES = ["Tunis", "Sfax", "Sousse", "Bizerte", "Nabeul", "Monastir", "Gafsa", "Gabès"]
ZONES = ["médina", "zone industrielle", "cité résidentielle", "zone côtière"]

COORDONNEES_VILLES = {
    "Tunis": (36.8065, 10.1815),
    "Sfax": (34.7406, 10.7603),
    "Sousse": (35.8256, 10.6369),
    "Bizerte": (37.2744, 9.8739),
    "Nabeul": (36.4561, 10.7376),
    "Monastir": (35.7780, 10.8262),
    "Gafsa": (34.4250, 8.7842),
    "Gabès": (33.8815, 10.0982),
}

# 3 entreprises réalistes par ville (traitement des déchets, plastique, verre, etc.)
ENTREPRISES_PAR_VILLE = {
    "Tunis": ["SOTUVER (Verre)", "Tunisie Recyclage", "EcoPact"],
    "Sfax": ["Sfax Plast", "SOTUBI", "Recyclage Sud"],
    "Sousse": ["Sousse Éco", "Plastik M", "Metalica Sousse"],
    "Bizerte": ["Bizerte Recup", "Eco Bizerte", "Ferraille Nord"],
    "Nabeul": ["Nabeul Vert", "Cap Bon Recyclage", "SOTUF"],
    "Monastir": ["Monastir Plast", "MonaRecycle", "Textile Eco"],
    "Gafsa": ["Phosphate Eco", "Sud Metal", "Oasis Recyclage"],
    "Gabès": ["Chimie Eco Gabès", "Gabès Recup", "Plast Sud"],
}

SOURCES_BASE = [
    "déchetterie municipale",
    "collecte informelle (barbecha)",
    "entreprise",
    "ménage",
]

# Prix réels approximatifs en TND par kg
PRIX_TND_AU_KG = {
    "Plastique": 1.200,
    "Papier": 0.400,
    "Carton": 0.600,
    "Verre": 0.050,
    "Metal": 2.500,
    "Electronique": 5.000,
}


def generer_donnees_de_base(input_csv, output_csv):
    print(f"Chargement du dataset {input_csv}...")
    df = pd.read_csv(input_csv)

    villes_list = []
    zones_list = []
    sources_list = []
    lats = []
    lons = []
    prix_tnd = []

    for idx, row in df.iterrows():
        # Choix de la ville et zone
        ville = random.choice(VILLES)
        zone = random.choice(ZONES)

        # Génération des coordonnées avec un léger bruit pour simuler des quartiers différents
        base_lat, base_lon = COORDONNEES_VILLES[ville]
        lat = base_lat + np.random.uniform(-0.02, 0.02)
        lon = base_lon + np.random.uniform(-0.02, 0.02)

        # Choix de la source, si 'entreprise', on prend une des boites de la ville
        source_type = random.choice(SOURCES_BASE)
        if source_type == "entreprise":
            source = random.choice(ENTREPRISES_PAR_VILLE[ville])
        else:
            source = source_type

        # Calcul du prix
        cat = row.get("Categorie", "Plastique")
        poids = row.get("Poids")
        if pd.isna(poids):
            poids = np.random.uniform(5, 50)

        prix_base = PRIX_TND_AU_KG.get(cat, 0.5)
        # Variation de 20% pour le réalisme (négociations, qualité...)
        variation = np.random.uniform(0.8, 1.2)
        prix_final = poids * prix_base * variation

        villes_list.append(ville)
        zones_list.append(zone)
        sources_list.append(source)
        lats.append(round(lat, 6))
        lons.append(round(lon, 6))
        prix_tnd.append(round(prix_final, 3))

    df["Ville"] = villes_list
    df["Zone"] = zones_list
    df["Latitude"] = lats
    df["Longitude"] = lons
    df["Source"] = sources_list
    df["Prix_Revente_TND"] = prix_tnd
    df = df.drop(columns=["Prix_Revente"], errors="ignore")

    print("Sauvegarde du dataset de base tunisifié...")
    df.to_csv(output_csv, index=False)
    return df


if __name__ == "__main__":
    input_file = "dataset_ProjetML_2026.csv"
    base_tunisia_file = "dataset_tunisified_base.csv"

    if os.path.exists(input_file):
        df_base = generer_donnees_de_base(input_file, base_tunisia_file)
    else:
        print(f"Erreur: {input_file} introuvable dans le répertoire courant.")
