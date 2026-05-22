#!/usr/bin/env bash
# ============================================================
# cloud_run_deploy.sh — Déploiement Eco-Smart API sur Cloud Run
# ============================================================
# Usage:
#   chmod +x cloud_run_deploy.sh
#   ./cloud_run_deploy.sh
#
# Prérequis:
#   1. Google Cloud SDK installé: https://cloud.google.com/sdk/docs/install
#   2. Authentification: gcloud auth login
#   3. Projet GCP configuré: gcloud config set project <PROJECT_ID>
# ============================================================

set -euo pipefail

# ── Configuration ────────────────────────────────────────────
SERVICE_NAME="${GCP_SERVICE_NAME:-eco-smart-api}"
REGION="${GCP_REGION:-europe-west1}"
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
MEMORY="${GCP_MEMORY:-1Gi}"
TIMEOUT="${GCP_TIMEOUT:-120}"
MAX_INSTANCES="${GCP_MAX_INSTANCES:-3}"

# ── Couleurs ─────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}══════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  🌱 Eco-Smart Classifier — Cloud Run Deployment ${NC}"
echo -e "${BLUE}══════════════════════════════════════════════════${NC}"
echo ""

# ── Vérifications ────────────────────────────────────────────
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}❌ gcloud CLI non trouvé. Installez-le: https://cloud.google.com/sdk/docs/install${NC}"
    exit 1
fi

if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "(unset)" ]; then
    echo -e "${RED}❌ Aucun projet GCP configuré.${NC}"
    echo -e "   Exécutez: ${YELLOW}gcloud config set project <PROJECT_ID>${NC}"
    exit 1
fi

echo -e "${GREEN}📋 Configuration:${NC}"
echo -e "   Projet:     ${YELLOW}${PROJECT_ID}${NC}"
echo -e "   Service:    ${YELLOW}${SERVICE_NAME}${NC}"
echo -e "   Région:     ${YELLOW}${REGION}${NC}"
echo -e "   Mémoire:    ${YELLOW}${MEMORY}${NC}"
echo -e "   Timeout:    ${YELLOW}${TIMEOUT}s${NC}"
echo -e "   Max inst.:  ${YELLOW}${MAX_INSTANCES}${NC}"
echo ""

# ── Activation des API nécessaires ───────────────────────────
echo -e "${BLUE}🔧 Activation des API GCP...${NC}"
gcloud services enable \
    run.googleapis.com \
    cloudbuild.googleapis.com \
    artifactregistry.googleapis.com \
    --quiet

# ── Build & Deploy ───────────────────────────────────────────
echo ""
echo -e "${BLUE}🚀 Build et déploiement en cours...${NC}"
echo -e "   (Cela peut prendre 3-5 minutes la première fois)"
echo ""

# Se placer à la racine du projet (parent du dossier backend)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

gcloud run deploy "${SERVICE_NAME}" \
    --source "${PROJECT_ROOT}" \
    --dockerfile "${PROJECT_ROOT}/Dockerfile.cloud" \
    --region "${REGION}" \
    --platform managed \
    --allow-unauthenticated \
    --port 8080 \
    --memory "${MEMORY}" \
    --cpu 1 \
    --timeout "${TIMEOUT}" \
    --max-instances "${MAX_INSTANCES}" \
    --min-instances 0 \
    --set-env-vars="MODEL_PATH=/app/model/multimodal_model.pkl,DATASET_PATH=/app/dataset_ProjetML_2026.csv" \
    --quiet

# ── Récupérer l'URL ──────────────────────────────────────────
echo ""
SERVICE_URL=$(gcloud run services describe "${SERVICE_NAME}" \
    --region "${REGION}" \
    --format="value(status.url)" 2>/dev/null)

echo -e "${GREEN}══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅ Déploiement réussi !${NC}"
echo -e "${GREEN}══════════════════════════════════════════════════${NC}"
echo ""
echo -e "  🌐 URL de l'API:     ${YELLOW}${SERVICE_URL}${NC}"
echo -e "  📖 Documentation:    ${YELLOW}${SERVICE_URL}/docs${NC}"
echo -e "  ❤️  Health Check:     ${YELLOW}${SERVICE_URL}/health${NC}"
echo ""
echo -e "  ${BLUE}Exemple de test:${NC}"
echo -e "  curl -X POST ${SERVICE_URL}/predict \\"
echo -e '    -H "Content-Type: application/json" \'
echo -e '    -d '"'"'{"Rapport_Collecte":"Lot de bouteilles plastiques PET","Poids":12.5,"Volume":5.0,"Conductivite":0.1,"Opacite":0.8,"Rigidite":0.3}'"'"''
echo ""
