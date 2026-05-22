import logging
import math
import os
import random
import re
import unicodedata
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Optional, Tuple

import numpy as np
import pandas as pd

logger = logging.getLogger(__name__)


_KEYWORD_VECTORIZER = None
_KEYWORD_VECTORIZER_ERROR: str | None = None


_STOP_WORDS_FR_TN = {
    "avec",
    "sans",
    "dans",
    "pour",
    "par",
    "plus",
    "moins",
    "tres",
    "trop",
    "mais",
    "pas",
    "comme",
    "cette",
    "cela",
    "celui",
    "celle",
    "leurs",
    "leur",
    "dont",
    "alors",
    "ainsi",
    "apres",
    "avant",
    "entre",
    "dechets",
    "dechet",
    "rapport",
    "collecte",
    "presence",
    "khorda",
    "barbecha",
    "barcha",
    "behi",
    "lot",
    "matiere",
    "materiau",
    "poids",
    "volume",
    "aspect",
    "etat",
    "non",
    "aucune",
    "trace",
    "observée",
    "observee",
}


_TUNISIFY_MAP = {
    "khorda": "dechets",
    "barbecha": "collecte informelle",
    "barbechaï": "collecte informelle",
    "barcha": "beaucoup",
    "behi": "bon",
    "mouch": "pas",
    "mouchi": "pas",
    "yesser": "tres",
    "yaser": "tres",
    "chwaya": "peu",
    "chwiya": "peu",
    "mey": "eau",
    "ma": "eau",
    "7did": "metal",
    "7didha": "metal",
    "plastik": "plastique",
    "karto": "carton",
    "kartan": "carton",
    "wrak": "papier",
    "wara9": "papier",
    "zjaj": "verre",
    "zjaja": "verre",
    "metal": "metal",
}


def _strip_accents(text: str) -> str:
    normalized = unicodedata.normalize("NFD", text)
    return "".join(ch for ch in normalized if unicodedata.category(ch) != "Mn")


def normalize_tunisified_text(text: str) -> str:
    if not text:
        return ""

    lowered = text.lower()
    lowered = lowered.replace("’", "'").replace("`", "'")
    lowered = re.sub(r"\s+", " ", lowered).strip()

    base = _strip_accents(lowered)
    base = re.sub(r"[^a-z0-9\s\-']+", " ", base)
    base = re.sub(r"\s+", " ", base).strip()

    tokens = base.split(" ")
    out_tokens: list[str] = []
    for tok in tokens:
        if not tok:
            continue
        mapped = _TUNISIFY_MAP.get(tok)
        if mapped:
            out_tokens.extend(mapped.split(" "))
        else:
            out_tokens.append(tok)

    return " ".join(out_tokens)


def correct_tunisified_text_pretty(text: str) -> str:
    if not text:
        return ""
    corrected = text
    for src in sorted(_TUNISIFY_MAP.keys(), key=len, reverse=True):
        dst = _TUNISIFY_MAP[src]
        corrected = re.sub(
            rf"\b{re.escape(src)}\b", dst, corrected, flags=re.IGNORECASE
        )
    corrected = re.sub(r"\s+", " ", corrected).strip()
    return corrected


def _load_keyword_vectorizer():
    global _KEYWORD_VECTORIZER, _KEYWORD_VECTORIZER_ERROR
    if _KEYWORD_VECTORIZER is not None or _KEYWORD_VECTORIZER_ERROR is not None:
        return _KEYWORD_VECTORIZER

    try:
        from sklearn.feature_extraction.text import TfidfVectorizer

        dataset_path = (
            Path(__file__).resolve().parents[2] / "dataset_tunisified_base.csv"
        )
        if not dataset_path.exists():
            _KEYWORD_VECTORIZER_ERROR = f"Dataset introuvable: {dataset_path}"
            return None

        df = pd.read_csv(dataset_path, usecols=["Rapport_Collecte"])
        corpus_raw = df["Rapport_Collecte"].dropna().astype(str).tolist()
        if not corpus_raw:
            _KEYWORD_VECTORIZER_ERROR = "Corpus vide"
            return None

        corpus = [normalize_tunisified_text(t) for t in corpus_raw[:8000]]

        _KEYWORD_VECTORIZER = TfidfVectorizer(
            ngram_range=(1, 2),
            max_features=6000,
            min_df=2,
            token_pattern=r"(?u)\b[a-z][a-z0-9']+\b",
        )
        _KEYWORD_VECTORIZER.fit(corpus)
        return _KEYWORD_VECTORIZER
    except Exception as exc:
        _KEYWORD_VECTORIZER_ERROR = str(exc)
        return None


