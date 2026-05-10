from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import joblib
import pandas as pd
import os

app = FastAPI(title="Waste Classification API", description="API pour la prédiction de la catégorie des déchets", version="1.0")

# Chemin vers le modèle (depuis le dossier backend vers le dossier notebooks)
MODEL_PATH = os.path.join(os.path.dirname(__file__), "..", "notebooks", "multimodal_model.pkl")

# Chargement du modèle au démarrage
try:
    model = joblib.load(MODEL_PATH)
    print("Modèle chargé avec succès !")
except Exception as e:
    model = None
    print(f"Erreur lors du chargement du modèle : {e}")

# Définition du schéma des données d'entrée
class WasteData(BaseModel):
    Rapport_Collecte: str
    Poids: float
    Volume: float
    Conductivite: float
    Opacite: float
    Rigidite: float
    Source_Centre_Tri: float
    Source_Collecte_Citoyenne: float
    Source_Usine_A: float
    Source_Usine_B: float
    Source_nan: float
    Densite: float
    Cond_Opacite_Ratio: float
    Log_Volume: float

@app.get("/")
def read_root():
    return {"message": "Bienvenue sur l'API de classification Multimodale"}

@app.post("/predict")
def predict(data: WasteData):
    if model is None:
        raise HTTPException(status_code=500, detail="Modèle non chargé sur le serveur.")
    
    # Convertir les données entrantes en DataFrame (format attendu par sklearn)
    input_data = pd.DataFrame([data.model_dump()])
    
    try:
        # Faire la prédiction
        prediction = model.predict(input_data)
        return {
            "prediction": str(prediction[0])
        }
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
