import json
import logging
import re
from typing import Any

from apps.generative.services import generative_service

from .models import QuizQuestion

logger = logging.getLogger(__name__)


class QuizService:
    SYSTEM_PROMPT = (
        "Tu es un generateur de quiz. Retourne uniquement du JSON valide, sans markdown. "
        "Ne mets pas de texte hors JSON."
    )

    def generate_quiz(
        self,
        topic: str,
        question_count: int,
        difficulty: str,
        formats: list[str],
        language: str,
        model: str,
    ) -> dict[str, Any]:
        prompt = self._build_prompt(
            topic, question_count, difficulty, formats, language
        )

        messages = [
            {"role": "system", "content": self.SYSTEM_PROMPT},
            {"role": "user", "content": prompt},
        ]

        result = generative_service.chat(
            messages,
            model=model,
            temperature=0.4,
            max_tokens=2600,
        )

        if not result.get("success"):
            return {
                "success": False,
                "error": result.get("error", "Quiz generation failed"),
                "processing_time": result.get("processing_time"),
            }

        raw_text = (result.get("response") or "").strip()
        payload = self._extract_json(raw_text)
        if payload is None:
            payload = self._repair_json(raw_text, model)

        if payload is None:
            logger.warning("Quiz JSON parse failed: %s", raw_text[:400])
            return {
                "success": False,
                "error": "Reponse invalide du modele (JSON manquant).",
                "raw": raw_text,
            }

        normalized = self._normalize_payload(
            payload, topic, question_count, difficulty, formats, language
        )
        if not normalized["questions"]:
            return {
                "success": False,
                "error": "Aucune question valide produite par le modele.",
                "raw": raw_text,
            }

        return {
            "success": True,
            "quiz": normalized,
            "raw": raw_text,
            "processing_time": result.get("processing_time"),
            "model": result.get("model", model),
        }

    def grade_open_answer(
        self,
        prompt: str,
        expected: str,
        answer: str,
        language: str,
        model: str,
    ) -> dict[str, Any]:
        system_prompt = (
            "Tu es un evaluateur de reponses. Retourne uniquement du JSON valide. "
            "Champ score entre 0 et 1."
        )

        user_prompt = (
            "Evalue la reponse d'un apprenant. "
            'Retourne un JSON strict avec: {"score": 0.0-1.0, "feedback": "..."}.\n'
            f"Langue: {language}\n"
            f"Question: {prompt}\n"
            f"Reponse attendue: {expected}\n"
            f"Reponse donnee: {answer}\n"
        )

        messages = [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt},
        ]

        result = generative_service.chat(
            messages,
            model=model,
            temperature=0.2,
            max_tokens=400,
        )

        if not result.get("success"):
            return {
                "score": 0.0,
                "feedback": "Evaluation indisponible.",
                "error": result.get("error"),
            }

        raw_text = (result.get("response") or "").strip()
        payload = self._extract_json(raw_text)
        if payload is None:
            return {
                "score": 0.0,
                "feedback": "Evaluation indisponible.",
            }

        try:
            score = float(payload.get("score", 0.0))
        except (TypeError, ValueError):
            score = 0.0

        return {
            "score": max(0.0, min(score, 1.0)),
            "feedback": str(payload.get("feedback") or "").strip() or "OK",
        }

    def _build_prompt(
        self,
        topic: str,
        question_count: int,
        difficulty: str,
        formats: list[str],
        language: str,
    ) -> str:
        formats_text = ", ".join(formats) if formats else "mcq"
        return (
            "Cree un quiz moderne, clair et utile. "
            "Retourne uniquement du JSON.\n"
            "Schema attendu:\n"
            "{\n"
            '  "title": "...",\n'
            '  "topic": "...",\n'
            '  "language": "...",\n'
            '  "difficulty": "easy|medium|hard",\n'
            '  "questions": [\n'
            "    {\n"
            '      "id": 1,\n'
            '      "type": "mcq|true_false|open",\n'
            '      "question": "...",\n'
            '      "options": ["..."],\n'
            '      "answer": "...",\n'
            '      "explanation": "..."\n'
            "    }\n"
            "  ]\n"
            "}\n\n"
            f"Sujet: {topic}\n"
            f"Nombre de questions: {question_count}\n"
            f"Difficulte: {difficulty}\n"
            f"Formats autorises: {formats_text}\n"
            f"Langue: {language}\n"
            "Regles:\n"
            "- Respecte exactement le nombre de questions.\n"
            "- Pour true_false, options doit contenir True/False (ou Vrai/Faux si langue francais).\n"
            "- Pour mcq, propose 4 options.\n"
            "- Pour open, options doit etre un tableau vide.\n"
        )

    def _extract_json(self, text: str) -> dict[str, Any] | None:
        cleaned = text.strip()

        if cleaned.startswith("```"):
            cleaned = re.sub(r"^```[a-zA-Z]*\n?", "", cleaned)
            cleaned = re.sub(r"```$", "", cleaned).strip()

        start = cleaned.find("{")
        end = cleaned.rfind("}")
        if start == -1 or end == -1:
            return None

        try:
            return json.loads(cleaned[start : end + 1])
        except json.JSONDecodeError:
            return None

    def _repair_json(self, text: str, model: str) -> dict[str, Any] | None:
        if not text.strip():
            return None

        system_prompt = (
            "Tu reçois un JSON incomplet ou invalide. "
            "Repare-le et retourne UNIQUEMENT un JSON valide, sans markdown."
        )

        user_prompt = (
            "Corrige la sortie suivante pour produire un JSON valide qui "
            "respecte le schema attendu. "
            "Ne change pas le contenu si possible, complete uniquement ce qui manque.\n\n"
            f"SORTIE:\n{text}"
        )

        result = generative_service.chat(
            [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt},
            ],
            model=model,
            temperature=0.0,
            max_tokens=800,
        )

        if not result.get("success"):
            return None

        raw_text = (result.get("response") or "").strip()
        return self._extract_json(raw_text)

    def _normalize_payload(
        self,
        payload: dict[str, Any],
        topic: str,
        question_count: int,
        difficulty: str,
        formats: list[str],
        language: str,
    ) -> dict[str, Any]:
        title = str(payload.get("title") or f"Quiz: {topic}").strip()
        normalized_language = str(payload.get("language") or language or "auto").strip()
        normalized_difficulty = str(payload.get("difficulty") or difficulty).strip()

        questions = (
            payload.get("questions")
            if isinstance(payload.get("questions"), list)
            else []
        )
        normalized_questions = []

        allowed_types = {choice[0] for choice in QuizQuestion.QUESTION_TYPES}

        for index, item in enumerate(questions, start=1):
            if not isinstance(item, dict):
                continue

            q_type = (
                str(item.get("type") or item.get("question_type") or "mcq")
                .strip()
                .lower()
            )
            if q_type in {"truefalse", "true-false", "boolean"}:
                q_type = "true_false"
            if q_type not in allowed_types:
                q_type = "mcq"

            prompt = str(item.get("question") or item.get("prompt") or "").strip()
            if not prompt:
                continue

            options = (
                item.get("options") if isinstance(item.get("options"), list) else []
            )
            options = [str(opt).strip() for opt in options if str(opt).strip()]

            answer = str(item.get("answer") or item.get("correct_answer") or "").strip()
            explanation = str(item.get("explanation") or "").strip()

            normalized_questions.append(
                {
                    "order": index,
                    "question_type": q_type,
                    "prompt": prompt,
                    "options": options,
                    "correct_answer": answer,
                    "explanation": explanation,
                }
            )

            if len(normalized_questions) >= question_count:
                break

        return {
            "title": title,
            "topic": topic,
            "language": normalized_language,
            "difficulty": normalized_difficulty,
            "question_count": len(normalized_questions),
            "formats": formats,
            "questions": normalized_questions,
        }


quiz_service = QuizService()
