from __future__ import annotations

import os
from pathlib import Path


def _iter_render_blocks(md_text: str):
    in_code = False
    code_lang = ""
    for raw_line in md_text.splitlines():
        line = raw_line.rstrip("\n")
        if line.strip().startswith("```"):
            fence = line.strip()
            if not in_code:
                in_code = True
                code_lang = fence[3:].strip()
                yield ("code_fence_start", code_lang)
            else:
                in_code = False
                yield ("code_fence_end", "")
            continue

        if in_code:
            yield ("code", line)
            continue

        if line.startswith("# "):
            yield ("h1", line[2:].strip())
        elif line.startswith("## "):
            yield ("h2", line[3:].strip())
        elif line.startswith("- "):
            yield ("li", line[2:].strip())
        elif line.strip() == "":
            yield ("blank", "")
        else:
            yield ("p", line)


def build_pdf(md_path: Path, out_path: Path) -> None:
    try:
        from fpdf import FPDF  # type: ignore
    except Exception as exc:  # pragma: no cover
        raise SystemExit(
            "fpdf2 n'est pas installé. Exécute: python -m pip install -U fpdf2"
        ) from exc

    md_text = md_path.read_text(encoding="utf-8")

    pdf = FPDF(orientation="P", unit="mm", format="A4")
    pdf.set_auto_page_break(auto=True, margin=12)
    pdf.add_page()

    left_margin = 12
    right_margin = 12
    usable_width = 210 - left_margin - right_margin

    def try_register_unicode_font() -> str | None:
        windir = Path(os.environ.get("WINDIR", r"C:\\Windows"))
        candidates = [
            windir / "Fonts" / "arial.ttf",
            windir / "Fonts" / "calibri.ttf",
            windir / "Fonts" / "segoeui.ttf",
        ]
        for ttf in candidates:
            if ttf.exists():
                family = "Unicode"
                pdf.add_font(family, style="", fname=str(ttf))
                pdf.add_font(family, style="B", fname=str(ttf))
                return family
        return None

    unicode_family = try_register_unicode_font()

    def sanitize_text(text: str) -> str:
        if unicode_family is not None:
            return text
        return (
            text.replace("’", "'")
            .replace("“", '"')
            .replace("”", '"')
            .replace("–", "-")
            .replace("…", "...")
            .replace("•", "-")
        )

    def set_font(kind: str):
        base = unicode_family or "Helvetica"
        if kind == "h1":
            pdf.set_font(base, "B", 16)
        elif kind == "h2":
            pdf.set_font(base, "B", 12)
        elif kind == "code":
            pdf.set_font("Courier", "", 9)
        else:
            pdf.set_font(base, "", 11)

    def write_paragraph(text: str, indent_mm: float = 0.0):
        text = sanitize_text(text)
        pdf.set_x(left_margin + indent_mm)
        pdf.multi_cell(usable_width - indent_mm, 5.2, text)

    def write_code_line(text: str):
        text = sanitize_text(text)
        pdf.set_x(left_margin + 3)
        pdf.multi_cell(usable_width - 3, 4.6, text)

    in_code = False
    for kind, payload in _iter_render_blocks(md_text):
        if kind == "code_fence_start":
            in_code = True
            pdf.ln(1)
            pdf.set_draw_color(180, 180, 180)
            pdf.set_fill_color(248, 248, 248)
            pdf.rect(left_margin, pdf.get_y(), usable_width, 6, style="F")
            set_font("code")
            label = payload.strip()
            pdf.set_x(left_margin + 2)
            pdf.cell(
                usable_width - 4,
                6,
                sanitize_text(f"Code{(' (' + label + ')') if label else ''}"),
            )
            pdf.ln(7)
            continue

        if kind == "code_fence_end":
            in_code = False
            pdf.ln(2)
            continue

        if kind == "blank":
            pdf.ln(2)
            continue

        if in_code or kind == "code":
            set_font("code")
            write_code_line(payload)
            continue

        if kind == "h1":
            set_font("h1")
            write_paragraph(payload)
            pdf.ln(1)
            continue

        if kind == "h2":
            set_font("h2")
            pdf.ln(1)
            write_paragraph(payload)
            pdf.ln(0.5)
            continue

        if kind == "li":
            set_font("p")
            write_paragraph(f"• {payload}", indent_mm=2)
            continue

        if kind == "p":
            set_font("p")
            write_paragraph(payload)
            continue

    out_path.parent.mkdir(parents=True, exist_ok=True)
    pdf.output(str(out_path))


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    md_path = root / "docs" / "GUIDE_COMMANDES.md"
    out_path = root / "docs" / "GUIDE_COMMANDES.pdf"

    if not md_path.exists():
        raise SystemExit(f"Fichier introuvable: {md_path}")

    build_pdf(md_path, out_path)
    print(f"OK: {out_path}")


if __name__ == "__main__":
    main()
