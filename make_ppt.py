from pathlib import Path

from PIL import Image
from pptx import Presentation
from pptx.dml.color import RGBColor
from pptx.enum.shapes import MSO_SHAPE
from pptx.enum.text import PP_ALIGN
from pptx.util import Inches, Pt

PRIMARY = RGBColor(11, 45, 92)
SECONDARY = RGBColor(20, 131, 182)
ACCENT = RGBColor(245, 166, 35)
TEXT_DARK = RGBColor(34, 34, 34)
TEXT_LIGHT = RGBColor(245, 247, 250)
BG_LIGHT = RGBColor(248, 251, 255)
PLACEHOLDER_BG = RGBColor(231, 238, 247)


def style_text(run, size=20, bold=False, color=TEXT_DARK, name="Calibri"):
    run.font.name = name
    run.font.size = Pt(size)
    run.font.bold = bold
    run.font.color.rgb = color


def add_header_band(slide, title, subtitle=None):
    band = slide.shapes.add_shape(
        MSO_SHAPE.RECTANGLE, Inches(0), Inches(0), Inches(13.33), Inches(1.25)
    )
    band.fill.solid()
    band.fill.fore_color.rgb = PRIMARY
    band.line.fill.background()

    stripe = slide.shapes.add_shape(
        MSO_SHAPE.RECTANGLE, Inches(0), Inches(1.12), Inches(13.33), Inches(0.13)
    )
    stripe.fill.solid()
    stripe.fill.fore_color.rgb = SECONDARY
    stripe.line.fill.background()

    title_box = slide.shapes.add_textbox(
        Inches(0.6), Inches(0.25), Inches(10.4), Inches(0.52)
    )
    title_tf = title_box.text_frame
    title_tf.clear()
    p = title_tf.paragraphs[0]
    r = p.add_run()
    r.text = title
    style_text(r, size=30, bold=True, color=TEXT_LIGHT)

    if subtitle:
        sub_box = slide.shapes.add_textbox(
            Inches(0.6), Inches(0.73), Inches(10.8), Inches(0.35)
        )
        sub_tf = sub_box.text_frame
        sub_tf.clear()
        p_sub = sub_tf.paragraphs[0]
        r_sub = p_sub.add_run()
        r_sub.text = subtitle
        style_text(r_sub, size=15, color=RGBColor(214, 228, 243))

    badge = slide.shapes.add_shape(
        MSO_SHAPE.ROUNDED_RECTANGLE,
        Inches(11.25),
        Inches(0.26),
        Inches(1.45),
        Inches(0.56),
    )
    badge.fill.solid()
    badge.fill.fore_color.rgb = ACCENT
    badge.line.fill.background()
    badge_tf = badge.text_frame
    badge_tf.clear()
    p_badge = badge_tf.paragraphs[0]
    p_badge.alignment = PP_ALIGN.CENTER
    run_badge = p_badge.add_run()
    run_badge.text = "SOUTENANCE"
    style_text(run_badge, size=12, bold=True, color=PRIMARY)


def add_footer(slide, page_number):
    footer = slide.shapes.add_shape(
        MSO_SHAPE.RECTANGLE, Inches(0), Inches(7.24), Inches(13.33), Inches(0.26)
    )
    footer.fill.solid()
    footer.fill.fore_color.rgb = BG_LIGHT
    footer.line.fill.background()

    left = slide.shapes.add_textbox(
        Inches(0.5), Inches(7.24), Inches(7.5), Inches(0.22)
    )
    left_tf = left.text_frame
    left_tf.clear()
    lp = left_tf.paragraphs[0]
    lrun = lp.add_run()
    lrun.text = "Eco-Smart Classifier - Flutter + FastAPI/Django"
    style_text(lrun, size=10, color=RGBColor(94, 104, 117))

    right = slide.shapes.add_textbox(
        Inches(12.45), Inches(7.24), Inches(0.45), Inches(0.22)
    )
    right_tf = right.text_frame
    right_tf.clear()
    rp = right_tf.paragraphs[0]
    rp.alignment = PP_ALIGN.RIGHT
    rrun = rp.add_run()
    rrun.text = str(page_number)
    style_text(rrun, size=10, bold=True, color=PRIMARY)


