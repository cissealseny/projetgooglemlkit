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
    band = slide.shapes.add_shape(MSO_SHAPE.RECTANGLE, Inches(0), Inches(0), Inches(13.33), Inches(1.25))
    band.fill.solid()
    band.fill.fore_color.rgb = PRIMARY
    band.line.fill.background()

    stripe = slide.shapes.add_shape(MSO_SHAPE.RECTANGLE, Inches(0), Inches(1.12), Inches(13.33), Inches(0.13))
    stripe.fill.solid()
    stripe.fill.fore_color.rgb = SECONDARY
    stripe.line.fill.background()

    title_box = slide.shapes.add_textbox(Inches(0.6), Inches(0.25), Inches(10.4), Inches(0.52))
    title_tf = title_box.text_frame
    title_tf.clear()
    p = title_tf.paragraphs[0]
    r = p.add_run()
    r.text = title
    style_text(r, size=30, bold=True, color=TEXT_LIGHT)

    if subtitle:
        sub_box = slide.shapes.add_textbox(Inches(0.6), Inches(0.73), Inches(10.8), Inches(0.35))
        sub_tf = sub_box.text_frame
        sub_tf.clear()
        p_sub = sub_tf.paragraphs[0]
        r_sub = p_sub.add_run()
        r_sub.text = subtitle
        style_text(r_sub, size=15, color=RGBColor(214, 228, 243))

    badge = slide.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Inches(11.25), Inches(0.26), Inches(1.45), Inches(0.56))
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
    footer = slide.shapes.add_shape(MSO_SHAPE.RECTANGLE, Inches(0), Inches(7.24), Inches(13.33), Inches(0.26))
    footer.fill.solid()
    footer.fill.fore_color.rgb = BG_LIGHT
    footer.line.fill.background()

    left = slide.shapes.add_textbox(Inches(0.5), Inches(7.24), Inches(7.5), Inches(0.22))
    left_tf = left.text_frame
    left_tf.clear()
    lp = left_tf.paragraphs[0]
    lrun = lp.add_run()
    lrun.text = "Google ML Kit - Flutter + Django REST"
    style_text(lrun, size=10, color=RGBColor(94, 104, 117))

    right = slide.shapes.add_textbox(Inches(12.45), Inches(7.24), Inches(0.45), Inches(0.22))
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
    box = slide.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Inches(0.7), Inches(1.55), Inches(12.0), Inches(5.35))
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

    slide.shapes.add_picture(str(image_path), Inches(pic_x), Inches(pic_y), width=Inches(pic_w), height=Inches(pic_h))


def image_exists(image_path):
    return image_path is not None and Path(image_path).exists()


