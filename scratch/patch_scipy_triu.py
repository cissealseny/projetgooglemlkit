import json
from pathlib import Path

nb_path = Path(r"c:\Users\DELL\Downloads\GoogleMLKit\notebooks\03b_nlp_word2vec_fasttext.ipynb")

print("Reading NLP notebook...")
with open(nb_path, "r", encoding="utf-8") as f:
    nb = json.load(f)

patched = False
for cell in nb["cells"]:
    if cell["cell_type"] == "code" and any("from gensim.models import Word2Vec" in line for line in cell.get("source", [])):
        print("Found Gensim cell, patching it...")
        src = cell["source"]
        
        # We replace any existing scipy patch or write a new one
        # Let's clean the old patch if present and set the correct one
        cleaned_src = [line for line in src if not any(x in line for x in ["import scipy", "hasattr(scipy, 'triu')", "scipy.linalg", "scipy.triu = triu"])]
        
        patch = [
            "import scipy\n",
            "if not hasattr(scipy, 'triu'):\n",
            "    from scipy.sparse import triu\n",
            "    scipy.triu = triu\n",
            "\n"
        ]
        cell["source"] = patch + cleaned_src
        patched = True
        print("Gensim cell updated with scipy.sparse.triu patch!")
        break

if patched:
    with open(nb_path, "w", encoding="utf-8") as f:
        json.dump(nb, f, indent=1, ensure_ascii=False)
    print("Notebook patched successfully!")
else:
    print("No changes made.")
