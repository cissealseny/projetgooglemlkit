# Proposition 2 — Vision IA dédiée déchets (2–5 jours)

Objectif: remplacer (ou compléter) Google ML Kit Image Labeling **générique** par un modèle **spécialisé déchets** en **TFLite on-device**.

## Résultat attendu (effet démo)
- L’utilisateur prend une photo → l’app renvoie **catégorie déchets** + **confiance**.
- Offline (pas de réseau).
- Plus stable que le labeling générique (classes cohérentes, meilleure précision sur déchets).

## Option A (recommandée): modèle custom TFLite on-device
### Modèle
- Backbone: `MobileNetV3` ou `EfficientNet-Lite` (classification image)
- Export: `TensorFlow Lite` (quantization possible)

### Dataset (au choix)
- **TrashNet**: simple pour démarrer.
- **TACO**: plus réaliste (plus varié, plus “in the wild”).
- Vos images: si disponibles → meilleur match au contexte.

### Étapes d’implémentation (2–5 jours)
1) **Définir les classes cibles**
   - Idéalement alignées avec votre Eco‑smart: `Plastique`, `Papier`, `Carton`, `Verre`, `Metal`, `Electronique`.
2) **Préparer le dataset**
   - Split `train/val/test`, équilibrage minimal, nettoyage.
   - Output attendu: dossiers par classe (format simple) ou CSV + paths.
3) **Fine-tuning**
   - Entraîner un modèle léger avec augmentation (crop/rotate/brightness).
   - Suivre métriques: accuracy, confusion matrix.
4) **Conversion TFLite**
   - Export SavedModel → `.tflite`
   - Option: quantization `float16` (bon compromis) ou `int8` (plus rapide mais calibration requise).
5) **Intégration Flutter**
   - Ajouter le modèle dans `assets/`.
   - Inference via `tflite_flutter` (ou `tensorflow_lite_flutter` selon choix).
   - Préprocessing: resize + normalize identiques à l’entraînement.
6) **Fallback**
   - Si modèle manquant / erreur runtime → fallback sur ML Kit existant (sans changer l’UX).

## Livrables techniques
- `waste_classifier.tflite` + `labels.txt`
- Une petite page/onglet de debug (optionnel) affichant top‑k + temps d’inférence (ms)
- Script reproductible d’entraînement + conversion

## Risques / points à valider
- Mapping des classes (TrashNet/TACO != vos classes) → besoin d’un mapping clair.
- Performance sur appareils bas de gamme → préférer MobileNetV3 + quantization.
- Cohérence préprocessing (sinon perfs chutent).

## Décisions à prendre avant d’implémenter
1) Classes finales (liste exacte)
2) Dataset retenu (TrashNet vs TACO vs images internes)
3) Mode de quantization (float16 recommandé en première passe)
