from fastapi.testclient import TestClient

import api_inference

client = TestClient(api_inference.app)


def test_read_root():
    response = client.get("/")
    assert response.status_code == 200
    assert response.json().get("service") == "Eco-Smart Classifier API"


def test_predict_returns_503_when_model_missing(monkeypatch):
    monkeypatch.setattr(api_inference, "model", None)

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
        "Log_Volume": 2.56,
    }

    response = client.post("/predict", json=sample_data)

    assert response.status_code == 503
    assert response.json().get("detail")


def test_predict_returns_prediction_when_model_available(monkeypatch):
    class _DummyModel:
        def predict(self, X):
            return ["Papier"]

    monkeypatch.setattr(api_inference, "model", _DummyModel())

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
        "Log_Volume": 2.56,
    }

    response = client.post("/predict", json=sample_data)
    assert response.status_code == 200
    payload = response.json()
    assert payload.get("prediction") == "Papier"


def test_predict_returns_predicted_price_from_regression_model(monkeypatch):
    """Vérifie que predicted_price provient du modèle de régression quand il est disponible."""

    class _DummyClf:
        def predict(self, X):
            return ["Plastique"]

    class _DummyReg:
        def predict(self, X):
            return [42.5]

    monkeypatch.setattr(api_inference, "model", _DummyClf())
    monkeypatch.setattr(api_inference, "regression_model", _DummyReg())

    sample_data = {
        "Rapport_Collecte": "Plastique mélangé",
        "Poids": 10.0,
        "Volume": 5.0,
        "Conductivite": 0.1,
        "Opacite": 0.8,
        "Rigidite": 0.3,
    }

    response = client.post("/predict", json=sample_data)
    assert response.status_code == 200
    payload = response.json()
    assert payload.get("predicted_price") == 42.5
    assert payload.get("prediction") == "Plastique"


def test_predict_returns_fallback_price_when_no_regression_model(monkeypatch):
    """Vérifie le fallback heuristique du prix quand le régresseur est absent."""

    class _DummyClf:
        def predict(self, X):
            return ["Métal"]

    monkeypatch.setattr(api_inference, "model", _DummyClf())
    monkeypatch.setattr(api_inference, "regression_model", None)

    sample_data = {
        "Rapport_Collecte": "Lot de ferraille",
        "Poids": 10.0,
        "Volume": 3.0,
        "Conductivite": 8.0,
        "Opacite": 0.2,
        "Rigidite": 9.0,
    }

    response = client.post("/predict", json=sample_data)
    assert response.status_code == 200
    payload = response.json()
    # Fallback: Métal = 2.5 TND/kg * 10 kg = 25.0
    assert payload.get("predicted_price") == 25.0