# ──────────────────────────────────────────────
# Chargement des modèles ML (PKL)
# ──────────────────────────────────────────────
_MODEL = None
_MODEL_LOAD_ERROR = None

_REG_MODEL = None
_REG_MODEL_LOAD_ERROR = None

_SCALER_MODEL = None
_SCALER_MODEL_LOAD_ERROR = None

_KMEANS_MODEL = None
_KMEANS_MODEL_LOAD_ERROR = None

_PCA_MODEL = None
_PCA_MODEL_LOAD_ERROR = None


@dataclass(frozen=True)
class _PreprocessStats:
    medians: dict[str, float]
    scaler_mean: dict[str, float]
    scaler_scale: dict[str, float]


_STATS: _PreprocessStats | None = None
_STATS_LOAD_ERROR: str | None = None


def _load_model():
    global _MODEL, _MODEL_LOAD_ERROR
    if _MODEL is not None:
        return _MODEL
    candidate_paths = [
        Path(__file__).resolve().parents[3] / "notebooks" / "multimodal_model.pkl",
        (
            Path(os.environ.get("MODEL_PATH", ""))
            if os.environ.get("MODEL_PATH")
            else None
        ),
    ]
    for path in candidate_paths:
        if path and path.exists():
            try:
                import joblib

                _MODEL = joblib.load(path)
                logger.info(f"Modèle multimodal chargé depuis {path}")
                return _MODEL
            except Exception as exc:
                _MODEL_LOAD_ERROR = str(exc)
                logger.warning(f"Impossible de charger le modèle depuis {path}: {exc}")
    logger.warning(
        "Modèle multimodal non disponible — fallback sur les règles heuristiques."
    )
    return None


def _load_regression_model():
    global _REG_MODEL, _REG_MODEL_LOAD_ERROR
    if _REG_MODEL is not None:
        return _REG_MODEL
    candidate_paths = [
        Path(__file__).resolve().parents[3] / "notebooks" / "regression_model.pkl",
        (
            Path(os.environ.get("REG_MODEL_PATH", ""))
            if os.environ.get("REG_MODEL_PATH")
            else None
        ),
    ]
    for path in candidate_paths:
        if path and path.exists():
            try:
                import joblib

                _REG_MODEL = joblib.load(path)
                logger.info(f"Modèle de régression chargé depuis {path}")
                return _REG_MODEL
            except Exception as exc:
                _REG_MODEL_LOAD_ERROR = str(exc)
                logger.warning(
                    f"Impossible de charger le modèle de régression depuis {path}: {exc}"
                )
    return None


def _load_scaler_model():
    global _SCALER_MODEL, _SCALER_MODEL_LOAD_ERROR
    if _SCALER_MODEL is not None:
        return _SCALER_MODEL
    candidate_paths = [
        Path(__file__).resolve().parents[3] / "notebooks" / "scaler_model.pkl",
        (
            Path(os.environ.get("SCALER_MODEL_PATH", ""))
            if os.environ.get("SCALER_MODEL_PATH")
            else None
        ),
    ]
    for path in candidate_paths:
        if path and path.exists():
            try:
                import joblib

                _SCALER_MODEL = joblib.load(path)
                logger.info(f"Modèle Scaler chargé depuis {path}")
                return _SCALER_MODEL
            except Exception as exc:
                _SCALER_MODEL_LOAD_ERROR = str(exc)
                logger.warning(
                    f"Impossible de charger le modèle Scaler depuis {path}: {exc}"
                )
    return None