def set_speaker_notes(slide, notes_text):
    notes = slide.notes_slide.notes_text_frame
    notes.clear()
    notes.text = notes_text


def add_bullet_content(slide, bullets):
    box = slide.shapes.add_shape(
        MSO_SHAPE.ROUNDED_RECTANGLE,
        Inches(0.7),
        Inches(1.55),
        Inches(12.0),
        Inches(5.35),
    )
    box.fill.solid()
    box.fill.fore_color.rgb = BG_LIGHT
    box.line.color.rgb = RGBColor(217, 225, 236)

    tf = box.text_frame
    tf.clear()
    tf.margin_left = Inches(0.24)
    tf.margin_right = Inches(0.24)
    tf.margin_top = Inches(0.18)

    for i, bullet in enumerate(bullets):
        p = tf.paragraphs[0] if i == 0 else tf.add_paragraph()
        p.level = 0
        p.space_after = Pt(14)
        p.text = "• " + bullet
        for run in p.runs:
            style_text(run, size=24)


def add_picture_fit(slide, image_path, x, y, w, h, pad=0.08):
    with Image.open(image_path) as img:
        img_ratio = img.width / img.height

    # Fit the image inside the frame (no overflow), with small inner padding.
    inner_x = x + pad
    inner_y = y + pad
    inner_w = w - (2 * pad)
    inner_h = h - (2 * pad)

    box_ratio = inner_w / inner_h
    if img_ratio > box_ratio:
        pic_w = inner_w
        pic_h = inner_w / img_ratio
        pic_x = inner_x
        pic_y = inner_y + (inner_h - pic_h) / 2
    else:
        pic_h = inner_h
        pic_w = inner_h * img_ratio
        pic_x = inner_x + (inner_w - pic_w) / 2
        pic_y = inner_y

    slide.shapes.add_picture(
        str(image_path),
        Inches(pic_x),
        Inches(pic_y),
        width=Inches(pic_w),
        height=Inches(pic_h),
    )


def image_exists(image_path):
    return image_path is not None and Path(image_path).exists()


def add_screenshot_layout(slide, subtitle, notes, image_left=None, image_right=None):
    title_box = slide.shapes.add_textbox(
        Inches(0.85), Inches(1.55), Inches(12.0), Inches(0.45)
    )
    ttf = title_box.text_frame
    ttf.clear()
    p = ttf.paragraphs[0]
    run = p.add_run()
    run.text = subtitle
    style_text(run, size=22, bold=True, color=PRIMARY)

    left_x, left_y, left_w, left_h = 0.85, 2.15, 5.9, 3.75
    left = slide.shapes.add_shape(
        MSO_SHAPE.ROUNDED_RECTANGLE,
        Inches(left_x),
        Inches(left_y),
        Inches(left_w),
        Inches(left_h),
    )
    left.fill.solid()
    left.fill.fore_color.rgb = RGBColor(247, 250, 255)
    left.line.color.rgb = SECONDARY
    left_tf = left.text_frame
    left_tf.clear()
    lp = left_tf.paragraphs[0]
    lp.alignment = PP_ALIGN.CENTER
    left_run = lp.add_run()
    left_run.text = "INSERER CAPTURE 1"
    style_text(left_run, size=18, bold=True, color=PRIMARY)
    if image_exists(image_left):
        add_picture_fit(slide, image_left, left_x, left_y, left_w, left_h)

    right_x, right_y, right_w, right_h = 6.58, 2.15, 5.9, 3.75
    right = slide.shapes.add_shape(
        MSO_SHAPE.ROUNDED_RECTANGLE,
        Inches(right_x),
        Inches(right_y),
        Inches(right_w),
        Inches(right_h),
    )
    right.fill.solid()
    right.fill.fore_color.rgb = RGBColor(247, 250, 255)
    right.line.color.rgb = SECONDARY
    right_tf = right.text_frame
    right_tf.clear()
    rp = right_tf.paragraphs[0]
    rp.alignment = PP_ALIGN.CENTER
    right_run = rp.add_run()
    right_run.text = "INSERER CAPTURE 2"
    style_text(right_run, size=18, bold=True, color=PRIMARY)
    if image_exists(image_right):
        add_picture_fit(slide, image_right, right_x, right_y, right_w, right_h)

    notes_box = slide.shapes.add_shape(
        MSO_SHAPE.ROUNDED_RECTANGLE,
        Inches(0.85),
        Inches(6.1),
        Inches(11.63),
        Inches(0.72),
    )
    notes_box.fill.solid()
    notes_box.fill.fore_color.rgb = RGBColor(255, 248, 231)
    notes_box.line.color.rgb = RGBColor(240, 204, 130)
    notes_tf = notes_box.text_frame
    notes_tf.clear()
    np = notes_tf.paragraphs[0]
    nrun = np.add_run()
    nrun.text = "Message cle: " + notes
    style_text(nrun, size=16, color=RGBColor(109, 77, 16))


