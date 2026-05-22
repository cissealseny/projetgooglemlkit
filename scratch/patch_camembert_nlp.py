import json
from pathlib import Path

nb_path = Path(
    r"c:\Users\DELL\Downloads\GoogleMLKit\notebooks\03b_nlp_word2vec_fasttext.ipynb"
)

print("Reading NLP notebook...")
with open(nb_path, "r", encoding="utf-8") as f:
    nb = json.load(f)

patched_md = False
patched_code = False

for cell in nb["cells"]:
    if cell["cell_type"] == "markdown" and any(
        "## 3b. Transformers / CamemBERT" in line for line in cell.get("source", [])
    ):
        print("Found Transformer MD cell, updating...")
        cell["source"] = [
            "## 3b. Transformers / CamemBERT (PyTorch & Hugging Face)\n",
            "\n",
            "Pour surpasser les baselines traditionnelles (BoW, TF-IDF) et sémantiques statiques (Word2Vec, FastText), nous intégrons un modèle de Deep Learning basé sur l'architecture Transformer.\n",
            "Nous utilisons le modèle de référence francophone **`CamemBERT-base`** déjà entièrement pré-téléchargé dans notre cache local (utilisation 100% offline).\n",
            "Les embeddings de phrases sont extraits par mean pooling sur la dernière couche de CamemBERT, puis un RandomForestClassifier est entraîné sur ces représentations denses.",
        ]
        patched_md = True

    elif cell["cell_type"] == "code" and any(
        "from sentence_transformers import SentenceTransformer" in line
        for line in cell.get("source", [])
    ):
        print(
            "Found SentenceTransformer code cell, replacing with CamemBERT offline code..."
        )
        cell["source"] = [
            "import os\n",
            "import torch\n",
            "import numpy as np\n",
            "from transformers import AutoTokenizer, AutoModel\n",
            "\n",
            "# Forcer transformers à n'utiliser que PyTorch pour éviter le conflit Keras 3 / TensorFlow\n",
            "os.environ['USE_TF'] = '0'\n",
            "os.environ['USE_TORCH'] = '1'\n",
            "\n",
            "try:\n",
            "    print('Chargement de CamemBERT depuis le cache local (mode 100% offline)...')\n",
            "    tokenizer = AutoTokenizer.from_pretrained('camembert-base', local_files_only=True)\n",
            "    model = AutoModel.from_pretrained('camembert-base', local_files_only=True)\n",
            "    model.eval()\n",
            "    print('CamemBERT chargé avec succès !')\n",
            "    \n",
            "    # Récupérer les textes bruts d'origine pour le Transformer\n",
            "    X_train_raw = df.loc[X_train.index, 'Rapport_Collecte'].astype(str).tolist()\n",
            "    X_test_raw = df.loc[X_test.index, 'Rapport_Collecte'].astype(str).tolist()\n",
            "    \n",
            "    # Extraction par batch pour la stabilité mémoire et la vitesse sur CPU\n",
            "    def get_camembert_embeddings(texts, batch_size=64):\n",
            "        all_embeddings = []\n",
            "        for i in range(0, len(texts), batch_size):\n",
            "            batch_texts = texts[i:i+batch_size]\n",
            "            inputs = tokenizer(batch_texts, padding=True, truncation=True, max_length=128, return_tensors='pt')\n",
            "            with torch.no_grad():\n",
            "                outputs = model(**inputs)\n",
            "                # Mean pooling sur la dimension de séquence (dim 1)\n",
            "                embeddings = outputs.last_hidden_state.mean(dim=1).cpu().numpy()\n",
            "                all_embeddings.append(embeddings)\n",
            "        return np.vstack(all_embeddings)\n",
            "    \n",
            "    print('Calcul des embeddings CamemBERT sur le dataset de train/test...')\n",
            "    X_tr_emb = get_camembert_embeddings(X_train_raw)\n",
            "    X_te_emb = get_camembert_embeddings(X_test_raw)\n",
            "    \n",
            "    # Entraînement du classifieur sur les embeddings denses\n",
            "    print('Entraînement du RandomForestClassifier sur les embeddings CamemBERT...')\n",
            "    clf = RandomForestClassifier(n_estimators=300, max_depth=30, random_state=RANDOM_STATE)\n",
            "    clf.fit(X_tr_emb, y_train)\n",
            "    preds = clf.predict(X_te_emb)\n",
            "    \n",
            "    acc = accuracy_score(y_test, preds)\n",
            "    f1  = f1_score(y_test, preds, average='weighted')\n",
            "    \n",
            "    results['CamemBERT + RF'] = {'accuracy': round(acc, 4), 'f1': round(f1, 4)}\n",
            "    print(f\"{'CamemBERT + RF':<30} acc={acc:.4f}  f1={f1:.4f}\")\n",
            "    \n",
            "except Exception as e:\n",
            "    print(f'⚠️ Erreur lors de l\\'exécution de CamemBERT: {e}')\n",
        ]
        patched_code = True

if patched_md and patched_code:
    with open(nb_path, "w", encoding="utf-8") as f:
        json.dump(nb, f, indent=1, ensure_ascii=False)
    print("Notebook patched with CamemBERT offline pipeline successfully!")
else:
    print("Error: Could not find all target cells in the notebook!")