def _load_kmeans_model():
    global _KMEANS_MODEL, _KMEANS_MODEL_LOAD_ERROR
    if _KMEANS_MODEL is not None:
        return _KMEANS_MODEL
    candidate_paths = [
        Path(__file__).resolve().parents[3] / "notebooks" / "kmeans_model.pkl",
        (
            Path(os.environ.get("KMEANS_MODEL_PATH", ""))
            if os.environ.get("KMEANS_MODEL_PATH")
            else None
        ),
    ]
    for path in candidate_paths:
        if path and path.exists():
            try:
                import joblib

                _KMEANS_MODEL = joblib.load(path)
                logger.info(f"Modèle K-Means chargé depuis {path}")
                return _KMEANS_MODEL
            except Exception as exc:
                _KMEANS_MODEL_LOAD_ERROR = str(exc)
                logger.warning(
                    f"Impossible de charger le modèle K-Means depuis {path}: {exc}"
                )
    return None


def _load_pca_model():
    global _PCA_MODEL, _PCA_MODEL_LOAD_ERROR
    if _PCA_MODEL is not None:
        return _PCA_MODEL
    candidate_paths = [
        Path(__file__).resolve().parents[3] / "notebooks" / "pca_model.pkl",
        (
            Path(os.environ.get("PCA_MODEL_PATH", ""))
            if os.environ.get("PCA_MODEL_PATH")
            else None
        ),
    ]
    for path in candidate_paths:
        if path and path.exists():
            try:
                import joblib

                _PCA_MODEL = joblib.load(path)
                logger.info(f"Modèle PCA chargé depuis {path}")
                return _PCA_MODEL
            except Exception as exc:
                _PCA_MODEL_LOAD_ERROR = str(exc)
                logger.warning(
                    f"Impossible de charger le modèle PCA depuis {path}: {exc}"
                )
    return None


# Tenter le chargement au démarrage
_load_model()
_load_regression_model()
_load_scaler_model()
_load_kmeans_model()
_load_pca_model()


def _cap_outliers_iqr_series(values: pd.Series) -> pd.Series:
    q1 = values.quantile(0.25)
    q3 = values.quantile(0.75)
    iqr = q3 - q1
    lower = q1 - 1.5 * iqr
    upper = q3 + 1.5 * iqr
    return values.clip(lower=lower, upper=upper)


def _load_preprocess_stats() -> _PreprocessStats | None:
    global _STATS, _STATS_LOAD_ERROR
    if _STATS is not None:
        return _STATS

    try:
        dataset_path = Path(__file__).resolve().parents[2] / "dataset_ProjetML_2026.csv"
        if not dataset_path.exists():
            logger.warning(
                "Dataset brut introuvable (%s); pas de standardisation en inférence.",
                dataset_path,
            )
            return None

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

        feature_cols = NUM_COLS
        mat = df[feature_cols].astype(float)
        mean = mat.mean(axis=0)
        std = mat.std(axis=0, ddof=0).replace(0, 1.0)

        _STATS = _PreprocessStats(
            medians=medians,
            scaler_mean={k: float(v) for k, v in mean.to_dict().items()},
            scaler_scale={k: float(v) for k, v in std.to_dict().items()},
        )
        logger.info(
            "Stats de prétraitement chargées pour standardisation en inférence."
        )
        return _STATS
    except Exception as exc:
        _STATS_LOAD_ERROR = str(exc)
        logger.warning("Impossible de charger les stats de prétraitement: %s", exc)
        return None


# ──────────────────────────────────────────────
# Colonnes attendues par le modèle PKL
# (correspondant aux colonnes produites par preprocess_data.py)
# ──────────────────────────────────────────────
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