def add_title_slide(prs):
    slide = prs.slides.add_slide(prs.slide_layouts[6])
    bg = slide.shapes.add_shape(
        MSO_SHAPE.RECTANGLE, Inches(0), Inches(0), Inches(13.33), Inches(7.5)
    )
    bg.fill.solid()
    bg.fill.fore_color.rgb = PRIMARY
    bg.line.fill.background()

    glow = slide.shapes.add_shape(
        MSO_SHAPE.OVAL, Inches(8.9), Inches(-0.95), Inches(5.6), Inches(5.6)
    )
    glow.fill.solid()
    glow.fill.fore_color.rgb = SECONDARY
    glow.line.fill.background()

    glow2 = slide.shapes.add_shape(
        MSO_SHAPE.OVAL, Inches(-1.2), Inches(4.6), Inches(4.9), Inches(4.9)
    )
    glow2.fill.solid()
    glow2.fill.fore_color.rgb = RGBColor(15, 87, 141)
    glow2.line.fill.background()

    title = slide.shapes.add_textbox(
        Inches(0.9), Inches(1.8), Inches(10.6), Inches(1.35)
    )
    tf = title.text_frame
    tf.clear()
    p = tf.paragraphs[0]
    run = p.add_run()
    run.text = "Eco-Smart Classifier\nPipeline Data & IA"
    style_text(run, size=46, bold=True, color=TEXT_LIGHT)

    sub = slide.shapes.add_textbox(Inches(0.95), Inches(3.35), Inches(8.8), Inches(0.7))
    stf = sub.text_frame
    stf.clear()
    sp = stf.paragraphs[0]
    srun = sp.add_run()
    srun.text = "Classification + Prix + Clustering + NLP + MLOps"
    style_text(srun, size=22, color=RGBColor(206, 228, 248))

    chips = ["Classification", "Regression", "Clustering", "MLOps"]
    start_x = 0.95
    for label in chips:
        w = 2.2
        chip = slide.shapes.add_shape(
            MSO_SHAPE.ROUNDED_RECTANGLE,
            Inches(start_x),
            Inches(4.35),
            Inches(w),
            Inches(0.53),
        )
        chip.fill.solid()
        chip.fill.fore_color.rgb = RGBColor(228, 239, 250)
        chip.line.fill.background()
        ctf = chip.text_frame
        ctf.clear()
        cp = ctf.paragraphs[0]
        cp.alignment = PP_ALIGN.CENTER
        cr = cp.add_run()
        cr.text = label
        style_text(cr, size=13, bold=True, color=PRIMARY)
        start_x += w + 0.25

    footer = slide.shapes.add_textbox(
        Inches(0.95), Inches(6.95), Inches(6.5), Inches(0.3)
    )
    ftf = footer.text_frame
    ftf.clear()
    fp = ftf.paragraphs[0]
    fr = fp.add_run()
    fr.text = "Presentation projet - 2026"
    style_text(fr, size=12, color=RGBColor(196, 216, 237))
    set_speaker_notes(
        slide,
        "Introduction (30 sec): Presenter l objectif: classifier et valoriser des dechets (Tunisie) via un pipeline data/ML complet "
        "et une application Flutter connectee a une API d inference. Annoncer les modules: imputation, modeles, clustering, NLP et MLOps.",
    )


