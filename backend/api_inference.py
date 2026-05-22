from __future__ import annotations

import os
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import joblib
import numpy as np
import pandas as pd
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

# ══════════════════════════════════════════════════════════════
# Application FastAPI
# ══════════════════════════════════════════════════════════════
app = FastAPI(
    title="Eco-Smart Classifier API",
    description=(
        "API de classification multimodale des déchets.\n\n"
        "Prédit la **catégorie** (Plastique, Verre, Métal, Papier) "
        "et le **prix de revente** estimé à partir de mesures physiques "
        "et d'un rapport textuel."
    ),
    version="1.1.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

# ── CORS (autorise les appels depuis Flutter Web, localhost, etc.) ──
app.add_middleware(
    CORSMiddleware,
    allow_origins=os.getenv(
        "CORS_ORIGINS",
        "*",
    ).split(","),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ══════════════════════════════════════════════════════════════
# Chargement du modèle
# ══════════════════════════════════════════════════════════════

# Chemin vers les modèles (override possible via variables d'environnement)
DEFAULT_MODEL_PATH = os.path.join(
    os.path.dirname(__file__), "..", "notebooks", "multimodal_model.pkl"
)
MODEL_PATH = os.environ.get("MODEL_PATH", DEFAULT_MODEL_PATH)

DEFAULT_REG_MODEL_PATH = os.path.join(
    os.path.dirname(__file__), "..", "notebooks", "regression_model.pkl"
)
REG_MODEL_PATH = os.environ.get("REG_MODEL_PATH", DEFAULT_REG_MODEL_PATH)

# Chargement du modèle de classification au démarrage
_startup_time = time.time()
try:
    if not os.path.exists(MODEL_PATH):
        raise FileNotFoundError(f"Modèle de classification introuvable: {MODEL_PATH}")
    model = joblib.load(MODEL_PATH)
    print(f"✅ Modèle de classification chargé avec succès depuis: {MODEL_PATH}")
except Exception as e:
    model = None
    print(f"⚠️  Erreur lors du chargement du modèle de classification : {e}")

# Chargement du modèle de régression au démarrage
try:
    if not os.path.exists(REG_MODEL_PATH):
        raise FileNotFoundError(f"Modèle de régression introuvable: {REG_MODEL_PATH}")
    regression_model = joblib.load(REG_MODEL_PATH)
    print(f"✅ Modèle de régression chargé avec succès depuis: {REG_MODEL_PATH}")
except Exception as e:
    regression_model = None
    print(f"⚠️  Erreur lors du chargement du modèle de régression : {e}")


TEXT_COL = "Rapport_Collecte"
NUM_COLS = [
    "Poids",
    "Volume",
    "Conductivite",
    "Opacite",
    "Rigidite",
    "Source_Centre_Tri",
    "Source_Collecte_Citoyenne",
    "Source_Usine_A",
    "Source_Usine_B",
    "Source_nan",
    "Densite",
    "Cond_Opacite_Ratio",
    "Log_Volume",
]

SOURCE_MAP = {
    "Centre_Tri": "Source_Centre_Tri",
    "Collecte_Citoyenne": "Source_Collecte_Citoyenne",
    "Usine_A": "Source_Usine_A",
    "Usine_B": "Source_Usine_B",
}


@dataclass(frozen=True)
class _PreprocessStats:
    medians: dict[str, float]
    scaler_mean: dict[str, float]
    scaler_scale: dict[str, float]


_STATS: _PreprocessStats | None = None


def _cap_outliers_iqr_series(values: pd.Series) -> pd.Series:
    q1 = values.quantile(0.25)
    q3 = values.quantile(0.75)
    iqr = q3 - q1
    lower = q1 - 1.5 * iqr
    upper = q3 + 1.5 * iqr
    return values.clip(lower=lower, upper=upper)


def _load_preprocess_stats() -> _PreprocessStats | None:
    global _STATS
    if _STATS is not None:
        return _STATS

    # Chemin configurable via DATASET_PATH (pour Cloud Run)
    dataset_path_env = os.environ.get("DATASET_PATH")
    if dataset_path_env:
        dataset_path = Path(dataset_path_env)
    else:
        dataset_path = Path(__file__).resolve().parent / "dataset_ProjetML_2026.csv"

    if not dataset_path.exists():
        print(f"⚠️  Dataset introuvable: {dataset_path}")
        return None

    try:
        df = pd.read_csv(dataset_path)
        df = df.drop_duplicates()

        base_numeric = ["Poids", "Volume", "Conductivite", "Opacite", "Rigidite"]
        for col in base_numeric + ["Prix_Revente"]:
            if col in df.columns:
                df[col] = pd.to_numeric(df[col], errors="coerce")

        medians: dict[str, float] = {}
        for col in base_numeric:
            if col in df.columns:
                medians[col] = float(df[col].median())

        for col in base_numeric:
            if col in df.columns:
                df[col] = df[col].fillna(medians[col])
                df[col] = _cap_outliers_iqr_series(df[col])

        for col in [
            "Source_Centre_Tri",
            "Source_Collecte_Citoyenne",
            "Source_Usine_A",
            "Source_Usine_B",
            "Source_nan",
        ]:
            df[col] = 0.0
        if "Source" in df.columns:
            src = df["Source"].fillna("").astype(str)
            known = {"Centre_Tri", "Collecte_Citoyenne", "Usine_A", "Usine_B"}
            for k in known:
                df[f"Source_{k}"] = (src.str.strip() == k).astype(float)
            df["Source_nan"] = (~src.str.strip().isin(known)).astype(float)
        else:
            df["Source_nan"] = 1.0

        df["Densite"] = df["Poids"] / df["Volume"].replace(0, np.nan)
        df["Cond_Opacite_Ratio"] = df["Conductivite"] / df["Opacite"].replace(0, np.nan)
        df["Log_Volume"] = np.log1p(df["Volume"])

        for col in ["Densite", "Cond_Opacite_Ratio", "Log_Volume"]:
            df[col] = df[col].replace([np.inf, -np.inf], np.nan)
            medians[col] = float(df[col].median())
            df[col] = df[col].fillna(medians[col])
            df[col] = _cap_outliers_iqr_series(df[col])

        mat = df[NUM_COLS].astype(float)
        mean = mat.mean(axis=0)
        std = mat.std(axis=0, ddof=0).replace(0, 1.0)

        _STATS = _PreprocessStats(
            medians=medians,
            scaler_mean={k: float(v) for k, v in mean.to_dict().items()},
            scaler_scale={k: float(v) for k, v in std.to_dict().items()},
        )
        print("✅ Stats de prétraitement chargées avec succès")
        return _STATS
    except Exception as exc:
        print(f"⚠️  Erreur chargement stats: {exc}")
        return None


# ══════════════════════════════════════════════════════════════
# Schéma Pydantic
# ══════════════════════════════════════════════════════════════


class WasteData(BaseModel):
    """Données d'entrée pour la prédiction de classification des déchets."""

    Rapport_Collecte: str
    Poids: float
    Volume: float
    Conductivite: float
    Opacite: float
    Rigidite: float
    Source: str | None = None
    Source_Centre_Tri: float | None = None
    Source_Collecte_Citoyenne: float | None = None
    Source_Usine_A: float | None = None
    Source_Usine_B: float | None = None
    Source_nan: float | None = None
    Densite: float | None = None
    Cond_Opacite_Ratio: float | None = None
    Log_Volume: float | None = None
    preprocessed: bool = False


# ══════════════════════════════════════════════════════════════
# Endpoints
# ══════════════════════════════════════════════════════════════


@app.get("/", tags=["Info"])
def read_root():
    """Page d'accueil de l'API."""
    return {
        "service": "Eco-Smart Classifier API",
        "version": "1.1.0",
        "status": "running",
        "docs": "/docs",
        "endpoints": {
            "predict": "POST /predict",
            "health": "GET /health",
            "docs": "GET /docs",
        },
    }


@app.get("/health", tags=["Info"])
def health_check():
    """Health check endpoint pour Cloud Run et monitoring."""
    uptime = round(time.time() - _startup_time, 1)
    return {
        "status": "healthy" if model is not None else "degraded",
        "model_loaded": model is not None,
        "model_path": MODEL_PATH,
        "uptime_seconds": uptime,
    }


@app.post("/predict", tags=["Prediction"])
def predict(data: WasteData):
    """
    Prédiction de la catégorie et du prix de revente d'un déchet.

    Accepte les mesures physiques brutes et/ou un rapport textuel.
    Le prétraitement (feature engineering, normalisation) est appliqué
    automatiquement si `preprocessed=false` (défaut).
    """
    if model is None:
        raise HTTPException(status_code=503, detail="Modèle non chargé sur le serveur.")

    payload: dict[str, Any] = data.model_dump()
    stats = _load_preprocess_stats()

    source_cols = [
        "Source_Centre_Tri",
        "Source_Collecte_Citoyenne",
        "Source_Usine_A",
        "Source_Usine_B",
        "Source_nan",
    ]
    if all(payload.get(c) is None for c in source_cols):
        src = str(payload.get("Source") or "")
        normalized = src.lower().replace("_", " ")
        encoded = {c: 0.0 for c in source_cols}
        matched = False
        for key, col in SOURCE_MAP.items():
            if key.lower().replace("_", " ") in normalized:
                encoded[col] = 1.0
                matched = True
                break
        if not matched:
            encoded["Source_nan"] = 1.0
        payload.update(encoded)
    else:
        for c in source_cols:
            payload[c] = float(payload.get(c) or 0.0)

    poids = float(payload.get("Poids"))
    volume = float(payload.get("Volume"))
    conductivite = float(payload.get("Conductivite"))
    opacite = float(payload.get("Opacite"))

    if payload.get("Densite") is None:
        payload["Densite"] = (
            poids / volume
            if volume > 0
            else (stats.medians.get("Densite", 0.0) if stats else 0.0)
        )
    if payload.get("Cond_Opacite_Ratio") is None:
        payload["Cond_Opacite_Ratio"] = (
            conductivite / opacite
            if opacite > 0
            else (stats.medians.get("Cond_Opacite_Ratio", 0.0) if stats else 0.0)
        )
    if payload.get("Log_Volume") is None:
        payload["Log_Volume"] = (
            float(np.log1p(volume))
            if volume >= 0
            else (stats.medians.get("Log_Volume", 0.0) if stats else 0.0)
        )

    input_row = {TEXT_COL: payload.get(TEXT_COL, "")}
    for col in NUM_COLS:
        input_row[col] = float(payload.get(col) or 0.0)
    input_data = pd.DataFrame([input_row])[[TEXT_COL] + NUM_COLS]

    if not data.preprocessed and stats is not None:
        for col in NUM_COLS:
            mu = stats.scaler_mean.get(col)
            sigma = stats.scaler_scale.get(col)
            if mu is None or sigma is None:
                continue
            input_data[col] = (input_data[col].astype(float) - mu) / (
                sigma if sigma != 0 else 1.0
            )

    try:
        # Faire la prédiction de classification
        prediction = model.predict(input_data)
        category_pred = str(prediction[0])

        response: dict[str, Any] = {
            "prediction": category_pred,
            "category": category_pred,
            "prediction_method": "ml_model",
            "model": "eco-smart-multimodal",
        }

        # Faire la prédiction du prix de revente
        if regression_model is not None:
            try:
                price_pred = float(regression_model.predict(input_data)[0])
                response["predicted_price"] = round(max(0.01, price_pred), 3)
            except Exception:
                response["predicted_price"] = None
        else:
            # Fallback heuristique basé sur la catégorie et le poids
            p_coefs = {
                "Plastique": 1.200,
                "Papier": 0.400,
                "Carton": 0.600,
                "Verre": 0.050,
                "Métal": 2.500,
                "Metal": 2.500,
                "Mixte": 0.200,
            }
            base_coef = p_coefs.get(category_pred, 0.5)
            w_val = max(0.1, poids)
            response["predicted_price"] = round(w_val * base_coef, 3)

        if hasattr(model, "predict_proba"):
            try:
                proba = model.predict_proba(input_data)
                if isinstance(proba, (list, tuple)):
                    proba = np.asarray(proba)
                response["confidence"] = float(np.max(proba))
            except Exception:
                pass

        return response
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
