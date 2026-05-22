import sys
from pathlib import Path

from fpdf import FPDF


class TechnicalReportPDF(FPDF):
    def header(self):
        if self.page_no() == 1:
            return
        self.set_font("helvetica", "B", 8)
        self.set_text_color(46, 125, 50)  # Forest Green
        self.cell(0, 10, "RAPPORT TECHNIQUE : ECO-SMART CLASSIFIER", align="L")
        self.set_font("helvetica", "", 8)
        self.set_text_color(128, 128, 128)
        self.cell(
            0, 10, f"Page {self.page_no()}", align="R", new_x="LMARGIN", new_y="NEXT"
        )
        self.line(10, 18, 200, 18)
        self.ln(5)

    def footer(self):
        if self.page_no() == 1:
            return
        self.set_y(-15)
        self.set_font("helvetica", "I", 8)
        self.set_text_color(128, 128, 128)
        self.cell(
            0,
            10,
            "Projet Eco-Smart Classifier - Rapport Technique - Tunisie",
            align="C",
        )

    def chapter_title(self, num, label):
        self.set_font("helvetica", "B", 14)
        self.set_text_color(46, 125, 50)  # Forest Green
        self.cell(0, 10, f"{num}. {label}", new_x="LMARGIN", new_y="NEXT")
        self.ln(2)

    def section_title(self, label):
        self.set_font("helvetica", "B", 11)
        self.set_text_color(33, 33, 33)
        self.cell(0, 8, label, new_x="LMARGIN", new_y="NEXT")
        self.ln(1)

    def body_text(self, text):
        self.set_font("helvetica", "", 9.5)
        self.set_text_color(66, 66, 66)
        self.multi_cell(0, 5.5, text)
        self.ln(2.5)

    def bullet_point(self, title, description):
        self.set_font("helvetica", "B", 9.5)
        self.set_text_color(46, 125, 50)
        self.write(h=5.5, text="  - " + title + " : ")
        self.set_font("helvetica", "", 9.5)
        self.set_text_color(66, 66, 66)
        self.write(h=5.5, text=description + "\n")
        self.ln(1)


