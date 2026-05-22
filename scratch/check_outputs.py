import json
import sys

sys.stdout.reconfigure(encoding='utf-8')
nb_path = r"notebooks/03b_nlp_word2vec_fasttext.ipynb"

try:
    with open(nb_path, "r", encoding="utf-8") as f:
        nb = json.load(f)
        
    for idx, cell in enumerate(nb['cells']):
        if cell['cell_type'] == 'code':
            print(f"=== Cell {idx} ({cell.get('id', '')}) ===")
            source = "".join(cell.get('source', []))
            print(f"Source (first 100 chars): {source[:100]}...")
            
            outputs = cell.get('outputs', [])
            if not outputs:
                print("No outputs.")
            for out in outputs:
                if 'text' in out:
                    text = out['text']
                    print("".join(text) if isinstance(text, list) else text)
                elif 'data' in out:
                    data = out['data']
                    if 'text/plain' in data:
                        print(data['text/plain'])
            print("-" * 50)
            
except Exception as e:
    print(f"Error checking notebook: {e}")