def _build_feature_row(data: Dict) -> pd.DataFrame:
    """Construit un DataFrame à une ligne compatible avec le pipeline ColumnTransformer."""
    stats = _load_preprocess_stats()

    def _fallback_median(col: str, default: float) -> float:
        if stats is None:
            return default
        return float(stats.medians.get(col, default))

    poids = float(
        data.get("poids")
        if data.get("poids") is not None
        else _fallback_median("Poids", 5.0)
    )
    volume = float(
        data.get("volume")
        if data.get("volume") is not None
        else _fallback_median("Volume", 1.0)
    )
    conductivite = float(
        data.get("conductivite")
        if data.get("conductivite") is not None
        else _fallback_median("Conductivite", 0.0)
    )
    opacite = float(
        data.get("opacite")
        if data.get("opacite") is not None
        else _fallback_median("Opacite", 0.5)
    )
    rigidite = float(
        data.get("rigidite")
        if data.get("rigidite") is not None
        else _fallback_median("Rigidite", 0.0)
    )
    rapport_raw = str(data.get("rapport_collecte") or "")
    rapport = normalize_tunisified_text(rapport_raw)
    source_raw = str(data.get("source") or "")

    # Encodage one-hot de la source
    source_row = {
        col: 0.0
        for col in [
            "Source_Centre_Tri",
            "Source_Collecte_Citoyenne",
            "Source_Usine_A",
            "Source_Usine_B",
            "Source_nan",
        ]
    }
    matched = False
    normalized_source = source_raw.lower().replace("_", " ")
    for key, col in SOURCE_MAP.items():
        if key.lower().replace("_", " ") in normalized_source:
            source_row[col] = 1.0
            matched = True
            break
    if not matched:
        source_row["Source_nan"] = 1.0

    # Features dérivées (mêmes que dans preprocess_data.py)
    densite = poids / volume if volume > 0 else _fallback_median("Densite", 0.0)
    cond_opacite = (
        conductivite / opacite
        if opacite > 0
        else _fallback_median("Cond_Opacite_Ratio", 0.0)
    )
    log_volume = (
        float(np.log1p(volume)) if volume >= 0 else _fallback_median("Log_Volume", 0.0)
    )

    row = {
        TEXT_COL: rapport,
        "Poids": poids,
        "Volume": volume,
        "Conductivite": conductivite,
        "Opacite": opacite,
        "Rigidite": rigidite,
        **source_row,
        "Densite": densite,
        "Cond_Opacite_Ratio": cond_opacite,
        "Log_Volume": log_volume,
    }
    frame = pd.DataFrame([row])[[TEXT_COL] + NUM_COLS]

    if stats is not None:
        for col in NUM_COLS:
            mu = stats.scaler_mean.get(col)
            sigma = stats.scaler_scale.get(col)
            if mu is None or sigma is None:
                continue
            frame[col] = (frame[col].astype(float) - mu) / (
                sigma if sigma != 0 else 1.0
            )

    return frame


# ──────────────────────────────────────────────
# Données géographiques tunisiennes
# ──────────────────────────────────────────────
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

PRIX_TND_AU_KG = {
    "Plastique": 1.200,
    "Papier": 0.400,
    "Carton": 0.600,
    "Verre": 0.050,
    "Métal": 2.500,
    "Metal": 2.500,
    "Electronique": 5.000,
    "Organique": 0.100,
    "Mixte": 0.200,
}


# ──────────────────────────────────────────────
# Heuristiques de fallback (utilisées si modèle absent)
# ──────────────────────────────────────────────
def _parse_text(text: str) -> str:
    return (text or "").lower()


def _infer_category_heuristic(report: str, conductivite: float, rigidite: float) -> str:
    """Règles heuristiques de secours si le modèle PKL n'est pas disponible."""
    text = _parse_text(report)
    if "plastique" in text or "khalta" in text:
        return "Plastique"
    if "verre" in text or "belar" in text:
        return "Verre"
    if any(w in text for w in ["metal", "acier", "alu", "hdid", "métal"]):
        return "Métal"
    if any(w in text for w in ["papier", "carton", "kardhoun"]):
        return "Papier"
    if conductivite > 7 or rigidite > 7:
        return "Métal"
    if conductivite < 1 and rigidite < 4:
        return "Plastique"
    return "Mixte"