def add_bullets_slide(prs, page_number, title, subtitle, bullets, notes):
    slide = prs.slides.add_slide(prs.slide_layouts[6])
    add_header_band(slide, title, subtitle)
    add_bullet_content(slide, bullets)
    add_footer(slide, page_number)
    set_speaker_notes(slide, notes)


def add_screenshot_slide(
    prs, page_number, title, subtitle, notes, image_left=None, image_right=None
):
    slide = prs.slides.add_slide(prs.slide_layouts[6])
    add_header_band(slide, title)
    add_screenshot_layout(
        slide, subtitle, notes, image_left=image_left, image_right=image_right
    )
    add_footer(slide, page_number)
    set_speaker_notes(slide, notes)


def build_concise_7min(output_path, image_map):
    prs = Presentation()
    add_title_slide(prs)

    add_bullets_slide(
        prs,
        2,
        "1. Contexte et enjeux",
        "Gestion des dechets et economie circulaire",
        [
            "Objectif: classifier (categorie) et estimer le prix de revente (TND)",
            "Donnees heterogenes: numerique + texte (Rapport_Collecte)",
            "Livrable: pipeline reproductible + API d inference + UI Flutter",
        ],
        "Slide 2 (40 sec): Poser le contexte (dechets) et les 2 taches: classification + regression. "
        "Insister sur l approche produit: API + interface demo.",
    )

    add_bullets_slide(
        prs,
        3,
        "2. Pipeline end-to-end",
        "De la data brute au monitoring",
        [
            "Nettoyage + imputation + feature engineering",
            "Training: classification, regression, clustering, NLP",
            "MLOps: DVC (repro), MLflow (tracking/registry), tests, monitoring drift",
        ],
        "Slide 3 (45 sec): Donner une vue globale des etapes et de l outillage MLOps.",
    )

    add_bullets_slide(
        prs,
        4,
        "3. Nettoyage et imputation",
        "Median vs KNN vs IterativeImputer",
        [
            "Probleme: ~10% de valeurs manquantes sur Poids",
            "Comparaison quantitative via masquage 10% + RMSE de reconstruction",
            "Decision: KNN (k=5) meilleur compromis qualite/cout ; Iterative plus lent et instable",
        ],
        "Slide 4 (55 sec): Expliquer le protocole RMSE, puis justifier le choix KNN.",
    )

    add_bullets_slide(
        prs,
        5,
        "4. Modeles supervises",
        "Classification + Regression (prix)",
        [
            "Classification: LogReg vs RandomForest vs GradientBoosting (ACC/F1)",
            "Regression: LinReg vs RFRegressor vs GBRegressor (MAE/RMSE/R2)",
            "Point critique: ecart validation/test a surveiller (outliers, shift, split)",
        ],
        "Slide 5 (70 sec): Presenter les resultats cles et une lecture critique (risque dataset trop separable).",
    )

    add_bullets_slide(
        prs,
        6,
        "5. Clustering non supervise",
        "K-Means + Elbow + PCA",
        [
            "Elbow method: k=4 clusters",
            "PCA 2D pour visualiser et interpreter les segments",
            "Utilite: comprendre des sous-profils de dechets (metal, plastique, papier, verre)",
        ],
        "Slide 6 (45 sec): Expliquer k=4, PCA et ce que les clusters apportent au produit.",
    )

    add_bullets_slide(
        prs,
        7,
        "6. Multimodal + NLP",
        "Texte + numerique dans un seul pipeline",
        [
            "Vectorisation texte (TF-IDF uni+bi) + variables numeriques (ColumnTransformer)",
            "Option: StackingClassifier pour combiner plusieurs modeles",
            "NLP: nettoyage, stopwords, n-grams ; evaluation par accuracy >= 0.70",
        ],
        "Slide 7 (55 sec): Montrer l avantage du multimodal pour exploiter Rapport_Collecte + mesures.",
    )

    add_bullets_slide(
        prs,
        8,
        "7. MLOps et qualite",
        "Reproductibilite + registry + monitoring",
        [
            "DVC: pipeline rejouable (preprocess + train) via dvc repro",
            "MLflow: tracking des runs + Model Registry (stage Production)",
            "Tests: pytest dans venv Py3.12 + couverture >= 70% sur api_inference",
            "Monitoring: Evidently (data drift) + alertes JSON",
        ],
        "Slide 8 (65 sec): Expliquer comment on passe du notebook a une chaine industrialisable.",
    )

    add_screenshot_slide(
        prs,
        9,
        "8. Demonstration",
        "UI Flutter: Dashboard / Curseurs / Assistant NLP",
        "Montrer: (1) dashboard, (2) sliders en temps reel, (3) assistant texte -> prediction.",
        image_left=image_map.get("dashboard"),
        image_right=image_map.get("sliders"),
    )

    add_bullets_slide(
        prs,
        10,
        "9. Conclusion",
        "Message final et limites",
        [
            "Solution complete: data -> modeles -> API -> interface -> monitoring",
            "Limites: possibles biais dataset, gestion outliers et evaluation en conditions reelles",
            "Perspectives: embeddings type CamemBERT, deploiement cloud, dashboard monitoring",
        ],
        "Slide 10 (40 sec): Conclure et ouvrir sur une mini roadmap.",
    )

    add_bullets_slide(
        prs,
        11,
        "10. Questions",
        "Fin de presentation",
        [
            "Merci pour votre attention",
            "Je suis disponible pour une demonstration supplementaire en direct",
        ],
        "Slide 11 (20 sec): Inviter aux questions et proposer mini demo si necessaire.",
    )

    prs.save(output_path)


