from fastapi.testclient import TestClient
from api_inference import app

client = TestClient(app)

def test_read_root():
    response = client.get("/")
    assert response.status_code == 200
    assert response.json() == {"message": "Bienvenue sur l'API de classification Multimodale"}

def test_predict_valid_data():
    sample_data = {
        "Rapport_Collecte": "Lot de cartons et papiers recyclables",
        "Poids": 150.5,
        "Volume": 12.0,
        "Conductivite": 0.05,
        "Opacite": 0.9,
        "Rigidite": 0.4,
        "Source_Centre_Tri": 1.0,
        "Source_Collecte_Citoyenne": 0.0,
        "Source_Usine_A": 0.0,
        "Source_Usine_B": 0.0,
        "Source_nan": 0.0,
        "Densite": 12.54,
        "Cond_Opacite_Ratio": 0.055,
        "Log_Volume": 2.56
    }
    
    response = client.post("/predict", json=sample_data)
    
    assert response.status_code == 200
    assert "prediction" in response.json()