def add_screenshot_layout(slide, subtitle, notes, image_left=None, image_right=None):
    title_box = slide.shapes.add_textbox(Inches(0.85), Inches(1.55), Inches(12.0), Inches(0.45))
    ttf = title_box.text_frame
    ttf.clear()
    p = ttf.paragraphs[0]
    run = p.add_run()
    run.text = subtitle
    style_text(run, size=22, bold=True, color=PRIMARY)

    left_x, left_y, left_w, left_h = 0.85, 2.15, 5.9, 3.75
    left = slide.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Inches(left_x), Inches(left_y), Inches(left_w), Inches(left_h))
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
    right = slide.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Inches(right_x), Inches(right_y), Inches(right_w), Inches(right_h))
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

    notes_box = slide.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Inches(0.85), Inches(6.1), Inches(11.63), Inches(0.72))
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
    bg = slide.shapes.add_shape(MSO_SHAPE.RECTANGLE, Inches(0), Inches(0), Inches(13.33), Inches(7.5))
    bg.fill.solid()
    bg.fill.fore_color.rgb = PRIMARY
    bg.line.fill.background()

    glow = slide.shapes.add_shape(MSO_SHAPE.OVAL, Inches(8.9), Inches(-0.95), Inches(5.6), Inches(5.6))
    glow.fill.solid()
    glow.fill.fore_color.rgb = SECONDARY
    glow.line.fill.background()

    glow2 = slide.shapes.add_shape(MSO_SHAPE.OVAL, Inches(-1.2), Inches(4.6), Inches(4.9), Inches(4.9))
    glow2.fill.solid()
    glow2.fill.fore_color.rgb = RGBColor(15, 87, 141)
    glow2.line.fill.background()

    title = slide.shapes.add_textbox(Inches(0.9), Inches(1.8), Inches(10.6), Inches(1.35))
    tf = title.text_frame
    tf.clear()
    p = tf.paragraphs[0]
    run = p.add_run()
    run.text = "Google ML Kit\nApplication Full Stack"
    style_text(run, size=46, bold=True, color=TEXT_LIGHT)

    sub = slide.shapes.add_textbox(Inches(0.95), Inches(3.35), Inches(8.8), Inches(0.7))
    stf = sub.text_frame
    stf.clear()
    sp = stf.paragraphs[0]
    srun = sp.add_run()
    srun.text = "Flutter mobile + Django REST + IA locale et cloud"
    style_text(srun, size=22, color=RGBColor(206, 228, 248))

    chips = ["Vision", "NLP", "Generative AI", "DataHub"]
    start_x = 0.95
    for label in chips:
        w = 1.45 if label in {"Vision", "NLP"} else 2.35
        chip = slide.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Inches(start_x), Inches(4.35), Inches(w), Inches(0.53))
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

    footer = slide.shapes.add_textbox(Inches(0.95), Inches(6.95), Inches(6.5), Inches(0.3))
    ftf = footer.text_frame
    ftf.clear()
    fp = ftf.paragraphs[0]
    fr = fp.add_run()
    fr.text = "Presentation projet - Mars 2026"
    style_text(fr, size=12, color=RGBColor(196, 216, 237))
    set_speaker_notes(
        slide,
        "Introduction (30 sec): Presenter l objectif du projet: application full stack IA avec Flutter et Django REST. "
        "Annoncer la logique hybride: ML local pour vitesse et cloud pour fonctions avancees.",
    )


def add_bullets_slide(prs, page_number, title, subtitle, bullets, notes):
    slide = prs.slides.add_slide(prs.slide_layouts[6])
    add_header_band(slide, title, subtitle)
    add_bullet_content(slide, bullets)
    add_footer(slide, page_number)
    set_speaker_notes(slide, notes)


def add_screenshot_slide(prs, page_number, title, subtitle, notes, image_left=None, image_right=None):
    slide = prs.slides.add_slide(prs.slide_layouts[6])
    add_header_band(slide, title)
    add_screenshot_layout(slide, subtitle, notes, image_left=image_left, image_right=image_right)
    add_footer(slide, page_number)
    set_speaker_notes(slide, notes)


