import json
from pathlib import Path

# Path to the notebook
NB_PATH = Path(r"c:\Users\DELL\Downloads\GoogleMLKit\notebooks\03b_nlp_word2vec_fasttext.ipynb")

print("Reading NLP notebook...")
with open(NB_PATH, "r", encoding="utf-8") as f:
    nb = json.load(f)

# Find the index of the cell containing the comparison table (starts with "## 4. Tableau comparatif")
insert_idx = -1
for idx, cell in enumerate(nb["cells"]):
    if cell["cell_type"] == "markdown" and any("## 4. Tableau comparatif" in line for line in cell.get("source", [])):
        insert_idx = idx
        break

if insert_idx != -1:
    print(f"Found insertion point at index {insert_idx}")
    
    transformer_md = {
        "cell_type": "markdown",
        "id": "transformer_md_cell",
        "metadata": {},
        "source": [
            "## 3b. Transformers / CamemBERT (SentenceTransformers)\n",
            "\n",
            "Pour surpasser les baselines BoW, TF-IDF, Word2Vec et FastText, nous intégrons un modèle de Deep Learning basé sur l'architecture Transformer.\n",
            "Nous utilisons `SentenceTransformers` avec le modèle multilingue performant **`paraphrase-multilingual-MiniLM-L12-v2`** (qui supporte parfaitement le français). \n",
            "Contrairement à Word2Vec/FastText qui font la moyenne des vecteurs de mots sans contexte, le Transformer capture le contexte sémantique global de la phrase entière."
        ]
    }
    
    transformer_code = {
        "cell_type": "code",
        "execution_count": None,
        "id": "transformer_code_cell",
        "metadata": {},
        "outputs": [],
        "source": [
            "import os\n",
            "# Forcer transformers à n'utiliser que PyTorch pour éviter le conflit Keras 3 / TensorFlow\n",
            "os.environ['USE_TF'] = '0'\n",
            "os.environ['USE_TORCH'] = '1'\n",
            "\n",
            "try:\n",
            "    from sentence_transformers import SentenceTransformer\n",
            "    print('Sentence-Transformers chargé avec succès ✅')\n",
            "    \n",
            "    # Chargement d'un modèle léger et performant\n",
            "    model = SentenceTransformer('paraphrase-multilingual-MiniLM-L12-v2')\n",
            "    \n",
            "    # Récupérer les textes bruts d'origine pour le Transformer\n",
            "    X_train_raw = df.loc[X_train.index, 'Rapport_Collecte'].astype(str)\n",
            "    X_test_raw = df.loc[X_test.index, 'Rapport_Collecte'].astype(str)\n",
            "    \n",
            "    print('Calcul des embeddings de phrases (cela peut prendre quelques secondes)...')\n",
            "    X_tr_emb = model.encode(X_train_raw.tolist(), show_progress_bar=True)\n",
            "    X_te_emb = model.encode(X_test_raw.tolist(), show_progress_bar=True)\n",
            "    \n",
            "    # Entraînement du classifieur sur les embeddings denses\n",
            "    clf = RandomForestClassifier(n_estimators=300, max_depth=30, random_state=RANDOM_STATE)\n",
            "    clf.fit(X_tr_emb, y_train)\n",
            "    preds = clf.predict(X_te_emb)\n",
            "    \n",
            "    acc = accuracy_score(y_test, preds)\n",
            "    f1  = f1_score(y_test, preds, average='weighted')\n",
            "    \n",
            "    results['SentenceTransformer + RF'] = {'accuracy': round(acc, 4), 'f1': round(f1, 4)}\n",
            "    print(f\"{'SentenceTransformer + RF':<30} acc={acc:.4f}  f1={f1:.4f}\")\n",
            "    \n",
            "except ImportError as e:\n",
            "    print(f'⚠️ sentence-transformers ou torch non disponible: {e}')\n",
            "except Exception as e:\n",
            "    print(f'⚠️ Erreur lors de l\\'exécution: {e}')\n"
        ]
    }
    
    # Insert new cells
    nb["cells"].insert(insert_idx, transformer_md)
    nb["cells"].insert(insert_idx + 1, transformer_code)
    
    # Save the modified notebook
    with open(NB_PATH, "w", encoding="utf-8") as f:
        json.dump(nb, f, indent=1, ensure_ascii=False)
    
    print("Notebook modified and saved successfully!")
else:
    print("Error: Could not find insert point in notebook!")
