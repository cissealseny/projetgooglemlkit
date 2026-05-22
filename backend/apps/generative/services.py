import logging
import time

from django.conf import settings

logger = logging.getLogger(__name__)


class GenerativeService:

    SYSTEM_PROMPT = """Tu es l'Eco-Assistant de l'application Eco-smart.
Ta mission principale est de guider les utilisateurs dans l'application et de répondre à toutes leurs questions sur Eco-smart.
Réponds toujours en français, avec un ton calme, chaleureux, simple et utile.

Tu connais ces parties de l'application :
1. Accueil : résumé de l'impact, accès rapide au scan, au quiz, aux statistiques et aux fonctions principales.
2. Scanner un déchet / Vision : l'utilisateur prend une photo ou scanne un code-barres. L'application identifie le déchet, son type, son poids estimé, les points et les gains.
3. Nouvelle collecte : l'utilisateur enregistre une collecte manuelle avec la société partenaire, le type de déchet et le poids en kg.
4. Centres : carte des centres de recyclage et de collecte proches de l'utilisateur.
5. Eco-Impact / Statistiques : totaux recyclés, gains en TND, points, graphiques et historique des collectes.
6. Eco-smart / prédiction : estimation et analyse intelligente autour des déchets, des gains et du recyclage.
7. Eco-Quiz : questions sur l'environnement et le recyclage pour apprendre et gagner des points bonus.
8. Profil : informations de l'utilisateur, progression, paramètres et données personnelles.
9. Assistant IA : aide l'utilisateur à comprendre l'application, trouver une page, expliquer une fonctionnalité, ou obtenir des conseils écologiques liés au recyclage.

Tu peux aussi donner des conseils sur le tri, le recyclage, l'upcycling, le compostage, les centres de collecte et les bons gestes écologiques.

Si la question n'a aucun lien avec l'application Eco-smart, le recyclage, l'environnement, les déchets, les centres de collecte ou l'aide à l'utilisateur dans cette application, ne réponds pas au sujet externe. Réponds paisiblement exactement dans cet esprit :
"Voulez-vous savoir quelque chose sur l'application ? Je suis là pour vous assister."
"""

    def __init__(self):
        self.ollama_host = getattr(settings, "OLLAMA_HOST", "http://localhost:11434")
        self.gemini_api_key = getattr(settings, "GEMINI_API_KEY", "")
        self.openai_api_key = getattr(settings, "OPENAI_API_KEY", "")

    # -------------------------------------------------
    # CHAT ROUTER
    # -------------------------------------------------
    def chat(self, messages, model="ollama:mistral", temperature=0.7, max_tokens=1024):
        start_time = time.time()
        messages = self._with_system_prompt(messages)

        try:

            if model.startswith("ollama:"):
                ollama_model = model.replace("ollama:", "")
                return self._ollama_chat(
                    messages, ollama_model, temperature, max_tokens
                )

            elif model.startswith("hf:"):
                hf_model = model.replace("hf:", "")
                return self._huggingface_chat(
                    messages, hf_model, temperature, max_tokens
                )

            elif model.startswith("gemini:"):
                gemini_model = model.replace("gemini:", "")
                return self._gemini_chat(
                    messages, gemini_model, temperature, max_tokens
                )

            elif model.startswith("gpt:"):
                gpt_model = model.replace("gpt:", "")
                return self._openai_chat(messages, gpt_model, temperature, max_tokens)

            else:
                raise Exception("Unsupported model provider")

        except Exception as e:
            logger.error(f"Chat error: {str(e)}")

            # If local Ollama fails, transparently fallback to Gemini when configured.
            if model.startswith("ollama:") and self.gemini_api_key:
                try:
                    fallback_result = self._gemini_chat(
                        messages,
                        "gemini-2.0-flash",
                        temperature,
                        max_tokens,
                    )
                    fallback_result["fallback_from"] = model
                    fallback_result["fallback_notice"] = (
                        "Ollama indisponible, reponse generee via Gemini 2.0 Flash."
                    )
                    return fallback_result
                except Exception as fallback_error:
                    logger.error(f"Gemini fallback failed: {str(fallback_error)}")

            return {
                "success": False,
                "error": str(e),
                "processing_time": time.time() - start_time,
            }

    # -------------------------------------------------
    # OLLAMA
    # -------------------------------------------------
    def _ollama_chat(self, messages, model, temperature, max_tokens):

        start_time = time.time()

        try:
            import ollama

            response = ollama.chat(
                model=model,
                messages=messages,
                options={"temperature": temperature, "num_predict": max_tokens},
            )

            return {
                "success": True,
                "response": response["message"]["content"],
                "model": f"ollama:{model}",
                "tokens_used": 0,
                "processing_time": time.time() - start_time,
            }

        except Exception as e:
            raise Exception(f"Ollama error: {str(e)}")

    # -------------------------------------------------
    # HUGGINGFACE
    # -------------------------------------------------
    def _huggingface_chat(self, messages, model, temperature, max_tokens):

        start_time = time.time()

        try:
            from transformers import pipeline

            prompt = "\n".join(
                [f"{m['role'].upper()}: {m['content']}" for m in messages]
            )
            prompt += "\nASSISTANT:"

            generator = pipeline(
                "text-generation",
                model=model,
                max_new_tokens=max_tokens,
                temperature=temperature,
                do_sample=True,
            )

            output = generator(prompt)[0]["generated_text"]
            response_text = output.split("ASSISTANT:")[-1].strip()

            return {
                "success": True,
                "response": response_text,
                "model": f"hf:{model}",
                "tokens_used": 0,
                "processing_time": time.time() - start_time,
            }

        except Exception as e:
            raise Exception(f"HuggingFace error: {str(e)}")

    # -------------------------------------------------
    # GEMINI
    # -------------------------------------------------
    def _gemini_chat(self, messages, model, temperature, max_tokens):

        start_time = time.time()

        try:
            import google.generativeai as genai

            genai.configure(api_key=self.gemini_api_key)

            gemini_model = genai.GenerativeModel(
                model_name=model,
                generation_config=genai.types.GenerationConfig(
                    temperature=temperature,
                    max_output_tokens=max_tokens,
                ),
            )

            system_context = "\n\n".join(
                msg["content"] for msg in messages if msg.get("role") == "system"
            )
            conversation_messages = [
                msg for msg in messages if msg.get("role") != "system"
            ]
            if not conversation_messages:
                conversation_messages = [{"role": "user", "content": ""}]

            history = []
            for msg in conversation_messages[:-1]:
                role = "user" if msg["role"] == "user" else "model"
                history.append({"role": role, "parts": [msg["content"]]})

            chat_session = gemini_model.start_chat(history=history)

            last_content = conversation_messages[-1]["content"]
            if system_context:
                last_content = (
                    f"{system_context}\n\n" f"Question utilisateur:\n{last_content}"
                )

            response = chat_session.send_message(last_content)

            return {
                "success": True,
                "response": response.text,
                "model": f"gemini:{model}",
                "tokens_used": 0,
                "processing_time": time.time() - start_time,
            }

        except Exception as e:
            raise Exception(f"Gemini error: {str(e)}")

    # -------------------------------------------------
    # OPENAI GPT
    # -------------------------------------------------
    def _openai_chat(self, messages, model, temperature, max_tokens):

        start_time = time.time()

        try:
            from openai import OpenAI

            client = OpenAI(api_key=self.openai_api_key)

            response = client.chat.completions.create(
                model=model,
                messages=messages,
                temperature=temperature,
                max_tokens=max_tokens,
            )

            return {
                "success": True,
                "response": response.choices[0].message.content,
                "model": f"gpt:{model}",
                "tokens_used": response.usage.total_tokens,
                "processing_time": time.time() - start_time,
            }

        except Exception as e:
            raise Exception(f"OpenAI error: {str(e)}")

    # -------------------------------------------------
    # HELPER FUNCTIONS
    # -------------------------------------------------
    def _with_system_prompt(self, messages):
        normalized_messages = list(messages or [])
        if any(msg.get("role") == "system" for msg in normalized_messages):
            return normalized_messages

        return [
            {"role": "system", "content": self.SYSTEM_PROMPT},
            *normalized_messages,
        ]

    def generate_text(
        self, prompt, model="ollama:mistral", temperature=0.7, max_tokens=1024
    ):

        messages = [{"role": "user", "content": prompt}]

        return self.chat(messages, model, temperature, max_tokens)

    def generate_code(self, prompt, language="python", model="ollama:mistral"):

        code_prompt = f"""
Generate {language} code for the following task:
{prompt}

Only output the code with comments.
"""

        return self.generate_text(code_prompt, model, temperature=0.3, max_tokens=2048)

    def generate_embedding(self, text, model="hf:all-MiniLM-L6-v2"):

        start_time = time.time()

        try:
            from sentence_transformers import SentenceTransformer

            hf_model = model.replace("hf:", "")
            st_model = SentenceTransformer(hf_model)

            embedding = st_model.encode(text).tolist()

            return {
                "success": True,
                "embedding": embedding,
                "model": hf_model,
                "dimensions": len(embedding),
                "processing_time": time.time() - start_time,
            }

        except Exception as e:
            return {
                "success": False,
                "error": str(e),
                "processing_time": time.time() - start_time,
            }


generative_service = GenerativeService()