# ──────────────────────────────────────────────
# Fonctions métier
# ──────────────────────────────────────────────
def infer_category(
    report: str,
    conductivite: float,
    rigidite: float,
    feature_row: Optional[pd.DataFrame] = None,
) -> Tuple[str, float, str]:
    """
    Retourne (category, confidence, method).
    Utilise le modèle ML si disponible, sinon les heuristiques.
    """
    model = _load_model()
    if model is not None and feature_row is not None:
        try:
            pred = model.predict(feature_row)[0]
            # Confiance via predict_proba si disponible
            try:
                proba = model.predict_proba(feature_row)[0]
                confidence = float(np.max(proba))
            except AttributeError:
                confidence = 0.92  # RandomForest sans proba exposée
            return str(pred), confidence, "ml_model"
        except Exception as exc:
            logger.warning(f"Prédiction ML échouée, fallback heuristique: {exc}")

    # Fallback heuristique
    category = _infer_category_heuristic(report, conductivite, rigidite)
    confidence = _infer_confidence_heuristic(report, conductivite, rigidite)
    return category, confidence, "heuristic"


def _infer_confidence_heuristic(
    report: str, conductivite: float, rigidite: float
) -> float:
    score = 0.45
    text = _parse_text(report)
    if any(
        w in text
        for w in [
            "plastique",
            "verre",
            "metal",
            "papier",
            "organique",
            "kardhoun",
            "hdid",
            "belar",
            "métal",
        ]
    ):
        score += 0.25
    if conductivite > 6 or rigidite > 6:
        score += 0.15
    if len(report or "") > 60:
        score += 0.05
    return float(min(0.9, max(0.35, score)))


def estimate_tnd_price(
    poids: float, category: str, feature_row: Optional[pd.DataFrame] = None
) -> float:
    if poids <= 0:
        poids = 5.0

    reg_model = _load_regression_model()
    if reg_model is not None and feature_row is not None:
        try:
            price_pred = float(reg_model.predict(feature_row)[0])
            return float(max(0.01, price_pred))
        except Exception as exc:
            logger.warning(
                f"Prédiction de prix ML échouée, fallback heuristique: {exc}"
            )

    base_price = PRIX_TND_AU_KG.get(category, 0.5)
    return float(poids * base_price)


def find_closest_city(lat: float, lon: float) -> Tuple[str, float]:
    closest_city = "Tunis"
    min_dist = float("inf")
    for ville, coords in COORDONNEES_VILLES.items():
        dist = math.sqrt((lat - coords[0]) ** 2 + (lon - coords[1]) ** 2)
        if dist < min_dist:
            min_dist = dist
            closest_city = ville
    return closest_city, min_dist


def get_local_company(ville: str) -> str:
    entreprises = ENTREPRISES_PAR_VILLE.get(ville, ENTREPRISES_PAR_VILLE["Tunis"])
    return random.choice(entreprises)