def build_detailed_12min(output_path, image_map):
    prs = Presentation()
    add_title_slide(prs)

    slides = [
        (
            "1. Contexte et enjeux",
            "Gestion des dechets et economie circulaire",
            [
                "Classification de dechets + estimation prix de revente (TND)",
                "Donnees: numeriques (Poids, Volume, etc.) + texte (Rapport_Collecte)",
                "Objectif produit: API d inference + application Flutter demonstrable",
            ],
            "Slide 2 (50 sec): Contextualiser le besoin et annoncer les 2 taches ML.",
        ),
        (
            "2. Vue pipeline end-to-end",
            "De la data au monitoring",
            [
                "Nettoyage + imputation + feature engineering",
                "Training: classification + regression + clustering + NLP",
                "MLOps: DVC, MLflow Registry, tests, monitoring drift",
            ],
            "Slide 3 (55 sec): Presenter la chaine de valeur et les choix d outillage.",
        ),
        (
            "3. Donnees et preparation",
            "EDA, split et pretraitements",
            [
                "Jeux: train/val/test + dataset full nettoye",
                "Outliers: capping IQR ; normalisation si necessaire",
                "Encodage source: One-Hot ; ajout de features derivees (densite, log volume)",
            ],
            "Slide 4 (70 sec): Montrer comment on evite le data leakage (fit sur train, apply sur test).",
        ),
        (
            "4. Imputation des manquants",
            "Median vs KNN vs Iterative",
            [
                "Protocole: masquage 10% sur Poids connu + RMSE",
                "KNN (k=5) retient les correlations inter-variables",
                "Iterative: plus lent + avertissements de convergence possibles",
            ],
            "Slide 5 (55 sec): Justifier le choix retenu et les limites.",
        ),
        (
            "5. Classification",
            "RandomForest, GradientBoosting, Stacking",
            [
                "Mesures: Accuracy + F1 pondere",
                "Comparaison: LogReg (baseline), RF (robuste), GB (boosting)",
                "Point critique: scores tres eleves -> verifier separabilite et fuite de donnees",
            ],
            "Slide 6 (60 sec): Presenter resultats et lecture critique.",
        ),
        (
            "6. Regression (prix)",
            "RFRegressor vs GBRegressor",
            [
                "Mesures: MAE, RMSE, R2",
                "Baseline lineaire faible -> relations non lineaires dominantes",
                "Ecart val/test a analyser (outliers, shift, split)",
            ],
            "Slide 7 (60 sec): Presenter les chiffres cles et l interpretation.",
        ),
        (
            "7. Clustering + NLP + Multimodal",
            "Analyse non supervisee et features texte",
            [
                "K-Means: choix k=4 (elbow) + PCA 2D",
                "NLP: TF-IDF, n-grams, pipeline sklearn",
                "Multimodal: ColumnTransformer (texte + numerique) ; option stacking",
            ],
            "Slide 8 (70 sec): Relier les modules a un seul pipeline utilisable en inference.",
        ),
        (
            "8. MLOps",
            "Reproductibilite, registry, tests, monitoring",
            [
                "DVC: dvc.yaml + dvc repro pour rejouer preprocess/train",
                "MLflow: tracking + Model Registry (promotion Production)",
                "Tests: pytest dans venv propre ; couverture sur api_inference",
                "Monitoring: Evidently (drift) + alertes JSON",
            ],
            "Slide 9 (70 sec): Montrer la maturite: du notebook a la production.",
        ),
    ]

    page = 2
    for title, subtitle, bullets, notes in slides:
        add_bullets_slide(prs, page, title, subtitle, bullets, notes)
        page += 1

    add_screenshot_slide(
        prs,
        page,
        "9. Demonstration",
        "Dashboard + curseurs + assistant NLP",
        "Slide demo (90 sec): Montrer l interface Flutter. Enchainer: dashboard -> sliders -> assistant texte -> prediction.",
        image_left=image_map.get("dashboard"),
        image_right=image_map.get("assistant"),
    )
    page += 1

    add_bullets_slide(
        prs,
        page,
        "10. Resultats et limites",
        "Bilan global",
        [
            "Classification et regression avec performances elevees sur splits",
            "Pipeline reproductible et demo stable via API d inference",
            "Limites: separabilite dataset, robustesse hors-distribution a evaluer",
        ],
        "Slide resultats (60 sec): Presenter les acquis et les limites assumees.",
    )
    page += 1

    add_bullets_slide(
        prs,
        page,
        "11. Perspectives & Questions",
        "Roadmap",
        [
            "Bonus: CamemBERT/Sentence Transformers pour enrichir le NLP",
            "Deploiement: Render/Railway/HuggingFace Spaces pour API ou Flutter Web",
            "Monitoring avance: Prometheus/Grafana sur logs drift",
            "Merci pour votre attention - Questions",
        ],
        "Slide finale (45 sec): Ouvrir sur les bonus et passer aux questions.",
    )

    prs.save(output_path)


def build_image_map(base_dir):
    img_dir = Path(base_dir) / "slides"
    return {
        "dashboard": img_dir / "dashboard.png",
        "sliders": img_dir / "sliders.png",
        "assistant": img_dir / "assistant_nlp.png",
    }


if __name__ == "__main__":
    root = Path(__file__).resolve().parent
    image_map = build_image_map(root)

    concise = "EcoSmartClassifier_presentation_7min.pptx"
    detailed = "EcoSmartClassifier_presentation_12min.pptx"
    build_concise_7min(concise, image_map)
    build_detailed_12min(detailed, image_map)

    print(f"Created: {concise}")
    print(f"Created: {detailed}")
