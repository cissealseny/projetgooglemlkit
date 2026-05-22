import sys
from pathlib import Path

from fpdf import FPDF


class EcoSmartPDF(FPDF):
    def header(self):
        if self.page_no() == 1:
            return
        self.set_font("helvetica", "B", 8)
        self.set_text_color(46, 125, 50)  # Vert forêt
        self.cell(0, 10, "ECO-SMART : GUIDE TECHNIQUE ET DE PRESENTATION", align="L")
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
            "Application Eco-Smart - Realise avec Flutter & Django - Rapport Academique",
            align="C",
        )

    def chapter_title(self, label):
        self.set_font("helvetica", "B", 14)
        self.set_text_color(46, 125, 50)  # Vert
        self.cell(0, 10, label, new_x="LMARGIN", new_y="NEXT")
        self.ln(2)

    def section_title(self, label):
        self.set_font("helvetica", "B", 11)
        self.set_text_color(33, 33, 33)
        self.cell(0, 8, label, new_x="LMARGIN", new_y="NEXT")
        self.ln(1)

    def body_text(self, text):
        self.set_font("helvetica", "", 10)
        self.set_text_color(66, 66, 66)
        self.multi_cell(0, 6, text)
        self.ln(3)

    def bullet_point(self, title, description):
        self.set_font("helvetica", "B", 10)
        self.set_text_color(46, 125, 50)
        self.write(h=6, text="  - " + title + " : ")
        self.set_font("helvetica", "", 10)
        self.set_text_color(66, 66, 66)
        self.write(h=6, text=description + "\n")
        self.ln(1)