def infer_cluster(
    poids: float,
    volume: float,
    conductivite: float,
    rigidite: float,
    feature_row: Optional[pd.DataFrame] = None,
) -> Dict:
    kmeans_model = _load_kmeans_model()
    pca_model = _load_pca_model()
    scaler_model = _load_scaler_model()

    if (
        kmeans_model is not None
        and pca_model is not None
        and scaler_model is not None
        and feature_row is not None
    ):
        try:
            X_num = feature_row[NUM_COLS].copy()
            X_scaled = scaler_model.transform(X_num)
            cluster_id_val = int(kmeans_model.predict(X_scaled)[0])
            pca_coords = pca_model.transform(X_scaled)[0]
            pca_x = float(pca_coords[0])
            pca_y = float(pca_coords[1])

            cluster_info = {}
            if cluster_id_val == 0:
                cluster_info = {
                    "cluster_id": "0",
                    "cluster_label": "Métaux",
                    "size_hint": "Rigidité forte, conductivité et densité élevées",
                    "features": [
                        "conducteur",
                        "très rigide",
                        "dense",
                        "recyclage haute valeur",
                    ],
                }
            elif cluster_id_val == 1:
                cluster_info = {
                    "cluster_id": "1",
                    "cluster_label": "Plastiques",
                    "size_hint": "Densité faible, forte opacité",
                    "features": [
                        "léger",
                        "opaque",
                        "synthétique",
                        "tri mécanique requis",
                    ],
                }
            elif cluster_id_val == 2:
                cluster_info = {
                    "cluster_id": "2",
                    "cluster_label": "Papier/Carton",
                    "size_hint": "Rigidité minimale, densité très faible",
                    "features": [
                        "léger",
                        "très souple",
                        "biodégradable",
                        "sensible à l'humidité",
                    ],
                }
            elif cluster_id_val == 3:
                cluster_info = {
                    "cluster_id": "3",
                    "cluster_label": "Verre",
                    "size_hint": "Rigidité maximale, opacité nulle/transparent",
                    "features": [
                        "très rigide",
                        "transparent/translucide",
                        "fragile",
                        "recyclable à l'infini",
                    ],
                }
            else:
                cluster_info = {
                    "cluster_id": str(cluster_id_val),
                    "cluster_label": f"Cluster {cluster_id_val}",
                    "size_hint": "Profil hétérogène",
                    "features": ["caractéristiques mixtes"],
                }

            cluster_info["pca_x"] = round(pca_x, 4)
            cluster_info["pca_y"] = round(pca_y, 4)
            return cluster_info

        except Exception as exc:
            logger.warning(f"Clustering ML échoué, fallback heuristique: {exc}")

    if poids < 2 and volume < 2:
        res = {
            "cluster_id": "A1",
            "cluster_label": "Cluster A: Léger & compact",
            "size_hint": "Petits volumes",
            "features": ["léger", "compact", "faible densité"],
        }
    elif conductivite > 6:
        res = {
            "cluster_id": "B3",
            "cluster_label": "Cluster B: Conducteur",
            "size_hint": "Valeur élevée",
            "features": ["conducteur", "dense", "recyclable"],
        }
    elif rigidite > 6:
        res = {
            "cluster_id": "C2",
            "cluster_label": "Cluster C: Rigide",
            "size_hint": "Structure stable",
            "features": ["rigide", "volume moyen", "traitement mécanique"],
        }
    else:
        res = {
            "cluster_id": "D4",
            "cluster_label": "Cluster D: Mixte",
            "size_hint": "Profil hétérogène",
            "features": ["mixte", "tri requis", "valeur variable"],
        }

    res["pca_x"] = 0.0
    res["pca_y"] = 0.0
    return res


def extract_keywords(report: str, limit: int = 6) -> List[str]:
    if not report:
        return []
    normalized = normalize_tunisified_text(report)
    vect = _load_keyword_vectorizer()

    if vect is not None:
        try:
            X = vect.transform([normalized])
            if X.nnz:
                scores = X.toarray()[0]
                feature_names = getattr(vect, "get_feature_names_out", None)
                names = (
                    feature_names()
                    if feature_names
                    else np.array(vect.get_feature_names())
                )
                top_idx = np.argsort(scores)[::-1]
                out: list[str] = []
                for idx in top_idx:
                    if scores[idx] <= 0:
                        break
                    kw = str(names[idx])
                    if any(tok in _STOP_WORDS_FR_TN for tok in kw.split(" ")):
                        continue
                    out.append(kw)
                    if len(out) >= limit:
                        break
                if out:
                    return out
        except Exception:
            pass

    tokens = [
        t
        for t in re.split(r"[^a-z0-9']+", normalized)
        if len(t) > 3 and t not in _STOP_WORDS_FR_TN
    ]
    seen: set[str] = set()
    out: list[str] = []
    for t in tokens:
        if t in seen:
            continue
        seen.add(t)
        out.append(t)
        if len(out) >= limit:
            break
    return out