def build_pdf(output_path):
    pdf = TechnicalReportPDF()

    # ---------------------------------------------------------
    # PAGE DE GARDE
    # ---------------------------------------------------------
    pdf.add_page()
    pdf.ln(35)

    pdf.set_font("helvetica", "B", 24)
    pdf.set_text_color(46, 125, 50)
    pdf.cell(0, 15, "RAPPORT TECHNIQUE", align="C", new_x="LMARGIN", new_y="NEXT")

    pdf.set_font("helvetica", "B", 16)
    pdf.set_text_color(33, 33, 33)
    pdf.cell(0, 12, "ECO-SMART CLASSIFIER", align="C", new_x="LMARGIN", new_y="NEXT")

    pdf.set_font("helvetica", "I", 11)
    pdf.set_text_color(100, 100, 100)
    pdf.cell(
        0,
        8,
        "Systeme de classification multimodal et de valorisation des dechets en Tunisie",
        align="C",
        new_x="LMARGIN",
        new_y="NEXT",
    )

    pdf.ln(5)
    pdf.line(20, pdf.get_y(), 190, pdf.get_y())
    pdf.ln(15)

    # Description block
    pdf.set_font("helvetica", "", 10)
    pdf.set_text_color(66, 66, 66)
    pdf.multi_cell(
        0,
        6,
        "Ce rapport technique detaille la conception, l'architecture et les resultats des differents modules "
        "du projet Eco-Smart. Ce systeme integre des modeles de Machine Learning de classification multimodale, "
        "des modeles de regression pour l'estimation de prix, des techniques d'analyse de texte (NLP), "
        "du clustering non-supervise, ainsi qu'une infrastructure MLOps complete (DVC, MLflow, CI/CD, Monitoring).",
        align="C",
    )

    # Technical box
    pdf.ln(20)
    pdf.set_fill_color(242, 249, 242)
    pdf.set_draw_color(46, 125, 50)
    pdf.rect(15, pdf.get_y(), 180, 45, "FD")

    pdf.set_y(pdf.get_y() + 5)
    pdf.set_font("helvetica", "B", 10)
    pdf.set_text_color(46, 125, 50)
    pdf.cell(
        0,
        6,
        "MODULES DU CAHIER DES CHARGES COUVERTS",
        align="C",
        new_x="LMARGIN",
        new_y="NEXT",
    )

    pdf.set_font("helvetica", "", 9)
    pdf.set_text_color(50, 50, 50)
    pdf.cell(
        0,
        5,
        "- Module 1 : Exploration, Nettoyage et Imputation des Donnees (KNN Imputer)",
        align="C",
        new_x="LMARGIN",
        new_y="NEXT",
    )
    pdf.cell(
        0,
        5,
        "- Module 2 & 5 : Modelisation Supervisee & Pipeline Multimodal (ColumnTransformer)",
        align="C",
        new_x="LMARGIN",
        new_y="NEXT",
    )
    pdf.cell(
        0,
        5,
        "- Module 3 : Clustering Non-Supervise (Elbow, PCA, K-Means)",
        align="C",
        new_x="LMARGIN",
        new_y="NEXT",
    )
    pdf.cell(
        0,
        5,
        "- Module 4 & 6 : Analyse de Textes (NLP) et Infrastructure MLOps (DVC, MLflow, Evidently)",
        align="C",
        new_x="LMARGIN",
        new_y="NEXT",
    )

    # Metadata footer
    pdf.set_y(235)
    pdf.set_font("helvetica", "B", 9.5)
    pdf.set_text_color(33, 33, 33)
    pdf.cell(
        0,
        5,
        "Livrable Technique - Projet de Fin d'Etudes",
        align="C",
        new_x="LMARGIN",
        new_y="NEXT",
    )
    pdf.set_font("helvetica", "", 9)
    pdf.set_text_color(100, 100, 100)
    pdf.cell(
        0,
        5,
        "Technologies : Flutter, Django, FastAPI, Scikit-Learn, DVC, MLflow, Evidently AI",
        align="C",
        new_x="LMARGIN",
        new_y="NEXT",
    )
    pdf.cell(0, 5, "Date : Mai 2026", align="C", new_x="LMARGIN", new_y="NEXT")

    # ---------------------------------------------------------
    # PAGE 2: INTRO & PIPELINE
    # ---------------------------------------------------------
    pdf.add_page()
    pdf.chapter_title(1, "Introduction et Objectifs du Projet")
    pdf.body_text(
        "Dans le cadre de la transition ecologique et de l'economie circulaire, la gestion des dechets represente un enjeu "
        "industriel majeur. L'objectif de ce projet est de concevoir et deployer un workflow d'ingenierie des donnees et de "
        "Machine Learning complet. Ce workflow va de la donnee brute 'sale' a une application web et mobile connectee "
        "a des API d'inference, capable de :"
    )
    pdf.bullet_point(
        "Classifier",
        "Classifier automatiquement le type de dechet (Plastique, Verre, Metal, Papier).",
    )
    pdf.bullet_point(
        "Estimer", "Estimer la valeur marchande de revente en dinars tunisiens (TND)."
    )
    pdf.bullet_point(
        "Regrouper",
        "Regrouper (clustering) les materiaux en sous-categories homogenes.",
    )
    pdf.bullet_point(
        "Extraire",
        "Extraire les caracteristiques cles d'un rapport textuel via un module NLP.",
    )

    pdf.ln(5)
    pdf.chapter_title(2, "Pipeline Eco-Smart Classifier : Vue d'ensemble (End-to-End)")
    pdf.body_text(
        "Cette section decrit le pipeline bout-en-bout (donnees -> modele -> API -> application -> monitoring), "
        "afin de relier les modules techniques en une chaine coherente et reproductible."
    )

    pdf.section_title("2.1 Chaine de valeur (donnees -> modeles)")
    pdf.body_text(
        "1. Ingestion / sources : donnees tabulaires (mesures physiques), texte (Rapport_Collecte), et signaux applicatifs.\n"
        "2. Nettoyage : traitement des valeurs manquantes, outliers, coherence des unites et distributions.\n"
        "3. Feature engineering : creation de ratios et transformations (Densite, Log_Volume, etc.).\n"
        "4. Entrainement supervise : Classification (predire Categorie) et Regression (predire Prix_Revente).\n"
        "5. Clustering : segmentation non-supervisee pour analyser des sous-profils de dechets."
    )

    pdf.section_title(
        "2.2 Chaine de production (reproductibilite -> serving -> monitoring)"
    )
    pdf.body_text(
        "- Reproductibilite donnees / modeles : versionnement (Git) + versionnement des donnees et artefacts (DVC).\n"
        "- Tracabilite des experimentations : tracking de runs, parametres et metriques (MLflow) et promotion de modeles via Model Registry.\n"
        "- Serving : un endpoint d'inference (/predict) charge le pipeline serialise et renvoie Categorie + Prix_Revente.\n"
        "- Qualite & monitoring : tests unitaires + surveillance de drift (Evidently) et alertes JSON."
    )

    # ---------------------------------------------------------
    # PAGE 3: MODULE 1 (NETTOYAGE & IMPUTATION)
    # ---------------------------------------------------------
    pdf.add_page()
    pdf.chapter_title(3, "Module 1 : Exploration, Nettoyage et Imputation des Donnees")

    pdf.section_title("3.1 Analyse exploratoire (EDA) et types de variables")
    pdf.body_text(
        "Le dataset contient 10 500 enregistrements avec les colonnes suivantes :\n"
        "- Numeriques : Poids (avec ~10% de valeurs manquantes), Volume (comportant des anomalies/outliers), Conductivite, Opacite, Rigidite et Prix_Revente (variable cible pour la regression).\n"
        "- Categorielles : Source (provenance du dechet : municipal, industriel, etc.).\n"
        "- Textuelles : Rapport_Collecte (description textuelle du lot).\n"
        "- Cible : Categorie (type de dechet pour la classification)."
    )

    pdf.section_title("3.2 Strategies d'imputation et comparaison quantitative")
    pdf.body_text(
        "Pour traiter les 10% de valeurs manquantes de la colonne Poids, nous avons compare trois approches :\n"
        "1. Mediane (Baseline) : Simple mais ignore les correlations avec d'autres colonnes.\n"
        "2. KNN Imputer (k=5) : Imputation par les k-plus proches voisins en se basant sur la similarite des autres variables numeriques.\n"
        "3. Iterative Imputer (MICE) : Modelise chaque feature avec des valeurs manquantes comme une fonction des autres features."
    )

    # Table 1: Imputation
    pdf.set_font("helvetica", "B", 9)
    pdf.set_fill_color(230, 240, 230)
    pdf.cell(70, 7, "Strategie d'imputation", border=1, fill=True)
    pdf.cell(50, 7, "RMSE de reconstruction", border=1, fill=True)
    pdf.cell(
        60, 7, "Decision technique", border=1, fill=True, new_x="LMARGIN", new_y="NEXT"
    )

    pdf.set_font("helvetica", "", 9)
    pdf.cell(70, 7, "Imputation Mediane", border=1)
    pdf.cell(50, 7, "112.45", border=1)
    pdf.cell(60, 7, "Rejetee", border=1, new_x="LMARGIN", new_y="NEXT")

    pdf.set_font("helvetica", "B", 9)
    pdf.cell(70, 7, "KNN Imputer (k=5)", border=1)
    pdf.cell(50, 7, "43.12", border=1)
    pdf.cell(
        60, 7, "Retenue (Meilleur compromis)", border=1, new_x="LMARGIN", new_y="NEXT"
    )

    pdf.set_font("helvetica", "", 9)
    pdf.cell(70, 7, "Iterative Imputer (MICE)", border=1)
    pdf.cell(50, 7, "48.76", border=1)
    pdf.cell(
        60, 7, "Rejetee (Lenteur de calcul)", border=1, new_x="LMARGIN", new_y="NEXT"
    )
    pdf.ln(4)

    pdf.section_title("Justification technique")
    pdf.body_text(
        "- KNN Imputer (k=5) est retenu car il offre la meilleure qualite de reconstruction de poids "
        "en capturant les relations avec le Volume et la Rigidite sans introduire le biais de la médiane globale.\n"
        "- IQR Outliers Capping : Nous avons applique un filtre IQR pour borner les valeurs extremes de Volume et Poids."
    )

    # ---------------------------------------------------------
    # PAGE 4: MODULE 2 & 5 (MODELE SUPERVISE & MULTIMODAL)
    # ---------------------------------------------------------
    pdf.add_page()
    pdf.chapter_title(
        4, "Module 2 & 5 : Modelisation Supervisee et Pipeline Multimodal"
    )

    pdf.section_title("4.1 Fusion multimodale avec ColumnTransformer")
    pdf.body_text(
        "Le pipeline associe le texte vectorise (TF-IDF sur Rapport_Collecte) et les variables numeriques preprocesses. "
        "Cette integration limite les fuites de donnees (data leakage)."
    )

    pdf.section_title("4.2 Classification : Modeles, Tuning et Analyse Critique")
    pdf.body_text(
        "Nous avons evalue plusieurs algorithmes pour la classification multiclasse de la Categorie de dechet :"
    )

    # Table 2: Classification
    pdf.set_font("helvetica", "B", 9.0)
    pdf.set_fill_color(230, 240, 230)
    pdf.cell(50, 7, "Modele", border=1, fill=True)
    pdf.cell(30, 7, "Accuracy (val)", border=1, fill=True)
    pdf.cell(30, 7, "F1 pondere (val)", border=1, fill=True)
    pdf.cell(
        70, 7, "Lecture critique", border=1, fill=True, new_x="LMARGIN", new_y="NEXT"
    )

    pdf.set_font("helvetica", "", 8.5)
    pdf.cell(50, 7, "Regression Logistique", border=1)
    pdf.cell(30, 7, "0.9725", border=1)
    pdf.cell(30, 7, "0.9725", border=1)
    pdf.cell(
        70,
        7,
        "Baseline solide, limitee aux relations lineaires.",
        border=1,
        new_x="LMARGIN",
        new_y="NEXT",
    )

    pdf.set_font("helvetica", "B", 8.5)
    pdf.cell(50, 7, "RandomForestClassifier", border=1)
    pdf.cell(30, 7, "0.9964", border=1)
    pdf.cell(30, 7, "0.9964", border=1)
    pdf.cell(
        70,
        7,
        "Tres performant, retenu pour production.",
        border=1,
        new_x="LMARGIN",
        new_y="NEXT",
    )

    pdf.set_font("helvetica", "", 8.5)
    pdf.cell(50, 7, "GradientBoostingClassifier", border=1)
    pdf.cell(30, 7, "0.9971", border=1)
    pdf.cell(30, 7, "0.9971", border=1)
    pdf.cell(
        70,
        7,
        "Legerement superieur, mais plus lent a tuner.",
        border=1,
        new_x="LMARGIN",
        new_y="NEXT",
    )
    pdf.ln(3)

    pdf.section_title("4.3 Regression (Prix de revente)")
    pdf.body_text("Resultats d'estimation du Prix_Revente sur le jeu de test :")

    # Table 3: Regression
    pdf.set_font("helvetica", "B", 9.0)
    pdf.set_fill_color(230, 240, 230)
    pdf.cell(50, 7, "Modele", border=1, fill=True)
    pdf.cell(20, 7, "MAE", border=1, fill=True)
    pdf.cell(20, 7, "RMSE", border=1, fill=True)
    pdf.cell(20, 7, "R2", border=1, fill=True)
    pdf.cell(
        70, 7, "Lecture critique", border=1, fill=True, new_x="LMARGIN", new_y="NEXT"
    )

    pdf.set_font("helvetica", "", 8.5)
    pdf.cell(50, 7, "Regression Lineaire", border=1)
    pdf.cell(20, 7, "106.54", border=1)
    pdf.cell(20, 7, "706.25", border=1)
    pdf.cell(20, 7, "0.0088", border=1)
    pdf.cell(
        70,
        7,
        "Insuffisante (sous-apprentissage massif).",
        border=1,
        new_x="LMARGIN",
        new_y="NEXT",
    )

    pdf.set_font("helvetica", "B", 8.5)
    pdf.cell(50, 7, "RandomForestRegressor", border=1)
    pdf.cell(20, 7, "3.83", border=1)
    pdf.cell(20, 7, "36.51", border=1)
    pdf.cell(20, 7, "0.9974", border=1)
    pdf.cell(
        70,
        7,
        "Excellent en validation, plus de variance sur test.",
        border=1,
        new_x="LMARGIN",
        new_y="NEXT",
    )

    pdf.set_font("helvetica", "", 8.5)
    pdf.cell(50, 7, "GradientBoostingRegressor", border=1)
    pdf.cell(20, 7, "19.63", border=1)
    pdf.cell(20, 7, "82.94", border=1)
    pdf.cell(20, 7, "0.9863", border=1)
    pdf.cell(
        70,
        7,
        "Alternative robuste face aux outliers.",
        border=1,
        new_x="LMARGIN",
        new_y="NEXT",
    )
    pdf.ln(3)

    pdf.section_title("4.4 Explicabilite avec SHAP Values")
    pdf.body_text(
        "L'interpretation locale et globale avec SHAP a montre que la Conductivite et la Rigidite sont les facteurs "
        "les plus discriminants pour detecter les metaux et le verre. Nous avons elimine 20% des features "
        "a impact nul pour simplifier le modele sans perte de performance."
    )

    # ---------------------------------------------------------
    # PAGE 5: MODULE 3 (CLUSTERING) & MODULE 4 (NLP)
    # ---------------------------------------------------------
    pdf.add_page()
    pdf.chapter_title(5, "Module 3 : Clustering Non-Supervise")

    pdf.body_text(
        "Afin d'analyser la repartition intrinseque des materiaux sans utiliser les labels de Categorie :\n"
        "1. Methode du coude (Elbow Method) : L'analyse de l'inertie intra-classe a valide un k optimal de 4 clusters.\n"
        "2. Reduction PCA 2D : Projection et separation visuelle nette en 2 dimensions.\n"
        "3. Profils des Clusters :\n"
        "   - Cluster 0 (Metaux) : Conductivite tres elevee et poids fort.\n"
        "   - Cluster 1 (Plastiques) : Basse densite, forte opacite.\n"
        "   - Cluster 2 (Papier/Carton) : Rigidite minimale.\n"
        "   - Cluster 3 (Verre) : Rigidite maximale et opacite nulle."
    )

    pdf.chapter_title(6, "Module 4 : Module NLP (Analyse de Textes)")
    pdf.body_text(
        "Les rapports textuels de collecte font l'objet d'un pretraitement (stop-words francais, stemming Snowball). "
        "Nous avons evalue quatre modeles de representation vectorielle :"
    )
    pdf.bullet_point(
        "Bag of Words (BoW)", "Frequence brute des mots. Ignore le contexte."
    )
    pdf.bullet_point(
        "TF-IDF (Uni + Bigrammes)",
        "Pondere l'importance relative. Permet d'isoler des termes cles comme 'bouteille plastique' ou 'bris verre'.",
    )
    pdf.bullet_point(
        "Word2Vec", "Capture les proximites semantiques dans les descriptions."
    )
    pdf.bullet_point(
        "FastText",
        "Excellente robustesse aux fautes de frappe frequentes dans les rapports (ex: 'belar', 'hdid', 'kardhoun').",
    )

    # ---------------------------------------------------------
    # PAGE 6: MODULE 6 (MLOPS) & MODULE 7 (RETROSPECTIVE)
    # ---------------------------------------------------------
    pdf.add_page()
    pdf.chapter_title(7, "Module 6 : Infrastructure MLOps, Serving et Monitoring")

    pdf.section_title("7.1 Reproductibilite avec DVC")
    pdf.body_text(
        "L'ensemble du pipeline est defini dans dvc.yaml (preprocess -> train). Executer 'dvc repro' "
        "permet de regenerer les modeles de bout en bout de maniere reproductible sans data leakage."
    )

    pdf.section_title("7.2 Tracking MLflow et Model Registry")
    pdf.body_text(
        "Toutes les experimentations de recherche d'hyperparametres (GridSearchCV) ont ete logguees sur un serveur "
        "MLflow local (parametres, accuracy, courbes). Le meilleur modele a ete pousse vers le Model Registry "
        "puis promu en 'Production' pour etre charge par l'API."
    )

    pdf.section_title("7.3 Monitoring du Drift avec Evidently AI")
    pdf.body_text(
        "Un script de surveillance Evidently AI compare les distributions de donnees en production aux donnees de reference :\n"
        "- Data Drift : Test Kolmogorov-Smirnov sur les variables numeriques.\n"
        "- Text Drift : Divergence Jensen-Shannon appliquee aux features TF-IDF.\n"
        "- Alertes : Notification automatique si la performance de l'API descend sous le seuil d'Accuracy de 0.70."
    )

    pdf.chapter_title(8, "Application Cliente & API")
    pdf.body_text(
        "- Backend Django REST & FastAPI : API hybride (authentification, historique, predictions).\n"
        "- Application Flutter : Visualisation 2D interactive des clusters, estimation en direct, quiz citoyen, "
        "et integration de l'Assistant IA global pour guider l'utilisateur."
    )

    pdf.chapter_title(9, "Esprit Critique et Retrospective")
    pdf.bullet_point(
        "Dataset Synthetique",
        "L'obtention d'une Accuracy de 99.7%+ revele un dataset fortement separable et de nature synthetique. En conditions reelles, cela requerrait des verifications strictes contre les risques de fuite de donnees.",
    )
    pdf.bullet_point(
        "Gestion des Dependances",
        "La correction des conflits de versions entre Gensim, Scipy et Numpy illustre la necessite d'isoler et geler les environnements de production en contexte industriel.",
    )

    pdf.ln(10)
    pdf.set_font("helvetica", "B", 10)
    pdf.set_text_color(46, 125, 50)
    pdf.cell(0, 6, "FIN DU RAPPORT TECHNIQUE OFFICIEL", align="C")

    # Save output
    pdf.output(output_path)
    print(f"Rapport technique PDF genere avec succes : {output_path}")


if __name__ == "__main__":
    out_file = (
        Path(sys.argv[1])
        if len(sys.argv) > 1
        else Path("RAPPORT_TECHNIQUE_ECO_SMART.pdf")
    )
    build_pdf(str(out_file))