def build_pdf(output_path):
    pdf = EcoSmartPDF()

    # Page de Garde
    pdf.add_page()
    pdf.ln(35)

    # Titre principal
    pdf.set_font("helvetica", "B", 26)
    pdf.set_text_color(46, 125, 50)
    pdf.cell(0, 15, "PROJET ECO-SMART", align="C", new_x="LMARGIN", new_y="NEXT")

    pdf.set_font("helvetica", "B", 16)
    pdf.set_text_color(33, 33, 33)
    pdf.cell(
        0,
        12,
        "Guide Pratique & Manuel de Presentation Academique",
        align="C",
        new_x="LMARGIN",
        new_y="NEXT",
    )

    pdf.ln(5)
    pdf.line(30, pdf.get_y(), 180, pdf.get_y())
    pdf.ln(10)

    # Sous-titre
    pdf.set_font("helvetica", "I", 11)
    pdf.set_text_color(100, 100, 100)
    pdf.multi_cell(
        0,
        6,
        "Une application intelligente de tri et d'eco-citoyennete\npropulsee par Flutter (Frontend) et Django REST Framework (Backend)",
        align="C",
    )

    # Encadre premium
    pdf.ln(25)
    pdf.set_fill_color(242, 249, 242)
    pdf.set_draw_color(46, 125, 50)
    pdf.rect(15, pdf.get_y(), 180, 40, "FD")

    pdf.set_y(pdf.get_y() + 5)
    pdf.set_font("helvetica", "B", 10)
    pdf.set_text_color(46, 125, 50)
    pdf.cell(
        0, 6, "COMPOSANTES CLEFS EVALUEES", align="C", new_x="LMARGIN", new_y="NEXT"
    )
    pdf.set_font("helvetica", "", 9)
    pdf.set_text_color(50, 50, 50)
    pdf.cell(
        0,
        5,
        "- Classification de Dechets par Vision IA & Estimation de Prix de Revente",
        align="C",
        new_x="LMARGIN",
        new_y="NEXT",
    )
    pdf.cell(
        0,
        5,
        "- Tableau de Bord Interactif Eco-Impact (Statistiques detaillees de Recyclage)",
        align="C",
        new_x="LMARGIN",
        new_y="NEXT",
    )
    pdf.cell(
        0,
        5,
        "- Cartographie Spatialisee des Centres en Tunisie & Assistant Generatif Contextuel",
        align="C",
        new_x="LMARGIN",
        new_y="NEXT",
    )

    # Footer de garde
    pdf.set_y(230)
    pdf.set_font("helvetica", "B", 10)
    pdf.set_text_color(33, 33, 33)
    pdf.cell(0, 6, "Preparation Academique", align="C", new_x="LMARGIN", new_y="NEXT")
    pdf.set_font("helvetica", "", 9)
    pdf.set_text_color(100, 100, 100)
    pdf.cell(
        0,
        5,
        "A l'attention du Professeur Evaluateur",
        align="C",
        new_x="LMARGIN",
        new_y="NEXT",
    )
    pdf.cell(
        0,
        5,
        "Environnement : Flutter SDK 3.x - Python Django 4.2 - SQLite 3",
        align="C",
        new_x="LMARGIN",
        new_y="NEXT",
    )
    pdf.cell(0, 5, "Date : Mai 2026", align="C", new_x="LMARGIN", new_y="NEXT")

    # Page 2: Vision Globale et Architecture
    pdf.add_page()
    pdf.chapter_title("1. Vision Globale du Projet Eco-Smart")

    pdf.body_text(
        "Eco-Smart est une solution technologique innovante destinee a moderniser et a encourager "
        "la gestion des dechets en Tunisie. L'application repond a une double problematique : le manque "
        "de tri selectif a la base et la difficulte pour les citoyens de localiser et valoriser leurs dechets. "
        "En integrant des outils d'Intelligence Artificielle et une cartographie localisee, Eco-Smart transforme "
        "le recyclage en une experience interactive et gratifiante."
    )

    pdf.section_title("Architecture Technique du Systeme")
    pdf.body_text(
        "Le projet s'appuie sur une separation stricte entre l'interface utilisateur et la logique metier :\n"
        "- Frontend (Client) : Developpe en Flutter, il assure une portabilite totale sur Windows (Desktop) "
        "et Mobile. L'architecture respecte le pattern Clean Architecture et utilise BLoC pour la gestion d'etat.\n"
        "- Backend (Serveur) : Base sur Django REST Framework (DRF), il gere l'authentification securisee JWT, "
        "l'enregistrement des collectes, le stockage des donnees de tri et fournit les API de statistiques d'impact."
    )

    # Tableau des Technologies
    pdf.set_font("helvetica", "B", 9)
    pdf.set_fill_color(230, 240, 230)
    pdf.cell(60, 8, "Module / Composant", border=1, fill=True)
    pdf.cell(
        130,
        8,
        "Technologies & Libraries associees",
        border=1,
        fill=True,
        new_x="LMARGIN",
        new_y="NEXT",
    )

    pdf.set_font("helvetica", "", 9)
    pdf.cell(60, 8, "Frontend Mobile & Desktop", border=1)
    pdf.cell(
        130,
        8,
        "Flutter, Bloc, Dio, Fl Chart, Google Maps Flutter",
        border=1,
        new_x="LMARGIN",
        new_y="NEXT",
    )
    pdf.cell(60, 8, "API & Logique Metier", border=1)
    pdf.cell(
        130,
        8,
        "Django, Django REST Framework, SimpleJWT",
        border=1,
        new_x="LMARGIN",
        new_y="NEXT",
    )
    pdf.cell(60, 8, "Service Vision IA", border=1)
    pdf.cell(
        130,
        8,
        "Scikit-Learn (baseline) & Google ML Kit (Mobile)",
        border=1,
        new_x="LMARGIN",
        new_y="NEXT",
    )
    pdf.cell(60, 8, "Assistant Conversationnel", border=1)
    pdf.cell(
        130,
        8,
        "Integration d'API generative LLM locale / Gemini",
        border=1,
        new_x="LMARGIN",
        new_y="NEXT",
    )
    pdf.ln(8)

    # Page 3: Fonctionnalites detaillees - Vision et Dashboard
    pdf.add_page()
    pdf.chapter_title("2. Fonctionnalites Principales & Resultats")

    pdf.section_title("A. Module de Vision IA : Tri & Estimation de Prix")
    pdf.body_text(
        "Ce module constitue l'entree principale du cycle de recyclage. L'utilisateur soumet ou prend "
        "une photo d'un dechet. Le systeme execute une analyse multimodale et renvoie :\n"
        "- La categorie identifiee (Plastique, Verre, Papier, Carton, Metal, Autre).\n"
        "- Un score de confiance sur la prediction.\n"
        "- Une estimation de la valeur de revente (en Millimes/TND) basee sur le poids moyen de l'objet."
    )

    pdf.section_title("B. Tableau de Bord Eco-Impact Interactif")
    pdf.body_text(
        "Ce tableau de bord centralise et valorise les actions ecologiques de l'utilisateur. Il contient :"
    )
    pdf.bullet_point(
        "Indicateurs Globaux",
        "Poids total recycle (Kg), points accumules, et gains monetaires virtuels.",
    )
    pdf.bullet_point(
        "Graphique Circulaire Interactif",
        "Affiche la repartition des dechets recycles. Au clic sur une categorie (ex: Plastique), le graphique s'anime de maniere fluide pour zoomer sur la tranche selectionnee et affiche un encart detaille.",
    )
    pdf.bullet_point(
        "Historique des Transactions",
        "Liste complete des collectes avec l'heure, le lieu, la quantite et l'icone du type de dechet recycle.",
    )
    pdf.ln(5)

    # Page 4: Fonctionnalites detaillees - Cartographie et Assistant
    pdf.add_page()
    pdf.chapter_title("2. Fonctionnalites Principales & Resultats (Suite)")

    pdf.section_title("C. Carte des Centres de Recyclage (Mode Multi-Plateforme)")
    pdf.body_text(
        "La localisation des centres est indispensable pour finaliser la collecte :\n"
        "- Mode Mobile : Affiche une veritable carte Google Maps avec des marqueurs pour chaque centre.\n"
        "- Mode Desktop (Windows) : Le SDK Google Maps n'etant pas supporte nativement sur Windows Desktop, "
        "l'application charge automatiquement un composant de remplacement premium : _WindowsMapMockup. "
        "Ce widget dessine une carte interactive stylisee de la Tunisie ou chaque gouvernorat (Tunis, Bizerte, "
        "Sousse, Sfax, Monastir, etc.) dispose d'une broche cliquable. Cliquer sur une broche filtre instantanement "
        "les centres situes dans ce gouvernorat, permettant de tester l'application sur Windows sans aucun plantage."
    )

    pdf.section_title("D. Assistant IA Ecologique (Accessible Partout)")
    pdf.body_text(
        "Afin d'accompagner l'utilisateur, un assistant conversationnel intelligent est accessible a tout moment via "
        "un bouton flottant violet present sur tous les ecrans. L'assistant :\n"
        "- Est configure avec un system prompt specifique pour connaitre l'integralite de l'application Eco-Smart.\n"
        "- Peut expliquer comment soumettre une collecte, ou trouver les centres de recyclage ou encore donner des "
        "conseils pratiques sur le tri selectif."
    )

    pdf.section_title("E. Quiz Eco-Citoyen")
    pdf.body_text(
        "Un module ludique de quiz permet de tester ses connaissances sur l'environnement. Chaque question beneficie "
        "d'une correction immediate et d'une explication detaillee pour renforcer l'apprentissage citoyen."
    )
    pdf.ln(5)

    # Page 5: Demonstration & Guide de Validation pour l'Evaluation
    pdf.add_page()
    pdf.chapter_title("3. Guide de Demonstration & Validation")

    pdf.body_text(
        "Ce guide decrit les etapes precises a suivre devant le professeur pour valider le bon "
        "fonctionnement de l'application :"
    )

    pdf.section_title("Etape 1 : Connexion / Creation de Compte")
    pdf.body_text(
        "1. Lancez l'application (client Windows ou mobile).\n"
        "2. Creez un nouveau compte avec un email valide ou connectez-vous avec un compte existant. "
        "L'authentification s'effectue en temps reel aupres du backend Django REST Framework."
    )

    pdf.section_title("Etape 2 : Simulation de Tri de Dechet")
    pdf.body_text(
        "1. Rendez-vous sur l'onglet 'Trier'.\n"
        "2. Importez une image de bouteille plastique ou de carton.\n"
        "3. Observez la classification instantanee de la categorie, du score de confiance et du prix estime de revente."
    )

    pdf.section_title("Etape 3 : Enregistrement d'une Collecte")
    pdf.body_text(
        "1. Allez sur l'onglet 'Collecte'.\n"
        "2. Remplissez le formulaire en saisissant le poids (ex: 15 Kg), l'entreprise partenaire, la ville, et selectionnez le type de dechet (ex: Plastique).\n"
        "3. Cliquez sur 'Valider la collecte'.\n"
        "4. Rendez-vous sur l'onglet 'Eco-Impact' ou sur la page d'accueil pour voir le graphique mis a jour en temps reel et la collecte ajoutee a votre historique."
    )

    pdf.section_title("Etape 4 : Consultation de la Carte et de l'Assistant")
    pdf.body_text(
        "1. Allez sur l'onglet 'Centres' et cliquez sur les broches interactives des villes pour filtrer les centres de recyclage.\n"
        "2. Cliquez sur le bouton flottant violet IA en bas a droite depuis n'importe quel ecran, tapez une question comme 'Comment puis-je gagner plus de points ?' et observez la reponse contextualisee de l'assistant."
    )

    pdf.ln(10)
    pdf.set_font("helvetica", "B", 10)
    pdf.set_text_color(46, 125, 50)
    pdf.cell(0, 6, "FIN DU GUIDE DE PRESENTATION", align="C")

    # Enregistrer le PDF
    pdf.output(output_path)
    print(f"Rapport PDF genere avec succes : {output_path}")


if __name__ == "__main__":
    out_file = (
        Path(sys.argv[1])
        if len(sys.argv) > 1
        else Path("Rapport_Presentation_EcoSmart.pdf")
    )
    build_pdf(str(out_file))