def build_concise_7min(output_path, image_map):
    prs = Presentation()
    add_title_slide(prs)

    add_bullets_slide(
        prs,
        2,
        "1. Contexte et Problematique",
        "Pourquoi ce projet est important",
        [
            "Les applications IA cloud-only subissent latence et indisponibilite reseau",
            "Les utilisateurs attendent une experience rapide et fiable en conditions reelles",
            "Notre approche: architecture hybride, locale sur mobile et distante via API",
        ],
        "Slide 2 (40 sec): Expliquer le probleme principal. Le cloud seul ne suffit pas pour une UX stable. "
        "Insister sur la motivation du choix hybride.",
    )

    add_bullets_slide(
        prs,
        3,
        "2. Objectifs du Projet",
        "Ce que la solution doit garantir",
        [
            "Regrouper Vision, NLP et IA generative dans une seule application",
            "Maintenir securite et qualite UX avec JWT, timeouts et gestion d erreurs",
            "Concevoir une base modulaire, evolutive, et facilement demonstrable",
        ],
        "Slide 3 (35 sec): Donner 3 objectifs: capacites IA, robustesse, extensibilite.",
    )

    add_bullets_slide(
        prs,
        4,
        "3. Architecture Globale",
        "Vue systeme",
        [
            "Frontend Flutter: BLoC, navigation, client Dio avec intercepteur JWT",
            "Backend Django REST: endpoints /api/v1 pour users, vision, nlp, generative, datahub",
            "Providers IA: traitement local ML Kit + modeles distants selon disponibilite",
            "Flux: App mobile -> API securisee -> Services IA -> reponse contextualisee",
        ],
        "Slide 4 (55 sec): Decrire le flux complet du mobile vers backend puis services IA. "
        "Conclure sur la separation claire des responsabilites.",
    )

    add_screenshot_slide(
        prs,
        5,
        "4. Demonstration Vision",
        "OCR et detection en direct",
        "Montrer la vitesse du traitement local et la qualite du resultat instantane.",
        image_left=image_map.get("vision"),
        image_right=image_map.get("ocr"),
    )

    add_screenshot_slide(
        prs,
        6,
        "5. Demonstration NLP",
        "Sentiment, traduction, extraction d entites",
        "Mettre en avant le mode degrade grace au fallback quand le reseau est lent.",
        image_left=image_map.get("nlp"),
        image_right=image_map.get("home"),
    )

    add_screenshot_slide(
        prs,
        7,
        "6. Demonstration IA + Dashboard",
        "Chat IA, stats dynamiques, profil",
        "Insister sur la coherence globale de l experience utilisateur.",
        image_left=image_map.get("gen"),
        image_right=image_map.get("home"),
    )

    add_bullets_slide(
        prs,
        8,
        "7. Resultats",
        "Bilan de la mise en oeuvre",
        [
            "Application full stack operationnelle et presentable en demo live",
            "Communication backend/frontend validee en environnement emulateur",
            "Architecture lisible et reutilisable pour futurs cas d usage IA",
        ],
        "Slide 8 (45 sec): Donner des faits concrets: app tourne, backend repond, demo stable.",
    )

    add_bullets_slide(
        prs,
        9,
        "8. Limites et Evolutions",
        "Pistes d amelioration",
        [
            "Dependance a certaines cles API cloud pour des fonctions avancees",
            "Performance variable selon modele et qualite de connexion",
            "Perspectives: RAG documentaire, benchmark multi-modeles, monitoring IA",
        ],
        "Slide 9 (40 sec): Montrer maturite du projet avec limites assumees et roadmap claire.",
    )

    add_bullets_slide(
        prs,
        10,
        "9. Conclusion",
        "Message final",
        [
            "Le projet combine utilite technique, robustesse et qualite de presentation",
            "La strategie hybride local+cloud apporte une vraie valeur en contexte reel",
            "Prise en main immediate pour une soutenance claire et convaincante",
        ],
        "Slide 10 (35 sec): Resumer la valeur: utile, robuste, extensible.",
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
            "1. Contexte et Problematique",
            "Pourquoi ce projet est important",
            [
                "Les applications IA cloud-only subissent latence et indisponibilite reseau",
                "Les utilisateurs attendent une experience rapide et fiable en conditions reelles",
                "Notre approche: architecture hybride, locale sur mobile et distante via API",
            ],
            "Slide 2 (50 sec): Contextualiser le besoin et annoncer la logique hybride.",
        ),
        (
            "2. Objectifs du Projet",
            "Ce que la solution doit garantir",
            [
                "Regrouper Vision, NLP et IA generative dans une seule application",
                "Maintenir securite et qualite UX avec JWT, timeouts et gestion d erreurs",
                "Concevoir une base modulaire, evolutive, et facilement demonstrable",
            ],
            "Slide 3 (45 sec): Les objectifs guident toutes les decisions techniques.",
        ),
        (
            "3. Architecture Globale",
            "Vue systeme",
            [
                "Frontend Flutter: BLoC, navigation, client Dio avec intercepteur JWT",
                "Backend Django REST: endpoints /api/v1 pour users, vision, nlp, generative, datahub",
                "Providers IA: traitement local ML Kit + modeles distants selon disponibilite",
                "Flux: App mobile -> API securisee -> Services IA -> reponse contextualisee",
            ],
            "Slide 4 (70 sec): Decrire l architecture et la responsabilite de chaque couche.",
        ),
        (
            "4. Vision",
            "Briques ML Kit locale",
            [
                "OCR pour extraction de texte",
                "Detection d objets, visages et code-barres",
                "Latence faible grace au traitement on-device",
            ],
            "Slide 5 (45 sec): Expliquer pourquoi Vision local donne une meilleure reactivite.",
        ),
        (
            "5. NLP",
            "Traitement de texte hybride",
            [
                "Sentiment, langue, traduction et extraction d entites",
                "Fallback automatique sur local en cas de timeout distant",
                "Stabilite des fonctionnalites en reseau degrade",
            ],
            "Slide 6 (50 sec): Insister sur le fallback comme element cle de robustesse.",
        ),
        (
            "6. IA Generative",
            "Assistant conversationnel",
            [
                "Chat IA via backend",
                "Generation texte/code avec gestion timeout",
                "Possibilite de bascule vers modele plus leger",
            ],
            "Slide 7 (50 sec): Montrer la valeur pratique et la gestion des erreurs.",
        ),
        (
            "7. Securite et UX",
            "Qualite produit",
            [
                "Authentification JWT access/refresh",
                "Messages d erreur comprehensibles",
                "Dashboard dynamique avec cache local",
            ],
            "Slide 8 (55 sec): Expliquer que la fiabilite percue vient aussi de l UX.",
        ),
    ]

    page = 2
    for title, subtitle, bullets, notes in slides:
        add_bullets_slide(prs, page, title, subtitle, bullets, notes)
        page += 1

    add_screenshot_slide(
        prs,
        page,
        "8. Demonstration Vision",
        "OCR et detection en direct",
        "Slide demo (70 sec): Afficher une image de texte puis resultat OCR. Enchainer avec une detection d objet.",
        image_left=image_map.get("vision"),
        image_right=image_map.get("ocr"),
    )
    page += 1

    add_screenshot_slide(
        prs,
        page,
        "9. Demonstration NLP",
        "Sentiment, traduction, extraction d entites",
        "Slide demo (70 sec): Montrer un cas positif/negatif puis une traduction. Mentionner fallback.",
        image_left=image_map.get("nlp"),
        image_right=image_map.get("home"),
    )
    page += 1

    add_screenshot_slide(
        prs,
        page,
        "10. Demonstration IA + Dashboard",
        "Chat IA et statistiques",
        "Slide demo (70 sec): Poser une question au chat puis montrer stats dashboard et rafraichissement.",
        image_left=image_map.get("gen"),
        image_right=image_map.get("home"),
    )
    page += 1

    add_bullets_slide(
        prs,
        page,
        "11. Resultats et Impacts",
        "Bilan global",
        [
            "Application full stack operationnelle en condition de demo",
            "Communication backend/frontend validee avec endpoints securises",
            "Architecture modulable pour nouvelles features IA",
        ],
        "Slide resultats (50 sec): Donner preuves concretes de fonctionnement.",
    )
    page += 1

    add_bullets_slide(
        prs,
        page,
        "12. Limites, Perspectives, Questions",
        "Vision de continuation",
        [
            "Limites: dependances cloud et variabilite des modeles",
            "Perspectives: RAG, benchmark multi-modeles, observabilite IA",
            "Merci pour votre attention - Questions",
        ],
        "Slide finale (40 sec): Montrer projection et ouverture aux questions.",
    )

    prs.save(output_path)


def build_image_map(base_dir):
    img_dir = Path(base_dir) / "frontend" / "imagess"
    return {
        "vision": img_dir / "vision.png",
        "ocr": img_dir / "OCRVison.png",
        "nlp": img_dir / "NLP.png",
        "gen": img_dir / "IAgenerative.png",
        "home": img_dir / "accueil.png",
    }


if __name__ == "__main__":
    root = Path(__file__).resolve().parent
    image_map = build_image_map(root)

    concise = "GoogleMLKit_presentation_7min.pptx"
    detailed = "GoogleMLKit_presentation_12min.pptx"
    build_concise_7min(concise, image_map)
    build_detailed_12min(detailed, image_map)

    print(f"Created: {concise}")
    print(f"Created: {detailed}")
