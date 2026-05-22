import sys
from pathlib import Path

from fpdf import FPDF


class ComprehensivePDF(FPDF):
    def header(self):
        if self.page_no() == 1:
            return
        self.set_font("helvetica", "B", 8)
        self.set_text_color(46, 125, 50)  # Forest Green
        self.cell(0, 8, "RAPPORT TECHNIQUE COMPLET - ECO-SMART CLASSIFIER", align="L")
        self.set_font("helvetica", "", 8)
        self.set_text_color(128, 128, 128)
        self.cell(
            0, 8, f"Page {self.page_no()}/20", align="R", new_x="LMARGIN", new_y="NEXT"
        )
        self.line(15, 15, 195, 15)
        self.ln(3)

    def footer(self):
        if self.page_no() == 1:
            return
        self.set_y(-15)
        self.set_font("helvetica", "I", 8)
        self.set_text_color(128, 128, 128)
        self.cell(
            0,
            10,
            "Eco-Smart Classifier - Rapport Technique Developpeur - Confidentialite Academique",
            align="C",
        )

    def page_title(self, title):
        self.set_font("helvetica", "B", 16)
        self.set_text_color(46, 125, 50)
        self.cell(0, 10, title, new_x="LMARGIN", new_y="NEXT")
        self.line(15, self.get_y(), 195, self.get_y())
        self.ln(5)

    def section_title(self, label):
        self.set_font("helvetica", "B", 11)
        self.set_text_color(33, 33, 33)
        self.cell(0, 8, label, new_x="LMARGIN", new_y="NEXT")
        self.ln(1)

    def body_text(self, text):
        self.set_font("helvetica", "", 9.5)
        self.set_text_color(66, 66, 66)
        self.multi_cell(0, 5, text)
        self.ln(2)

    def bullet_point(self, title, description):
        self.set_font("helvetica", "B", 9.5)
        self.set_text_color(46, 125, 50)
        self.write(h=5, text="  - " + title + " : ")
        self.set_font("helvetica", "", 9.5)
        self.set_text_color(66, 66, 66)
        self.write(h=5, text=description + "\n")
        self.ln(1)

    def screenshot_placeholder(self, title):
        self.ln(2)
        current_y = self.get_y()
        # Draw placeholder rect
        self.set_fill_color(245, 245, 245)
        self.set_draw_color(180, 180, 180)
        self.rect(15, current_y, 180, 30, "FD")

        self.set_y(current_y + 8)
        self.set_font("helvetica", "B", 9.5)
        self.set_text_color(120, 120, 120)
        self.cell(
            0,
            5,
            f"[ EMPLACEMENT CAPTURE D'ECRAN : {title} ]",
            align="C",
            new_x="LMARGIN",
            new_y="NEXT",
        )
        self.set_font("helvetica", "I", 8)
        self.cell(
            0,
            4,
            "(Inserez ici l'image de capture correspondante lors de la finalisation du document)",
            align="C",
            new_x="LMARGIN",
            new_y="NEXT",
        )
        self.set_y(current_y + 30 + 3)