def summarize_report(report: str, max_len: int = 90) -> str:
    if not report:
        return "Aucun rapport fourni."
    cleaned = re.sub(r"\s+", " ", report).strip()
    sentences = [s.strip() for s in re.split(r"(?<=[.!?])\s+", cleaned) if s.strip()]
    if not sentences:
        trimmed = cleaned
        return trimmed if len(trimmed) <= max_len else f"{trimmed[:max_len]}..."

    joined = " ".join(sentences)
    norm = normalize_tunisified_text(joined)
    token_freq: dict[str, int] = {}
    for tok in re.split(r"[^a-z0-9']+", norm):
        if len(tok) <= 3 or tok in _STOP_WORDS_FR_TN:
            continue
        token_freq[tok] = token_freq.get(tok, 0) + 1

    def score_sentence(sent: str, index: int) -> float:
        s_norm = normalize_tunisified_text(sent)
        toks = [t for t in re.split(r"[^a-z0-9']+", s_norm) if t]
        if not toks:
            return 0.0
        base_score = sum(token_freq.get(t, 0) for t in toks)
        position_bonus = 1.0 / (1.0 + index)
        length_penalty = 1.0 / (1.0 + max(0, len(sent) - 200) / 200)
        return float(base_score) * position_bonus * length_penalty

    scored = [(i, score_sentence(s, i), s) for i, s in enumerate(sentences)]
    scored.sort(key=lambda item: item[1], reverse=True)

    selected: list[tuple[int, str]] = []
    budget = max_len
    for i, sc, s in scored:
        if sc <= 0:
            continue
        s_trim = s
        if len(s_trim) > budget and budget > 30:
            s_trim = s_trim[:budget].rstrip() + "..."
        if len(s_trim) <= budget:
            selected.append((i, s_trim))
            budget -= len(s_trim) + 1
        if budget <= 0 or len(selected) >= 2:
            break

    if not selected:
        first = sentences[0]
        return first if len(first) <= max_len else f"{first[:max_len]}..."

    selected.sort(key=lambda item: item[0])
    summary = " ".join(s for _, s in selected).strip()
    return summary if len(summary) <= max_len else f"{summary[:max_len]}..."


def build_payload(data: Dict) -> Dict:
    """
    Point d'entrée principal : construit la réponse complète à partir des données brutes.
    Utilise le modèle ML multimodal si disponible, sinon les heuristiques.
    """
    poids = float(data.get("poids") or 0)
    volume = float(data.get("volume") or 1.0)
    conductivite = float(data.get("conductivite") or 0)
    opacite = float(data.get("opacite") or 0.5)
    rigidite = float(data.get("rigidite") or 0)
    rapport = data.get("rapport_collecte") or ""
    lat = data.get("latitude")
    lon = data.get("longitude")

    # Construire la ligne de features pour le modèle
    feature_row = _build_feature_row(data)

    # Prédiction (ML ou heuristique)
    category, confidence, method = infer_category(
        rapport, conductivite, rigidite, feature_row
    )

    tnd_price = estimate_tnd_price(poids, category, feature_row)

    ville_detectee, distance_deg = "Tunis", 0.0
    entreprise = "Tunisie Recyclage"
    if lat is not None and lon is not None:
        ville_detectee, distance_deg = find_closest_city(float(lat), float(lon))
        entreprise = get_local_company(ville_detectee)

    cluster = infer_cluster(poids, volume, conductivite, rigidite, feature_row)
    keywords = extract_keywords(rapport)
    summary = summarize_report(rapport)
    corrected_report = correct_tunisified_text_pretty(rapport)

    return {
        "category": category,
        "confidence": confidence,
        "prediction_method": method,  # 'ml_model' ou 'heuristic'
        "price_tnd": round(tnd_price, 3),
        "min_price_tnd": round(max(0.05, tnd_price * 0.85), 3),
        "max_price_tnd": round(tnd_price * 1.15, 3),
        "currency": "TND",
        "location": {
            "latitude": lat,
            "longitude": lon,
            "ville_proche": ville_detectee,
            "centre_collecte": entreprise,
        },
        "cluster": cluster,
        "keywords": keywords,
        "summary": summary,
        "rapport_collecte": rapport,
        "rapport_collecte_corrige": corrected_report,
    }