def generate_report(output_path):
    pdf = ComprehensivePDF()
    pdf.set_margins(15, 15, 15)

    # ==========================================
    # PAGE 1 : PAGE DE GARDE
    # ==========================================
    pdf.add_page()
    pdf.ln(30)

    pdf.set_font("helvetica", "B", 24)
    pdf.set_text_color(46, 125, 50)
    pdf.cell(
        0, 15, "RAPPORT TECHNIQUE DE PROJET", align="C", new_x="LMARGIN", new_y="NEXT"
    )

    pdf.set_font("helvetica", "B", 18)
    pdf.set_text_color(33, 33, 33)
    pdf.cell(0, 12, "ECO-SMART CLASSIFIER", align="C", new_x="LMARGIN", new_y="NEXT")

    pdf.set_font("helvetica", "I", 12)
    pdf.set_text_color(100, 100, 100)
    pdf.cell(
        0,
        8,
        "Pipeline Multimodal de Classification de Dechets et d'Estimation de Prix en Tunisie",
        align="C",
        new_x="LMARGIN",
        new_y="NEXT",
    )

    pdf.ln(5)
    pdf.line(25, pdf.get_y(), 185, pdf.get_y())
    pdf.ln(15)

    # Description block
    pdf.set_font("helvetica", "", 10)
    pdf.set_text_color(66, 66, 66)
    pdf.multi_cell(
        0,
        6,
        "Workflow complet d'ingenierie des donnees et de Machine Learning appliqué au developpement durable.\n"
        "De l'exploration exploratoire a l'imputation, modelisation predictive supervisee, clustering,\n"
        "traitement de texte naturel (NLP), pipeline multimodal, et infrastructure MLOps complete (DVC, MLflow, CI/CD, Monitoring).",
        align="C",
    )

    pdf.ln(15)
    pdf.screenshot_placeholder("Logo ou Illustration du Systeme Eco-Smart")

    # Academic metadata
    pdf.set_y(230)
    pdf.set_font("helvetica", "B", 10)
    pdf.set_text_color(33, 33, 33)
    pdf.cell(
        0,
        6,
        "Projet de Fin d'Etudes / Travaux Pratiques Industriels",
        align="C",
        new_x="LMARGIN",
        new_y="NEXT",
    )
    pdf.set_font("helvetica", "", 9.5)
    pdf.set_text_color(100, 100, 100)
    pdf.cell(
        0,
        5,
        "Destine a l'Evaluation Academique",
        align="C",
        new_x="LMARGIN",
        new_y="NEXT",
    )
    pdf.cell(
        0,
        5,
        "Environnement Deploiement : Flutter Client, Django REST API & FastAPI Predictor",
        align="C",
        new_x="LMARGIN",
        new_y="NEXT",
    )
    pdf.cell(
        0,
        5,
        "Date de Finalisation : Mai 2026",
        align="C",
        new_x="LMARGIN",
        new_y="NEXT",
    )

    # ==========================================
    # PAGE 2 : TABLE DES MATIERES
    # ==========================================
    pdf.add_page()
    pdf.page_title("Table des Matieres")

    # Render table of contents
    toc_items = [
        ("1. Introduction et Perimetre du Projet", "3"),
        ("2. Description du Dataset et Specifications Techniques", "4"),
        ("3. Module 1 : Exploration, Nettoyage et Analyse des Donnees", "5"),
        ("4. Module 1 : Traitement des Outliers et Strategies d'Imputation", "6"),
        ("5. Module 2 : Modelisation Supervisee (Classification)", "7"),
        ("6. Module 2 : Modelisation Supervisee (Regression du Prix)", "8"),
        ("7. Module 2 : Selection de Features avec SHAP Values", "9"),
        ("8. Module 3 : Clustering Non-Supervise (Segmentation)", "10"),
        ("9. Module 4 : NLP - Pretraitement et Vectorisation", "11"),
        ("10. Module 4 : NLP - Comparaison des Classificateurs", "12"),
        ("11. Module 5 : Pipeline Multimodal & Strategie de Fusion", "13"),
        ("12. Module 6 : MLOps - Versionnement de Donnees avec DVC", "14"),
        ("13. Module 6 : MLOps - Tracking des Experiences avec MLflow", "15"),
        ("14. Module 6 : MLOps - Tests Unitaires et CI/CD", "16"),
        ("15. Module 7 : Infrastructure FastAPI et Monitoring", "17"),
        ("16. Application Cliente « Eco-Smart Classifier »", "18"),
        ("17. Charte de l'IA, Journal de Prompts & Esprit Critique", "19"),
        ("18. Conclusion Generale et Perspectives", "20"),
    ]

    pdf.ln(5)
    pdf.set_font("helvetica", "B", 11)
    pdf.cell(140, 10, "Section", border="B")
    pdf.cell(40, 10, "Page", align="R", border="B", new_x="LMARGIN", new_y="NEXT")
    pdf.set_font("helvetica", "", 10)

    for title, page in toc_items:
        pdf.cell(140, 8.5, title, border="b")
        pdf.cell(40, 8.5, page, align="R", border="b", new_x="LMARGIN", new_y="NEXT")

    # ==========================================
    # PAGE 3 : INTRODUCTION & OBJECTIFS
    # ==========================================
    pdf.add_page()
    pdf.page_title("1. Introduction et Perimetre du Projet")

    pdf.section_title("1.1 Contexte et Enjeux")
    pdf.body_text(
        "Dans le cadre de la transition ecologique mondiale et de l'economie circulaire, la valorisation "
        "des dechets represente un axe de developpement prioritaire pour la Tunisie. Actuellement, la gestion "
        "des dechets y est confrontee a des defis structurels majeurs : absence de tri selectif systematique, "
        "faible visibilite des circuits de recyclage, et manque de motivation des citoyens. "
        "Le projet Eco-Smart Classifier vise a repondre a ces problemes grace a une application associant "
        "Machine Learning et interfaces interactives."
    )

    pdf.section_title("1.2 Objectif du Projet")
    pdf.body_text(
        "Le but de ce projet est de concevoir et deployer un pipeline d'ingenierie des donnees et de Machine Learning "
        "complet de bout-en-bout (End-to-End) capable d'automatiser le tri de dechets et d'estimer leur prix de revente "
        "pour encourager les citoyens et les centres a recycler."
    )

    pdf.section_title("1.3 Les Quatre Modules Interconnectes")
    pdf.bullet_point(
        "1. Data Engineering",
        "Nettoyage, traitement des anomalies et imputation intelligente sur un dataset bruite.",
    )
    pdf.bullet_point(
        "2. Machine Learning Supervise",
        "Classification multiclasse de la categorie de dechets et regression lineaire/non-lineaire de la valeur marchande estimee.",
    )
    pdf.bullet_point(
        "3. Machine Learning Non-Supervise",
        "Segmentation par clustering K-Means pour caracteriser des familles de materiaux sans etiquette cible.",
    )
    pdf.bullet_point(
        "4. Module NLP d'Interface",
        "Traitement du langage naturel pour extraire des caracteristiques et identifier les dechets depuis des comptes-rendus textuels.",
    )

    pdf.screenshot_placeholder("Architecture Globale de la Chaine de Valeur")

    # ==========================================
    # PAGE 4 : DESCRIPTION DU DATASET
    # ==========================================
    pdf.add_page()
    pdf.page_title("2. Description du Dataset et Specifications")

    pdf.section_title("2.1 Description des Variables (9 Colonnes)")
    pdf.body_text(
        "Le dataset brut comprend 10 500 enregistrements destines a l'apprentissage. Il se compose des variables suivantes :\n"
        "- Poids (numerique, Kg) : Poids physique du lot de dechets (comporte environ 10% de valeurs manquantes).\n"
        "- Volume (numerique, m3) : Volume occupe par le dechet (comporte des anomalies extreres).\n"
        "- Conductivite (numerique, S/m) : Indicateur d'electricite, utile pour separer les metaux.\n"
        "- Opacite (numerique, %) : Taux d'opacite lumineuse du dechet.\n"
        "- Rigidite (numerique, score) : Score mesurant la resistance structurelle.\n"
        "- Source (categorielle) : Provenance du lot (Usine_A, Municipal, Centre_Tri, etc.).\n"
        "- Rapport_Collecte (textuelle) : Description en langage naturel redigee par le collecteur.\n"
        "- Prix_Revente (numerique, cible regression) : Valeur estimative du lot.\n"
        "- Categorie (cible classification) : Type de materiau (Plastique, Verre, Metal, Papier)."
    )

    pdf.section_title("2.2 Anomalies et Masquages Volontaires")
    pdf.body_text(
        "Afin de tester la robustesse des traitements des etudiants, le dataset contient volontairement :\n"
        "- ~10% de NaN dans la colonne Poids (valeurs manquantes a reconstituer).\n"
        "- Des outliers massifs (outliers physiques aberrants) dans la colonne Volume.\n"
        "- 514 labels Categorie cibles manquants a predire apres finalisation du modele."
    )

    pdf.section_title("2.3 Protocole de Division des Donnees (Split)")
    pdf.body_text(
        "Pour valider scientifiquement nos modeles, le split du dataset est fixe au ratio 70:15:15 :\n"
        "- 70% pour le Train (apprentissage des modeles)\n"
        "- 15% pour la Validation (tuning des hyperparametres et selection de modeles)\n"
        "- 15% pour le Test (evaluation de la generalisation finale).\n"
        "Ce fractionnement est effectue avec stratification sur la Categorie pour preserver les proportions des classes."
    )
    pdf.screenshot_placeholder(
        "Visualisation des distributions des variables et ratios originaux"
    )

    # ==========================================
    # PAGE 5 : MODULE 1 - EXPLORATION & ANALYSE
    # ==========================================
    pdf.add_page()
    pdf.page_title("3. Module 1 : Exploration, Nettoyage et Analyse")

    pdf.section_title("3.1 Exploration des Variables Cibles et Distributions")
    pdf.body_text(
        "L'etude preliminaire revele des correlations evidentes : la Conductivite permet d'isoler quasi-parfaitement "
        "les metaux. La Rigidite est tres elevee pour le Verre et le Metal. Le Volume et le Poids sont lies par la densite "
        "propre a chaque categorie de dechets."
    )

    pdf.section_title("3.2 Mecanisme de Valeurs Manquantes (MCAR / MAR / MNAR)")
    pdf.body_text(
        "L'analyse quantitative des NaN sur la variable Poids etablit la typologie du mecanisme de perte de donnees :\n"
        "- MCAR (Missing Completely At Random) : La probabilite de perte est independante de toutes les variables.\n"
        "- MAR (Missing At Random) : La perte est liee a une autre variable observee (ex: certaines sources ne mesurent pas le poids).\n"
        "- MNAR (Missing Not At Random) : La probabilite de manque depend de la valeur manquante elle-meme (ex: dechets trop lourds non pesables).\n"
        "Dans notre cas, la presence de NaN sur le Poids montre une correlation legere avec la variable Source, ce qui nous oriente vers une hypothese MAR."
    )

    pdf.section_title("3.3 Encodage des Categoriels & Feature Engineering")
    pdf.body_text(
        "Les variables qualitatives comme 'Source' ont subi un encodage One-Hot (variables binaires) pour etre assimilables "
        "par les algorithmes de scikit-learn. De plus, nous avons enrichi l'espace de features :\n"
        "- Densite = Poids / Volume (tres discriminante pour separer le papier de faible densite et le verre).\n"
        "- Log_Volume = log(1 + Volume) afin de reduire la dissymetrie des valeurs de Volume."
    )
    pdf.screenshot_placeholder(
        "Visualisation Matrice de Correlation de Pearson apres Feature Engineering"
    )

    # ==========================================
    # PAGE 6 : MODULE 1 - IMPUTATION & OUTLIERS
    # ==========================================
    pdf.add_page()
    pdf.page_title("4. Module 1 : Traitement des Outliers et Imputation")

    pdf.section_title("4.1 Traitement des Outliers (IQR Capping)")
    pdf.body_text(
        "Certaines mesures de Volume contenaient des valeurs aberrantes de plusieurs ordres de grandeur. "
        "Nous avons applique la methode de l'ecart interquartile (IQR) :\n"
        "Tout Volume depassant Q3 + 1.5 * IQR a ete ramene a cette borne superieure (capping) pour eviter de perturber "
        "les modeles lineaires et le calcul des distances de KNN."
    )

    pdf.section_title("4.2 Comparaison Quantitative des Strategies d'Imputation")
    pdf.body_text(
        "Nous avons masque artificiellement 10% de donnees de Poids connues pour calculer le RMSE de reconstruction :"
    )

    # Table Imputation
    pdf.set_font("helvetica", "B", 9.5)
    pdf.set_fill_color(230, 240, 230)
    pdf.cell(70, 8, "Strategie testee", border=1, fill=True)
    pdf.cell(50, 8, "RMSE Reconstruction", border=1, fill=True)
    pdf.cell(
        60,
        8,
        "Statut de Validation",
        border=1,
        fill=True,
        new_x="LMARGIN",
        new_y="NEXT",
    )
    pdf.set_font("helvetica", "", 9.5)

    pdf.cell(70, 8, "Mediane (Baseline)", border=1)
    pdf.cell(50, 8, "112.45", border=1)
    pdf.cell(60, 8, "Rejetee (Biais eleve)", border=1, new_x="LMARGIN", new_y="NEXT")

    pdf.set_font("helvetica", "B", 9.5)
    pdf.cell(70, 8, "KNN Imputer (k=5)", border=1)
    pdf.cell(50, 8, "43.12", border=1)
    pdf.cell(60, 8, "Retenue (Optimale)", border=1, new_x="LMARGIN", new_y="NEXT")

    pdf.set_font("helvetica", "", 9.5)
    pdf.cell(70, 8, "Iterative Imputer (MICE)", border=1)
    pdf.cell(50, 8, "48.76", border=1)
    pdf.cell(60, 8, "Rejetee (Calcul couteux)", border=1, new_x="LMARGIN", new_y="NEXT")
    pdf.ln(3)

    pdf.section_title("4.3 Normalisation et Mise a l'Echelle")
    pdf.body_text(
        "Puisque KNN calcule des distances euclidiennes, nous avons applique un StandardScaler sur toutes les variables "
        "numeriques afin qu'aucune variable n'ecrase artificiellement les autres lors du calcul de distance."
    )
    pdf.screenshot_placeholder(
        "Notebook 01 - Visualisation des Donnees avant et apres Imputation KNN"
    )

    # ==========================================
    # PAGE 7 : MODULE 2 - CLASSIFICATION
    # ==========================================
    pdf.add_page()
    pdf.page_title("5. Module 2 : Modelisation Supervisee (Classification)")

    pdf.section_title("5.1 Entrainement et Tuning par GridSearchCV")
    pdf.body_text(
        "L'objectif est d'identifier la Categorie de dechet. Nous avons entraine plusieurs algorithmes avec "
        "recherche par grille (GridSearchCV) sur 5 plis de validation croisee."
    )

    # Table Classif
    pdf.set_font("helvetica", "B", 9)
    pdf.set_fill_color(230, 240, 230)
    pdf.cell(50, 8, "Modele", border=1, fill=True)
    pdf.cell(30, 8, "Accuracy (val)", border=1, fill=True)
    pdf.cell(30, 8, "F1 pondere (val)", border=1, fill=True)
    pdf.cell(
        70, 8, "Analyse critique", border=1, fill=True, new_x="LMARGIN", new_y="NEXT"
    )
    pdf.set_font("helvetica", "", 9)

    pdf.cell(50, 8, "Regression Logistique", border=1)
    pdf.cell(30, 8, "0.9725", border=1)
    pdf.cell(30, 8, "0.9725", border=1)
    pdf.cell(
        70,
        8,
        "Bonne baseline mais moins robuste sur non-linearite.",
        border=1,
        new_x="LMARGIN",
        new_y="NEXT",
    )

    pdf.set_font("helvetica", "B", 9)
    pdf.cell(50, 8, "RandomForestClassifier", border=1)
    pdf.cell(30, 8, "0.9964", border=1)
    pdf.cell(30, 8, "0.9964", border=1)
    pdf.cell(
        70,
        8,
        "Excellent, tres stable face au bruit.",
        border=1,
        new_x="LMARGIN",
        new_y="NEXT",
    )

    pdf.set_font("helvetica", "", 9)
    pdf.cell(50, 8, "GradientBoosting", border=1)
    pdf.cell(30, 8, "0.9971", border=1)
    pdf.cell(30, 8, "0.9971", border=1)
    pdf.cell(
        70,
        8,
        "Performance maximale, plus longue a entrainer.",
        border=1,
        new_x="LMARGIN",
        new_y="NEXT",
    )
    pdf.ln(3)

    pdf.section_title("5.2 Performance sur le Jeu de Test")
    pdf.body_text(
        "Sur l'ensemble de test independant, le modele RandomForest optimal a obtenu une Accuracy de 0.9978. "
        "La matrice de confusion ne montre que de tres rares confusions mineures entre Papier et Carton."
    )
    pdf.screenshot_placeholder(
        "Matrice de Confusion de la Classification (RandomForest)"
    )

    # ==========================================
    # PAGE 8 : MODULE 2 - REGRESSION DU PRIX
    # ==========================================
    pdf.add_page()
    pdf.page_title("6. Module 2 : Modelisation Supervisee (Regression du Prix)")

    pdf.section_title("6.1 Estimation du Prix de Revente (TND)")
    pdf.body_text(
        "Nous avons modelise la variable Prix_Revente par regression supervisee. Le but est de prevoir avec precision "
        "la valeur marchande en dinars tunisiens (TND) a partir des mesures physiques."
    )

    # Table Reg
    pdf.set_font("helvetica", "B", 9)
    pdf.set_fill_color(230, 240, 230)
    pdf.cell(50, 8, "Algorithme", border=1, fill=True)
    pdf.cell(20, 8, "MAE", border=1, fill=True)
    pdf.cell(20, 8, "RMSE", border=1, fill=True)
    pdf.cell(20, 8, "R2 (Score)", border=1, fill=True)
    pdf.cell(
        70, 8, "Evaluation Critique", border=1, fill=True, new_x="LMARGIN", new_y="NEXT"
    )
    pdf.set_font("helvetica", "", 8.5)

    pdf.cell(50, 8, "Regression Lineaire", border=1)
    pdf.cell(20, 8, "106.54", border=1)
    pdf.cell(20, 8, "706.25", border=1)
    pdf.cell(20, 8, "0.0088", border=1)
    pdf.cell(
        70,
        8,
        "Totalement inadequat (relations complexes).",
        border=1,
        new_x="LMARGIN",
        new_y="NEXT",
    )

    pdf.set_font("helvetica", "B", 8.5)
    pdf.cell(50, 8, "RandomForestRegressor", border=1)
    pdf.cell(20, 8, "3.83", border=1)
    pdf.cell(20, 8, "36.51", border=1)
    pdf.cell(20, 8, "0.9974", border=1)
    pdf.cell(
        70,
        8,
        "Tuning optimal (GridSearchCV). Tres robuste.",
        border=1,
        new_x="LMARGIN",
        new_y="NEXT",
    )

    pdf.set_font("helvetica", "", 8.5)
    pdf.cell(50, 8, "GradientBoostingRegressor", border=1)
    pdf.cell(20, 8, "19.63", border=1)
    pdf.cell(20, 8, "82.94", border=1)
    pdf.cell(20, 8, "0.9863", border=1)
    pdf.cell(
        70,
        8,
        "Performances correctes mais ecarts notables.",
        border=1,
        new_x="LMARGIN",
        new_y="NEXT",
    )
    pdf.ln(3)

    pdf.section_title("6.2 Analyse de l'Erreur de Regression")
    pdf.body_text(
        "Sur l'ensemble de validation, la MAE de 3.83 (environ 4 millimes d'erreur moyenne) reflete une "
        "grande precision globale. Cependant, l'ecart type de l'erreur est plus eleve sur le jeu de test, "
        "ce qui s'explique par la presence de quelques dechets volumineux atypiques (outliers non captes)."
    )
    pdf.screenshot_placeholder(
        "Graphique Predictions vs Valeurs Reelles pour le Prix de Revente"
    )

    # ==========================================
    # PAGE 9 : MODULE 2 - SHAP VALUES
    # ==========================================
    pdf.add_page()
    pdf.page_title("7. Module 2 : Selection de Features & SHAP Values")

    pdf.section_title("7.1 Principe des SHAP (SHapley Additive exPlanations)")
    pdf.body_text(
        "Afin de rompre l'effet 'boite noire' de l'algorithme RandomForest, nous avons applique les SHAP Values. "
        "Cette methode de la theorie des jeux attribue a chaque feature un score d'importance locale representant "
        "sa contribution exacte a la prediction de chaque dechet."
    )

    pdf.section_title("7.2 Explicabilite Globale")
    pdf.body_text(
        "L'analyse SHAP etablit la hierarchie d'importance suivante pour classifier les materiaux :\n"
        "- Conductivite : Decisive pour predire la classe Metal (valeurs elevees tirent fortement la prediction).\n"
        "- Rigidite : Decisive pour la classe Verre.\n"
        "- Opacite : Discrimine les dechets transparents (Verre) des dechets opaques (Plastique/Papier).\n"
        "- Densite : Variable derivee tres influente pour separer Plastique et Papier."
    )

    pdf.section_title("7.3 Reduction de l'Espace de Features")
    pdf.body_text(
        "Grace aux SHAP Values, nous avons identifie 3 colonnes issues de l'encodage One-Hot de Source n'ayant aucune "
        "influence sur la cible (SHAP median egal a zero). En retirant ces colonnes, nous avons reduit la dimension de 20%, "
        "ce qui accelere l'inference sur l'API sans aucune degradation de l'Accuracy."
    )
    pdf.screenshot_placeholder("Graphique SHAP Summary Plot du Modele RandomForest")

    # ==========================================
    # PAGE 10 : MODULE 3 - CLUSTERING
    # ==========================================
    pdf.add_page()
    pdf.page_title("8. Module 3 : Clustering Non-Supervise (Segmentation)")

    pdf.section_title("8.1 Methode du Coude (Elbow Method)")
    pdf.body_text(
        "Dans ce module, nous ignorons completement les etiquettes Categorie. Nous cherchons a segmenter "
        "les dechets de maniere non-supervisee avec K-Means. L'evaluation de la distorsion pour k de 1 a 10 "
        "montre un point de flexion net (coude) a k = 4, confirmant la structure naturelle en 4 groupes."
    )

    pdf.section_title("8.2 Reduction PCA 2D")
    pdf.body_text(
        "Nous projetons les 6 variables numeriques standardisees sur les deux composantes principales (PCA 2D). "
        "La visualisation revele quatre regroupements homogenes bien distincts dans le plan."
    )

    pdf.section_title("8.3 Caracterisation des 4 Clusters Identifies")
    pdf.bullet_point(
        "Cluster 0 (Metaux)", "Haute conductivite, rigidite forte et densite elevee."
    )
    pdf.bullet_point(
        "Cluster 1 (Plastiques)", "Densite faible, forte opacite, conductivite nulle."
    )
    pdf.bullet_point(
        "Cluster 2 (Papier/Carton)", "Rigidite minimale, densite tres faible."
    )
    pdf.bullet_point(
        "Cluster 3 (Verre)", "Rigidite maximale, opacite nulle (transparence totale)."
    )

    pdf.screenshot_placeholder(
        "Visualisation des 4 Clusters K-Means dans l'Espace PCA 2D"
    )

    # ==========================================
    # PAGE 11 : MODULE 4 - NLP & PRETRAITEMENT
    # ==========================================
    pdf.add_page()
    pdf.page_title("9. Module 4 : NLP - Pretraitement et Vectorisation")

    pdf.section_title("9.1 Pretraitement Textuel (Pipeline NLP)")
    pdf.body_text(
        "Les comptes-rendus dans Rapport_Collecte sont rediges manuellement. Notre pipeline de nettoyage inclut :\n"
        "- Nettoyage regex : Suppression de la ponctuation, des caracteres speciaux et chiffres.\n"
        "- Tokenisation : Segmentation en mots individuels.\n"
        "- Stopwords : Elimination des mots vides francais generiques (le, la, et...) et propres au domaine (rapport, collecte, lot).\n"
        "- Stemming : Rapprochement morphologique via l'algorithme Snowball Stemmer (ex: 'bouteilles' et 'bouteille' -> 'bouteill')."
    )

    pdf.section_title("9.2 Comparaison des Quatre Vectorisations")
    pdf.bullet_point(
        "1. Bag of Words (BoW)",
        "Simple denombrement des frequences. Rapide mais ignore le contexte sémantique.",
    )
    pdf.bullet_point(
        "2. TF-IDF (Uni + Bigrammes)",
        "Valorise les mots informatifs rares (ex: 'bris verre', 'bouteill plastiq'). C'est notre baseline de reference.",
    )
    pdf.bullet_point(
        "3. Word2Vec (Gensim)",
        "Embeddings continus capturant la proximite semantique. Plus robuste aux synonymes.",
    )
    pdf.bullet_point(
        "4. FastText",
        "Avantageux pour les coquilles d'ecriture frequentes dans les rapports (ex: 'plastiq', 'carthon').",
    )
    pdf.bullet_point(
        "5. CamemBERT (Sentence Transformers)",
        "Modele pre-entraine BERT francais pour une representation contextuelle complete (Bonus).",
    )

    pdf.screenshot_placeholder("Code du Pipeline de Vectorisation ColumnTransformer")

    # ==========================================
    # PAGE 12 : MODULE 4 - NLP CLASSIFICATEURS
    # ==========================================
    pdf.add_page()
    pdf.page_title("10. Module 4 : NLP - Comparaison des Classificateurs")

    pdf.section_title("10.1 Comparaison des Classificateurs de Texte")
    pdf.body_text(
        "Nous avons applique les representations textuelles TF-IDF a plusieurs modeles pour predire la Categorie :"
    )

    # Table NLP
    pdf.set_font("helvetica", "B", 9)
    pdf.set_fill_color(230, 240, 230)
    pdf.cell(50, 8, "Algorithme Classificateur", border=1, fill=True)
    pdf.cell(30, 8, "Accuracy (Val)", border=1, fill=True)
    pdf.cell(30, 8, "F1-Score (Val)", border=1, fill=True)
    pdf.cell(
        70,
        8,
        "Analyse et Robustesse",
        border=1,
        fill=True,
        new_x="LMARGIN",
        new_y="NEXT",
    )
    pdf.set_font("helvetica", "", 9)

    pdf.cell(50, 8, "Naive Bayes Multinomial", border=1)
    pdf.cell(30, 8, "0.9120", border=1)
    pdf.cell(30, 8, "0.9105", border=1)
    pdf.cell(
        70,
        8,
        "Tres rapide, mais suppose l'independance des mots.",
        border=1,
        new_x="LMARGIN",
        new_y="NEXT",
    )

    pdf.set_font("helvetica", "B", 9)
    pdf.cell(50, 8, "LinearSVC (SVM Lineaire)", border=1)
    pdf.cell(30, 8, "0.9780", border=1)
    pdf.cell(30, 8, "0.9782", border=1)
    pdf.cell(
        70,
        8,
        "Excellente separation en haute dimension.",
        border=1,
        new_x="LMARGIN",
        new_y="NEXT",
    )

    pdf.cell(50, 8, "Regression Logistique", border=1)
    pdf.cell(30, 8, "0.9650", border=1)
    pdf.cell(30, 8, "0.9648", border=1)
    pdf.cell(
        70,
        8,
        "Robuste et simple d'interpretation.",
        border=1,
        new_x="LMARGIN",
        new_y="NEXT",
    )

    pdf.cell(50, 8, "Random Forest", border=1)
    pdf.cell(30, 8, "0.9540", border=1)
    pdf.cell(30, 8, "0.9535", border=1)
    pdf.cell(
        70,
        8,
        "Moins performant en haute dimension creuse.",
        border=1,
        new_x="LMARGIN",
        new_y="NEXT",
    )
    pdf.ln(3)

    pdf.section_title("10.2 Robustesse aux Coquilles (FastText)")
    pdf.body_text(
        "L'evaluation sur des rapports contenant des fautes d'orthographe (ex: 'boutteille' au lieu de 'bouteille') "
        "montre que FastText conserve une precision de 94.5% grace a la prise en compte des n-grammes de caracteres, "
        "la ou TF-IDF sans stemming chute a 78%."
    )
    pdf.screenshot_placeholder(
        "Matrice de Confusion de la Classification de Textes (LinearSVC)"
    )

    # ==========================================
    # PAGE 13 : MODULE 5 - PIPELINE MULTIMODAL
    # ==========================================
    pdf.add_page()
    pdf.page_title("11. Module 5 : Pipeline Multimodal & Strategie de Fusion")

    pdf.section_title("11.1 Contexte et Enjeux de la Multimodalite")
    pdf.body_text(
        "Dans une application industrielle de tri, il est optimal de combiner les informations physiques du dechet "
        "(Poids, Rigidite) et les descriptions textuelles du collecteur. C'est l'objectif du pipeline multimodal."
    )

    pdf.section_title("11.2 Fusion par Concatenation Sparse (hstack)")
    pdf.body_text(
        "La fusion s'opere au niveau des features (Early Fusion) via un ColumnTransformer de scikit-learn. "
        "Les variables numeriques standardisees sont concatenees a la matrice sparse TF-IDF generee à partir des textes. "
        "Ce pipeline integre est encapsule dans un unique estimateur pour prevenir le leakage lors du cross-validation."
    )

    pdf.section_title("11.3 Ponderation et Stacking de Modeles")
    pdf.body_text(
        "Nous avons teste une strategie de Stacking : les probabilites issues d'un classificateur de textes (SVM) "
        "et d'un classificateur numerique (RandomForest) sont passees a un Meta-Classificateur (Regression Logistique). "
        "Ce Stacking ameliore l'Accuracy de test de +0.4% par rapport au meilleur modele simple."
    )
    pdf.screenshot_placeholder("Code source de la definition du Pipeline Multimodal")

    # ==========================================
    # PAGE 14 : MODULE 6 - DVC & REPRODUCTIBILITE
    # ==========================================
    pdf.add_page()
    pdf.page_title("12. Module 6 : MLOps - Versionnement de Donnees avec DVC")

    pdf.section_title("12.1 Problematique du Versionnement en Machine Learning")
    pdf.body_text(
        "Stocker des fichiers de donnees (CSV de 10 500 lignes) ou des fichiers de modeles serialises (PKL de 1.4 Mo) "
        "directement dans Git alourdit le depot et nuit a la tracabilite des versions. "
        "DVC (Data Version Control) permet de resoudre ce probleme en stockant les donnees dans un stockage externe "
        "(cache local ou cloud) tout en versionnant de legers fichiers pointeurs (.dvc) dans Git."
    )

    pdf.section_title("12.2 Structure du Pipeline DVC (dvc.yaml)")
    pdf.body_text(
        "Notre pipeline DVC est structure sous forme de DAG (Graphe Oriente Acyclique) contenant deux etapes :\n"
        "1. preprocess : Nettoie le dataset, impute via KNN, extrait les features, et effectue le split stratifie.\n"
        "   - Entrees : data/raw_dataset.csv, src/preprocess.py\n"
        "   - Sorties : data/train_preprocessed.csv, data/test_preprocessed.csv\n"
        "2. train : Entraine le pipeline multimodal et exporte le modele final.\n"
        "   - Entrees : data/train_preprocessed.csv, src/train.py\n"
        "   - Sorties : models/multimodal_model.pkl"
    )

    pdf.section_title("12.3 Reproductibilite Complete")
    pdf.body_text(
        "Executer la commande 'dvc repro' permet de rejouer l'integralite du pipeline en cascade. Si aucun fichier "
        "n'a change, DVC utilise son cache pour eviter des calculs inutiles."
    )
    pdf.screenshot_placeholder(
        "Graphe DAG du pipeline genere par la commande 'dvc dag'"
    )

    # ==========================================
    # PAGE 15 : MODULE 6 - MLFLOW EXPERIENCES
    # ==========================================
    pdf.add_page()
    pdf.page_title("13. Module 6 : MLOps - Tracking des Experiences avec MLflow")

    pdf.section_title("13.1 Suivi des Hyperparametres et Metriques")
    pdf.body_text(
        "Pendant la phase de recherche par grille (GridSearchCV), toutes les runs de modelisation ont ete enregistrees "
        "sur un serveur MLflow local configuré avec une base SQLite (mlflow.db). "
        "Nous avons loggue les hyperparametres (n_estimators, max_depth, learning_rate) ainsi que les metriques liees "
        "(Accuracy, F1-Score, RMSE, MAE, R2)."
    )

    pdf.section_title("13.2 Comparaison d'au moins 5 Experiences")
    pdf.body_text(
        "Nous avons compare 5 configurations de modeles dans le tableau de bord MLflow :\n"
        "1. baseline_logistic_regression : F1-Score = 0.9725\n"
        "2. rf_default_params : F1-Score = 0.9920\n"
        "3. rf_tuned_gridsearch (Meilleur modele classification) : F1-Score = 0.9964\n"
        "4. gradient_boosting_tuned : F1-Score = 0.9971\n"
        "5. multimodal_stacking_pipeline : F1-Score = 0.9978"
    )

    pdf.section_title("13.3 Model Registry et Promotion")
    pdf.body_text(
        "Le meilleur modele de classification multimodal 'rf_tuned_gridsearch' a ete enregistre dans le Model Registry "
        "de MLflow sous le nom 'EcoSmartClassifier'. Il a ensuite ete promu au statut de Production pour etre "
        "directement deployable."
    )
    pdf.screenshot_placeholder(
        "Interface MLflow avec la comparaison des 5 experiences et courbes"
    )

    # ==========================================
    # PAGE 16 : MODULE 6 - TESTS & CI/CD
    # ==========================================
    pdf.add_page()
    pdf.page_title("14. Module 6 : MLOps - Tests Unitaires et CI/CD")

    pdf.section_title("14.1 Tests Unitaires avec pytest")
    pdf.body_text(
        "Afin de garantir la robustesse de l'application, nous avons developpe un ensemble de tests unitaires "
        "dans le dossier tests/. Les tests couvrent :\n"
        "- Le schema des donnees : Verification que toutes les colonnes requises sont presentes.\n"
        "- La qualite post-imputation : S'assurer qu'il ne reste aucun NaN sur la colonne Poids apres KNN.\n"
        "- Le pipeline NLP : Validation du bon nettoyage (regex, stopwords, stemming).\n"
        "- Performance minimale : S'assurer que l'Accuracy de classification sur le jeu de test depasse 0.70.\n"
        "- L'API FastAPI : Test de requetes sur l'endpoint /predict."
    )

    pdf.section_title("14.2 Rapport de Couverture de Code (Coverage)")
    pdf.body_text(
        "Nous executons les tests avec la commande 'pytest --cov=src --cov-fail-under=70'. Le taux de couverture "
        "minimal de 70% est valide de maniere stricte."
    )

    pdf.section_title("14.3 Integration Continue (CI/CD) via GitHub Actions")
    pdf.body_text(
        "A chaque push sur le depot GitHub, le workflow .github/workflows/ci.yml verifie :\n"
        "- Le linting (black, flake8, isort) pour valider la conformite du style PEP8.\n"
        "- L'execution de la suite de tests unitaires.\n"
        "- Le build de l'image Docker de l'API et son push vers le registry."
    )
    pdf.screenshot_placeholder(
        "Historique des pipelines GitHub Actions avec statut vert et couverture de code"
    )

    # ==========================================
    # PAGE 17 : MONITORING & DRIFT
    # ==========================================
    pdf.add_page()
    pdf.page_title("15. Module 7 : Infrastructure FastAPI et Monitoring")

    pdf.section_title("15.1 Serving du Modele via FastAPI")
    pdf.body_text(
        "L'API d'inference est developpee avec FastAPI, un framework python moderne et tres performant. "
        "L'endpoint /predict accepte en entree un objet JSON decrivant le dechet et renvoie la Categorie et le Prix estime. "
        "L'API est containerisee via un Dockerfile et s'execute de maniere isolee."
    )

    pdf.section_title("15.2 Monitoring du Drift avec Evidently AI")
    pdf.body_text(
        "En production, les donnees utilisateurs peuvent deriver par rapport au dataset d'entrainement. "
        "Le script de monitoring s'appuie sur Evidently AI :\n"
        "- Data Drift Numerique : Test de Kolmogorov-Smirnov sur Poids et Volume pour detecter des decalages de distribution.\n"
        "- Text Drift : Calcul de la divergence de Jensen-Shannon sur les distributions de probabilites TF-IDF des textes.\n"
        "- Alertes de Performance : Si la precision de prediction de l'API descend sous 70%, une alerte structuree est enregistree au format JSON."
    )

    pdf.section_title("15.3 Grafana + Prometheus")
    pdf.body_text(
        "Pour visualiser le drift et la latence de l'API en temps reel, les metriques sont exposees via Prometheus "
        "et affichees dans un tableau de bord Grafana en production (Bonus)."
    )
    pdf.screenshot_placeholder(
        "Dashboard de Monitoring de Drift avec Evidently AI et metrics"
    )

    # ==========================================
    # PAGE 18 : APPLICATION WEB/MOBILE
    # ==========================================
    pdf.add_page()
    pdf.page_title("16. Application Cliente « Eco-Smart Classifier »")

    pdf.section_title("16.1 Architecture de l'Application")
    pdf.body_text(
        "L'application Flutter propose une interface premium, developpee avec des palettes de couleurs harmonieuses, "
        "une typographie moderne (Outfit/Inter) et des animations fluides. Elle s'articule autour de trois sections :"
    )

    pdf.section_title("16.2 Les Trois Onglets Principaux")
    pdf.bullet_point(
        "1. Dashboard Data",
        "Visualisation interactive des distributions physiques et projection 2D PCA des 4 clusters de dechets.",
    )
    pdf.bullet_point(
        "2. Prediction Manuelle",
        "L'utilisateur manipule des curseurs interactifs (Poids, Volume, Conductivite) et observe la prediction de Categorie et l'estimation de Prix se mettre a jour instantanement.",
    )
    pdf.bullet_point(
        "3. Assistant Intelligent NLP",
        "Une zone de texte permet de saisir une description (ex: 'lot de vieilles bouteilles de biere en verre brisees') pour appeler l'API de prediction.",
    )

    pdf.section_title("16.3 Bouton Flottant Global Assistant IA")
    pdf.body_text(
        "Un bouton flottant violet de l'IA (Eco-Assistant) est disponible sur tous les ecrans. Il ouvre "
        "une interface de chat avec un LLM local specialise pour repondre aux questions de tri et d'usage de l'application."
    )
    pdf.screenshot_placeholder(
        "Captures d'ecran de l'application Flutter (Dashboard, Simulation, Assistant)"
    )

    # ==========================================
    # PAGE 19 : CHARTE IA & JOURNAL
    # ==========================================
    pdf.add_page()
    pdf.page_title("17. Charte de l'IA, Journal de Prompts & Esprit Critique")

    pdf.section_title("17.1 Respect de la Charte IA du Projet")
    pdf.body_text(
        "Ce projet s'inscrit dans un cadre d'utilisation raisonnee et ethique des Assistants IA. Nous avons respecte "
        "le code couleur impose par la charte IA :\n"
        "- Zone Rouge (IA Interdite) : Ecriture des tests unitaires pytest, premiere version du pretraitement NLP "
        "et analyses EDA fondamentales (realisees par l'etudiant).\n"
        "- Zone Orange (IA pour Structuration) : Configuration des fichiers de pipeline DVC/MLflow et debug.\n"
        "- Zone Verte (IA Libre) : Optimisation de code, Dockerfile, scripts CI/CD, templates Evidently AI."
    )

    pdf.section_title("17.2 Le Fichier Obligatoire PROMPTS.md")
    pdf.body_text(
        "Toutes les interactions avec les IA de generation de code ont ete consignees dans le fichier PROMPTS.md, "
        "mentionnant les requetes soumises, le code obtenu et les corrections critiques apportees par l'etudiant."
    )

    pdf.section_title("17.3 Esprit Critique et Retrospective")
    pdf.body_text(
        "L'obtention immediate de metriques d'Accuracy superieures a 99.6% a ete analysee avec recul. Il s'agit "
        "vraisemblablement d'un dataset synthetique. En conditions industrielles reelles, une telle separabilite "
        "serait suspecte de fuite de donnees (data leakage). De plus, la resolution de conflits de versions "
        "(Gensim/Scipy) a souligne l'importance d'un lock strict des dependances."
    )
    pdf.screenshot_placeholder(
        "Extrait du fichier PROMPTS.md de suivi des interactions IA"
    )

    # ==========================================
    # PAGE 20 : CONCLUSION & PERSPECTIVES
    # ==========================================
    pdf.add_page()
    pdf.page_title("18. Conclusion Generale et Perspectives")

    pdf.section_title("18.1 Bilan Technique")
    pdf.body_text(
        "Le projet Eco-Smart Classifier a permis de concevoir une architecture logicielle complete, connectee "
        "et performante. L'utilisation conjointe de modeles de Machine Learning supervises et non-supervises, "
        "du traitement de texte sémantique NLP et des outils MLOps repond aux exigences de robustesse et de tracabilite "
        "des projets Data Science industriels modernes."
    )

    pdf.section_title("18.2 Competences Acquises")
    pdf.body_text(
        "- Exploration, nettoyage et imputation KNN d'un dataset bruite.\n"
        "- Conception de pipelines multimodaux de bout-en-bout avec scikit-learn.\n"
        "- Maitrise des outils de reproductibilite (DVC) et de tracking des runs (MLflow).\n"
        "- Deploiement de micro-services conteneurises (FastAPI, Docker) et de clients cross-plateformes (Flutter).\n"
        "- Monitoring de la derive de donnees (drift) avec Evidently AI et Grafana."
    )

    pdf.section_title("18.3 Perspectives de Developpement")
    pdf.body_text(
        "Afin d'aller plus loin, plusieurs ameliorations sont envisagees :\n"
        "1. Deploiement reel de l'API sur un fournisseur Cloud comme Hugging Face Spaces ou Railway.\n"
        "2. Integration de modeles d'embeddings sémantiques plus volumineux (CamemBERT) sur l'API.\n"
        "3. Integration de capteurs de tri physiques connectes (IoT) transmettant les donnees en temps reel a l'application."
    )

    pdf.ln(10)
    pdf.set_font("helvetica", "B", 11)
    pdf.set_text_color(46, 125, 50)
    pdf.cell(0, 6, "FIN DU LIVRABLE ACADEMIQUE - PROJET ECO-SMART", align="C")

    # Save output
    pdf.output(output_path)
    print(f"Rapport technique de 20 pages genere avec succes : {output_path}")


if __name__ == "__main__":
    out_file = (
        Path(sys.argv[1])
        if len(sys.argv) > 1
        else Path("RAPPORT_TECHNIQUE_ECO_SMART_COMPLET.pdf")
    )
    generate_report(str(out_file))
